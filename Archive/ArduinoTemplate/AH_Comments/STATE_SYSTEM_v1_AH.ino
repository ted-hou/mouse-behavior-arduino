/*********************************************************************
  Arduino state machine code for lever task
  
  Matlab Serial Communication Interface by Ofer
  State System architecture by Lingfeng Hou (lingfenghou@g.harvard.edu)
    Created:      9/13/16
    Last Updated: 9/15/16 - Allison Hamilos (ahamilos@g.harvard.edu)

   - Everything is done in the main loop()
   - Incoming messages
    - Receive one byte on each loop
    - Parsed when end of message character ('#') received
    - "P 0 100#" tells Arduino to change the 1st parameter to 100. This will hold Arduino in INTERTRIAL state until we tell it to continue.
    - "O#" tells Arduino we're done updating parameters, you may start the next trial.
    - "G#" tells Arduino to break out of IDLE and begin trials
    - "Q#" tells Arduino abort whatever it's doing to go to IDLE state
   - Outgoing messages
    - "~" tells MATLAB we're up and running.
    - "@ 1 IDLE" tells MATLAB that the second state is called "IDLE".
    - "# 1 INTERVAL_MIN 1250" tells MATLAB that the second parameter is called "INTERVAL_MIN", and the default value is 1250.
    - '* 0 ERROR_LEVER_NOT_PRESSED' tells MATLAB error code -1 means ERROR_LEVER_NOT_PRESSED
    - '* 1 ERROR_EARLY_RELEASE' tells MATLAB error code -2 means ERROR_EARLY_RELEASE
    - "$0" tells MATLAB we've entered the first state
    - "$5 0 1000" tells MATLAB we've entered the 6th state and the time is 1000.
    - "$5 1 0" tells MATLAB we've entered the 6th state, and the trial result is error code -1.
    - "+3 EVENT_1" -> uploads the event marker names to matlab
    - "&2 5548" &=event code, 2 is the event code, 5548 is the timestamp of code. Matlab will put into 2xn array
    - "Any random collection of words" sends a string to MATLAB to print. Used for debugging.
   - State machine
    - States are written as individual functions
    - The main loop calls the appropriate state function
    depending on current state.
    - A state function consists of two parts
     - Action: executed once when first entering this state.
     - Transitions: evaluated on each loop and determines
     what the next state should be.
*********************************************************************/

/*****************************************************
  Global stuff
*****************************************************/

// Arduino Pin-Outs
  /* PINOUT MODE: MEGA */

  // Digital OUT
#define PIN_LED_ILLUM     34  // House Lamp Pin         (DUE = 34)  (MEGA = 34)  (UNO = 5?)  (TEENSY = 6?)
#define PIN_LED_CUE       28  // Cue LED Pin            (DUE = 35)  (MEGA = 52)  (UNO =  4)  (TEENSY = 4)
#define PIN_REWARD        52  // Reward Pin                         (MEGA = 52)  (UNO =  7)  (TEENSY = 7)

  // PWM OUT
#define PIN_SPEAKER        8  // Speaker Pin            (DUE =  2)  (MEGA =  8)  (UNO =  9)  (TEENSY = 5)

  // Digital IN
#define PIN_LEVER          2  // Lever Pin              (DUE = 36)  (MEGA =  2)  (UNO =  2)  (TEENSY = 2)


/*****************************************************
  Enums - DEFINE States
*****************************************************/
// All the states
enum State
{
  _INIT,                // (Private) Initial state used on first loop. 
  IDLE_STATE,           // Idle state. Wait for go signal from host.
  READY,                // Ready, wait for lever press & hold
  RANDOM_WAIT,          // Wait a random amount of time before starting a trial.
  CUE_ON,               // Cue to start timing
  LEVER_RELEASED,       // Triggered when lever is released
  REWARD,               // Give reward.
  ABORT_TRIAL,          // Go to this state when something's wrong. Goes to intertrial so we can upload error info to host.
  INTERTRIAL,           // Intertrial interval. Upload data and recieve new params.
  _NUM_STATES           // (Private) Used to count number of states
};

