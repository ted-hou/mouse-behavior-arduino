/*********************************************************************
  Arduino state machine code for Pavlovian-Operant Training (mice)
  
  Training Paradigm and Architecture    - Allison Hamilos (ahamilos@g.harvard.edu)
  Matlab Serial Communication Interface - Ofer
  State System Architecture             - Lingfeng Hou (lingfenghou@g.harvard.edu)

  Created       9/16/16 - ahamilos
  Last Modified 9/20/16 - ahamilos
  
  (prior version: LFH Arduino STATE_MACHINE_v1_AH)
  ------------------------------------------------------------------
  COMPATIBILITY REPORT:
    Matlab HOST: Matlab 2016a - FileName = TBD
    Arduino:
      Default: MEGA
      Others:  UNO, TEENSY, DUE
  ------------------------------------------------------------------
  Reserved:
    
    Event Markers: 0-11
    States:        0-8
    Result Codes:  0-3
    Parameters:    0-12
  ------------------------------------------------------------------
  Task Architecture: Pavlovian-Operant

  Init Trial                (event marker = 0)
    -  House Lamp OFF       (event marker = 1)
    -  Random delay
  Trial Body
    -  Cue presentation     (event marker = 2)
    -  Pre-window interval
    -  Window opens         (event marker = 3)
    -  1st half response window
    -  Target time          (event marker = 4)    - (Pavlovian-only) reward dispensed (event marker = 8)
    -  2nd half response window
    -  Window closes        (event marker = 5)
    -  Post-window Interval                       - trial aborted at this point           
  End Trial                 (event marker = 6)    - House lamps ON (if not already)
    -  ITI                  (event marker = 7)

  Behavioral Events:
    -  Lick                 (event marker = 8)
    -  Reward dispensed     (event marker = 9)
    -  Waiting for ITI      (event marker = 10)   - enters this state if trial aborted by behavioral error, House lamps ON
  --------------------------------------------------------------------
  States:
    0: _INIT                (private) 1st state in init loop, sets up communication to Matlab HOST
    1: IDLE_STATE           Awaiting command from Matlab HOST to begin experiment
    2: TRIAL_INIT           House lamp OFF, random delay before cue presentation
    3: PRE_WINDOW           (+/-) Enforced no lick before response window opens
    4: RESPONSE_WINDOW      First lick in this interval rewarded (operant). Reward delivered at target time (pavlov)
    5: POST_WINDOW          Checking for late licks
    6: REWARD               Dispense reward, wait for trial Timeout
    7: ABORT_TRIAL          Behavioral Error - House lamps ON, await trial Timeout
    8: INTERTRIAL           House lamps ON (if not already), write data to HOST and DISK
  ---------------------------------------------------------------------
  Result Codes:
    0: CODE_CORRECT         First lick within response window               
    1: CODE_EARLY_LICK      Early lick -> Abort (Enforced No-Lick Only)
    2: CODE_LATE_LICK       Late Lick  -> Abort (Operant Only)
    3: CODE_NO_LICK         No Response -> Time Out
  ---------------------------------------------------------------------
  Parameters:
    0:  _DEBUG              (private) 1 to enable debug messages to HOST
    1:  PAVLOVIAN           1 to enable Pavlovian Mode
    2:  OPERANT             1 to enable Operant Mode
    3:  ENFORCE_NO_LICK     1 to enforce no lick in the pre-window interval
    4:  INTERVAL_MIN        Time to start of reward window (ms)
    5:  INTERVAL_MAX        Time to end of reward window (ms)
    6:  TARGET              Target time (ms)
    7:  TRIAL_DURATION      Total alloted time/trial (ms)
    8:  ITI                 Intertrial interval duration (ms)
    9:  RANDOM_DELAY_MIN    Minimum random pre-Cue delay (ms)
    10: RANDOM_DELAY_MAX    Maximum random pre-Cue delay (ms)
    11: CUE_DURATION        Duration of the cue tone and LED flash (ms)
    12: REWARD_DURATION     Duration of reward dispensal
  ---------------------------------------------------------------------
    Incoming Message Syntax: (received from Matlab HOST)
      "(character)#"        -- a command
      "(character int1 int2)# -- update parameter (int1) to new value (int2)"
      Command characters:
        P  -- parameter
        O# -- HOST has received updated paramters, may resume trial
        Q# -- quit and go to IDLE_STATE
        G# -- begin trial (from IDLE_STATE)
  ---------------------------------------------------------------------
    Outgoing Message Syntax: (delivered to Matlab HOST)
      ONLINE:  
        "~"                           Tells Matlab HOST arduino is running
      STATES:
        "@ (enum num) stateName"      Defines state names for Matlab HOST
        "$(enum num) num num"         State-number, parameter, value
 -                                          param = 0: current time
 -                                          param = 1: result code (enum num)
      EVENT MARKERS:
        "+(enum num) eventMarker"     Defines event markers with string
        "&(enum num) timestamp"       Event Marker with timestamp

      RESULT CODES:
      "* (enum num) result_code_name" Defines result code names with str 
      "` (enum num of result_code)"   Send result code for trial to Matlab HOST

      MESSAGE:
        "string"                      String to Matlab HOST serial monitor (debugging) 
  ---------------------------------------------------------------------
  STATE MACHINE
    - States are written as individual functions
    - The main loop calls the appropriate state function depending on current state.
    - A state function consists of two parts
     - Action: executed once when first entering this state.
     - Transitions: evaluated on each loop and determines what the next state should be.
*********************************************************************/



