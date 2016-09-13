/*********************************************************************
  Arduino state machine code for lever task

  By Lingfeng Hou (lingfenghou@g.harvard.edu)
    Created: 9/13/16
    Last Updated: 9/13/16 - Allison Hamilos (ahamilos@g.harvard.edu)

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

  // Digital OUT
#define PIN_LED_ILLUM     34  // House Lamp Pin
#define PIN_LED_CUE       35  // Cue LED Pin

  // PWM OUT
#define PIN_SPEAKER        2  // Speaker Pin

  // Digital IN
#define PIN_LEVER         36  // Lever Pin


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
static const char *stateNames[] = 
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
static const int stateCanUpdateParams[] = {0,1,0,0,0,0,0,0,1}; // Defined to allow Parameter upload from host during IDLE_STATE and INTERTRIAL

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
static const char *resultCodeNames[] =
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
enum SoundType
{
  TONE_REWARD = 4186,             // Correct tone: C8
  TONE_ABORT  = 131,              // Error tone: C3
  TONE_CUE    = 1047              // 'Start counting the interval' cue: C6
};

/*****************************************************
  Parameters that can be updated by host
*****************************************************/
// Storing everything in array params[]. Using enum ParamID as array indices so it's easier to add/remove parameters. 
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
  _NUM_PARAMS                     // (Private) Used to count how many parameters there are so we can initialize the param array with the correct size. Insert additional parameters before this.
}; //**** BE SURE TO ADD NEW PARAMS TO THE NAMES LIST BELOW!*****//

// Store parameter names as strings, will be sent to host
// Names cannot contain spaces!!!
static const char *paramNames[] = 
{
  "_DEBUG",
  "INTERVAL_MIN",
  "INTERVAL_MAX",
  "TARGET",
  "REWARD_DURATION",
  "TIMEOUT_READY",
  "RANDOM_WAIT_MIN",
  "RANDOM_WAIT_MAX",
  "ITI"
}; //**** BE SURE TO INIT NEW PARAM VALUES BELOW!*****//

// Initialize parameters
int params[_NUM_PARAMS] = 
{
  0,                              // _DEBUG
  1250,                           // INTERVAL_MIN
  1750,                           // INTERVAL_MAX
  1500,                           // TARGET
  100,                            // REWARD_DURATION
  20000,                          // TIMEOUT_READY
  1000,                           // RANDOM_WAIT_MIN
  2000,                           // RANDOM_WAIT_MAX
  5000                            // ITI
};

/*****************************************************
  Global variables 
*****************************************************/
// Variables declared here can be carried to the next loop, AND read/written in function scope as well as main scope
static unsigned long timer          = 0;        // Timer
static long leverPressDuration      = 0;        // Lever press duration in ms. 0 if not applicable
static long resultCode              = 0;        // Result code number, see "enum ResultCode" for details.
static State state                  = _INIT;    // This variable (current state) get passed into a state function, which determines what the next state should be, and updates it to the next state.
static State prevState              = _INIT;    // Remembers the previous state from the last loop (actions should only be executed when you enter a state for the first time, comparing currentState vs prevState helps us keep track of that).
static char command                 = ' ';      // Command char received from host, resets on each loop
static int arguments[2]             = {0};      // Two integers received from host , resets on each loop

// Debug: measure tick-rate (per ms)
static unsigned long debugTimer     = 0;        // Debugging timer
static unsigned long ticks          = 0;        // # of loops/sec in the debugger

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
  debugTimer = millis();                      // Start DEBUG timer clock
}




/*****************************************************
  MAIN LOOP
*****************************************************/