// State names stored as strings, will be sent to host
// Names cannot contain spaces!!!
static const char *_stateNames[] = 
{
  "_INIT",
  "IDLE_STATE",
  "READY",
  "RANDOM_WAIT",
  "CUE_ON",
  "LEVER_RELEASED",
  "REWARD",
  "ABORT_TRIAL",
  "INTERTRIAL"
};

// Define which states allow param update
static const int _stateCanUpdateParams[] = {0,1,0,0,0,0,0,0,1}; // Defined to allow Parameter upload from host during IDLE_STATE and INTERTRIAL


/*****************************************************
  Event Markers
*****************************************************/
enum EventMarkers
/* You may define as many event markers as you like.
    Assign event markers to any IN/OUT event
    Times and trials will be defined by global time, 
    which can be parsed later to validate time measurements */
{
  EVENT_1,
  EVENT_2,
  EVENT_3,
  _NUM_OF_EVENT_MARKERS
};

static const char *_eventMarkerNames[] =    // * to define array of strings
{
  "Your Mom",
  "Your Ancestors",
  "All 18 Ancestors"
};

static const _eventMarkerTimer = 0;

/*****************************************************
  Result codes
*****************************************************/
enum ResultCode
{
  CODE_CORRECT,                              // Correct
  CODE_EARLY_RELEASE,                        // Early Release
  CODE_LATE_RELEASE,                         // Late Release
  CODE_LEVER_NOT_PRESSED,                    // No Press
  CODE_PRE_CUE_RELEASE,                      // Lever Break
  _NUM_RESULT_CODES                          // (Private) Used to count how many codes there are.
};

// We'll send result code translations to MATLAB at startup
static const char *_resultCodeNames[] =
{
  "CORRECT",
  "EARLY_RELEASE",
  "LATE_RELEASE",
  "LEVER_NOT_PRESSED",
  "PRE_CUE_RELEASE"
};

/*****************************************************
  Audio cue frequencies
*****************************************************/
enum SoundEventFrequencyEnum
{
  TONE_REWARD = 4186,             // Correct tone: C8
  TONE_ABORT  = 131,              // Error tone: C3
  TONE_CUE    = 1047              // 'Start counting the interval' cue: C6
};

/*****************************************************
  Parameters that can be updated by host
*****************************************************/
// Storing everything in array _params[]. Using enum ParamID as array indices so it's easier to add/remove parameters. 
enum ParamID
{
  _DEBUG,                         // (Private) 1 to enable debug messages. 0 to disable. Default 0.
  INTERVAL_MIN,                   // Minimumum time to reward threshold (ms).
  INTERVAL_MAX,                   // Max time for reward threshold (ms).
  TARGET,                         // Target time (ms).
  REWARD_DURATION,                // Reward size (ms).
  TIMEOUT_READY,                  // Max trial time (ms) - abort trial if no press before now
  RANDOM_WAIT_MIN,                // Minimum random pre-trial interval (ms)
  RANDOM_WAIT_MAX,                // Maximum random pre-trial interval (ms)
  ITI,                            // Intertrial interval length (ms)
  CUE_DURATION,                   // Duration of cue tone and LED flash (ms)
  _NUM_PARAMS                     // (Private) Used to count how many parameters there are so we can initialize the param array with the correct size. Insert additional parameters before this.
}; //**** BE SURE TO ADD NEW PARAMS TO THE NAMES LIST BELOW!*****//

// Store parameter names as strings, will be sent to host
// Names cannot contain spaces!!!
static const char *_paramNames[] = 
{
  "_DEBUG",
  "INTERVAL_MIN",
  "INTERVAL_MAX",
  "TARGET",
  "REWARD_DURATION",
  "TIMEOUT_READY",
  "RANDOM_WAIT_MIN",
  "RANDOM_WAIT_MAX",
  "ITI",
  "CUE_DURATION"
}; //**** BE SURE TO INIT NEW PARAM VALUES BELOW!*****//

// Initialize parameters
int _params[_NUM_PARAMS] = 
{
  0,                              // _DEBUG
  1250,                           // INTERVAL_MIN
  1750,                           // INTERVAL_MAX
  1500,                           // TARGET
  100,                            // REWARD_DURATION
  20000,                          // TIMEOUT_READY
  1000,                           // RANDOM_WAIT_MIN
  2000,                           // RANDOM_WAIT_MAX
  5000,                           // ITI
  200                             // CUE_DURATION (ms)
};