/*****************************************************
  Global Variables
*****************************************************/

  /*****************************************************
    Arduino Pin Outs (Mode: MEGA)
  *****************************************************/

    // Digital OUT
    #define PIN_HOUSE_LAMP     6  // House Lamp Pin         (DUE = 34)  (MEGA = 34)  (UNO = 5?)  (TEENSY = 6?)
    #define PIN_LED_CUE        4  // Cue LED Pin            (DUE = 35)  (MEGA = 28)  (UNO =  4)  (TEENSY = 4)
    #define PIN_REWARD         7  // Reward Pin             (DUE = 37) (MEGA = 52)  (UNO =  7)  (TEENSY = 7)

    // PWM OUT
    #define PIN_SPEAKER        5  // Speaker Pin            (DUE =  2)  (MEGA =  8)  (UNO =  9)  (TEENSY = 5)

    // Digital IN
    #define PIN_LICK           3  // Lick Pin               (DUE = 36)  (MEGA =  2)  (UNO =  2)  (TEENSY = 2)


  /*****************************************************
    Enums - DEFINE States
  *****************************************************/
    // All the states
    enum State
    {
      _INIT,                // (Private) Initial state used on first loop. 
      IDLE_STATE,           // Idle state. Wait for go signal from host.
      REWARD,               // Dispense reward, wait for trial Timeout
      _NUM_STATES           // (Private) Used to count number of states
    };

    // State names stored as strings, will be sent to host
    // Names cannot contain spaces!!!
    static const char *_stateNames[] = 
    {
      "_INIT",
      "IDLE_STATE",
      "REWARD"
    };

    // Define which states allow param update
    static const int _stateCanUpdateParams[] = {0,1,0}; 
    // Defined to allow Parameter upload from host during IDLE_STATE and INTERTRIAL


  /*****************************************************
    Event Markers
  *****************************************************/
    enum EventMarkers
    /* You may define as many event markers as you like.
        Assign event markers to any IN/OUT event
        Times and trials will be defined by global time, 
        which can be parsed later to validate time measurements */
    {
      _NUM_OF_EVENT_MARKERS
    };

    static const char *_eventMarkerNames[] =    // * to define array of strings
    {
    };


  /*****************************************************
    Result codes
  *****************************************************/
    enum ResultCode
    {
      _NUM_RESULT_CODES                          // (Private) Used to count how many codes there are.
    };

    // We'll send result code translations to MATLAB at startup
    static const char *_resultCodeNames[] =
    {
    };


  /*****************************************************
    Audio cue frequencies
  *****************************************************/
    enum SoundEventFrequencyEnum
    {
      TONE_REWARD = 5050,             // Correct tone: (prev C8 = 4186)
      TONE_ABORT  = 440,              // Error tone: (prev C3 = 131)
      TONE_CUE    = 3300,             // 'Start counting the interval' cue: (prev C6 = 1047)
      TONE_ALERT  = 131               // Reserved for system errors
    };

  /*****************************************************
    Parameters that can be updated by HOST
  *****************************************************/
    // Storing everything in array _params[]. Using enum ParamID as array indices so it's easier to add/remove parameters. 
    enum ParamID
    {
      _DEBUG,                         // (Private) 1 to enable debug messages from HOST. Default 0.
      NUM_REWARDS,
      REWARD_DURATION,
      TIME_BETWEEN_REWARDS,
      _NUM_PARAMS                     // (Private) Used to count how many parameters there are so we can initialize the param array with the correct size. Insert additional parameters before this.
    }; //**** BE SURE TO ADD NEW PARAMS TO THE NAMES LIST BELOW!*****//

    // Store parameter names as strings, will be sent to host
    // Names cannot contain spaces!!!
    static const char *_paramNames[] = 
    {
      "_DEBUG",
      "NUM_REWARDS",
      "REWARD_DURATION",
      "TIME_BETWEEN_REWARDS"
    }; //**** BE SURE TO INIT NEW PARAM VALUES BELOW!*****//

    // Initialize parameters
    int _params[_NUM_PARAMS] = 
    {
      0,                              // _DEBUG
      100,                            // NUM_REWARDS
      100,                            // REWARD_DURATION
      100,                            // TIME_BETWEEN_REWARDS
    };

  /*****************************************************
    Other Global Variables 
  *****************************************************/
    // Variables declared here can be carried to the next loop, AND read/written in function scope as well as main scope
    // (previously defined):
      // static unsigned long _eventMarkerTimer = 0;
      // static unsigned long _trialTimer = 0;
      // static long _resultCode              = 0;        // Result code number, see "enum ResultCode" for details.
    static unsigned long _random_delay_timer = 0;    // Random delay timer
    static unsigned long _single_loop_timer = 0;     // Timer
    static State _state                  = _INIT;    // This variable (current _state) get passed into a _state function, which determines what the next _state should be, and updates it to the next _state.
    static State _prevState              = _INIT;    // Remembers the previous _state from the last loop (actions should only be executed when you enter a _state for the first time, comparing currentState vs _prevState helps us keep track of that).
    static char _command                 = ' ';      // Command char received from host, resets on each loop
    static int _arguments[2]             = {0};      // Two integers received from host , resets on each loop
    static bool _lick_state              = false;    // True when lick detected, False when no lick
    static bool _pre_window_elapsed      = false;    // Track if pre_window time has elapsed
    static bool _reached_target          = false;    // Track if target time reached
    static bool _late_lick_detected      = false;    // Track if late lick detected
    static unsigned long _exp_timer      = 0;        // Experiment timer, reset to millis() at every soft reset
    static unsigned long _lick_time      = 0;        // Tracks most recent lick time
    static unsigned long _cue_on_time    = 0;        // Tracks time cue has been displayed for
    static unsigned long _response_window_timer = 0; // Tracks time in response window state
    static unsigned long _reward_timer = 0;          // Tracks time in reward state
    static unsigned long _abort_timer = 0;           // Tracks time in abort state
    static unsigned long _ITI_timer = 0;             // Tracks time in ITI state
    static unsigned long _preCueDelay = 0;           // Initialize _preCueDelay var
    static bool _reward_dispensed_complete = false;  // init tracker of reward dispensal

    //------Debug Mode: measure tick-rate (per ms)------------//
    static unsigned long _debugTimer     = 0;        // Debugging _single_loop_timer
    static unsigned long _ticks          = 0;        // # of loops/sec in the debugger


