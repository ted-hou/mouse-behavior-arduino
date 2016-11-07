/*********************************************************************
  Arduino state machine code for Lever Training (mice)
  
  Training Paradigm and Architecture    - Allison Hamilos (ahamilos@g.harvard.edu)
  Matlab Serial Communication Interface - Ofer
  State System Architecture             - Lingfeng Hou (lingfenghou@g.harvard.edu)

  Created       11/2/16 - ahamilos
  Last Modified 11/7/16 - ahamilos
  
  (prior version: PAV_OP_QUININE2)
  New to this version: 
  -> Keeping architecture of pav-op task, implement the lever control for task
  ------------------------------------------------------------------
  COMPATIBILITY REPORT:
    Matlab HOST: Matlab 2016a - FileName = MouseBehaviorInterface.m (depends on ArduinoConnection.m)
    Arduino:
      Default: TEENSY
      Others:  DUE, MEGA (NOTE! This version no longer compatible with UNO (not enough memory))
  ------------------------------------------------------------------
  Reserved:
    
    Event Markers: 0-16
    States:        0-10
    Result Codes:  0-3
    Parameters:    0-20
  ------------------------------------------------------------------
  Task Architecture: Lever Press and Hold

  Init Trial                (event marker = 0)
    -  House Lamp OFF       (event marker = 1)
    -  Lever Press          (event marker = 2)
    -  Random delay state   (event marker = 3)
  Trial Body
    -  Cue presentation     (event marker = 4)
    -  Pre-window interval
    -  Window opens         (event marker = 5)
    -  1st half response window
    -  Target time          (event marker = 6)
    -  2nd half response window
    -  Window closes        (event marker = 7)
    -  Post-window Interval                       - trial aborted at this point           
  End Trial                 (event marker = 8)    - House lamps ON (if not already)
    -  ITI                  (event marker = 9)    - Enforced no press - i.e., wait for him to get off lever before init next trial

  Behavioral Events:
    -  Lever Press          (event marker = 2)
    -  Lever Release        (event marker = 10)
    -  Lick                 (event marker = 11)
    -  Reward dispensed     (event marker = 12)
    -  Quinine dispensed    (event marker = 13)
    -  Behavioral Error     (event marker = 14)   - enters this state if trial aborted by behavioral error, House lamps ON
    -  Never Released       (event marker = 15)   - enters this state if still holding lever at trial end
    -  Correct Release      (event marker = 16)
  --------------------------------------------------------------------
  States:
    0: _INIT                (private) 1st state in init loop, sets up communication to Matlab HOST
    1: IDLE_STATE           Awaiting command from Matlab HOST to begin experiment
    2: TRIAL_INIT           House lamp OFF, wait for press, 
    3: RANDOM_DELAY         Random delay before Cue presented
    4: PRE_WINDOW           (+/-) Enforced no lick before response window opens, enforced no release
    5: RESPONSE_WINDOW      Release in this interval rewarded. Correct tone, then reward delivered
    6: POST_WINDOW          Checking for late lever release
    7: REWARD               Dispense reward, wait for trial Timeout
    8: ABORT_TRIAL          Behavioral Error - House lamps ON, await trial Timeout
    9: WAIT_FOR_RELEASE     Wait for release if never let go
    10: INTERTRIAL           House lamps ON (if not already), write data to HOST and DISK, enforce no press before going to TRIAL_INIT
  ---------------------------------------------------------------------
  Result Codes:
    0: CODE_CORRECT         First lick within response window               
    1: CODE_EARLY_LICK      Early lick -> Abort (Enforced No-Lick Only)
    2: CODE_EARLY_RELEASE   Early Release  -> Abort (either during trial init or prewindow)
    3: CODE_LATE_RELEASE    Late Release -> Abort
    4: CODE_NO_RELEASE      No Release in Trial Time -> ITI
  ---------------------------------------------------------------------
  Parameters:
    0:  _DEBUG              (private) 1 to enable debug messages to HOST
    1:  ENFORCE_NO_LICK     1 to enforce no lick in the pre-window interval
    2:  INTERVAL_MIN        Time to start of reward window (ms)
    3:  INTERVAL_MAX        Time to end of reward window (ms)
    4:  TARGET              Target time (ms)
    5:  TRIAL_DURATION      Total alloted time/trial (ms)
    6:  ITI                 Intertrial interval duration (ms)
    7:  RANDOM_DELAY_MIN    Minimum random pre-Cue delay (ms)
    8: RANDOM_DELAY_MAX    Maximum random pre-Cue delay (ms)
    9: CUE_DURATION        Duration of the cue tone and LED flash (ms)
    10: REWARD_DURATION     Duration of reward dispensal (ms)
    11: QUININE_DURATION    Duration of quinine dispensal (ms)
    12: QUININE_TIMEOUT     Minimum time between quinine deterrants (ms)
    13: QUININE_MIN         Minimum time after cue before quinine available (ms)
    14: QUININE_MAX         Maximum time after cue before quinine turns off (ms)
    15: SHOCK_ON            1 to connect tube shock circuit
    16: SHOCK_MIN           Miminum time after cue before shock connected (ms)
    17: SHOCK_MAX           Maxumum time after cue before shock disconnected (ms)
    18: EARLY_LICK_ABORT    1 to abort trial with early lick
    19: ABORT_MIN           Minimum time after cue before early lick aborts trial (ms)
    20: ABORT_MAX           Maximum time after cue when abort available (ms)


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
    Arduino Pin Outs (Mode: TEENSY)
  *****************************************************/

    // Digital OUT
    #define PIN_HOUSE_LAMP     34   // House Lamp Pin         (DUE = 34)  (MEGA = 34)  (UNO = 5?)  (TEENSY = 6?)
    #define PIN_LED_CUE        28   // Cue LED Pin            (DUE = 35)  (MEGA = 28)  (UNO =  4)  (TEENSY = 4)
    #define PIN_REWARD         52   // Reward Pin             (DUE = 37)  (MEGA = 52)  (UNO =  7)  (TEENSY = 7)
    #define PIN_SHOCK          22   // Shock Trigger Pin                  (MEGA = 22)              (TEENSY = 3)
    
    // PWM OUT
    #define PIN_SPEAKER        8    // Speaker Pin            (DUE =  2)  (MEGA =  8)  (UNO =  9)  (TEENSY = 5)
    #define PIN_QUININE        9    // Quinine Pin            (DUE = 22)  (MEGA =  9)  (UNO =  8)  (TEENSY = 8) ** Must be PWM

    // Digital IN
    #define PIN_LICK           2    // Lick Pin               (DUE = 36)  (MEGA =  2)  (UNO =  2)  (TEENSY = 2)
    #define PIN_LEVER          3    // Lever Pin              (DUE = ? )  (MEGA =  3)  (UNO =  ?)  (TEENSY = 1) ** check touch sense doesn't affect Teensy


  /*****************************************************
    Enums - DEFINE States
  *****************************************************/
    // All the states
    enum State
    {
      _INIT,                // (Private) Initial state used on first loop. 
      IDLE_STATE,           // Idle state. Wait for go signal from host.
      INIT_TRIAL,           // House lamp OFF, random delay before cue presentation
      RANDOM_DELAY,         // Random delay before Cue presented
      PRE_WINDOW,           // (+/-) Enforced no lick before response window opens
      RESPONSE_WINDOW,      // First lick in this interval rewarded (operant). Reward delivered at target time (pavlov)
      POST_WINDOW,          // Check for late licks
      REWARD,               // Dispense reward, wait for trial Timeout
      ABORT_TRIAL,          // Behavioral Error - House lamps ON, await trial Timeout
      WAIT_FOR_RELEASE,     // Wait for release if never let go during trial time
      INTERTRIAL,           // House lamps ON (if not already), write data to HOST and DISK, receive new params
      _NUM_STATES           // (Private) Used to count number of states
    };


    // State names stored as strings, will be sent to host
    // Names cannot contain spaces!!!
    static const char *_stateNames[] = 
    {
      "_INIT",
      "IDLE_STATE",
      "INIT_TRIAL",
      "RANDOM_DELAY",
      "PRE_WINDOW",
      "RESPONSE_WINDOW",
      "POST_WINDOW",
      "REWARD",
      "ABORT_TRIAL",
      "WAIT_FOR_RELEASE",
      "INTERTRIAL"
    };

    // Define which states allow param update
    static const int _stateCanUpdateParams[] = {0,1,0,0,0,0,0,0,0,0,1,0}; 
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
      EVENT_TRIAL_INIT,       // New trial initiated
      EVENT_HOUSE_LAMP_OFF,   // House lamp off - start random pre-cue delay
      EVENT_LEVER_PRESS,      // Lever Pressed
      EVENT_RANDOM_DELAY,     // Entered Random Delay
      EVENT_CUE_ON,           // Begin cue presentation
      EVENT_WINDOW_OPEN,      // Response window open
      EVENT_TARGET_TIME,      // Target time
      EVENT_WINDOW_CLOSED,    // Response window closed
      EVENT_TRIAL_END,        // Trial end
      EVENT_ITI,              // Enter ITI
      EVENT_LEVER_RELEASE,    // Lever Released
      EVENT_LICK,             // Lick detected
      EVENT_REWARD,           // Reward dispensed
      EVENT_QUININE,          // Quinine dispensed
      EVENT_ABORT,            // Abort (behavioral error)
      EVENT_NEVER_RELEASED,   // Enters wait for release state
      EVENT_CORRECT_RELEASE,  // Marks time of correct release -- the reaction time
      _NUM_OF_EVENT_MARKERS
    };

    static const char *_eventMarkerNames[] =    // * to define array of strings
    {
      "TRIAL_INIT",
      "HOUSE_LAMP_OFF",
      "LEVER_PRESS",
      "RANDOM_DELAY",
      "CUE_ON",
      "WINDOW_OPEN",
      "TARGET_TIME",
      "WINDOW_CLOSED",
      "TRIAL_END",
      "ITI",
      "LICK",
      "REWARD",
      "QUININE",
      "ABORT",
      "NEVER_RELEASED",
      "CORRECT_RELEASE"
    };

    static unsigned long _eventMarkerTimer = 0;
    static unsigned long _trialTimer = 0;

  /*****************************************************
    Result codes
  *****************************************************/
    enum ResultCode
    {
      CODE_CORRECT,                              // Correct    (1st lick w/in window)
      CODE_EARLY_LICK,                           // Early Lick (-> Abort in Enforced No-Lick)                         // NOTE: Early lick should be removed
      CODE_EARLY_RELEASE,                        // Early Release  (-> Abort)
      CODE_LATE_RELEASE,                         // Late Release  (-> Abort)
      CODE_NO_RELEASE,                           // No Release    (Timeout -> Wait for Release)
      _NUM_RESULT_CODES                          // (Private) Used to count how many codes there are.
    };

    // We'll send result code translations to MATLAB at startup
    static const char *_resultCodeNames[] =
    {
      "CORRECT",
      "EARLY_LICK",
      "EARLY_RELEASE",
      "LATE_RELEASE",
      "NO_RELEASE",
    };

    static long _resultCode = -1;        // Result code number. -1 if there is no result.

  /*****************************************************
    Audio cue frequencies
  *****************************************************/
    enum SoundEventFrequencyEnum
    {
      TONE_REWARD  = 5050,             // Correct tone: (prev C8 = 4186)
      TONE_ABORT   = 440,              // Error tone: (prev C3 = 131)
      TONE_CUE     = 3300,             // 'Start counting the interval' cue: (prev C6 = 1047)
      TONE_ALERT   = 131,              // Reserved for system errors
      TONE_QUININE = 10000             // Quinine delivery -- using tone so don't require own state to deliver for set time
    };

  /*****************************************************
    Parameters that can be updated by HOST
  *****************************************************/
    // Storing everything in array _params[]. Using enum ParamID as array indices so it's easier to add/remove parameters. 
    enum ParamID
    {
      _DEBUG,                         // (Private) 1 to enable debug messages from HOST. Default 0.
      ENFORCE_NO_LICK,                // 1 to enforce no lick in the pre-window interval
      INTERVAL_MIN,                   // Time to start of reward window (ms)
      INTERVAL_MAX,                   // Time to end of reward window (ms)
      TARGET,                         // Target time (ms)
      TRIAL_DURATION,                 // Total alloted time/trial (ms)
      ITI,                            // Intertrial interval duration (ms)
      RANDOM_DELAY_MIN,               // Minimum random pre-Cue delay (ms)
      RANDOM_DELAY_MAX,               // Maximum random pre-Cue delay (ms)
      CUE_DURATION,                   // Duration of the cue tone and LED flash (ms)
      REWARD_DURATION,                // Duration of reward dispensal (ms)
      QUININE_DURATION,               // Duration of quinine dispensal (ms)
      QUININE_TIMEOUT,                // Minimum time between quinine dispensals (ms)
      QUININE_MIN,                    // Minimum time post cue before quinine available (ms)
      QUININE_MAX,                    // Maximum time post cue before quinine not available (ms)
      SHOCK_ON,                       // 1 to enable Shock Mode
      SHOCK_MIN,                      // Minimum time post cue before shock ckt connected (ms)
      SHOCK_MAX,                      // Maximum time post cue before shock ckt disconnected (ms)
      EARLY_LICK_ABORT,               // 1 to Abort with Early Licks in window (ms)
      ABORT_MIN,                      // Miminum time post cue before lick causes abort (ms)
      ABORT_MAX,                      // Maximum time post cue before abort unavailable (ms)
      _NUM_PARAMS                     // (Private) Used to count how many parameters there are so we can initialize the param array with the correct size. Insert additional parameters before this.
    }; //**** BE SURE TO ADD NEW PARAMS TO THE NAMES LIST BELOW!*****//

    // Store parameter names as strings, will be sent to host
    // Names cannot contain spaces!!!
    static const char *_paramNames[] = 
    {
      "_DEBUG",
      "ENFORCE_NO_LICK",
      "INTERVAL_MIN",
      "INTERVAL_MAX",
      "TARGET",
      "TRIAL_DURATION",
      "ITI",
      "RANDOM_DELAY_MIN",
      "RANDOM_DELAY_MAX",
      "CUE_DURATION",
      "REWARD_DURATION",
      "QUININE_DURATION",
      "QUININE_TIMEOUT",
      "QUININE_MIN",
      "QUININE_MAX",
      "SHOCK_ON",
      "SHOCK_MIN",
      "SHOCK_MAX",
      "EARLY_LICK_ABORT",
      "ABORT_MIN",
      "ABORT_MAX"
    }; //**** BE SURE TO INIT NEW PARAM VALUES BELOW!*****//

    // Initialize parameters
    int _params[_NUM_PARAMS] = 
    {
      0,                              // _DEBUG
      0,                              // ENFORCE_NO_LICK
      1250,                           // INTERVAL_MIN
      1750,                           // INTERVAL_MAX
      1500,                           // TARGET
      3000,                           // TRIAL_DURATION
      3000,                           // ITI
      400,                            // RANDOM_DELAY_MIN
      1500,                           // RANDOM_DELAY_MAX
      100,                            // CUE_DURATION
      35,                             // REWARD_DURATION
      30,                             // QUININE_DURATION
      400,                            // QUININE_TIMEOUT
      0,                              // QUININE_MIN
      1250,                           // QUININE_MAX
      0,                              // SHOCK_ON
      0,                              // SHOCK_MIN
      1250,                           // SHOCK_MAX
      0,                              // EARLY_LICK_ABORT
      0,                              // ABORT_MIN
      1250                            // ABORT_MAX
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
    static State _state                  = _INIT;    // This variable (current _state) get passed into a _state function, which determines what the next _state should be, and updates it to the next _state.
    static State _prevState              = _INIT;    // Remembers the previous _state from the last loop (actions should only be executed when you enter a _state for the first time, comparing currentState vs _prevState helps us keep track of that).
    static char _command                 = ' ';      // Command char received from host, resets on each loop
    static int _arguments[2]             = {0};      // Two integers received from host , resets on each loop
    static bool _lick_state              = false;    // True when lick detected, False when no lick
    static bool _lever_state             = false;    // True when lever pressed, false when released
    static bool _pre_window_elapsed      = false;    // Track if pre_window time has elapsed
    static bool _reached_target          = false;    // Track if target time reached
    static bool _late_lick_detected      = false;    // Track if late lick detected
    static unsigned long _exp_timer      = 0;        // Experiment timer, reset to millis() at every soft reset
    static unsigned long _lick_time      = 0;        // Tracks most recent lick time
    static unsigned long _lever_press_time=0;        // Tracks time of most recent press
    static unsigned long _cue_on_time    = 0;        // Tracks time cue has been displayed for
    static unsigned long _response_window_timer = 0; // Tracks time in response window state
    static unsigned long _reward_timer   = 0;        // Tracks time in reward state
    static unsigned long _quinine_timer  = 0;        // Tracks time since last quinine delivery
    static unsigned long _abort_timer    = 0;        // Tracks time in abort state
    static unsigned long _ITI_timer      = 0;        // Tracks time in ITI state
    static unsigned long _preCueDelay    = 0;        // Initialize _preCueDelay var
    static bool _reward_dispensed_complete = false;  // init tracker of reward dispensal
    static bool _shock_trigger_on        = false;    // Shock trigger default is off

    //------Debug Mode: measure tick-rate (per ms)------------//
    static unsigned long _single_loop_timer = 0;     // Timer for debugging cycles/loop
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
    pinMode(PIN_QUININE, OUTPUT);               // Quinine OUT
    pinMode(PIN_SHOCK, OUTPUT);                 // Shock Trigger OUT
    // INPUTS
    pinMode(PIN_LICK, INPUT);                   // Lick detector
    pinMode(PIN_LEVER, INPUT);                  // Lever detector
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
        
        case INIT_TRIAL:
          init_trial();
          break;

        case RANDOM_DELAY:
          random_delay();
          break;
        
        case PRE_WINDOW:    
          pre_window();
          break;
        
        case RESPONSE_WINDOW:         
          response_window();
          break;
        
        case POST_WINDOW:         
          post_window();
          break;

        case REWARD: 
          reward();
          break;
        
        case ABORT_TRIAL:
          abort_trial();
          break;

        
        case INTERTRIAL:
          intertrial();
          break;
      } // End switch statement--------------------------
    }
  } // End main loop-------------------------------------------------------------------------------------------------------------



  void mySetup()
  {

    //--------------Set ititial OUTPUTS----------------//
    setHouseLamp(true);                          // House Lamp ON
    setCueLED(false);                            // Cue LED OFF

    //-----------------------Global Clocks---------------------//
    // Tick rate
    _debugTimer = millis();                      // Start DEBUG _single_loop_timer clock

    //---------------------------Reset a bunch of variables---------------------------//
    _eventMarkerTimer       = 0;
    _trialTimer             = 0;
    _resultCode             = -1;       // No result code to start
    _random_delay_timer     = 0;        // Random delay timer
    _single_loop_timer      = 0;        // Timer
    _state                  = _INIT;    // This variable (current _state) get passed into a _state function, which determines what the next _state should be, and updates it to the next _state.
    _prevState              = _INIT;    // Remembers the previous _state from the last loop (actions should only be executed when you enter a _state for the first time, comparing currentState vs _prevState helps us keep track of that).
    _command                = ' ';      // Command char received from host, resets on each loop
    _arguments[0]           = 0;        // Two integers received from host , resets on each loop
    _arguments[1]           = 0;        // Two integers received from host , resets on each loop
    _lick_state             = false;    // True when lick detected, False when no lick
    _lever_state            = false;    // True when lever pressed, False when not
    _pre_window_elapsed     = false;    // Track if pre_window time has elapsed
    _reached_target         = false;    // Track if target time reached
    _late_lick_detected     = false;    // Track if late lick detected
    _exp_timer		          = millis();	// Experiment timer, reset to millis() at every soft reset
    _lick_time              = 0;        // Tracks most recent lick time
    _cue_on_time            = 0;        // Tracks time cue has been displayed for
    _response_window_timer  = 0;        // Tracks time in response window state
    _reward_timer           = 0;        // Tracks time in reward state
    _abort_timer            = 0;        // Tracks time in abort state
    _ITI_timer              = 0;        // Tracks time in ITI state
    _preCueDelay            = 0;        // Initialize _preCueDelay var
    _reward_dispensed_complete = false; // init tracker of reward dispensal
    _debugTimer             = 0;        // Debugging _single_loop_timer
    _ticks                  = 0;        // # of loops/sec in the debugger


    // Tell PC that we're running by sending '~' message:
    hostInit();                         // Sends all parameters, states and error codes to Matlab (LF Function)    
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
      setCueLED(false);                                 // Kill Cue LED
      noTone(PIN_SPEAKER);                              // Kill tone
      noTone(PIN_QUININE);                              // Kill quinine
      setShockTrigger(false);                           // Kill shock ckt
      setReward(false);                                 // Kill reward
      // Reset state variables
      _pre_window_elapsed = false;                  // Reset pre_window time tracker
      _reached_target = false;                      // Reset target time tracker
      _late_lick_detected = false;                  // Reset late lick detector
      _reward_dispensed_complete = false;           // Reset tracker of reward dispensal
      _resultCode = -1;                             // Clear previously registered result code

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
      _state = INIT_TRIAL;                              // State set to INIT_TRIAL
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
    INIT_TRIAL - Trial started. House Lamp OFF, Awaiting press
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  void init_trial() {
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      ACTION LIST -- initialize the new state
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    if (_state != _prevState) {                       // If ENTERTING READY STATE:
      //-----------------INIT TRIAL CLOCKS and OUTPUTS--------------//
      // Select the _preCueDelay now so can track time relative to cue onset (though haven't entered rand delay yet)
      _preCueDelay = random(_params[RANDOM_DELAY_MIN], _params[RANDOM_DELAY_MAX]);     // Choose random delay time
      _trialTimer = millis();                             // Start _trialTimer
      // Send event marker (trial_init) to HOST with timestamp
      sendMessage("&" + String(EVENT_TRIAL_INIT) + " " + String(millis() - _exp_timer)); 
      /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      NOTE: all events recorded in absolute time. For convenience, 
      we sometimes track events relative to the trial start as well for debugging 
      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
      _prevState = _state;                                // Assign _prevState to READY _state
      sendMessage("$" + String(_state));                  // Send  HOST _state entry -- $2 (Ready State)
      setHouseLamp(false);                                // House Lamp OFF
      // Send event marker (house_lamp_off) to HOST with timestamp
      sendMessage("&" + String(EVENT_HOUSE_LAMP_OFF) + " " + String(millis() - _exp_timer));
      //------------------------DEBUG MODE--------------------------//
        if (_params[_DEBUG]) {
          sendMessage("Trial Started. Awaiting press...");
        }
      //----------------------end DEBUG MODE------------------------//
    }


    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      TRANSITION LIST -- checks conditions, moves to next state
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    if (getLeverState()) {                            // MOUSE: "Lever Pressed"
      if (!_lever_state) {                             // If a new press initiated
        _lever_press_time = millis() - _trialTimer;    // Records _lever_press_time relative to trial start
        // Send a event marker (lick) to HOST with timestamp
        sendMessage("&" + String(EVENT_LEVER_PRESS) + " " + String(millis() - _exp_timer));
        _lever_state = true;                           // Halts press detection
        _state = RANDOM_DELAY;                         // Move -> RANDOM DELAY
        //------------------------DEBUG MODE--------------------------//
          if (_params[_DEBUG]) {sendMessage("Lever pressed to init trial, tallying press @ " + String(-(_lever_press_time + _preCueDelay)) + "ms wrt Cue ON");}
        //----------------------end DEBUG MODE------------------------//
        return;                                        // Break to RANDOM DELAY
      }
    }
    if (!getLeverState()) {                           // MOUSE: "No press"
      if (_lever_state) {                               // If press just ended  
        // Send a event marker (release) to HOST with timestamp
        sendMessage("&" + String(EVENT_LEVER_RELEASE) + " " + String(millis() - _exp_timer));                          
        _lever_state = false;                           // Resets lever detector
      }
    }

    if (getLickState()) {                            // MOUSE: "Licked"
      if (!_lick_state) {                              // If a new lick initiated
        // Send a event marker (lick) to HOST with timestamp
        sendMessage("&" + String(EVENT_LICK) + " " + String(millis() - _exp_timer));
        _lick_state = true;                            // Halts lick detection
        //------------------------DEBUG MODE--------------------------//
          if (_params[_DEBUG]) {sendMessage("Pre-press lick detected, tallying lick");}
        //----------------------end DEBUG MODE------------------------//
      }
    }


    if (_command == 'Q')  {                          // HOST: "QUIT" -> IDLE_STATE
      _state = IDLE_STATE;                                 // Set IDLE_STATE
      return;                                              // Exit Function
    }


    if (!getLickState()) {                           // MOUSE: "No lick"
      if (_lick_state) {                               // If lick just ended                            
        _lick_state = false;                           // Resets lick detector
      }
    }



    _state = INIT_TRIAL;                            // No Command --> Cycle back to INIT_TRIAL
  } // End INIT_TRIAL STATE ------------------------------------------------------------------------------------------------------------------------------------------



/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RANDOM_DELAY - Trial started, Random Delay before Cue
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  void random_delay() {
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      ACTION LIST -- initialize the new state
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    if (_state != _prevState) {                       // If ENTERTING RANDOM DELAY STATE:
      //-----------------INIT TRIAL CLOCKS and OUTPUTS--------------//
      sendMessage("&" + String(EVENT_RANDOM_DELAY) + " " + String(millis() - _exp_timer));
      _prevState = _state;                                // Assign _prevState to READY _state
      sendMessage("$" + String(_state));                  // Send  HOST _state entry -- $3 (Random Delay State)
      _random_delay_timer = millis();                     // Start _random_delay_timer
      //------------------------DEBUG MODE--------------------------//
        if (_params[_DEBUG]) {
          sendMessage("Random Pre-Cue Delay in Progress...(" + String(_preCueDelay) + "ms delay)");
        }
      //----------------------end DEBUG MODE------------------------//
    }


    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      TRANSITION LIST -- checks conditions, moves to next state
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    /*~ Check for EARLY RELEASE~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    if (!getLeverState()) {                           // MOUSE: "No press"
      if (_lever_state) {                               // If press just ended  
        // Send a event marker (release) to HOST with timestamp
        sendMessage("&" + String(EVENT_LEVER_RELEASE) + " " + String(millis() - _exp_timer));
        //sendMessage("`" + String(CODE_EARLY_RELEASE));  // Send result code (Early Release) to Matlab HOST                           
        _resultCode = CODE_EARLY_RELEASE;                  // Register result code 
        _lever_state = false;                           // Resets lever detector
        _state = ABORT_TRIAL;                           // Move -> ABORT, wait for trial timeout
        return;                                         // Break to Abort state
      }
    } /*~ ABORT TRIAL ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


    if (getLickState()) {                            // MOUSE: "Licked"
      if (!_lick_state) {                              // If a new lick initiated
        // Send a event marker (lick) to HOST with timestamp
        sendMessage("&" + String(EVENT_LICK) + " " + String(millis() - _exp_timer));
        _lick_state = true;                            // Halts lick detection
        //------------------------DEBUG MODE--------------------------//
          if (_params[_DEBUG]) {sendMessage("Pre-cue lick detected, tallying lick @ " + String(millis() - _random_delay_timer - _preCueDelay) + "ms wrt Cue ON");}
        //----------------------end DEBUG MODE------------------------//
      }
    }


    if (_command == 'Q')  {                          // HOST: "QUIT" -> IDLE_STATE
      _state = IDLE_STATE;                                 // Set IDLE_STATE
      return;                                              // Exit Function
    }


    if (!getLickState()) {                           // MOUSE: "No lick"
      if (_lick_state) {                               // If lick just ended                            
        _lick_state = false;                           // Resets lick detector
      }
    }


    if (millis() - _random_delay_timer >= _preCueDelay) {// Pre-Cue Delay elapsed -> PRE_WINDOW
      //------------------------DEBUG MODE--------------------------//  
        if (_params[_DEBUG]) {sendMessage("Pre-cue delay successfully completed.");}
      //----------------------end DEBUG MODE------------------------//
      _state = PRE_WINDOW;                              // Move to PRE_WINDOW state
      return;                                           // Exit Fx
    }



    _state = RANDOM_DELAY;                            // No Command --> Cycle back to RANDOM_DELAY
  } // End RANDOM_DELAY STATE ------------------------------------------------------------------------------------------------------------------------------------------



  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRE_WINDOW - Timing Interval (Cue presentation to opening of Reward Response Window)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  void pre_window() { 
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      ACTION LIST -- initialize the new state
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    static unsigned long pre_window_duration = _params[INTERVAL_MIN]; // Prewindow duration wrt cue onset
    if (_state != _prevState) {                      // If ENTERTING PRE_WINDOW:
      setCueLED(true);                                 // Cue LED ON
      playSound(TONE_CUE);                             // Cue tone ON
      _cue_on_time = millis();                         // Start Cue ON timer
      // Send event marker (cue_on) to HOST with timestamp
      sendMessage("&" + String(EVENT_CUE_ON) + " " + String(millis() - _exp_timer));
      _prevState = _state;                                // Assign _prevState to PRE_WINDOW state
      sendMessage("$" + String(_state));                  // Send HOST $3 (pre_window State)
      //------------------------DEBUG MODE--------------------------//  
        if (_params[_DEBUG]) {sendMessage("Cue on. Lick accepted between " + String(_params[INTERVAL_MIN]) + " - " + String(_params[INTERVAL_MAX]) + " ms");} 
      //----------------------end DEBUG MODE------------------------//
    }

    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      TRANSITION LIST -- checks conditions, moves to next state
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    if (_command == 'Q')  {                          // HOST: "QUIT" -> IDLE_STATE
      _state = IDLE_STATE;                                 // Set IDLE_STATE
      return;                                              // Exit Function
    }

    /*~ Check for EARLY RELEASE~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    if (!getLeverState()) {                           // MOUSE: "No press"
      if (_lever_state) {                               // If press just ended  
        // Send a event marker (release) to HOST with timestamp
        sendMessage("&" + String(EVENT_LEVER_RELEASE) + " " + String(millis() - _exp_timer));
        //sendMessage("`" + String(CODE_EARLY_RELEASE));  // Send result code (Early Release) to Matlab HOST                                
        _resultCode = CODE_EARLY_RELEASE;               // Register result code 
        _lever_state = false;                           // Resets lever detector
        _state = ABORT_TRIAL;                           // Move -> ABORT, wait for trial timeout
        return;                                         // Break to Abort state
      }
    } /*~ ABORT TRIAL ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

    if (millis() - _cue_on_time >= _params[CUE_DURATION]) {// Time to turn off Cue
      setCueLED(false);                                   // Turn Cue LED OFF
    }

    if (_params[SHOCK_ON] == 1) {                   // If shock circuit enforced
        if (!_shock_trigger_on && millis() - _cue_on_time > _params[SHOCK_MIN] && millis()-_cue_on_time < _params[SHOCK_MAX]) { // If shock window is open
            setShockTrigger(true);                          // Connect the shock ckt        
        }
        else if (_shock_trigger_on) {               // Otherwise, if shock is on, but we're in the wrong window...                                            
          setShockTrigger(false);                           // Disconnect shock ckt
        }
    }

    unsigned long current_time = millis()-_cue_on_time; 
    if (!_pre_window_elapsed && current_time >= _params[INTERVAL_MIN]) { // If prewindow elapsed, break to response window
      // Send event marker (target time) to HOST with timestamp relative to trial start
      _pre_window_elapsed = true;                    // Indicate prewindow elapsed
      _state = RESPONSE_WINDOW;                            // Move -> RESPONSE_WINDOW
      //------------------------DEBUG MODE--------------------------//  
      if (_params[_DEBUG]) {
        sendMessage("Prewindow successfully elapsed at " + String(current_time) +"ms wrt cue onset.");
      }
      //----------------------end DEBUG MODE------------------------//
      return;                                        // Break to RESPONSE_WINDOW
    }


    if (getLickState()) {                            // MOUSE: "Licked"
      if (!_lick_state) {                              // If new lick
        //======================ENFORCED NO LICK=========================//
        if (_params[ENFORCE_NO_LICK] == 1) {
          _lick_time = millis() - _cue_on_time;          // Records lick wrt CUE ON
          // Send a event marker (lick) to HOST with timestamp
          sendMessage("&" + String(EVENT_LICK) + " " + String(millis() - _exp_timer));
          _lick_state = true;                            // Halt lick detection
          //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Check for Quinine Window~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
          //~~~~~~~~~~~~~~~~~~~~~~~~~Deliver Quinine if Prior Quinine has elapsed~~~~~~~~~~~~~~~~~~~~~~~~//            
          if (millis() - _quinine_timer >= _params[QUININE_TIMEOUT] && millis() - _cue_on_time > _params[QUININE_MIN] && millis()-_cue_on_time < _params[QUININE_MAX]) { // If quinine window open
            playSound(TONE_QUININE);                   // Dispense quinine for QUININE_DURATION
            _quinine_timer = millis();                 // Log time of last quinine deterrant
          }
          //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
          //------------------------DEBUG MODE--------------------------//
            if (_params[_DEBUG]) {
              sendMessage("Early pre-window lick detected @ " + String(_lick_time) + "ms. Dispensing Quinine: No lick IS enforced.");
            }
          //----------------------end DEBUG MODE------------------------//
          if (_params[EARLY_LICK_ABORT] == 1 && millis() - _cue_on_time > _params[ABORT_MIN] && millis()-_cue_on_time < _params[ABORT_MAX]) { // If abort window open
            //sendMessage("`" + String(CODE_EARLY_LICK));    // Send result code (Early Lick) to Matlab HOST      
            _resultCode = CODE_EARLY_LICK;                 // Register result code 
            _state = ABORT_TRIAL;                          // Move to ABORT state
            return;
          }
        }
      
        //=======================NON-ENFORCED============================//
        else {
          // Send a event marker (lick) to HOST with timestamp
          sendMessage("&" + String(EVENT_LICK) + " " + String(millis() - _exp_timer));
          _lick_state = true;                            // Halts lick detection
          _state = PRE_WINDOW;                           // Returns to Pre-window
          //------------------------DEBUG MODE--------------------------//
            if (_params[_DEBUG]) {
              sendMessage("New pre-window lick detected, tallying lick @ " + String(millis() - _cue_on_time) + "ms wrt cue onset. No lick NOT enforced, continuing...");
            }
          //----------------------end DEBUG MODE------------------------//
        }
      }
    }

    if (!getLickState()) {                           // MOUSE: "No lick"
      if (_lick_state) {                               // If lick just ended                            
        _lick_state = false;                           // Resets lick detector
      //------------------------DEBUG MODE--------------------------//  
        if (_params[_DEBUG]) {sendMessage("Lick state reset (not licked anymore) ");} 
      //----------------------end DEBUG MODE------------------------//
      }
    }






    _state = PRE_WINDOW;                             // No Command --> Cycle back to PRE_WINDOW
  } // End PRE_WINDOW STATE ------------------------------------------------------------------------------------------------------------------------------------------


  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RESPONSE_WINDOW - Rewards first lick
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  void response_window() {
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      ACTION LIST -- initialize the new state
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
      if (_state != _prevState) {                        // If ENTERTING RESPONSE_WINDOW:
        _response_window_timer = millis();                  // Start _response_window_timer
        _prevState = _state;                                // Assign _prevState to RESPONSE_WINDOW state
        sendMessage("$" + String(_state));                  // Send a message to host upon _state entry -- $4 (response_window State)
        // Send event marker (window open) to HOST with timestamp
        sendMessage("&" + String(EVENT_WINDOW_OPEN) + " " + String(millis() - _exp_timer)); // relative to cue onset
        //------------------------DEBUG MODE--------------------------//  
        if (_params[_DEBUG]) {
          sendMessage("Entered response window at " + String(_response_window_timer - _cue_on_time) +"ms, awaiting lick.");
        }
        //----------------------end DEBUG MODE------------------------//
      }// End Action list

    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      TRANSITION LIST -- checks conditions, moves to next state
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

      if (_command == 'Q')  {                          // HOST: "QUIT" -> IDLE_STATE
        _state = IDLE_STATE;                                 // Set IDLE_STATE
        return;                                              // Exit Fx
      }

      /*~ Check for CORRECT RELEASE~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
      if (!getLeverState()) {                           // MOUSE: "No press"
        if (_lever_state) {                               // If press just ended  
          // Send a event marker (release) to HOST with timestamp
          sendMessage("&" + String(EVENT_LEVER_RELEASE) + " " + String(millis() - _exp_timer));
          //sendMessage("`" + String(CODE_CORRECT));        // Send result code (Correct) to Matlab HOST                                
          // Note: don't need to send the below, is done in REWARD state, delete in next version
          //_resultCode = CODE_CORECT;                      // Register result code 
          _lever_state = false;                           // Resets lever detector
          _state = REWARD;                                // Move -> REWARD, wait for trial timeout
          return;                                         // Break to REWARD state
        }
      } /*~ TO REWARD ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

      /* Check for LICKS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
      if (getLickState()) {                            // MOUSE: "Licked"
        if (!_lick_state) {                              // If new lick
          //======================ENFORCED NO LICK=========================//
          if (_params[ENFORCE_NO_LICK] == 1) {
            _lick_state = true;                            // Halt lick detection
            // Send a event marker (lick) to HOST with timestamp
            sendMessage("&" + String(EVENT_LICK) + " " + String(millis() - _exp_timer));
            //------------------------DEBUG MODE--------------------------//
              if (_params[_DEBUG]) {
                _lick_time = millis() - _cue_on_time;          // Records lick wrt cue onset
                sendMessage("Response Window Early lick detected @ " + String(_lick_time) + "ms wrt Cue Onset.");
              }
            //----------------------end DEBUG MODE------------------------//

            //~~~~~~~~~~~~~~~~~~~~~~~~~Deliver Quinine if Window Open~~~~~~~~~~~~~~~~~~~~~~~~//
            if (millis() - _cue_on_time > _params[QUININE_MIN] && millis()-_cue_on_time < _params[QUININE_MAX]) { // If quinine window open
              _quinine_timer = millis();                     // Records time of last quinine delivery (we know this is first in this trial since the Action List only runs 1x)
              playSound(TONE_QUININE);                       // Dispenses quinine for QUININE_DURATION _params
            } //End Quinine~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
            
            //~~~~~~~~~~~~~~~~~~~~~~~~~Abort if Window Open~~~~~~~~~~~~~~~~~~~~~~~~//
            if (_params[EARLY_LICK_ABORT] == 1 && millis() - _cue_on_time > _params[ABORT_MIN] && millis()-_cue_on_time < _params[ABORT_MAX]) { // If abort window open
              //sendMessage("`" + String(CODE_EARLY_LICK));    // Send result code (Early Lick) to Matlab HOST      
              _resultCode = CODE_EARLY_LICK;                 // Register result code 
              _state = ABORT_TRIAL;                          // Move -> ABORT state
              return;                                        // Break to Abort
            }  // End Abort ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
          }
      
          //=======================NON-ENFORCED============================//
          else {
            // Send a event marker (lick) to HOST with timestamp
            sendMessage("&" + String(EVENT_LICK) + " " + String(millis() - _exp_timer));
            _lick_state = true;                            // Halts lick detection
            //------------------------DEBUG MODE--------------------------//
              if (_params[_DEBUG]) {
                _lick_time = millis() - _cue_on_time;          // Records lick wrt CUE ONSET
                sendMessage("New response-window lick detected, tallying lick @ " + String(_lick_time) + "ms wrt cue onset. No lick NOT enforced, continuing...");
              }
             //----------------------end DEBUG MODE------------------------//                                        // Exit Function -> Re-Cycle or Idle
          } /* End Non-enforced No-Lick*/
        } /* End Check for New Licks */
      } /* End getLickState */
      if (!getLickState()) {                           // MOUSE: "No lick"
        if (_lick_state) {                               // If lick just ended                            
          _lick_state = false;                           // Resets lick detector
        }
      }


      if (_params[SHOCK_ON] == 1) {                    // If shock circuit enforced
          if (!_shock_trigger_on && millis() - _cue_on_time > _params[SHOCK_MIN] && millis()-_cue_on_time < _params[SHOCK_MAX]) { // If shock window is open
              setShockTrigger(true);                          // Connect the shock ckt        
          }
          else if (_shock_trigger_on) {                // Otherwise, if shock is on, but we're in the wrong window...                                            
            setShockTrigger(false);                           // Disconnect shock ckt
          }
      }

      unsigned long current_time = millis()-_cue_on_time; 
      if (!_reached_target && current_time >= _params[TARGET]) { // TARGET -> REWARD
        // Send event marker (target time) to HOST with timestamp
        sendMessage("&" + String(EVENT_TARGET_TIME) + " " + String(millis() - _exp_timer));
        _reached_target = true;                        // Indicate target reached
        //------------------------DEBUG MODE--------------------------//  
        if (_params[_DEBUG]) {
          sendMessage("Reached Target Time at " + String(current_time) +"ms.");
        }
        //----------------------end DEBUG MODE------------------------//
      }

      if (current_time >= _params[INTERVAL_MAX]) {     // Window Closed -> POST_WINDOW
        setHouseLamp(true);                               // House Lamp ON (to indicate error)
        playSound(TONE_ALERT);
        // Send event marker (window closed) to HOST with timestamp
        sendMessage("&" + String(EVENT_WINDOW_CLOSED) + " " + String(millis() - _exp_timer));
        //------------------------DEBUG MODE--------------------------//  
        if (_params[_DEBUG]) {
          sendMessage("Reward window closed at " + String(current_time) +"ms wrt Cue ON.");
        }
        //----------------------end DEBUG MODE------------------------//
        _state = POST_WINDOW;                           // Move -> POST_WINDOW
        return;                                         // Exit Fx
      }

      _state = RESPONSE_WINDOW;                        // Cycle back to Response Window
      
  } // End RESPONSE_WINDOW STATE ------------------------------------------------------------------------------------------------------------------------------------------



  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    POST_WINDOW - Checking for late licks (effectively an abort state)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  void post_window() {
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      ACTION LIST -- initialize the new state
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
      if (_state != _prevState) {                        // If ENTERTING POST_WINDOW:  
        _prevState = _state;                                // Assign _prevState to POST_WINDOW state
        sendMessage("$" + String(_state));                  // Send HOST $4 (post_window State)
        // Send event marker (window closed) to HOST with timestamp
        sendMessage("&" + String(EVENT_WINDOW_CLOSED) + " " + String(millis() - _exp_timer));
      }

    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      TRANSITION LIST -- checks conditions, moves to next state
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
      /*~ Check for LATE RELEASE~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
      if (!getLeverState()) {                           // MOUSE: "No press"
        if (_lever_state) {                               // If press just ended  
          // Send a event marker (release) to HOST with timestamp
          sendMessage("&" + String(EVENT_LEVER_RELEASE) + " " + String(millis() - _exp_timer));
          //sendMessage("`" + String(CODE_CORRECT));        // Send result code (Correct) to Matlab HOST                                
          // Note: don't need to send the below, is done in REWARD state, delete in next version
          //_resultCode = CODE_CORECT;                      // Register result code 
          _lever_state = false;                           // Resets lever detector
          _state = ABORT_TRIAL;                           // Move -> ABORT, wait for trial timeout
          return;                                         // Break to ABORT state
        }
      } /*~ TO ABORT_TRIAL ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

      if (_command == 'Q')  {                          // HOST: "QUIT" -> IDLE_STATE
        _state = IDLE_STATE;                             // Set IDLE_STATE
        return;                                          // Exit Fx
      }

      /*.... LICK detection: assuming witholding NOT enforced in POST_WINDOW ....*/
      if (getLickState()) {                            // MOUSE: "Licked"
        if (!_lick_state) {                              // If a new lick initiated
          // Send a event marker (lick) to HOST with timestamp
          sendMessage("&" + String(EVENT_LICK) + " " + String(millis() - _exp_timer));    
          _lick_state = true;                            // Halts lick detection
          //------------------------DEBUG MODE--------------------------//
          if (_params[_DEBUG]) {sendMessage("Late lick detected, tallying lick @ " + String(millis()-_cue_on_time) + "ms wrt Cue ON.");}
          //----------------------end DEBUG MODE------------------------//
        }
      }

      if (!getLickState()) {                           // MOUSE: "No lick"
        if (_lick_state) {                               // If lick just ended                            
          _lick_state = false;                           // Resets lick detector
        }
      } /* End lick detection..................................................*/  


      if (_params[SHOCK_ON] == 1) {                   // If shock circuit enforced
          if (!_shock_trigger_on && millis() - _cue_on_time > _params[SHOCK_MIN] && millis()-_cue_on_time < _params[SHOCK_MAX]) { // If shock window is open
              setShockTrigger(true);                          // Connect the shock ckt        
          }
          else if (_shock_trigger_on) {               // Otherwise, if shock is on, but we're in the wrong window...                                            
            setShockTrigger(false);                           // Disconnect shock ckt
          }
      }

      if (millis() - _cue_on_time >= _params[TRIAL_DURATION]) {  // TRIAL END -> ITI
        // Send event marker (trial end) to HOST with timestamp
        sendMessage("&" + String(EVENT_TRIAL_END) + " " + String(millis() - _exp_timer));
        _resultCode = CODE_NO_RELEASE;                            // Register result code 
        _state = INTERTRIAL;                                      // Move -> ITI
        return;                                                   // Exit Fx
      } /* -------------Trial Timed Out --> TO ITI---------------- */

      _state = POST_WINDOW;                             // No Command: Cycle -> POST_WINDOW
  } // End POST_WINDOW STATE ------------------------------------------------------------------------------------------------------------------------------------------



  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    REWARD - Deliver reward and wait for trial timeout while tracking licks
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  void reward() {
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      ACTION LIST -- initialize the new state
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
      if (_state != _prevState) {                        // If ENTERTING REWARD:
        _reward_timer = millis();                        // Start _reward_timer
        setReward(true);                                    // Initiate reward delivery
        playSound(TONE_REWARD);                             // Start reward tone    
        // Send event marker (reward) to HOST with timestamp
        sendMessage("&" + String(EVENT_REWARD) + " " + String(millis() - _exp_timer));
        //sendMessage("`" + String(CODE_CORRECT));            // Send result code (Correct) to Matlab HOST      
        _resultCode = CODE_CORRECT;                         // Register result code (THIS MAY BE REDUNDANT, CHECK...)
        _prevState = _state;                                // Assign _prevState to REWARD _state
        sendMessage("$" + String(_state));                  // Send HOST $6 (reward State)  
        //------------------------DEBUG MODE--------------------------//  
        if (_params[_DEBUG]) {sendMessage("Dispensing reward.");}
        //----------------------end DEBUG MODE------------------------//
      }

   /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      TRANSITION LIST -- checks conditions, moves to next state
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
      if (_command == 'Q')  {                          // HOST: "QUIT" -> IDLE_STATE
        _state = IDLE_STATE;                                      // Set IDLE_STATE
        return;                                                   // Exit Function
      }

      /*-~~~~~~~~~~~~~~~~~ Dispense Reward for Correct Duration ~~~~~~~~~~~~~~~~~~~~~*/
      if (millis() - _reward_timer >= _params[REWARD_DURATION] && !_reward_dispensed_complete) { // Reward duration elapsed...terminate reward
        setReward(false);                                   // Stop delivery
        _reward_dispensed_complete = true;                  // track completion
        //------------------------DEBUG MODE--------------------------//
          if (_params[_DEBUG]) {
            sendMessage("Reward terminated at " + String(millis() - _reward_timer) + "ms wrt reward initiation.");
          }
        //----------------------end DEBUG MODE------------------------//
      } /*------------------------- End Duration Checker ---------------------------*/



      /*~~~~~~~~~~~~~~~~~~~~~~ Manage shock circuit ~~~~~~~~~~~~~~~~~~~~~~~~~*/
      if (_params[SHOCK_ON] == 1) {                   // If shock circuit enforced
          if (!_shock_trigger_on && millis() - _cue_on_time > _params[SHOCK_MIN] && millis()-_cue_on_time < _params[SHOCK_MAX]) { // If shock window is open
              setShockTrigger(true);                          // Connect the shock ckt        
          }
          else if (_shock_trigger_on) {               // Otherwise, if shock is on, but we're in the wrong window...                                            
            setShockTrigger(false);                           // Disconnect shock ckt
          }
      } /*---------------------------------------------------------------------*/



      /*~~~~~~~~~~~~~~~~~ Check for new lever presses and releases ~~~~~~~~~~~~~~~~~~~*/
      if (getLeverState()) {                            // MOUSE: "Lever Pressed"
        if (!_lever_state) {                             // If a new press initiated
          // Send a event marker (LEVER PRESS) to HOST with timestamp
          sendMessage("&" + String(EVENT_LEVER_PRESS) + " " + String(millis() - _exp_timer));
          _lever_state = true;                           // Halts press detection
          //------------------------DEBUG MODE--------------------------//
            if (_params[_DEBUG]) {
              _lever_press_time = millis() - _trialTimer;    // Records _lever_press_time relative to trial start
              sendMessage("Lever pressed again, tallying press @ " + String(_lever_press_time - _cue_on_time) + "ms wrt Cue ON");
            }
          //----------------------end DEBUG MODE------------------------//
        }
      }
      if (!getLeverState()) {                           // MOUSE: "No press"
        if (_lever_state) {                               // If press just ended  
          // Send an event marker (release) to HOST with timestamp
          sendMessage("&" + String(EVENT_LEVER_RELEASE) + " " + String(millis() - _exp_timer));                          
          _lever_state = false;                           // Resets lever detector
          //------------------------DEBUG MODE--------------------------//
            if (_params[_DEBUG]) {sendMessage("Lever released again @ " + String(millis() - _cue_on_time) + "ms wrt Cue ON");}
          //----------------------end DEBUG MODE------------------------//
        }
      }
      /* ~~~~~~~~~~~~~~~~~ End Lever Services ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


      /*.....................Check for new licks................................*/
      if (getLickState()) {                            // MOUSE: "Licked"
        if (!_lick_state) {                              // If a new lick initiated
          // Send event marker (lick) to HOST with timestamp
          sendMessage("&" + String(EVENT_LICK) + " " + String(millis() - _exp_timer));
          _lick_state = true;                            // Halts lick detection
          //------------------------DEBUG MODE--------------------------//
          if (_params[_DEBUG]) {
            sendMessage("Lick detected, tallying lick @ " + String(millis() - _cue_on_time) + "ms");
          }
          //----------------------end DEBUG MODE------------------------//
        }
      }
      if (!getLickState()) {                           // MOUSE: "No lick"
        if (_lick_state) {                               // If lick just ended                            
          _lick_state = false;                           // Resets lick detector
        }
      } /* End Lick Checker ...................................................*/


      if (millis() - _trialTimer - _preCueDelay >= _params[TRIAL_DURATION]) {  // TRIAL END -> ITI
        // Send event marker (trial end) to HOST with timestamp
        sendMessage("&" + String(EVENT_TRIAL_END) + " " + String(millis() - _exp_timer));
        _state = INTERTRIAL;                                // Move to ITI
        return;                                             // Exit Fx
      }

      _state = REWARD;                                  // No Command --> Cycle back to REWARD
  } // End REWARD STATE ------------------------------------------------------------------------------------------------------------------------------------------



  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ABORT_TRIAL - Presents error and waits for Trial Timeout
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  void abort_trial() {
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      ACTION LIST -- initialize the new state
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
      if (_state != _prevState) {                        // If ENTERTING ABORT:
        _abort_timer = millis();                           // Start _abort_timer
        _prevState = _state;                               // Assign _prevState to ABORT_TRIAL _state
        setHouseLamp(true);                                // House Lamp ON
        playSound(TONE_ABORT);                             // Error Tone
        sendMessage("$" + String(_state));                 // Send HOST -- $7 (abort State) 
        // Send event marker (abort) to HOST with timestamp
        sendMessage("&" + String(EVENT_ABORT) + " " + String(millis() - _exp_timer));
        //------------------------DEBUG MODE--------------------------//  
        if (_params[_DEBUG]) {sendMessage("Incorrect: Trial aborted.");}
        //----------------------end DEBUG MODE------------------------//
      }

    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      TRANSITION LIST -- checks conditions, moves to next state
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
      if (_command == 'Q')  {                             // HOST: "QUIT" -> IDLE_STATE
        _state = IDLE_STATE;                                 // Set IDLE_STATE
        return;                                              // Exit Function
      }


      /*~~~~~~~~~~~~~~~~~ Check for new lever presses and releases ~~~~~~~~~~~~~~~~~~~*/
      if (getLeverState()) {                            // MOUSE: "Lever Pressed"
        if (!_lever_state) {                             // If a new press initiated
          _lever_press_time = millis() - _trialTimer;    // Records _lever_press_time relative to trial start
          // Send a event marker (lick) to HOST with timestamp
          sendMessage("&" + String(EVENT_LEVER_PRESS) + " " + String(millis() - _exp_timer));
          _lever_state = true;                           // Halts press detection
          //------------------------DEBUG MODE--------------------------//
            if (_params[_DEBUG]) {sendMessage("Lever pressed again, tallying press @ " + String(_lever_press_time - _cue_on_time) + "ms wrt Cue ON");}
          //----------------------end DEBUG MODE------------------------//
        }
      }
      if (!getLeverState()) {                           // MOUSE: "No press"
        if (_lever_state) {                               // If press just ended  
          // Send an event marker (release) to HOST with timestamp
          sendMessage("&" + String(EVENT_LEVER_RELEASE) + " " + String(millis() - _exp_timer));                          
          _lever_state = false;                           // Resets lever detector
          //------------------------DEBUG MODE--------------------------//
            if (_params[_DEBUG]) {sendMessage("Lever released again @ " + String(millis() - _cue_on_time) + "ms wrt Cue ON");}
          //----------------------end DEBUG MODE------------------------//
        }
      }
      /* ~~~~~~~~~~~~~~~~~ End Lever Services ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

      if (_params[SHOCK_ON] == 1) {                   // If shock circuit enforced
          if (!_shock_trigger_on && millis() - _cue_on_time > _params[SHOCK_MIN] && millis()-_cue_on_time < _params[SHOCK_MAX]) { // If shock window is open
              setShockTrigger(true);                          // Connect the shock ckt        
          }
          else if (_shock_trigger_on) {               // Otherwise, if shock is on, but we're in the wrong window...                                            
            setShockTrigger(false);                           // Disconnect shock ckt
          }
      }

      if (getLickState()) {                               // MOUSE: "Licked"
        if (!_lick_state) {                                 // If a new lick initiated
          // Send a event marker (lick) to HOST with timestamp
          sendMessage("&" + String(EVENT_LICK) + " " + String(millis() - _exp_timer));
          _lick_state = true;                               // Halts lick detection
          //------------------------DEBUG MODE--------------------------//
            if (_params[_DEBUG]) {
              _lick_time = millis() - _cue_on_time;          // Records lick wrt CUE ON
              sendMessage("Lick detected, tallying lick @ " + String(_lick_time) + "ms");
            }
          //----------------------end DEBUG MODE------------------------//
        }
      }


      if (!getLickState()) {                              // MOUSE: "No lick"
        if (_lick_state) {                               // If lick just ended                            
          _lick_state = false;                           // Resets lick detector
        }
      }
      

      if (millis() - _trialTimer - _preCueDelay >= _params[TRIAL_DURATION]) { // Trial Timeout -> ITI
        // Send event marker (trial end) to HOST with timestamp
        sendMessage("&" + String(EVENT_TRIAL_END) + " " + String(millis() - _exp_timer));
        _state = INTERTRIAL;                                      // Move to ITI
        return;                                                   // Exit Fx
      }


      _state = ABORT_TRIAL;                               // No Command: Cycle -> ABORT_TRIAL
  } // End ABORT_TRIAL STATE ---------------------------------------------------------------------------------------------------------------------


/////////////////////////////////////////////////////////
  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    INTERTRIAL - Enforced ITI with Data Writing and Initialization of new parameters delivered from host
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  void intertrial() {
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      ACTION LIST -- initialize the new state
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
      static bool isParamsUpdateStarted;              // Initialize tracker of new param reception from HOST - true when new params received
      static bool isParamsUpdateDone;                 // Set to true upon receiving confirmation signal from HOST ("Over")
      static unsigned short annoying_beep = 200;      // To get animal off lever, will use this as the inter-beep interval
      if (_state != _prevState) {                     // If ENTERTING ITI:
        _ITI_timer = millis();                           // Start ITI timer
        setHouseLamp(true);                              // House Lamp ON (if not already)
        setCueLED(false);                                // Cue LED OFF
        _prevState = _state;                             // Assign _prevState to ITI _state
        sendMessage("$" + String(_state));               // Send HOST $10 (ITI State)
        // Send event marker (ITI) to HOST with timestamp
        sendMessage("&" + String(EVENT_ITI) + " " + String(millis() - _exp_timer));
        
        // Reset state variables
        _pre_window_elapsed = false;                  // Reset pre_window time tracker
        _reached_target = false;                      // Reset target time tracker
        _late_lick_detected = false;                  // Reset late lick detector
        _reward_dispensed_complete = false;           // Reset tracker of reward dispensal

        //=================== INIT HOST COMMUNICATION=================//
        isParamsUpdateStarted = false;                      // Initialize HOST param message monitor Start
        isParamsUpdateDone = false;                         // Initialize HOST param message monitor End  
        

        //=================== SEND RESULT CODE=================//
        if (_resultCode > -1) {                       // If result code exists
          sendMessage("`" + String(_resultCode));           // Send result code to host to mark trial as complete
          _resultCode = -1;                                 // Reset the result code tracker
        }

        //------------------------DEBUG MODE--------------------------//  
          if (_params[_DEBUG]) {sendMessage("Intertrial.");}
        //----------------------end DEBUG MODE------------------------//
      }


    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      TRANSITION LIST -- checks conditions, moves to next state
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
      if (_command == 'Q')  {                             // HOST: "QUIT" -> IDLE_STATE
        _state = IDLE_STATE;                                 // Set IDLE_STATE
        return;                                              // Exit Function
      }


      if (_params[SHOCK_ON] == 1) {                   // If shock circuit enforced
          if (!_shock_trigger_on && millis() - _cue_on_time > _params[SHOCK_MIN] && millis()-_cue_on_time < _params[SHOCK_MAX]) { // If shock window is open
              setShockTrigger(true);                          // Connect the shock ckt        
          }
          else if (_shock_trigger_on) {               // Otherwise, if shock is on, but we're in the wrong window...                                            
            setShockTrigger(false);                           // Disconnect shock ckt
          }
      }

      if (getLickState()) {                               // MOUSE: "Licked"
        if (!_lick_state) {                                 // If a new lick initiated
          // Send a event marker (lick) to HOST with timestamp
          sendMessage("&" + String(EVENT_LICK) + " " + String(millis() - _exp_timer));
          _lick_state = true;                               // Halts lick detection
          //------------------------DEBUG MODE--------------------------//
            if (_params[_DEBUG]) {
              _lick_time = millis() - _cue_on_time;          // Records lick wrt CUE ON
              sendMessage("Lick detected, tallying lick @ " + String(_lick_time) + "ms");
            }
          //----------------------end DEBUG MODE------------------------//
        }
      }
      if (!getLickState()) {                              // MOUSE: "No lick"
        if (_lick_state) {                               // If lick just ended                            
          _lick_state = false;                           // Resets lick detector
        }
      } 
      


      if (_command == 'P') {                          // Received new param from HOST: format "P _paramID _newValue" ('P' for Parameters)
        isParamsUpdateStarted = true;                   // Mark transmission start. Don't start next trial until we've finished.
        _params[_arguments[0]] = _arguments[1];         // Update parameter. Serial input "P 0 1000" changes the 1st parameter to 1000.
        _state = INTERTRIAL;                            // Return -> ITI
      //------------------------DEBUG MODE--------------------------//  
        if (_params[_DEBUG]) {
            sendMessage("Parameter " + String(_arguments[0]) + " changed to " + String(_arguments[1]));
        } 
      //----------------------end DEBUG MODE------------------------//
        return;                                         // Exit Fx
      }
      

      if (_command == 'O') {                          // HOST transmission complete: HOST sends 'O' for Over.
        isParamsUpdateDone = true;                      // Mark transmission complete.
        _state = INTERTRIAL;                            // Return -> ITI
        return;                                         // Exit Fx
      }



      /* End ITI Services:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        -If param update initiated, should also wait for update completion signal from HOST ('O' for Over).
        -ITI must time out
        -Lever must not be pressed (will hold in ITI till lever released)
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
      if (millis() - _ITI_timer >= _params[ITI] && (isParamsUpdateDone || !isParamsUpdateStarted))  { 
        if (!getLeverState) {
          _state = INIT_TRIAL;                            // Move -> READY state
          return;                                         // Exit Fx
        }
        else {
          static unsigned long error_timer = 0;
          if (millis()-error_timer > 200 + annoying_beep) {
            playSound(TONE_ALERT);
            error_timer = millis();
          }
        }
      }

      _state = INTERTRIAL;                            // No Command -> Cycle back to ITI
  } // End ITI---------------------------------------------------------------------------------------------------------------------











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
  bool getLeverState() {
    if (digitalRead(PIN_LEVER) == HIGH) {
      return true;
    }
    else {
      return false;
    }
  } // end Get Lever State---------------------------------------------------------------------------------------------------------------------


  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GET LICK STATE (True/False - Boolean)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  bool getLickState() {
    if (digitalRead(PIN_LICK) == HIGH) {
      return true;
    }
    else {
      return false;
    }
  } // end Get Lick State---------------------------------------------------------------------------------------------------------------------

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
    if (soundEventFrequency == TONE_CUE) {          // MOUSE: Cue Tone
      noTone(PIN_SPEAKER);                              // Turn off current sound (if any)
      tone(PIN_SPEAKER, soundEventFrequency, _params[CUE_DURATION]); // Play Cue Tone (default 200 ms)
      return;                                           // Exit Fx
    }
    if (soundEventFrequency == TONE_ALERT) {        // SYSTEM: INTERNAL ERROR
      noTone(PIN_SPEAKER);                              // Turn off current sound (if any)
      tone(PIN_SPEAKER, soundEventFrequency, 2000);     // Play Alert Tone (default 2000 ms)
      return;                                           // Exit Fx
    }
    if (soundEventFrequency == TONE_QUININE) {       // DETERRANT: QUININE delivery
      noTone(PIN_QUININE);                              // Turn off current quinine (if any)
      tone(PIN_QUININE, soundEventFrequency, _params[QUININE_DURATION]);     // Deliver Quinine (default 30 ms)
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


  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SET SHOCK TRIGGER (Connect the shock ckt)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  void setShockTrigger(bool turnOn) {
    if (turnOn)                                                       
    {                                                                 // MOUSE: Deliver SHOCK = TRUE
      digitalWrite(PIN_SHOCK, HIGH);                                    // Shock Pin HIGH
      _shock_trigger_on = true;                                         // Shock trigger true
      //------------------------DEBUG MODE--------------------------//  
        if (_params[_DEBUG]) {sendMessage("Shock ckt connected");}
      //----------------------end DEBUG MODE------------------------//
    }
    else
    {                                                                 // MOUSE: Stop SHOCK
      digitalWrite(PIN_SHOCK, LOW);                                     // Shock Pin LOW
      _shock_trigger_on = false;                                        // Update shock trigger state
      //------------------------DEBUG MODE--------------------------// 
        if (_params[_DEBUG]) {sendMessage("Shock ckt offline");}
      //----------------------end DEBUG MODE------------------------//
    }
  } // end Set Shock Trigger--------------------------------------------------------------------------------------------------------------








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