/*****************************************************
  Global variables 
*****************************************************/
// Variables declared here can be carried to the next loop, AND read/written in function scope as well as main scope
static unsigned long _timer          = 0;        // Timer
static long _leverPressDuration      = 0;        // Lever press duration in ms. 0 if not applicable
static long _resultCode              = 0;        // Result code number, see "enum ResultCode" for details.
static State _state                  = _INIT;    // This variable (current _state) get passed into a _state function, which determines what the next _state should be, and updates it to the next _state.
static State _prevState              = _INIT;    // Remembers the previous _state from the last loop (actions should only be executed when you enter a _state for the first time, comparing currentState vs _prevState helps us keep track of that).
static char _command                 = ' ';      // Command char received from host, resets on each loop
static int _arguments[2]             = {0};      // Two integers received from host , resets on each loop

// Debug: measure tick-rate (per ms)
static unsigned long _debugTimer     = 0;        // Debugging _timer
static unsigned long _ticks          = 0;        // # of loops/sec in the debugger

/*****************************************************
  INITIALIZATION LOOP
*****************************************************/
void setup()
{
  //--------------------I/O initialization------------------//
  // OUTPUTS
  pinMode(PIN_LED_ILLUM, OUTPUT);             // LED for illumination
  pinMode(PIN_LED_CUE, OUTPUT);               // LED for 'start' cue
  pinMode(PIN_SPEAKER, OUTPUT);               // Speaker for cue/correct/error tone
  // INPUTS
  pinMode(PIN_LEVER, INPUT_PULLUP);           // Lever (`INPUT_PULLUP` means it'll be `LOW` when pressed, and `HIGH` when released)
  //--------------------------------------------------------//


  //--------------Set ititial outputs to OFF----------------//
  setIllumLED(false);                          // Illum LED off
  setCueLED(false);                            // Cue LED off



  //------------------------Serial Comms--------------------//
  // Set up USB communication at 115200 baud 
  Serial.begin(115200);
  // Tell PC that we're running by sending '~' message
  hostInit();                                 // Sends all parameters, states and error codes to Matlab (LF Function)
  sendMessage("~");                           // Tells PC that Arduino is on (Send Message is a LF Function)


  //-----------------------DEBUG Timing---------------------//
  // Tick rate
  _debugTimer = millis();                      // Start DEBUG _timer clock

} // End Initialization Loop -----------------------------------------------------------------------------------------------------