/*****************************************************
  INITIALIZATION LOOP
*****************************************************/
  void setup()
  {
    //--------------------I/O initialization------------------//
    // OUTPUTS
    pinMode(PIN_HOUSE_LAMP, OUTPUT);            // LED for illumination (trial cue)
    pinMode(PIN_LED_CUE, OUTPUT);               // LED for 'start' cue
    pinMode(PIN_SPEAKER, OUTPUT);               // Speaker for cue/correct/error tone
    pinMode(PIN_REWARD, OUTPUT);                // Reward OUT
    // INPUTS
    pinMode(PIN_LICK, INPUT);                   // Lick detector
    //--------------------------------------------------------//



    //------------------------Serial Comms--------------------//
    Serial.begin(115200);                       // Set up USB communication at 115200 baud 

  } // End Initialization Loop -----------------------------------------------------------------------------------------------------


/*****************************************************
  MAIN LOOP
*****************************************************/
  void loop()
  {
    // Initialization
    mySetup();

    // Main loop (R# resets it)
    while (true)
    {
      // //----------------------DEBUG MODE------------------------//
      // //* Debug mode will count the number of loop cycles/1000 ms to determine the reliability of arduino clock *//
      // if (millis() - _debugTimer == 1000)  {       // If 1000 ms since last tick readout...
      //   if (_params[_DEBUG]) {                           // If DEBUG mode is on
      //     sendMessage("Tick rate: " + String(_ticks) + " ticks per second.");  // Sends message to Matlab host
      //   }
      //   _ticks = 0;                                      // reset _ticks to 0
      //   _debugTimer = millis();                          // reset debug clock
      // }
      // else if (millis() - _debugTimer > 1000)  {   // If MORE than 1000 ms have passed, it means we lost a ms on the last loop
      //   if (_params[_DEBUG]) {
      //     sendMessage("Tick rate: A ms was lost on last loop cycle...Clock Speed Error?");
      //   }
      //   _ticks = 0;                                      // reset _ticks to 0
      //   _debugTimer = millis();                          // reset debug clock
      // }
      // else if (millis() - _debugTimer < 1000)  {   // If LESS than 1000 ms have passed, acculumate a loop tick
      //   _ticks = _ticks + 1;                              // Add a tick to the measurement
      // }
      // //----------------------end DEBUG MODE------------------------//



      /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        Step 1: Read USB MESSAGE from HOST (if available)
      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
      // 1) Check USB for MESSAGE from HOST, if available. String is read byte by byte. (Each character is a byte, so reads e/a character)
      static String usbMessage  = "";             // Initialize usbMessage to empty string, only happens once on first loop (thanks to static!)
      _command = ' ';                              // Initialize _command to a SPACE
      _arguments[0] = 0;                           // Initialize 1st integer argument
      _arguments[1] = 0;                           // Initialize 2nd integer argument

      if (Serial.available() > 0)  {              // If there's something in the SERIAL INPUT BUFFER (i.e., if another character from host is waiting in the queue to be read)
        char inByte = Serial.read();                  // Read next character
        
        // The pound sign ('#') indicates a complete message!------------------------
        if (inByte == '#')  {                         // If # received, terminate the message
          // Parse the string, and updates `_command`, and `_arguments`
          _command = getCommand(usbMessage);               // getCommand pulls out the character from the message for the _command         
          getArguments(usbMessage, _arguments);            // getArguments pulls out the integer values from the usbMessage
          usbMessage = "";                                // Clear message buffer (resets to prepare for next message)
          if (_command == 'R') {
            break;
          }
        }
        else {
          // append character to message buffer
          usbMessage = usbMessage + inByte;       // Appends the next character from the queue to the usbMessage string
        }
      }

      /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        Step 2: Update the State Machine
      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
      // Depending on what _state we're in , call the appropriate _state function, which will evaluate the transition conditions, and update `_state` to what the next _state should be
      switch (_state) {
        case _INIT:
          idle_state();
          break;

        case IDLE_STATE:
          idle_state();
          break;

        case REWARD: 
          reward();
          break;
        
      } // End switch statement--------------------------
    }
  } // End main loop-------------------------------------------------------------------------------------------------------------



  void mySetup()
  {

    //--------------Set ititial OUTPUTS----------------//
    setHouseLamp(true);                          // House Lamp ON
    setCueLED(false);                            // Cue LED OFF
    setReward(false);                            // Turn reward OFF

    //-----------------------Global Clocks---------------------//
    // Tick rate
    _debugTimer = millis();                      // Start DEBUG _single_loop_timer clock

    //---------------------------Reset a bunch of variables---------------------------//
    _state                   = _INIT;    // This variable (current _state) get passed into a _state function, which determines what the next _state should be, and updates it to the next _state.
    _prevState               = _INIT;    // Remembers the previous _state from the last loop (actions should only be executed when you enter a _state for the first time, comparing currentState vs _prevState helps us keep track of that).
    _command                 = ' ';      // Command char received from host, resets on each loop
    _arguments[0]            = 0;      // Two integers received from host , resets on each loop
    _arguments[1]            = 0;      // Two integers received from host , resets on each loop
    _reward_dispensed_complete = false;  // init tracker of reward dispensal
    _debugTimer              = 0;        // Debugging _single_loop_timer
    _ticks                   = 0;        // # of loops/sec in the debugger


    // Tell PC that we're running by sending '~' message:
    hostInit();                                 // Sends all parameters, states and error codes to Matlab (LF Function)    
  }