void loop()
{
  //----------------------DEBUG MODE------------------------//
  //* Debug mode will count the number of loop cycles/1000 ms to determine the reliability of arduino clock *//
  if (millis() - debugTimer == 1000)  {       // If 1000 ms since last tick readout...
    if (params[_DEBUG]) {                           // If DEBUG mode is on
      sendMessage("Tick rate: " + String(ticks) + " ticks per second.");  // Sends message to Matlab host
    }
    ticks = 0;                                      // reset ticks to 0
    debugTimer = millis();                          // reset debug clock
  }
  else if (millis() - debugTimer > 1000)  {   // If MORE than 1000 ms have passed, it means we lost a ms on the last loop
    if (params[_DEBUG]) {
      sendMessage("Tick rate: Woah where did that millisecond go?");
    }
    ticks = 0;
    debugTimer = millis();
  }
  else if (millis() - debugTimer < 1000)  {   // If LESS than 1000 ms have passed, acculumate a loop tick
    ticks = ticks + 1;
  }



  // 1) Check USB for MESSAGE from HOST, if available. String is read byte by byte. (Each character is a byte, so reads e/a character)
  static String usbMessage  = "";             // Initialize usbMessage to empty string, only happens once on first loop (thanks to static!)
  command = ' ';                              // Initialize command to a SPACE
  arguments[0] = 0;                           // Initialize 1st integer argument
  arguments[1] = 0;                           // Initialize 2nd integer argument

  if (Serial.available() > 0)  {              // If there's something in the SERIAL INPUT BUFFER (i.e., if another character from host is waiting in the queue to be read)
    char inByte = Serial.read();                  // Read next character
    // The pound sign ('#') indicates a complete message
    if (inByte == '#')  {                         // If # received, terminate the message
      // Parse the string, and updates `command`, and `arguments`
      command = getCommand(usbMessage);               // getCommand pulls out the character from the message for the command         
      getArguments(usbMessage, arguments);            // getArguments pulls out the integer values from the usbMessage
      if (params[_DEBUG]) {"Roger. " + command + String(arguments[0]) + String(arguments[1]);}
      // Clear message buffer
      usbMessage = ""; 
    }
    else
    {
      // append character to message buffer
      usbMessage = usbMessage + inByte;       // Appends the next character from the queue to the usbMessage string
    }
  }

    // 2) update state machine
  // Depending on what state we're in , call the appropriate state function, which will evaluate the transition conditions, and update `state` to what the next state should be
  switch (state)
  {
    case _INIT:
    {
      idle_state();
    } break;
    case IDLE_STATE:
    {
      idle_state();
    } break;
    case READY:
    {
      ready();
    } break;
    case RANDOM_WAIT:
    {
      random_wait();
    } break;
    case CUE_ON:
    {
      cue_on();
    } break;
    case LEVER_RELEASED:
    {
      lever_released();
    } break;
    case REWARD:
    {
      reward();
    } break;
    case ABORT_TRIAL:
    {
      abort_trial();
    } break;
    case INTERTRIAL:
    {
      intertrial();
    } break;
  }
}

/*****************************************************
  States for the State Machine
*****************************************************/
/*** IDLE_STATE ***/
void idle_state()
{
  // Actions - only execute once on state entry
  if (state != prevState)
  {
    prevState = state;

    // Send a message to host upon state entry
    sendMessage("$" + String(state));
    if (params[_DEBUG]) {sendMessage("Idle.");}

    // Illumination LED off
    setIllumLED(false);

    // Cue LED off
    setCueLED(false);

    // Kill tone
    noTone(PIN_SPEAKER);

    // Kill reward
    setReward(false);
  }

  // Transitions
  // Serial input (GO signal) -> READY
  if (command == 'G')
  {
    state = READY;
    return;
  }
  // Received new param from host: format "P _paramID _newValue" ('P' for Parameters)
  if (command == 'P')
  {
    params[arguments[0]] = arguments[1];  // Update parameter. Serial input "P 0 1000" changes the 1st parameter to 1000.
    if (params[_DEBUG]) {sendMessage("Parameter " + String(arguments[0]) + " changed to " + String(arguments[1]));} 
    state = IDLE_STATE;
    return;
  }
  // Otherwise stay in the same state
  state = IDLE_STATE;
}

/*** READY ***/
void ready()
{
  // Actions - only execute once on state entry
  if (state != prevState)
  {
    prevState = state;

    // Send a message to host upon state entry
    sendMessage("$" + String(state));
    if (params[_DEBUG]) {sendMessage("Ready. Press and hold lever.");}

    // Illumination LED on
    setIllumLED(true);

    // Start timer
    timer = millis();
  }

  // Transitions
  // Serial input (QUIT signal) -> IDLE_STATE
  if (command == 'Q')
  {
    state = IDLE_STATE;
    return;
  }
  // Lever pressed -> RANDOM_WAIT
  if (getLeverState())
  {
    if (params[_DEBUG]) {sendMessage("Lever pressed. Keep holding please.");}
    state = RANDOM_WAIT;
    return;
  }
  // Timeout w/o pressing the lever-> ABORT_TRIAL
  if (millis() - timer >= params[TIMEOUT_READY])
  {
    if (params[_DEBUG]) {sendMessage("Time out waiting for lever. Aborting.");}
    leverPressDuration = CODE_LEVER_NOT_PRESSED;  // Return -1 if lever was never pressed
    state = ABORT_TRIAL;
    return;
  }
  state = READY;
}