/*****************************************************
  MAIN LOOP
*****************************************************/
void loop()
{
  //----------------------DEBUG MODE------------------------//
  //* Debug mode will count the number of loop cycles/1000 ms to determine the reliability of arduino clock *//
  if (millis() - _debugTimer == 1000)  {       // If 1000 ms since last tick readout...
    if (_params[_DEBUG]) {                           // If DEBUG mode is on
      sendMessage("Tick rate: " + String(_ticks) + " ticks per second.");  // Sends message to Matlab host
    }
    _ticks = 0;                                      // reset _ticks to 0
    _debugTimer = millis();                          // reset debug clock
  }
  else if (millis() - _debugTimer > 1000)  {   // If MORE than 1000 ms have passed, it means we lost a ms on the last loop
    if (_params[_DEBUG]) {
      sendMessage("Tick rate: A ms was lost on last loop cycle...Clock Speed Error?");
    }
    _ticks = 0;                                      // reset _ticks to 0
    _debugTimer = millis();                          // reset debug clock
  }
  else if (millis() - _debugTimer < 1000)  {   // If LESS than 1000 ms have passed, acculumate a loop tick
    _ticks = _ticks + 1;                              // Add a tick to the measurement
  }
  //----------------------end DEBUG MODE------------------------//



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
      
      if (_params[_DEBUG]) {
        sendMessage("Parameter Updated: " + _command + String(_arguments[0]) + String(_arguments[1]));
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
    
    case READY:
      ready();
      break;
    
    case RANDOM_WAIT:    
      random_wait();
      break;
    
    case CUE_ON:         
      cue_on();
      break;
    
    case LEVER_RELEASED: 
      lever_released();
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

} // End main loop-------------------------------------------------------------------------------------------------------------









/*****************************************************
  States for the State Machine
*****************************************************/
/* New states are initialized by the ACTION LIST
   In the main loop after state runs, Arduino checks for new parameters and 


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  IDLE STATE - awaiting start cue from Matlab HOST
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
void idle_state() {
  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ACTION LIST -- initialize the new state
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  if (_state != _prevState) {                       // If ENTERTING IDLE_STATE:
    _prevState = _state;                                // Assign _prevState to idle _state
    sendMessage("$" + String(_state));                 // Send a message to host upon _state entry -- $1 (Idle State)
    setIllumLED(false);                               // Kill House Lamp
    setCueLED(false);                                 // Kill Cue LED
    noTone(PIN_SPEAKER);                              // Kill tone
    setReward(false);                                 // Kill reward

    //------------------------DEBUG MODE--------------------------//
    if (_params[_DEBUG]) {
      sendMessage("Idle.");
    }  
    //----------------------end DEBUG MODE------------------------//
  }

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    TRANSITION LIST -- checks conditions, moves to next state
    TRANSITION LIST -- checks conditions, moves to next _state
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  
  if (_command == 'G') {                           // If Received GO signal from HOST ---transition to---> READY
    _state = READY;                                    // State set to READY
    return;                                           // Exit function
  }

  
  if (_command == 'P') {                           // Received new param from host: format "P _paramID _newValue" ('P' for Parameters)
    //----------------------DEBUG MODE------------------------// 
    if (_params[_DEBUG]) {sendMessage("Parameter " + String(_arguments[0]) + " changed to " + String(_arguments[1]));
    } 
    //-------------------end DEBUG MODE--- -------------------//

    _params[_arguments[0]] = _arguments[1];              // Update parameter. Serial input "P 0 1000" changes the 1st parameter to 1000.
    _state = IDLE_STATE;                               // State returns to IDLE_STATE
    return;                                           // Exit function
  }

  _state = IDLE_STATE;                             // Return to IDLE_STATE
} // End IDLE_STATE ------------------------------------------------------------------------------------------------------------------------------------------








/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  READY - Trial started. House Lamp ON, Awaiting lever press
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
void ready() {
  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ACTION LIST -- initialize the new state
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  if (_state != _prevState) {                       // If ENTERTING READY STATE:
    _prevState = _state;                                // Assign _prevState to READY _state
    sendMessage("$" + String(_state));                 // Send a message to host upon _state entry -- $2 (Ready State)
    setIllumLED(true);                                // House Lamp ON
    _timer = millis();                                 // Start _timer clock

    //------------------------DEBUG MODE--------------------------//
    if (_params[_DEBUG]) {
      sendMessage("Ready. Awaiting lever press and hold.");
    }
    //----------------------end DEBUG MODE------------------------//
  }


  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    TRANSITION LIST -- checks conditions, moves to next state
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  if (_command == 'Q')  {                          // HOST: "QUIT" -> IDLE_STATE
    _state = IDLE_STATE;                                 // Set IDLE_STATE
    return;                                             // Exit Function
  }


  
  if (getLeverState()) {                          // MOUSE: "Lever pressed" -> RANDOM_WAIT
    //------------------------DEBUG MODE--------------------------//
    if (_params[_DEBUG]) {
      sendMessage("Lever pressed. Moving to random delay _state.");
    }
    //----------------------end DEBUG MODE------------------------//

    _state = RANDOM_WAIT;                                // Set RANDOM_WAIT _state
    return;                                             // Exit Fx
  }


  
  if (millis() - _timer >= _params[TIMEOUT_READY]) { // TIMEOUT: "No press" -> ABORT_TRIAL
    //------------------------DEBUG MODE--------------------------//
    if (_params[_DEBUG]) {
      sendMessage("Ran out of time to press lever. Aborting trial.");
    }
    //----------------------end DEBUG MODE------------------------//

    _leverPressDuration = 0;                        // Duration pressed = 0 -- all this stored in ITI
    _resultCode = CODE_LEVER_NOT_PRESSED;           // Return 3 if lever was never pressed
    _state = ABORT_TRIAL;                           // Move to ABORT_TRIAL _state
    return;                                        // Exit Fx
  }


  _state = READY;                                   // No Command --> Cycle back to READY
} // End READY STATE ------------------------------------------------------------------------------------------------------------------------------------------





/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  RANDOM_WAIT - Lever pressed, rand delay before cue
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
void random_wait() {
  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ACTION LIST -- initialize the new state
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  static unsigned long waitInterval;               // Initialize waitInterval var
  if (_state != _prevState) {                        // If ENTERTING RANDOM_WAIT:
    _prevState = _state;                                // Assign _prevState to RANDOM_WAIT _state
    sendMessage("$" + String(_state));                 // Send a message to host upon _state entry -- $3 (random_wait State)

    waitInterval = random(_params[RANDOM_WAIT_MIN], _params[RANDOM_WAIT_MAX]);     // Choose random delay time
    _timer = millis();                                                            // Start _timer
    //---------------------- DEBUG MODE --------------------------//
    if (_params[_DEBUG]) {
      sendMessage("Random delay before cue: " + String(waitInterval) + " ms");
    }
    //----------------------end DEBUG MODE------------------------//
  }



  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    TRANSITION LIST -- checks conditions, moves to next state
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  if (_command == 'Q')  {                          // HOST: "QUIT" -> IDLE_STATE
    _state = IDLE_STATE;                                 // Set IDLE_STATE
    return;                                             // Exit Function
  }


  if (!getLeverState())  {                        // MOUSE: "Lever released early" -> ABORT_TRIAL
    //------------------------DEBUG MODE--------------------------//    
    if (_params[_DEBUG]) {
      sendMessage("Lever released during pre-cue delay.");
    }
    //----------------------end DEBUG MODE------------------------//
    _leverPressDuration = 0;                       // Duration pressed = 0 -- all this stored in ITI
    _resultCode = CODE_PRE_CUE_RELEASE;            // Return 1 b/c lever was released early
    _state = ABORT_TRIAL;                          // Move to ABORT_TRIAL _state
    return;                                       // Exit Fx
  }


  if (millis() - _timer >= waitInterval) {         // RANDOM_WAIT elapsed -> CUE_ON
    //------------------------DEBUG MODE--------------------------//  
    if (_params[_DEBUG]) {
      sendMessage("Pre-cue delay successfully completed.");
    }
    //----------------------end DEBUG MODE------------------------//
    _state = CUE_ON;                               // Move to CUE_ON _state
    return;                                       // Exit Fx
  }


  _state = RANDOM_WAIT;                            // No Command --> Cycle back to RANDOM_WAIT
} // End RANDOM PRE-CUE DELAY STATE ------------------------------------------------------------------------------------------------------------------------------------------





/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  CUE_ON - Timing Interval (Cue presentation (LED + Tone) Throughout)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
void cue_on() {
  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ACTION LIST -- initialize the new state
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  if (_state != _prevState) {                        // If ENTERTING CUE_ON:
    _prevState = _state;                                // Assign _prevState to CUE_ON _state
    sendMessage("$" + String(_state));                 // Send a message to host upon _state entry -- $4 (cue_on State)
    setCueLED(true);                                  // Cue LED ON
    playSound(TONE_CUE);                              // Cue tone ON
    _timer = millis();                                 // Start _timer

    //------------------------DEBUG MODE--------------------------//  
    if (_params[_DEBUG]) {
      sendMessage("Cue on. Maintain Press for " + String(_params[INTERVAL_MIN]) + " - " + String(_params[INTERVAL_MAX]) + " ms");
    } 
    //----------------------end DEBUG MODE------------------------//
  }

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    TRANSITION LIST -- checks conditions, moves to next state
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  if (_command == 'Q')  {                          // HOST: "QUIT" -> IDLE_STATE
    _state = IDLE_STATE;                                 // Set IDLE_STATE
    return;                                             // Exit Function
  }


  if (!getLeverState())  {                        // MOUSE: "Lever released" -> LEVER_RELEASED
    _state = LEVER_RELEASED;                             // Set LEVER_RELEASED
    return;                                             // Exit Fx
  }


  _state = CUE_ON;                                 // No Command --> Cycle back to CUE_ON
} // End TIMING INTERVAL STATE ------------------------------------------------------------------------------------------------------------------------------------------





/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  LEVER_RELEASED - Check if released in correct time and assign result code
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
void lever_released() {
  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ACTION LIST -- initialize the new state
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
 if (_state != _prevState) {                        // If ENTERTING LEVER_RELEASED:
    _prevState = _state;                                // Assign _prevState to LEVER_RELEASED _state
    sendMessage("$" + String(_state));                 // Send a message to host upon _state entry -- $5 (lever_released State)
    _leverPressDuration = millis() - _timer;            // Calculate press duration
    //------------------------DEBUG MODE--------------------------//  
    if (_params[_DEBUG]) {
      sendMessage("Lever released. Held for " + String(_leverPressDuration) + " ms after cue.");
    }
    //----------------------end DEBUG MODE------------------------//
  }



  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    TRANSITION LIST -- checks conditions, moves to next state
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  if (_leverPressDuration >= _params[INTERVAL_MIN] && _leverPressDuration <= _params[INTERVAL_MAX]) {   // Correct -> REWARD
    // _leverPressDuration recorded before entering this _state - stored in ITI
    _resultCode = CODE_CORRECT;                    // Return 0 b/c correct
    _state = REWARD;                               // Move to REWARD _state
  }
  
  else if (_leverPressDuration < _params[INTERVAL_MIN]) {                                             // Early Release -> ABORT_TRIAL
    // _leverPressDuration recorded before entering this _state - stored in ITI
    _resultCode = CODE_EARLY_RELEASE;              // Return 1 b/c early release
    _state = ABORT_TRIAL;                          // Move to ABORT _state
  }

  else if (_leverPressDuration > _params[INTERVAL_MAX]) {                                             // Late Release -> ABORT_TRIAL
    // _leverPressDuration recorded before entering this _state - stored in ITI
    _resultCode = CODE_LATE_RELEASE;               // Return 2 b/c late release
    _state = ABORT_TRIAL;                          // Move to ABORT _state
  }

  if (_command == 'Q')  {                                                                            // HOST: "QUIT" -> IDLE_STATE
    _state = IDLE_STATE;                                 // Set IDLE_STATE
  }
} // End LEVER RELEASED STATE ------------------------------------------------------------------------------------------------------------------------------------------





/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  REWARD - deliver reward
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
void reward() {
  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ACTION LIST -- initialize the new state
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  static bool isRewardDelievered;                   // Initialize reward tracker (Boolean)Set to true when reward delivery is complete
  if (_state != _prevState) {                        // If ENTERTING REWARD:
    _prevState = _state;                                // Assign _prevState to REWARD _state
    sendMessage("$" + String(_state));                  // Send a message to host upon _state entry -- $6 (reward State)  
    isRewardDelievered = false;                         // Reward isn't fully delivered until delivery time has elapsed
    setReward(true);                                    // Initiate reward delivery
    playSound(TONE_REWARD);                             // Start reward tone
    _timer = millis();                                  // Start timer to track duration of reward delivery
  }

 /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    TRANSITION LIST -- checks conditions, moves to next state
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  if (_command == 'Q')  {                              // HOST: "QUIT" -> IDLE_STATE
    _state = IDLE_STATE;                                 // Set IDLE_STATE
    return;                                              // Exit Function
  }

  
  if (millis() - _timer >= _params[REWARD_DURATION]) { // Reward duration elapsed...terminate reward
    setReward(false);                                    // Stop delivery
    _state = INTERTRIAL;                                 // Move to ITI
    return;                                              // Exit fx
  }


  _state = REWARD;                                      // No Command --> Cycle back to REWARD
} // End REWARD STATE ------------------------------------------------------------------------------------------------------------------------------------------






/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ABORT_TRIAL - Kills the current trial -> ITI
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
void abort_trial() {
  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ACTION LIST -- initialize the new state
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  if (_state != _prevState) {                        // If ENTERTING ABORT:
    _prevState = _state;                                // Assign _prevState to ABORT_TRIAL _state
    sendMessage("$" + String(_state));                  // Send a message to host upon _state entry -- $7 (abort State) 
    playSound(TONE_ABORT);                              // Error tone
    //------------------------DEBUG MODE--------------------------//  
    if (_params[_DEBUG]) {sendMessage("Incorrect: Trial aborted.");}
    //----------------------end DEBUG MODE------------------------//
  }

  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    TRANSITION LIST -- checks conditions, moves to next state
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  if (_command == 'Q')  {                            // HOST: "QUIT" -> IDLE_STATE
    _state = IDLE_STATE;                                 // Set IDLE_STATE
    return;                                              // Exit Function
  }

  
  _state = INTERTRIAL;                               // (always) Proceed immediately to ITI

  /* PLACEHOLDER: Future version should make ever trial the same duration, this should be executed here */
} // End ABORT TRIAL STATE ---------------------------------------------------------------------------------------------------------------------




