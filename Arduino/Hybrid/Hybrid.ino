/*********************************************************************
	Arduino state machine
	Based on Allison's hybrid task (Pav-Op-quinine_v2)
*********************************************************************/



/*****************************************************
	Global Variables
*****************************************************/

/*****************************************************
	Arduino Pin Outs (Mode: TEENSY)
*****************************************************/

// Digital OUT
#define PIN_HOUSE_LAMP     6   // House Lamp Pin         (DUE = 34)  (MEGA = 34)  (UNO = 5?)  (TEENSY = 6)
#define PIN_LED_CUE        4   // Cue LED Pin            (DUE = 35)  (MEGA = 28)  (UNO =  4)  (TEENSY = 4)
#define PIN_REWARD         7   // Reward Pin             (DUE = 37)  (MEGA = 52)  (UNO =  7)  (TEENSY = 7)

// PWM OUT
#define PIN_SPEAKER        5   // Speaker Pin            (DUE =  2)  (MEGA =  8)  (UNO =  9)  (TEENSY = 5)

// Digital IN
#define PIN_LICK           2   // Lick Pin               (DUE = 36)  (MEGA =  2)  (UNO =  2)  (TEENSY = 2)


/*****************************************************
Enums - DEFINE States
*****************************************************/
// All the states
enum State
{
	_STATE_INIT,			// (Private) Initial state used on first loop. 
	STATE_IDLE,				// Idle state. Wait for go signal from host.
	STATE_TRIAL_START,		// House lamp OFF, random delay before cue presentation
	STATE_PRE_WINDOW,		// (+/-) Enforced no lick before response window opens
	STATE_RESPONSE_WINDOW,	// First lick in this interval rewarded (operant). Reward delivered at target time (pavlov)
	STATE_POST_WINDOW,		// Check for late licks
	STATE_REWARD,			// Dispense reward, wait for trial Timeout
	STATE_ABORT,			// Behavioral Error - House lamps ON, await trial Timeout
	STATE_INTERTRIAL,		// House lamps ON (if not already), write data to HOST and DISK, receive new params
	_NUM_STATES				// (Private) Used to count number of states
};

// State names stored as strings, will be sent to host
// Names cannot contain spaces!!!
static const char *_stateNames[] = 
{
	"_STATE_INIT",
	"IDLE",
	"TRIAL_START",
	"PRE_WINDOW",
	"RESPONSE_WINDOW",
	"POST_WINDOW",
	"REWARD",
	"ABORT",
	"INTERTRIAL"
};

// Define which states allow param update
static const int _stateCanUpdateParams[] = {0,1,0,0,0,0,0,0,1}; 
// Defined to allow Parameter upload from host during STATE_IDLE and STATE_INTERTRIAL


/*****************************************************
Event Markers
*****************************************************/
enum EventMarker
/* You may define as many event markers as you like.
		Assign event markers to any IN/OUT event
		Times and trials will be defined by global time, 
		which can be parsed later to validate time measurements */
{
	EVENT_TRIAL_START,				// New trial initiated
	EVENT_CUE_ON,					// Begin cue presentation
	EVENT_WINDOW_OPEN,				// Response window open
	EVENT_TARGET_TIME,				// Target time
	EVENT_WINDOW_CLOSED,			// Response window closed
	EVENT_TRIAL_END,				// Trial end
	EVENT_ITI,						// Enter ITI
	EVENT_LICK,						// Lick onset
	EVENT_LICK_OFF,					// Lick offset
	EVENT_FIRST_LICK,				// First lick in trial since cue on
	EVENT_FIRST_LICK_EARLY,			// First lick in trial since cue on (if it occurred before window)
	EVENT_FIRST_LICK_CORRECT,		// First lick in trial since cue on (if it occurred during window)
	EVENT_FIRST_LICK_LATE,			// First lick in trial since cue on (if it occurred after window)
	EVENT_FIRST_LICK_PAVLOVIAN,		// First lick in trial since cue on (if it occurred after pavlovian reward)
	EVENT_REWARD_ON,				// Reward, juice valve on
	EVENT_REWARD_OFF,				// Reward, juice valve off
	EVENT_ABORT,					// Trial aborted
	_NUM_OF_EVENT_MARKERS
};

static const char *_eventMarkerNames[] =    // * to define array of strings
{
	"STATE_TRIAL_START",
	"CUE_ON",
	"WINDOW_OPEN",
	"TARGET_TIME",
	"WINDOW_CLOSED",
	"TRIAL_END",
	"ITI",
	"LICK",
	"LICK_OFF",
	"FIRST_LICK",
	"FIRST_LICK_EARLY",
	"FIRST_LICK_CORRECT",
	"FIRST_LICK_LATE",
	"FIRST_LICK_PAVLOVIAN",
	"REWARD_ON",
	"REWARD_OFF",
	"ABORT"
};