/*** RANDOM_WAIT ***/
void random_wait()
{
  static unsigned long waitInterval;

  // Actions - only execute once on state entry
  if (state != prevState)
  {
    prevState = state;

    // Randomize interval length and start timer
    waitInterval = random(params[RANDOM_WAIT_MIN], params[RANDOM_WAIT_MAX]);
    timer = millis();

    // Send a message to host upon state entry
    sendMessage("$" + String(state));
    if (params[_DEBUG]) {sendMessage("Random wait: " + String(waitInterval) + " ms");}
  }

  // Transitions
  // Serial input (QUIT signal) -> IDLE_STATE
  if (command == 'Q')
  {
    state = IDLE_STATE;
    return;
  }
  // Lever released -> ABORT_TRIAL
  if (!getLeverState())
  {
    if (params[_DEBUG]) {sendMessage("Lever released during random wait.");}
    leverPressDuration = 0;
    resultCode = CODE_PRE_CUE_RELEASE;
    state = ABORT_TRIAL;
    return;
  }
  // Random wait complete-> CUE_ON
  if (millis() - timer >= waitInterval)
  {
    if (params[_DEBUG]) {sendMessage("Random wait complete.");}
    state = CUE_ON;
    return;
  }
  state = RANDOM_WAIT;
}

/*** CUE_ON ***/
void cue_on()
{
  // Actions - only execute once on state entry
  if (state != prevState)
  {
    prevState = state;

    // Send a message to host upon state entry
    sendMessage("$" + String(state));
    if (params[_DEBUG]) {sendMessage("Cue on. Hold for " + String(params[INTERVAL_MIN]) + " - " + String(params[INTERVAL_MAX]) + " ms");}

    // Cue LED ON
    setCueLED(true);

    // Cue tone - start counting
    playSound(TONE_CUE);

    // Start timer
    timer = millis();
  }

  // Transitions
  // Serial input (QUIT signal) -> IDLE_STATE
  if (command == 'Q')
  {
    state = IDLE_STATE;
    return;
  }
  // Lever released -> LEVER_RELEASED
  if (!getLeverState())
  {
    state = LEVER_RELEASED;
    return;
  }
  state = CUE_ON;
}

/*** LEVER_RELEASED ***/
void lever_released()
{
  // Actions - only execute once on state entry
  if (state != prevState)
  {
    prevState = state;

    // Calculate lever press duration
    leverPressDuration = millis() - timer;

    // Send a message to host upon state entry
    sendMessage("$" + String(state));
    if (params[_DEBUG]) {sendMessage("Lever released. Held for " + String(leverPressDuration) + " ms.");}
  }

  // Transitions
  // Serial input (QUIT signal) -> IDLE_STATE
  if (command == 'Q')
  {
    state = IDLE_STATE;
    return;
  }
  // Interval correct -> REWARD
  if (leverPressDuration >= params[INTERVAL_MIN] && leverPressDuration <= params[INTERVAL_MAX])
  {
    resultCode = CODE_CORRECT;
    state = REWARD;
    return;
  }
  // Interval too short -> ABORT_TRIAL
  else if (leverPressDuration < params[INTERVAL_MIN])
  {
    resultCode = CODE_EARLY_RELEASE;
    state = ABORT_TRIAL;
    return;
  }
  // Interval too long -> ABORT_TRIAL
  else if (leverPressDuration > params[INTERVAL_MAX])
  {
    resultCode = CODE_LATE_RELEASE;
    state = ABORT_TRIAL;
    return;
  }
}

/*** REWARD ***/
void reward()
{
  static bool isRewardDelievered; // Set to true when reward delivery is complete

  // Actions - only execute once on state entry
  if (state != prevState)
  {
    prevState = state;

    // Send a message to host upon state entry
    sendMessage("$" + String(state));

    // Give reward
    isRewardDelievered = false;
    setReward(true);

    // Reward tone
    playSound(TONE_REWARD);

    // Start timer
    timer = millis();
  }

  // Transitions
  // Serial input (QUIT signal) -> IDLE_STATE
  if (command == 'Q')
  {
    state = IDLE_STATE;
    return;
  }
  // Reward duration complete
  if (millis() - timer >= params[REWARD_DURATION])
  {
    setReward(false);
    state = INTERTRIAL;
    return;
  }
  state = REWARD;
}