/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  INTERTRIAL - Enforced ITI with Data Writing and Initialization of new parameters delivered from host
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
void intertrial() {
  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ACTION LIST -- initialize the new state
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  static bool isParamsUpdateStarted;              // Initialize tracker of new param reception from HOST - true when new params received
  static bool isParamsUpdateDone;                 // Set to true upon receiving confirmation signal from HOST ("Over")
  if (_state != _prevState) {                     // If ENTERTING ITI:
    _prevState = _state;                                // Assign _prevState to ITI _state
    sendMessage("$" + String(_state) + " " + String(_resultCode) + " " + String(_leverPressDuration)); // Send a message to host upon _state entry -- $8 (iti State) --
                                                        // for this state we append leverPressDuration or error code to end of message
    _leverPressDuration = 0;                            // Reset lever press monitor to 0
    setIllumLED(false);                                 // House Lamp OFF
    setCueLED(false);                                   // Cue LED OFF
    isParamsUpdateStarted = false;                      // Initialize HOST param message monitor Start
    isParamsUpdateDone = false;                         // Initialize HOST param message monitor End  
    _timer = millis();                                  // Start ITI timer
    //------------------------DEBUG MODE--------------------------//  
    if (_params[_DEBUG]) {sendMessage("Intertrial.");}
    //----------------------end DEBUG MODE------------------------//
  }


  /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    TRANSITION LIST -- checks conditions, moves to next state
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  if (_command == 'Q')  {                         // HOST: "QUIT" -> IDLE_STATE
    _state = IDLE_STATE;                                 // Set IDLE_STATE
    return;                                              // Exit Function
  }
  

  //------------------------DEBUG MODE--------------------------//  
  if (_params[_DEBUG]) {
      sendMessage("Parameter " + String(_arguments[0]) + " changed to " + String(_arguments[1]));
  } 
  //----------------------end DEBUG MODE------------------------//

  
  if (_command == 'P') {                          // Received new param from host: format "P _paramID _newValue" ('P' for Parameters)
    isParamsUpdateStarted = true;                   // Mark transmission start. Don't start next trial until we've finished.
    _params[_arguments[0]] = _arguments[1];         // Update parameter. Serial input "P 0 1000" changes the 1st parameter to 1000.
    _state = INTERTRIAL;                            // Return -> ITI
    return;                                         // Exit Fx
  }
  


  if (_command == 'O') {                          // HOST transmission complete: HOST sends 'O' for Over.
    isParamsUpdateDone = true;                      // Mark transmission complete.
    _state = INTERTRIAL;                            // Return -> ITI
    return;                                         // Exit Fx
  }


  
  if (millis() - _timer >= _params[ITI] && (isParamsUpdateDone || !isParamsUpdateStarted))  { // End when ITI ends. If param update initiated, should also wait for update completion signal from HOST ('O' for Over).
    _state = READY;                                 // Move -> READY state
    return;                                         // Exit Fx
  }

  _state = INTERTRIAL;                            // No Command -> Cycle back to ITI
} // End Get Arguments---------------------------------------------------------------------------------------------------------------------






