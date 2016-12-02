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
	STATE_PRE_CUE,			// House lamp OFF, random delay before cue presentation
	STATE_PRE_WINDOW,		// (+/-) Enforced no lick before response window opens
	STATE_RESPONSE_WINDOW,	// First lick in this interval rewarded (operant). Reward delivered at target time (pavlov)
	STATE_POST_WINDOW,		// Check for late licks
	STATE_REWARD,			// Dispense reward, wait for trial timeout
	STATE_PRE_CUE_ABORT,	// Pre cue lick -> House lamps ON, timeout, send virtual cue on event marker
	STATE_PRE_WINDOW_ABORT,	// Pre window lick - House lamps ON, timeout
	STATE_INTERTRIAL,		// House lamps ON (if not already), write data to HOST and DISK, receive new params
	_NUM_STATES				// (Private) Used to count number of states
};

// State names stored as strings, will be sent to host
// Names cannot contain spaces!!!
static const char *_stateNames[] = 
{
	"_INIT",
	"IDLE",
	"PRE_CUE",
	"PRE_WINDOW",
	"RESPONSE_WINDOW",
	"POST_WINDOW",
	"REWARD",
	"PRE_CUE_ABORT",
	"PRE_WINDOW_ABORT",
	"INTERTRIAL"
};

// Define which states allow param update
static const int _stateCanUpdateParams[] = {0,1,0,0,0,0,0,0,0,1}; 
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
	EVENT_WINDOW_OPEN,				// Response window open
	EVENT_TARGET_TIME,				// Target time
	EVENT_WINDOW_CLOSED,			// Response window closed
	EVENT_TRIAL_END,				// Trial end
	EVENT_LICK,						// Lick onset
	EVENT_LICK_OFF,					// Lick offset
	EVENT_FIRST_LICK,				// First lick in trial
	EVENT_FIRST_LICK_SINCE_CUE,		// First lick in trial since cue on (useful if pre-cue lick is allowed)
	EVENT_CUE_ON,					// Begin cue presentation
	EVENT_CUE_OFF,					// Begin cue presentation
	EVENT_HOUSELAMP_ON,				// House lamp on
	EVENT_HOUSELAMP_OFF,			// House lamp off
	EVENT_REWARD_ON,				// Reward, juice valve on
	EVENT_REWARD_OFF,				// Reward, juice valve off
	EVENT_ABORT,					// Trial aborted
	EVENT_PRE_CUE_ABORT,			// Trial aborted due to early lick (before cue)
	EVENT_PRE_WINDOW_ABORT,			// Trial aborted due to early lick (before window)
	EVENT_POST_WINDOW_ABORT,		// Trial aborted due to late lick (after window)
	_NUM_OF_EVENT_MARKERS
};

static const char *_eventMarkerNames[] =    // * to define array of strings
{
	"TRIAL_START",
	"CUE_ON",
	"CUE_OFF",
	"WINDOW_OPEN",
	"TARGET_TIME",
	"WINDOW_CLOSED",
	"TRIAL_END",
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
	"PAVLOV"
};


/*****************************************************
	Audio cue frequencies in Hz
*****************************************************/
enum SoundEventFrequencyEnum
{
	TONE_CUE     = 784,
	TONE_ABORT   = 89
};

/*****************************************************
	Parameters that can be updated by HOST
*****************************************************/
// Storing everything in array _params[]. Using enum ParamID as array indices so it's easier to add/remove parameters. 
enum ParamID
{
	_DEBUG,						// (Private) 1 to enable debug messages from HOST. Default 0.
	PAVLOVIAN,					// 1 to enable Pavlovian Mode
	ALLOW_PRE_CUE_LICK,			// 0 to abort trial if animal licks before cue
	ALLOW_PRE_WINDOW_LICK,		// 0 to abort trial if animal licks after cue and before window
	INTERVAL_MIN,				// Time to start of reward window (ms)
	TARGET,						// Target time (ms)
	INTERVAL_MAX,				// Time to end of reward window (ms)
	TRIAL_DURATION,				// Total alloted time/trial (ms)
	ITI,						// Intertrial interval duration (ms)
	RANDOM_DELAY_MIN,			// Minimum random pre-Cue delay (ms)
	RANDOM_DELAY_MAX,			// Maximum random pre-Cue delay (ms)
	CUE_DURATION,				// Duration of the cue tone and LED flash (ms)
	REWARD_DURATION,			// Duration of reward dispensal (ms)
	_NUM_PARAMS					// (Private) Used to count how many parameters there are so we can initialize the param array with the correct size. Insert additional parameters before this.
};