/*****************************************************
Result codes
*****************************************************/
enum ResultCode
{
	CODE_CORRECT,                              // Correct    (1st lick w/in window)
	CODE_EARLY_LICK,                           // Early Lick (-> Abort in Enforced No-Lick)                         // NOTE: Early lick should be removed
	CODE_LATE_LICK,                            // Late Lick  (-> Abort in Operant)
	CODE_NO_LICK,                              // No Lick    (Timeout -> ITI)
	CODE_CORRECT_OP_HYBRID,                    // Licked before target in window
	CODE_PAVLOV_HYBRID,                        // Reached target time and dispensed before lick
	_NUM_RESULT_CODES                          // (Private) Used to count how many codes there are.
};

// We'll send result code translations to MATLAB at startup
static const char *_resultCodeNames[] =
{
	"CORRECT",
	"EARLY_LICK",
	"LATE_LICK",
	"NO_LICK",
	"CORRECT_OP_HYBRID",
	"PAVLOV_HYBRID"
};


/*****************************************************
Audio cue frequencies
*****************************************************/
enum SoundEventFrequencyEnum
{
	TONE_REWARD  = 12000,             // Correct tone: (prev C8 = 4186)
	TONE_ABORT   = 89,              // Error tone: (prev C3 = 131)
	TONE_CUE     = 784,             // 'Start counting the interval' cue: (prev C6 = 1047)
	TONE_ALERT   = 36,              // Reserved for system errors
	TONE_QUININE = 10000             // Quinine delivery -- using tone so don't require own state to deliver for set time
};

/*****************************************************
Parameters that can be updated by HOST
*****************************************************/
// Storing everything in array _params[]. Using enum ParamID as array indices so it's easier to add/remove parameters. 
enum ParamID
{
	_DEBUG,                         // (Private) 1 to enable debug messages from HOST. Default 0.
	HYBRID,                         // 1 to overrule pav or op -- allows operant pre-target lick, but is otherwise pavlovian
	PAVLOVIAN,                      // 1 to enable Pavlovian Mode
	OPERANT,                        // 1 to enable Operant Mode (exclusive to PAVLOVIAN)
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
	EARLY_LICK_ABORT,               // 1 to Abort with Early Licks in window (ms)
	ABORT_MIN,                      // Miminum time post cue before lick causes abort (ms)
	ABORT_MAX,                      // Maximum time post cue before abort unavailable (ms)
	PERCENT_PAVLOVIAN,              // Percent of mixed trials that are pavlovian (decimal)
	PLAY_PAV_REWARD_TONE,			// 0 to disable reward tone for pavlovian trials
	_NUM_PARAMS                     // (Private) Used to count how many parameters there are so we can initialize the param array with the correct size. Insert additional parameters before this.
};

// Store parameter names as strings, will be sent to host
// Names cannot contain spaces!!!
static const char *_paramNames[] = 
{
	"_DEBUG",
	"HYBRID",
	"PAVLOVIAN",
	"OPERANT",
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
	"EARLY_LICK_ABORT",
	"ABORT_MIN",
	"ABORT_MAX",
	"PERCENT_PAVLOVIAN",
	"PLAY_PAV_REWARD_TONE"
};

// Initialize parameters
long _params[_NUM_PARAMS] = 
{
	0,                              // _DEBUG
	1,                              // HYBRID
	0,                              // PAVLOVIAN
	0,                              // OPERANT
	0,                              // ENFORCE_NO_LICK
	1250,                           // INTERVAL_MIN
	1750,                           // INTERVAL_MAX
	1500,                           // TARGET
	3000,                           // TRIAL_DURATION
	5000,                           // ITI
	400,                            // RANDOM_DELAY_MIN
	1500,                           // RANDOM_DELAY_MAX
	100,                            // CUE_DURATION
	35,                             // REWARD_DURATION
	0,                              // EARLY_LICK_ABORT
	0,                              // ABORT_MIN
	1250,                           // ABORT_MAX
	1,                              // PERCENT_PAVLOVIAN
	1								// PLAY_PAV_REWARD_TONE
};

/*****************************************************
Other Global Variables 
*****************************************************/
// Variables declared here can be carried to the next loop, AND read/written in function scope as well as main scope
// (previously defined):
static long _time_global		= 0;		// Reset to signedMillis() at every soft reset
static long _time_trial			= 0;		// Reset to 0 at start of trial
static long _resultCode			= -1;		// Result code. -1 if there is no result.
static State _state				= _STATE_INIT;	// This variable (current _state) get passed into a _state function, which determines what the next _state should be, and updates it to the next _state.
static State _prevState			= _STATE_INIT;	// Remembers the previous _state from the last loop (actions should only be executed when you enter a _state for the first time, comparing currentState vs _prevState helps us keep track of that).
static char _command			= ' ';		// Command char received from host, resets on each loop
static int _arguments[2]		= {0};		// Two integers received from host , resets on each loop