/*** ABORT_TRIAL ***/
void abort_trial()
{
  // Actions - only execute once on state entry
  if (state != prevState)
  {
    prevState = state;

    // Send a message to host upon state entry
    sendMessage("$" + String(state));
    if (params[_DEBUG]) {sendMessage("Trial aborted.");}

    // Error tone
    playSound(TONE_ABORT);
  }

  // Transitions
  // Serial input (QUIT signal) -> IDLE_STATE
  if (command == 'Q')
  {
    state = IDLE_STATE;
    return;
  }
  // Always -> INTERTRIAL
  state = INTERTRIAL;
}

/*** INTERTRIAL ***/
void intertrial()
{
  static bool isParamsUpdateStarted;  // Set to true upon receiving a new parameter
  static bool isParamsUpdateDone;   // Set to true upon receiving "Over" signal

  // Actions - only execute once on state entry
  if (state != prevState)
  {
    prevState = state;

    // Send a message to host upon state entry, for this state we append leverPressDuration or error code to end of message
    sendMessage("$" + String(state) + " " + String(resultCode) + " " + String(leverPressDuration));
    if (params[_DEBUG]) {sendMessage("Intertrial.");}

    // Reset output
    leverPressDuration = 0;

    // Illum LED OFF
    setIllumLED(false);

    // Cue LED OFF
    setCueLED(false);

    // Reset booleans used to track transmission progress
    isParamsUpdateStarted = false;
    isParamsUpdateDone = false;

    // Start timer
    timer = millis();
  }

  // Transitions
  // Serial input (QUIT signal) -> IDLE_STATE
  if (command == 'Q')
  {
    state = IDLE_STATE;
    return;
  }
  // Received new param from host: format "P _paramID _newValue" ('P' for Parameters)
  if (command == 'P')
  {
    isParamsUpdateStarted = true;     // Let loop know we've started transmitting parameters. Don't start next trial until we've finished.
    params[arguments[0]] = arguments[1];  // Update parameter. Serial input "P 0 1000" changes the 1st parameter to 1000.
    if (params[_DEBUG]) {sendMessage("Parameter " + String(arguments[0]) + " changed to " + String(arguments[1]));} 
    state = INTERTRIAL;
    return;
  }
  // Param transmission complete: host sends 'O' for Over.
  if (command == 'O') 
  {
    isParamsUpdateDone = true;
    state = INTERTRIAL;
    return;
  };
  // End when ITI ends. If param update initiated, should also wait for update completion signal ('O' for Over).
  if (millis() - timer >= params[ITI] && (isParamsUpdateDone || !isParamsUpdateStarted))
  {
    state = READY;
    return;
  }
  // Otherwise stay in same state
  state = INTERTRIAL;
}
/*****************************************************
  Hardware controls
*****************************************************/
void setIllumLED(bool turnOn)
{
  if (turnOn)
  {
    digitalWrite(PIN_LED_ILLUM, HIGH);
  }
  else
  {
    digitalWrite(PIN_LED_ILLUM, LOW);
  }
}

void setCueLED(bool turnOn)
{
  if (turnOn)
  {
    digitalWrite(PIN_LED_CUE, HIGH);
  }
  else
  {
    digitalWrite(PIN_LED_CUE, LOW);
  }
}

bool getLeverState()
{
  if (digitalRead(PIN_LEVER) == HIGH)
  {
    return false;
  }
  else
  {
    return true;
  }
}

void playSound(SoundType soundType)
{
  if (soundType == TONE_REWARD)
  {
    // Play correct tone
    noTone(PIN_SPEAKER);
    tone(PIN_SPEAKER, soundType, 200);
    return;
  }
  if (soundType == TONE_ABORT)
  {
    // Play incorrect tone
    noTone(PIN_SPEAKER);
    tone(PIN_SPEAKER, soundType, 200);
    return;
  }
  if (soundType == TONE_CUE)
  {
    // Play start interval tone
    noTone(PIN_SPEAKER);
    tone(PIN_SPEAKER, soundType, 200);
    return;
  }
}

void setReward(bool turnOn)
{
  if (turnOn)
  {
    if (params[_DEBUG]) {sendMessage("Nom nom nom.");}
  }
  else
  {
    if (params[_DEBUG]) {sendMessage("Where'd my juice go?");}
  }
}

/*****************************************************
  Serial comms
*****************************************************/
// Send a string message to host 
void sendMessage(String message)
{
  Serial.println(message);
}

// Get command (single character) received from host
char getCommand(String message)
{
  message.trim(); // Remove leading and trailing white space

  // Parse command string
  return message[0];
}