// Store parameter names as strings, will be sent to host
// Names cannot contain spaces!!!
static const char *_paramNames[] = 
{
	"_DEBUG",
	"PAVLOVIAN",
	"ALLOW_PRE_CUE_LICK",
	"ALLOW_PRE_WINDOW_LICK",
	"INTERVAL_MIN",
	"INTERVAL_TARGET",
	"INTERVAL_MAX",
	"TRIAL_DURATION",
	"ITI",
	"RANDOM_DELAY_MIN",
	"RANDOM_DELAY_MAX",
	"CUE_DURATION",
	"REWARD_DURATION"
};

// Initialize parameters
long _params[_NUM_PARAMS] = 
{
	0,		// _DEBUG
	0,		// PAVLOVIAN
	0,		// ALLOW_PRE_CUE_LICK
	0,		// ALLOW_PRE_WINDOW_LICK
	1500,	// INTERVAL_MIN
	3000,	// INTERVAL_TARGET
	4000,	// INTERVAL_MAX
	5000,	// TRIAL_DURATION
	10000,	// ITI
	1000,	// RANDOM_DELAY_MIN
	3000,	// RANDOM_DELAY_MAX
	100,	// CUE_DURATION
	150 	// REWARD_DURATION
};

/*****************************************************
	Other Global Variables 
*****************************************************/
// Variables declared here can be carried to the next loop, AND read/written in function scope as well as main scope
// (previously defined):
static long _timeReset						= 0;			// Reset to signedMillis() at every soft reset
static long _timeTrialStart					= 0;			// Reset to 0 at start of trial
static long _resultCode						= -1;			// Result code. -1 if there is no result.
static State _state							= _STATE_INIT;	// This variable (current _state) get passed into a _state function, which determines what the next _state should be, and updates it to the next _state.
static State _prevState						= _STATE_INIT;	// Remembers the previous _state from the last loop (actions should only be executed when you enter a _state for the first time, comparing currentState vs _prevState helps us keep track of that).
static char _command						= ' ';			// Command char received from host, resets on each loop
static int _arguments[2]					= {0};			// Two integers received from host , resets on each loop
static bool _isLicking 						= false;		// True if the little dude is licking
static bool _isLickOnset 					= false;		// True during lick onset
static bool _firstLickRegistered 			= false;		// True when first lick is registered for this trial
static bool _firstLickSinceCueRegistered 	= false;		// True when first lick (since cue on) is registered for this trial


static long _preCueDelay 	= 0;			// Random wait (ms) between trial start and cue on

/*****************************************************
	Setup
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


void mySetup()
{
	// Reset output
	setHouseLamp(true);                          // House Lamp ON
	setCueLED(false);                            // Cue LED OFF

	// Reset variables

	// Sends all parameters, states and error codes to Matlab, then tell PC that we're running by sending '~' message:
	hostInit();
}

/*****************************************************
	MAIN LOOP
*****************************************************/
void loop()
{
	// Initialization
	mySetup();

	// Main loop (break out via "soft reset" command)
	while (true)
	{
		// 1) Check USB for MESSAGE from HOST, if available. String is read byte by byte.
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

		// 2) Check for licks and update GVARS: _isLicking and _isLickOnset
		handleLick();

		// 3) Update state machine
		// Depending on what _state we're in , call the appropriate _state function, which will evaluate the transition conditions, and update `_state` to what the next _state should be
		switch (_state) 
		{
			case _STATE_INIT:
				state_idle();
				break;

			case STATE_IDLE:
				state_idle();
				break;
			
			case STATE_PRE_CUE:
				state_pre_cue();
				break;
			
			case STATE_PRE_WINDOW:
				state_pre_window();
				break;
		}
	}
}




/*****************************************************
	States for the State Machine
*****************************************************/

/*****************************************************
	IDLE - await GO command from host
*****************************************************/
void state_idle() 
{
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
	}

	/*****************************************************
		TRANSITION LIST
	*****************************************************/
	// GO signal from host --> STATE_PRE_CUE
	if (_command == 'G') 
	{                           
		_state = STATE_PRE_CUE;
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
	PRE_CUE - First state in trial
*****************************************************/
void state_pre_cue() 
{
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);

		// Register events
		sendEventMarker(EVENT_TRIAL_START, -1);

		// Turn off house lamp
		setHouseLamp(false);

		// Register trial start time
		_timeTrialStart = signedMillis();

		// Generate random interval length
		_preCueDelay = random(_params[RANDOM_DELAY_MIN], _params[RANDOM_DELAY_MAX]);

		// Reset variables
		_resultCode = -1;
		_firstLickRegistered = false;
		_firstLickSinceCueRegistered = false;
	}

	/*****************************************************
		TRANSITION LIST
	*****************************************************/
	// Quit signal from host --> IDLE
	if (_command == 'Q') 
	{                           
		_state = STATE_IDLE;
		return;
	}

	// Lick detected
	if (_isLickOnset)
	{
		// First lick registration
		if (!_firstLickRegistered)
		{
			_firstLickRegistered = true;
			sendEventMarker(EVENT_FIRST_LICK, -1);
		}

		// pre-cue lick not allowed --> PRE_CUE_ABORT
		if (_params[ALLOW_PRE_CUE_LICK] == 0)
		{
			_state = STATE_PRE_CUE_ABORT;
			return;
		}
	}

	// Pre-cue delay completed --> PRE_WINDOW
	if (getTimeSinceTrialStart() >= _preCueDelay)
	{
		_state = STATE_PRE_WINDOW;
		return;
	}

	_state = STATE_PRE_CUE;
}