/*****************************************************
  States for the State Machine
*****************************************************/
  /* New states are initialized by the ACTION LIST
   In the main loop after state runs, Arduino checks for new parameters and switches the state */


  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IDLE STATE - awaiting start cue from Matlab HOST
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  void idle_state() {
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      ACTION LIST -- initialize the new state
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    if (_state != _prevState) {                       // If ENTERTING IDLE_STATE:
      _prevState = _state;                              // Assign _prevState to idle _state
      sendMessage("$" + String(_state));                // Send a message to host upon _state entry -- $1 (Idle State)
      setHouseLamp(true);                               // Turn House Lamp ON
      setReward(false);                                 // Kill reward
      // Reset state variables

      //------------------------DEBUG MODE--------------------------//
      if (_params[_DEBUG]) {
        sendMessage("Idle.");
      }  
      //----------------------end DEBUG MODE------------------------//
    }

    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      TRANSITION LIST -- checks conditions, moves to next state
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    
    if (_command == 'G') {                           // If Received GO signal from HOST ---transition to---> READY
      _state = REWARD;                              // State set to INIT_TRIAL
      return;                                           // Exit function
    }

    
    if (_command == 'P') {                           // Received new param from host: format "P _paramID _newValue" ('P' for Parameters)
      //----------------------DEBUG MODE------------------------// 
      if (_params[_DEBUG]) {sendMessage("Parameter " + String(_arguments[0]) + " changed to " + String(_arguments[1]));
      } 
      //-------------------end DEBUG MODE--- -------------------//

      _params[_arguments[0]] = _arguments[1];           // Update parameter. Serial input "P 0 1000" changes the 1st parameter to 1000.
      _state = IDLE_STATE;                              // State returns to IDLE_STATE
      return;                                           // Exit function
    }

    _state = IDLE_STATE;                             // Return to IDLE_STATE
  } // End IDLE_STATE ------------------------------------------------------------------------------------------------------------------------------------------



  
  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    REWARD - Deliver reward and wait for trial timeout while tracking licks
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  void reward() {
      //------------------------DEBUG MODE--------------------------//
      if (_params[_DEBUG]) {
        sendMessage("Dispensing Calibration Reward.");
      }  
      //----------------------end DEBUG MODE------------------------//
      for (int i = 1; i <= _params[NUM_REWARDS]; i++) {
        setReward(true);
        delay(_params[REWARD_DURATION]);
        setReward(false);
        delay(_params[TIME_BETWEEN_REWARDS]);
      }

      tone(PIN_SPEAKER, 100, 100);

      _state = IDLE_STATE;                                  // End
  } // End REWARD STATE ------------------------------------------------------------------------------------------------------------------------------------------



  