// Get arguments (2 element array)
void getArguments(String message, int *arguments)
{
  arguments[0] = 0;
  arguments[1] = 0;

  message.trim(); // Remove leading and trailing white space

  // Remove command (first character) from string
  String parameters = message;
  parameters.remove(0,1);
  parameters.trim();

  // Parse first (optional) integer argument
  String intString = "";
  while ((parameters.length() > 0) && (isDigit(parameters[0]))) 
  {
    intString += parameters[0];
    parameters.remove(0,1);
  }
  arguments[0] = intString.toInt();

  // Parse second (optional) integer argument  
  parameters.trim();
  intString = "";
  while ((parameters.length() > 0) && (isDigit(parameters[0]))) 
  {
    intString += parameters[0];
    parameters.remove(0,1);
  }
  arguments[1] = intString.toInt();
}

// Send names of states, names/values of parameters to host
void hostInit()
{
  // Send state names and which states allow parameter update
  for (int iState = 0; iState < _NUM_STATES; iState++)
  {
      sendMessage("@ " + String(iState) + " " + stateNames[iState] + " " + String(stateCanUpdateParams[iState]));
  }
  // Send param names and default values
  for (int iParam = 0; iParam < _NUM_PARAMS; iParam++)
  {
      sendMessage("# " + String(iParam) + " " + paramNames[iParam] + " " + String(params[iParam]));
  }
  // Send error code interpretations. MATLAB will interpret {0, 1, 2} as {-1, -2, -3}.
  for (int iCode = 0; iCode < _NUM_RESULT_CODES; iCode++)
  {
      sendMessage("* " + String(iCode) + " " + resultCodeNames[iCode]);
  }
}



/*****************************************************
  Tone generator for Due
*****************************************************/
/*
Tone generator
v1  use timer, and toggle any digital pin in ISR
   funky duration from arduino version
   TODO use FindMckDivisor?
   timer selected will preclude using associated pins for PWM etc.
  could also do timer/pwm hardware toggle where caller controls duration
*/


// timers TC0 TC1 TC2   channels 0-2 ids 0-2  3-5  6-8     AB 0 1
// use TC1 channel 0 
#define TONE_TIMER TC1
#define TONE_CHNL 0
#define TONE_IRQ TC3_IRQn

// TIMER_CLOCK4   84MHz/128 with 16 bit counter give 10 Hz to 656KHz
//  piano 27Hz to 4KHz

static uint8_t pinEnabled[PINS_COUNT];
static uint8_t TCChanEnabled = 0;
static boolean pin_state = false ;
static Tc *chTC = TONE_TIMER;
static uint32_t chNo = TONE_CHNL;

volatile static int32_t toggle_count;
static uint32_t tone_pin;

// frequency (in hertz) and duration (in milliseconds).

void tone(uint32_t ulPin, uint32_t frequency, int32_t duration)
{
    const uint32_t rc = VARIANT_MCK / 256 / frequency; 
    tone_pin = ulPin;
    toggle_count = 0;  // strange  wipe out previous duration
    if (duration > 0 ) toggle_count = 2 * frequency * duration / 1000;
     else toggle_count = -1;

    if (!TCChanEnabled) {
      pmc_set_writeprotect(false);
      pmc_enable_periph_clk((uint32_t)TONE_IRQ);
      TC_Configure(chTC, chNo,
        TC_CMR_TCCLKS_TIMER_CLOCK4 |
        TC_CMR_WAVE |         // Waveform mode
        TC_CMR_WAVSEL_UP_RC ); // Counter running up and reset when equals to RC
  
      chTC->TC_CHANNEL[chNo].TC_IER=TC_IER_CPCS;  // RC compare interrupt
      chTC->TC_CHANNEL[chNo].TC_IDR=~TC_IER_CPCS;
      NVIC_EnableIRQ(TONE_IRQ);
             TCChanEnabled = 1;
    }
    if (!pinEnabled[ulPin]) {
      pinMode(ulPin, OUTPUT);
      pinEnabled[ulPin] = 1;
    }
    TC_Stop(chTC, chNo);
    TC_SetRC(chTC, chNo, rc);    // set frequency
    TC_Start(chTC, chNo);
}

void noTone(uint32_t ulPin)
{
  TC_Stop(chTC, chNo);  // stop timer
  digitalWrite(ulPin,LOW);  // no signal on pin
}

// timer ISR  TC1 ch 0
void TC3_Handler ( void ) {
  TC_GetStatus(TC1, 0);
  if (toggle_count != 0){
    // toggle pin  TODO  better
    digitalWrite(tone_pin,pin_state= !pin_state);
    if (toggle_count > 0) toggle_count--;
  } else {
    noTone(tone_pin);
  }
}