/*****************************************************
  HARDWARE CONTROLS
*****************************************************/

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Set House Lamp (ON/OFF)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
void setIllumLED(bool turnOn) {
  if (turnOn) {
    digitalWrite(PIN_LED_ILLUM, HIGH);
  }
  else {
    digitalWrite(PIN_LED_ILLUM, LOW);
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
    return false;
  }
  else {
    return true;
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
  if (soundEventFrequency == TONE_CUE) {          // MOUSE: Cue Tone
    noTone(PIN_SPEAKER);                              // Turn off current sound (if any)
    tone(PIN_SPEAKER, soundEventFrequency, _params[CUE_DURATION]); // Play Cue Tone (default 200 ms)
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
    if (_params[_DEBUG]) {sendMessage("Dispensing Reward");}
    //----------------------end DEBUG MODE------------------------//
  }
  else
  {                                                                 // MOUSE: Stop Reward
    digitalWrite(PIN_REWARD, LOW);                                     // Reward Pin LOW
    //------------------------DEBUG MODE--------------------------// 
    if (_params[_DEBUG]) {sendMessage("Terminating Reward");}
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
}



// /*****************************************************
//   Tone generator for Due -- not used in other Arduino modes
// *****************************************************/
// /*
// Tone generator
// v1  use timer, and toggle any digital pin in ISR
//    funky duration from arduino version
//    TODO use FindMckDivisor?
//    timer selected will preclude using associated pins for PWM etc.
//   could also do timer/pwm hardware toggle where caller controls duration
// */


// // timers TC0 TC1 TC2   channels 0-2 ids 0-2  3-5  6-8     AB 0 1
// // use TC1 channel 0 
// #define TONE_TIMER TC1
// #define TONE_CHNL 0
// #define TONE_IRQ TC3_IRQn

// // TIMER_CLOCK4   84MHz/128 with 16 bit counter give 10 Hz to 656KHz
// //  piano 27Hz to 4KHz

// static uint8_t pinEnabled[PINS_COUNT];
// static uint8_t TCChanEnabled = 0;
// static boolean pin_state = false ;
// static Tc *chTC = TONE_TIMER;
// static uint32_t chNo = TONE_CHNL;

// volatile static int32_t toggle_count;
// static uint32_t tone_pin;

// // frequency (in hertz) and duration (in milliseconds).

// void tone(uint32_t ulPin, uint32_t frequency, int32_t duration)
// {
//     const uint32_t rc = VARIANT_MCK / 256 / frequency; 
//     tone_pin = ulPin;
//     toggle_count = 0;  // strange  wipe out previous duration
//     if (duration > 0 ) toggle_count = 2 * frequency * duration / 1000;
//      else toggle_count = -1;

//     if (!TCChanEnabled) {
//       pmc_set_writeprotect(false);
//       pmc_enable_periph_clk((uint32_t)TONE_IRQ);
//       TC_Configure(chTC, chNo,
//         TC_CMR_TCCLKS_TIMER_CLOCK4 |
//         TC_CMR_WAVE |         // Waveform mode
//         TC_CMR_WAVSEL_UP_RC ); // Counter running up and reset when equals to RC
  
//       chTC->TC_CHANNEL[chNo].TC_IER=TC_IER_CPCS;  // RC compare interrupt
//       chTC->TC_CHANNEL[chNo].TC_IDR=~TC_IER_CPCS;
//       NVIC_EnableIRQ(TONE_IRQ);
//              TCChanEnabled = 1;
//     }
//     if (!pinEnabled[ulPin]) {
//       pinMode(ulPin, OUTPUT);
//       pinEnabled[ulPin] = 1;
//     }
//     TC_Stop(chTC, chNo);
//     TC_SetRC(chTC, chNo, rc);    // set frequency
//     TC_Start(chTC, chNo);
// }

// void noTone(uint32_t ulPin)
// {
//   TC_Stop(chTC, chNo);  // stop timer
//   digitalWrite(ulPin,LOW);  // no signal on pin
// }

// // timer ISR  TC1 ch 0
// void TC3_Handler ( void ) {
//   TC_GetStatus(TC1, 0);
//   if (toggle_count != 0){
//     // toggle pin  TODO  better
//     digitalWrite(tone_pin,pin_state= !pin_state);
//     if (toggle_count > 0) toggle_count--;
//   } else {
//     noTone(tone_pin);
//   }
// }