/*****************************************************
	INITIALIZATION LOOP
*****************************************************/
void setup()
{
	// Init pins
	pinMode(PIN_HOUSE_LAMP, OUTPUT);            // LED for illumination
	pinMode(PIN_LED_CUE, OUTPUT);               // LED for 'start' cue
	pinMode(PIN_SPEAKER, OUTPUT);               // Speaker for cue tone
	pinMode(PIN_REWARD, OUTPUT);                // Reward, set to HIGH to open juice valve
	pinMode(PIN_LICK, INPUT);                   // Lick detector

	// Serial comms
	Serial.begin(115200);                       // Set up USB communication at 115200 baud 
}

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
		/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			Step 1: Read USB MESSAGE from HOST (if available)
		~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
		// 1) Check USB for MESSAGE from HOST, if available. String is read byte by byte. (Each character is a byte, so reads e/a character)
		// Initialize usbMessage to empty string, only happens once on first loop (thanks to static!)
		static String usbMessage  = "";
		_command = ' ';
		_arguments[0] = 0;
		_arguments[1] = 0;

		if (Serial.available() > 0)
		{
			char inByte = Serial.read();
			// The pound sign ('#') indicates a complete message
			if (inByte == '#')  
			{
				// Parse the string, and updates `_command`, and `_arguments`
				_command = getCommand(usbMessage);         
				getArguments(usbMessage, _arguments);
				// Clear message buffer (resets to prepare for next message)
				usbMessage = "";
				// "R" triggers a soft reset
				if (_command == 'R') 
				{
					break;
				}
			}
			else 
			{
				// append character to message buffer
				usbMessage = usbMessage + inByte;
			}
		}

		// 2) Check lick state
		static bool _lick_state = false;

		/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			Step 2: Update the State Machine
		~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
		// Depending on what _state we're in , call the appropriate _state function, which will evaluate the transition conditions, and update `_state` to what the next _state should be
		switch (_state) 
		{
			case _STATE_INIT:
				idle_state();
				break;

			case STATE_IDLE:
				idle_state();
				break;
			
			case STATE_TRIAL_START:
				trial_start();
				break;
		} // End switch statement--------------------------
	}
} // End main loop-------------------------------------------------------------------------------------------------------------



void mySetup()
{

	//--------------Set ititial OUTPUTS----------------//
	setHouseLamp(true);                          // House Lamp ON
	setCueLED(false);                            // Cue LED OFF

	//---------------------------Reset a bunch of variables---------------------------//


	// Sends all parameters, states and error codes to Matlab, then tell PC that we're running by sending '~' message:
	hostInit();
}










/*****************************************************
	States for the State Machine
*****************************************************/

/*****************************************************
	IDLE - await GO command from host
*****************************************************/
void idle_state() {
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);

		// Reset output
		setHouseLamp(true);
		setCueLED(false);
		noTone(PIN_SPEAKER);
		setReward(false);
		
		// Reset variables
		_resultCode = -1;	// Reset result code to -1: no result
	}

	/*****************************************************
		TRANSITION LIST
	*****************************************************/
	// GO signal from host --> STATE_TRIAL_START
	if (_command == 'G') 
	{                           
		_state = STATE_TRIAL_START;
		return;
	}
	
	// Received new param from host: format "P _paramID _newValue" ('P' for Parameters)
	if (_command == 'P') 
	{                           
		_params[_arguments[0]] = _arguments[1];
		_state = STATE_IDLE;
		return;
	}

	_state = STATE_IDLE;
}


/*****************************************************
	STATE_TRIAL_START - Trial started
*****************************************************/
void trial_start() {
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);

		// Reset output
		setHouseLamp(false);
		
		// Reset variables
		_resultCode = -1;	// Reset result code to -1: no result
	}

	/*****************************************************
		TRANSITION LIST
	*****************************************************/
	// GO signal from host --> STATE_TRIAL_START
	if (_command == 'G') 
	{                           
		_state = STATE_TRIAL_START;
		return;
	}
	
	// Received new param from host: format "P _paramID _newValue" ('P' for Parameters)
	if (_command == 'P') 
	{                           
		_params[_arguments[0]] = _arguments[1];
		_state = STATE_IDLE;
		return;
	}

	_state = STATE_IDLE;
}


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
bool getLickState() 
{
	if (digitalRead(PIN_LICK) == HIGH) 
	{
		return true;
	}
	else 
	{
		return false;
	}
} // end Get Lever State---------------------------------------------------------------------------------------------------------------------

void handleLick() 
{
	if (getLickState() && !_lick_state)
	{
		_lick_state = true;

		sendEventMarker(EVENT_LICK);
	}

	if (!getLickState() && _lick_state)
	{
		_lick_state = false;
	}
}

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
} // end Play Sound---------------------------------------------------------------------------------------------------------------------

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	SET STATE_REWARD (Deliver or turn off reward)
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

void sendEventMarker(EventMarker eventMarker)
{
	sendMessage("&" + String(eventMarker) + " " + String(signedMillis() - _time_global));
}

void sendState(State state)
{
	sendMessage("$" + String(state));
}

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

long signedMillis()
{
	long time = (long)(millis());
	return time;
}