/*****************************************************
  HARDWARE CONTROLS
*****************************************************/

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Set House Lamp (ON/OFF)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  void setHouseLamp(bool turnOn) {
    if (turnOn) {
      digitalWrite(PIN_HOUSE_LAMP, HIGH);
    }
    else {
      digitalWrite(PIN_HOUSE_LAMP, LOW);
    }
  } // end Set House Lamp---------------------------------------------------------------------------------------------------------------------

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Set Cue LED (ON/OFF)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  void setCueLED(bool turnOn) {
    if (turnOn) {
      digitalWrite(PIN_LED_CUE, HIGH);
    }
    else {
      digitalWrite(PIN_LED_CUE, LOW);
    }
  } // end Set Cue LED---------------------------------------------------------------------------------------------------------------------

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GET LEVER STATE (True/False - Boolean)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  bool getLickState() {
    if (digitalRead(PIN_LICK) == HIGH) {
      return true;
    }
    else {
      return false;
    }
  } // end Get Lever State---------------------------------------------------------------------------------------------------------------------

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PLAY SOUND (Choose event from Enum list and input the frequency for that event)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  void playSound(SoundEventFrequencyEnum soundEventFrequency) {
    if (soundEventFrequency == TONE_REWARD) {       // MOUSE: Reward Tone
      noTone(PIN_SPEAKER);                              // Turn off current sound (if any)
      tone(PIN_SPEAKER, soundEventFrequency, 200);      // Play Reward Tone (200 ms)
      return;                                           // Exit Fx
    }
    if (soundEventFrequency == TONE_ABORT) {        // MOUSE: Abort Tone
      noTone(PIN_SPEAKER);                              // Turn off current sound (if any)
      tone(PIN_SPEAKER, soundEventFrequency, 200);      // Play Reward Tone (200 ms)
      return;                                           // Exit Fx
    }
    if (soundEventFrequency == TONE_ALERT) {        // SYSTEM: INTERNAL ERROR
      noTone(PIN_SPEAKER);                              // Turn off current sound (if any)
      tone(PIN_SPEAKER, soundEventFrequency, 2000);    // Play Alert Tone (default 2000 ms)
      return;                                           // Exit Fx
    }
  } // end Play Sound---------------------------------------------------------------------------------------------------------------------

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SET REWARD (Deliver or turn off reward)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  void setReward(bool turnOn) {
    if (turnOn)                                                       
    {                                                                 // MOUSE: Deliver Reward = TRUE
      digitalWrite(PIN_REWARD, HIGH);                                    // Reward Pin HIGH
      //------------------------DEBUG MODE--------------------------//  
        // if (_params[_DEBUG]) {sendMessage("Dispensing Reward");}
      //----------------------end DEBUG MODE------------------------//
    }
    else
    {                                                                 // MOUSE: Stop Reward
      digitalWrite(PIN_REWARD, LOW);                                     // Reward Pin LOW
      //------------------------DEBUG MODE--------------------------// 
        // if (_params[_DEBUG]) {sendMessage("Terminating Reward");}
      //----------------------end DEBUG MODE------------------------//
    }
  } // end Set Reward---------------------------------------------------------------------------------------------------------------------