/*****************************************************
	PRE_WINDOW - Trial started
*****************************************************/
void state_pre_window() 
{
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);

		// LED and audio cue
		setCueLED(true);
		playSound(TONE_CUE);

		// Register cue on time
		_timeCueOn = signedMillis();
	}

	/*****************************************************
		TRANSITION LIST
	*****************************************************/
	// Quit signal from host --> IDLE
	if (_command == 'Q') 
	{                           
		_state = STATE_IDLE;
		return;
	}

	// Lick detected
	if (_isLickOnset)
	{
		// First lick registration
		if (!_firstLickRegistered)
		{
			_firstLickRegistered = true;
			sendEventMarker(EVENT_FIRST_LICK, -1);
		}
		// First post cue lick registration
		if (!_firstLickSinceCueRegistered)
		{
			_firstLickSinceCueRegistered = true;
			sendEventMarker(EVENT_FIRST_LICK_SINCE_CUE, -1);
		}
		// pre-window lick not allowed --> PRE_WINDOW_ABORT
		if (_params[ALLOW_PRE_WINDOW_LICK] == 0)
		{
			_state = STATE_PRE_WINDOW_ABORT;
			return;
		}
	}

	// Pre-window elapsed --> PRE_WINDOW
	if (getTimeSinceCueOn() >= _params[INTERVAL_MIN])
	{
		_state = STATE_RESPONSE_WINDOW;
		return;
	}

	_state = STATE_PRE_WINDOW;
}


/*****************************************************
	RESPONSE_WINDOW - Licking triggers reward
*****************************************************/
void state_response_window() 
{
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);

		// Register events
		sendEventMarker(EVENT_WINDOW_OPEN, -1);
	}

	/*****************************************************
		TRANSITION LIST
	*****************************************************/
	// Quit signal from host --> IDLE
	if (_command == 'Q') 
	{                           
		_state = STATE_IDLE;
		return;
	}

	// Lick detected & pre-window lick not allowed --> PRE_WINDOW_ABORT
	if (_isLicking && _params[ALLOW_PRE_WINDOW_LICK] == 0)
	{
		_state = STATE_PRE_WINDOW_ABORT;
		return;
	}

	// Pre-window elapsed --> PRE_WINDOW
	if (getTimeSinceCueOn() >= _params[INTERVAL_MIN])
	{
		_state = STATE_RESPONSE_WINDOW;
		return;
	}

	_state = STATE_PRE_WINDOW;
}


/*****************************************************
	HARDWARE CONTROLS
*****************************************************/
// Toggle house lamp, register event when lamp state is changed
void setHouseLamp(bool turnOn) 
{
	static bool houseLampOn = false;
	if (turnOn) 
	{
		digitalWrite(PIN_HOUSE_LAMP, HIGH);
		if (!houseLampOn)
		{
			houseLampOn = true;
			sendEventMarker(EVENT_HOUSELAMP_ON, -1);
		}
	}
	else 
	{
		digitalWrite(PIN_HOUSE_LAMP, LOW);
		if (houseLampOn)
		{
			houseLampOn = false;
			sendEventMarker(EVENT_HOUSELAMP_OFF, -1);
		}
	}
}

// Toggle cue led, register event when state is changed
void setCueLED(bool turnOn) 
{
	static bool cueLEDOn = false;
	if (turnOn) 
	{
		digitalWrite(PIN_LED_CUE, HIGH);
		if (!cueLEDOn)
		{
			cueLEDOn = true;
			sendEventMarker(EVENT_CUE_ON, -1);
		}
	}
	else 
	{
		digitalWrite(PIN_LED_CUE, LOW);
		if (cueLEDOn)
		{
			cueLEDOn = false;
			sendEventMarker(EVENT_CUE_OFF, -1);
		}
	}
} 

// Lick detection
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
}