/*****************************************************
  SERIAL COMMUNICATION TO HOST
*****************************************************/

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SEND MESSAGE to HOST
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  void sendMessage(String message)   // Capital (String) because is defining message as an object of type String from arduino library
  {
    Serial.println(message);
  } // end Send Message---------------------------------------------------------------------------------------------------------------------

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GET COMMAND FROM HOST (single character)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  char getCommand(String message)
  {
    message.trim();                 // Remove leading and trailing white space
    return message[0];              // Parse message string for 1st character (the command)
  } // end Get Command---------------------------------------------------------------------------------------------------------------------

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GET ARGUMENTS (of the command) from HOST (2 int array)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  void getArguments(String message, int *_arguments)  // * to initialize array of strings(?)
  {
    _arguments[0] = 0;              // Init Arg 0 to 0 (reset)
    _arguments[1] = 0;              // Init Arg 1 to 0 (reset)

    message.trim();                 // Remove leading and trailing white space from MESSAGE

    //----Remove command (first character) from string:-----//
    String parameters = message;    // The remaining part of message is now "parameters"
    parameters.remove(0,1);         // Remove the command character and # (e.g., "P#")
    parameters.trim();              // Remove any spaces before next char

    //----Parse first (optional) integer argument-----------//
    String intString = "";          // init intString as a String object. intString concatenates the arguments as a string
    while ((parameters.length() > 0) && (isDigit(parameters[0]))) 
    {                               // while the first argument in parameters has digits left in it unparced...
      intString += parameters[0];       // concatenate the next digit to intString
      parameters.remove(0,1);           // delete the added digit from "parameters"
    }
    _arguments[0] = intString.toInt();  // transform the intString into integer and assign to first argument (Arg 0)


    //----Parse second (optional) integer argument----------//
    parameters.trim();              // trim the space off of parameters
    intString = "";                 // reinitialize intString
    while ((parameters.length() > 0) && (isDigit(parameters[0]))) 
    {                               // while the second argument in parameters has digits left in it unparced...
      intString += parameters[0];       // concatenate the next digit to intString
      parameters.remove(0,1);           // delete the added digit from "parameters"
    }
    _arguments[1] = intString.toInt();  // transform the intString into integer and assign to second argument (Arg 1)
  } // end Get Arguments---------------------------------------------------------------------------------------------------------------------


  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    INIT HOST (send States, Names/Value of Parameters to HOST)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  void hostInit()
  {
    //------Send state names and which states allow parameter update-------//
    for (int iState = 0; iState < _NUM_STATES; iState++)
    {// For each state, send "@ (number of state) (state name) (0/1 can update params)"
        sendMessage("@ " + String(iState) + " " + _stateNames[iState] + " " + String(_stateCanUpdateParams[iState]));
    }

    //-------Send event marker codes---------------------------------------//
    /* Note: "&" reserved for uploading new event marker and timestamp. "+" is reserved for initially sending event marker names */
    for (int iCode = 0; iCode < _NUM_OF_EVENT_MARKERS; iCode++)
    {// For each state, send "+ (number of event marker) (event marker name)"
        sendMessage("+ " + String(iCode) + " " + _eventMarkerNames[iCode]); // Matlab adds 1 to each code # to index from 1-n rather than 0-n
    }

    //-------Send param names and default values---------------------------//
    for (int iParam = 0; iParam < _NUM_PARAMS; iParam++)
    {// For each param, send "# (number of param) (param names) (param init value)"
        sendMessage("# " + String(iParam) + " " + _paramNames[iParam] + " " + String(_params[iParam]));
    }
    //--------Send result code interpretations.-----------------------------//
    for (int iCode = 0; iCode < _NUM_RESULT_CODES; iCode++)
    {// For each result code, send "* (number of result code) (result code name)"
        sendMessage("* " + String(iCode) + " " + _resultCodeNames[iCode]);
    }
    sendMessage("~");                           // Tells PC that Arduino is on (Send Message is a LF Function)
  }











// /*****************************************************
//   Tone generator for Due -- not used in other Arduino modes
// *****************************************************/
//   /*
//   Tone generator
//   v1  use timer, and toggle any digital pin in ISR
//      funky duration from arduino version
//      TODO use FindMckDivisor?
//      timer selected will preclude using associated pins for PWM etc.
//     could also do timer/pwm hardware toggle where caller controls duration
//   */


//   // timers TC0 TC1 TC2   channels 0-2 ids 0-2  3-5  6-8     AB 0 1
//   // use TC1 channel 0 
//   #define TONE_TIMER TC1
//   #define TONE_CHNL 0
//   #define TONE_IRQ TC3_IRQn

//   // TIMER_CLOCK4   84MHz/128 with 16 bit counter give 10 Hz to 656KHz
//   //  piano 27Hz to 4KHz

//   static uint8_t pinEnabled[PINS_COUNT];
//   static uint8_t TCChanEnabled = 0;
//   static boolean pin_state = false ;
//   static Tc *chTC = TONE_TIMER;
//   static uint32_t chNo = TONE_CHNL;

//   volatile static int32_t toggle_count;
//   static uint32_t tone_pin;

//   // frequency (in hertz) and duration (in milliseconds).

//   void tone(uint32_t ulPin, uint32_t frequency, int32_t duration)
//   {
//       const uint32_t rc = VARIANT_MCK / 256 / frequency; 
//       tone_pin = ulPin;
//       toggle_count = 0;  // strange  wipe out previous duration
//       if (duration > 0 ) toggle_count = 2 * frequency * duration / 1000;
//        else toggle_count = -1;

//       if (!TCChanEnabled) {
//         pmc_set_writeprotect(false);
//         pmc_enable_periph_clk((uint32_t)TONE_IRQ);
//         TC_Configure(chTC, chNo,
//           TC_CMR_TCCLKS_TIMER_CLOCK4 |
//           TC_CMR_WAVE |         // Waveform mode
//           TC_CMR_WAVSEL_UP_RC ); // Counter running up and reset when equals to RC
    
//         chTC->TC_CHANNEL[chNo].TC_IER=TC_IER_CPCS;  // RC compare interrupt
//         chTC->TC_CHANNEL[chNo].TC_IDR=~TC_IER_CPCS;
//         NVIC_EnableIRQ(TONE_IRQ);
//                TCChanEnabled = 1;
//       }
//       if (!pinEnabled[ulPin]) {
//         pinMode(ulPin, OUTPUT);
//         pinEnabled[ulPin] = 1;
//       }
//       TC_Stop(chTC, chNo);
//       TC_SetRC(chTC, chNo, rc);    // set frequency
//       TC_Start(chTC, chNo);
//   }

//   void noTone(uint32_t ulPin)
//   {
//     TC_Stop(chTC, chNo);  // stop timer
//     digitalWrite(ulPin,LOW);  // no signal on pin
//   }

//   // timer ISR  TC1 ch 0
//   void TC3_Handler ( void ) {
//     TC_GetStatus(TC1, 0);
//     if (toggle_count != 0){
//       // toggle pin  TODO  better
//       digitalWrite(tone_pin,pin_state= !pin_state);
//       if (toggle_count > 0) toggle_count--;
//     } else {
//       noTone(tone_pin);
//     }
//   }