// Must be called once and only once on each loop. Returns true during lick onset
void handleLick() 
{
	if (getLickState() && !_isLicking)
	{
		_isLicking = true;
		_isLickOnset = true;
		sendEventMarker(EVENT_LICK, -1);
	}
	else
	{
		if (!getLickState() && _isLicking)
		{
			_isLicking = false;
			sendEventMarker(EVENT_LICK_OFF, -1);
		}
		_isLickOnset = false;
	}

}

// Play a tone defined in SoundEventFrequencyEnum
void playSound(SoundEventFrequencyEnum soundEventFrequency) {
	long duration = 200;

	if (soundEventFrequency == TONE_CUE)
	{
		duration = _params[CUE_DURATION];
	}

	noTone(PIN_SPEAKER);
	tone(PIN_SPEAKER, soundEventFrequency, duration);
}

// Toggle juice valve, register event when state is changed
void setReward(bool turnOn) 
{
	static bool rewardOn = false;
	if (turnOn)                                                       
	{
		digitalWrite(PIN_REWARD, HIGH);
		if (!rewardOn)
		{
			rewardOn = true;
			sendEventMarker(EVENT_REWARD_ON, -1);
		}		
	}
	else
	{
		digitalWrite(PIN_REWARD, LOW);
		if (rewardOn)
		{
			rewardOn = false;
			sendEventMarker(EVENT_REWARD_OFF, -1);
		}				
	}
}

/*****************************************************
	SERIAL COMMUNICATION TO HOST
*****************************************************/

//SEND MESSAGE to HOST
void sendMessage(String message)   // Uses String object from arduino library
{
	Serial.println(message);
}

// Register eventMarker on host.
// If timestamp argument is negative, use current time
void sendEventMarker(EventMarker eventMarker, long timestamp)
{
	if (timestamp == -1)
	{
		sendMessage("&" + String(eventMarker) + " " + String(getTime()));
	}
	else
	{
		sendMessage("&" + String(eventMarker) + " " + String(timestamp));
	}
}

void sendState(State state)
{
	sendMessage("$" + String(state));
}

// GET COMMAND FROM HOST (single character)
char getCommand(String message)
{
	message.trim();                 // Remove leading and trailing white space
	return message[0];              // 1st character in a message string is the command
}

// GET ARGUMENTS (of the command) from HOST (2 int array)
void getArguments(String message, int *_arguments)
{
	_arguments[0] = 0;
	_arguments[1] = 0;

	message.trim();                 // Remove leading and trailing white space

	// Remove command (first character) from string
	String parameters = message;
	parameters.remove(0,1);
	parameters.trim();

	// Parse first (optional) integer argument if it exists
	String intString = "";
	while ((parameters.length() > 0) && (isDigit(parameters[0]))) 
	{
		intString += parameters[0];
		parameters.remove(0,1);
	}
	_arguments[0] = intString.toInt();


	// Parse second (optional) integer argument if it exists
	parameters.trim();
	intString = "";
	while ((parameters.length() > 0) && (isDigit(parameters[0]))) 
	{
		intString += parameters[0];
		parameters.remove(0,1);
	}
	_arguments[1] = intString.toInt();
}

// Send States, Names/Value of Parameters to host
// Arduino uses 0-based indexing and we're sending the indices as is - they will be converted to 1-based indexing by MATLAB 
void hostInit()
{
	// Send state names
	for (int iState = 0; iState < _NUM_STATES; iState++)
	{
			sendMessage("@ " + String(iState) + " " + _stateNames[iState] + " " + String(_stateCanUpdateParams[iState]));
	}

	// Send event marker names
	for (int iCode = 0; iCode < _NUM_OF_EVENT_MARKERS; iCode++)
	{
			sendMessage("+ " + String(iCode) + " " + _eventMarkerNames[iCode]);
	}

	// Send param names and default values
	for (int iParam = 0; iParam < _NUM_PARAMS; iParam++)
	{
			sendMessage("# " + String(iParam) + " " + _paramNames[iParam] + " " + String(_params[iParam]));
	}

	// Send result code names
	for (int iCode = 0; iCode < _NUM_RESULT_CODES; iCode++)
	{
			sendMessage("* " + String(iCode) + " " + _resultCodeNames[iCode]);
	}
	sendMessage("~");	// Tells PC that Arduino is ready
}


/*****************************************************
	MISC
*****************************************************/
// `signed long` version of `millis()`
long signedMillis()
{
	long time = (long)(millis());
	return time;
}

// Returns time since last reset in milliseconds
long getTime()
{
	long time = signedMillis() - _timeReset;
	return time;
}

// Returns time since trial start in milliseconds
long getTimeSinceTrialStart()
{
	long time = signedMillis() - _timeTrialStart;
	return time;
}

// Returns time since cue on in milliseconds
long getTimeSinceCueOn()
{
	long time = signedMillis() - _timeCueOn;
	return time;
}
