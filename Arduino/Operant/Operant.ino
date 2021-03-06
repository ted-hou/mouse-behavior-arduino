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
#define PIN_HOUSE_LAMP	6
#define PIN_LED_CUE		4
#define PIN_REWARD		7

// Digital OUT to Nidaq
#define PIN_NIDAQ_CUE		8
#define PIN_NIDAQ_LICK		9
#define PIN_NIDAQ_REWARD	10

// PWM OUT
#define PIN_SPEAKER		5

// Digital IN
#define PIN_LICK		2


/*****************************************************
	Enums - DEFINE States
*****************************************************/
// All the states
enum State
{
	_STATE_INIT,			// (Private) Initial state used on first loop. 
	STATE_IDLE,				// Idle state. Wait for go signal from host.
	STATE_INTERTRIAL,		// House lamps ON (if not already), write data to HOST and DISK, receive new params
	STATE_PRE_CUE,			// House lamp OFF, random delay before cue presentation
	STATE_PRE_WINDOW,		// (+/-) Enforced no lick before response window opens
	STATE_RESPONSE_WINDOW,	// First lick in this interval rewarded (operant). Reward delivered at target time (pavlov)
	STATE_REWARD,			// Dispense reward, wait for trial timeout
	STATE_ABORT,			// Pre window lick - House lamps ON, timeout
	_NUM_STATES				// (Private) Used to count number of states
};

// State names stored as strings, will be sent to host
// Names cannot contain spaces!!!
static const char *_stateNames[] = 
{
	"_INIT",
	"IDLE",
	"INTERTRIAL",
	"PRE_CUE",
	"PRE_WINDOW",
	"RESPONSE_WINDOW",
	"REWARD",
	"ABORT"
};

// Define which states allow param update
static const int _stateCanUpdateParams[] = {0,1,1,0,0,0,0,0}; 
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
	EVENT_LICK,						// Lick onset
	EVENT_LICK_OFF,					// Lick offset
	EVENT_FIRST_LICK,				// First lick in trial since cue on
	EVENT_CUE_ON,					// Begin cue presentation
	EVENT_CUE_OFF,					// Begin cue presentation
	EVENT_HOUSELAMP_ON,				// House lamp on
	EVENT_HOUSELAMP_OFF,			// House lamp off
	EVENT_REWARD_ON,				// Reward, juice valve on
	EVENT_REWARD_OFF,				// Reward, juice valve off
	EVENT_ABORT,					// Trial aborted
	EVENT_ITI,						// ITI
	_NUM_OF_EVENT_MARKERS
};

static const char *_eventMarkerNames[] =
{
	"TRIAL_START",				// New trial initiated
	"WINDOW_OPEN",				// Response window open
	"TARGET_TIME",				// Target time
	"WINDOW_CLOSED",			// Response window closed
	"LICK",						// Lick onset
	"LICK_OFF",					// Lick offset
	"FIRST_LICK",				// First lick in trial since cue on
	"CUE_ON",					// Begin cue presentation
	"CUE_OFF",					// Begin cue presentation
	"HOUSELAMP_ON",				// House lamp on
	"HOUSELAMP_OFF",			// House lamp off
	"REWARD_ON",				// Reward, juice valve on
	"REWARD_OFF",				// Reward, juice valve off
	"ABORT",					// Trial aborted
	"ITI"						// ITI
};

/*****************************************************
	Result codes
*****************************************************/
enum ResultCode
{
	CODE_CORRECT,			// Correct (1st lick w/in window)
	CODE_EARLY_LICK,		// Early Lick (-> Abort in Enforced No-Lick)
	CODE_NO_LICK,			// No Lick (Timeout -> ITI)
	_NUM_RESULT_CODES		// (Private) Used to count how many codes there are.
};

// We'll send result code translations to MATLAB at startup
static const char *_resultCodeNames[] =
{
	"CORRECT",
	"EARLY_LICK",
	"NO_LICK"
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
	ALLOW_EARLY_LICK,			// 0 to abort trial if animal licks after in pre-window
	INCREMENTAL_REWARD,			// 1 to give more reward if lick is closer to target time. 0 to always give MAX reward.
	INTERVAL_MIN,				// Time to start of reward window (ms)
	INTERVAL_TARGET,			// Target time (ms)
	INTERVAL_MAX,				// Time to end of reward window (ms)
	ITI,						// Intertrial interval duration (ms)
	RANDOM_DELAY_MIN,			// Minimum random pre-Cue delay (ms)
	RANDOM_DELAY_MAX,			// Maximum random pre-Cue delay (ms)
	CUE_DURATION,				// Duration of the cue tone and LED flash (ms)
	REWARD_DURATION_MIN,		// Min duration of reward if INCREMENTAL_REWARD == 1 (ms)
	REWARD_DURATION_MAX,		// Max duration of reward if INCREMENTAL_REWARD == 1 (ms)
	_NUM_PARAMS					// (Private) Used to count how many parameters there are so we can initialize the param array with the correct size. Insert additional parameters before this.
};

// Store parameter names as strings, will be sent to host
// Names cannot contain spaces!!!
static const char *_paramNames[] = 
{
	"_DEBUG",
	"ALLOW_EARLY_LICK",
	"INCREMENTAL_REWARD",
	"INTERVAL_MIN",
	"INTERVAL_TARGET",
	"INTERVAL_MAX",
	"ITI",
	"RANDOM_DELAY_MIN",
	"RANDOM_DELAY_MAX",
	"CUE_DURATION",
	"REWARD_DURATION_MIN",
	"REWARD_DURATION_MAX"
};

// Initialize parameters
long _params[_NUM_PARAMS] = 
{
	0,		// _DEBUG
	0,		// ALLOW_EARLY_LICK
	1,		// INCREMENTAL_REWARD
	1500,	// INTERVAL_MIN
	3000,	// INTERVAL_TARGET
	4500,	// INTERVAL_MAX
	10000,	// ITI
	1000,	// RANDOM_DELAY_MIN
	3000,	// RANDOM_DELAY_MAX
	100,	// CUE_DURATION
	50, 	// REWARD_DURATION_MIN
	200 	// REWARD_DURATION_MAX
};

/*****************************************************
	Other Global Variables 
*****************************************************/
// Variables declared here can be carried to the next loop, AND read/written in function scope as well as main scope
// (previously defined):
static long _timeReset				= 0;			// Reset to signedMillis() at every soft reset
static long _timeTrialStart			= 0;			// Reset to 0 at start of trial
static long _timeCueOn				= 0;			// Reset to 0 at cue on
static int _resultCode				= -1;			// Result code. -1 if there is no result.
static State _state					= _STATE_INIT;	// This variable (current _state) get passed into a _state function, which determines what the next _state should be, and updates it to the next _state.
static State _prevState				= _STATE_INIT;	// Remembers the previous _state from the last loop (actions should only be executed when you enter a _state for the first time, comparing currentState vs _prevState helps us keep track of that).
static char _command				= ' ';			// Command char received from host, resets on each loop
static int _arguments[2]			= {0};			// Two integers received from host , resets on each loop
static bool _isLicking 				= false;		// True if the little dude is licking
static bool _isLickOnset 			= false;		// True during lick onset
static bool _firstLickRegistered 	= false;		// True when first lick is registered for this trial

// For white noise generator
static bool _whiteNoiseIsPlaying 			= false;
static unsigned long _whiteNoiseInterval 	= 50;	// Determines frequency (us)
static unsigned long _whiteNoiseDuration 	= 200;	// Noise duration (ms)
static unsigned long _whiteNoiseFirstClick 	= 0;	// (us)
static unsigned long _whiteNoiseLastClick 	= 0;	// (us)
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

	pinMode(PIN_NIDAQ_CUE, OUTPUT);
	pinMode(PIN_NIDAQ_LICK, OUTPUT);
	pinMode(PIN_NIDAQ_REWARD, OUTPUT);

	// Serial comms
	Serial.begin(115200);                       // Set up USB communication at 115200 baud 
}


void mySetup()
{
	// Reset output
	setHouseLamp(true);                          // House Lamp ON
	setCueLED(false);                            // Cue LED OFF

	// Reset variables
	_timeReset				= 0;			// Reset to signedMillis() at every soft reset
	_timeTrialStart			= 0;			// Reset to 0 at start of trial
	_timeCueOn				= 0;
	_resultCode				= -1;			// Result code. -1 if there is no result.
	_state					= _STATE_INIT;	// This variable (current _state) get passed into a _state function, which determines what the next _state should be, and updates it to the next _state.
	_prevState				= _STATE_INIT;	// Remembers the previous _state from the last loop (actions should only be executed when you enter a _state for the first time, comparing currentState vs _prevState helps us keep track of that).
	_command				= ' ';			// Command char received from host, resets on each loop
	_arguments[2]			= {0};			// Two integers received from host , resets on each loop
	_isLicking 				= false;		// True if the little dude is licking
	_isLickOnset 			= false;		// True during lick onset
	_firstLickRegistered 	= false;		// True when first lick is registered for this trial

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
		
		// 3) Play white noise if required
		handleWhiteNoise();

		// 4) Update state machine
		// Depending on what _state we're in , call the appropriate _state function, which will evaluate the transition conditions, and update `_state` to what the next _state should be
		switch (_state) 
		{
			case _STATE_INIT:
				state_idle();
				break;

			case STATE_IDLE:
				state_idle();
				break;
			
			case STATE_INTERTRIAL:
				state_intertrial();
				break;
			
			case STATE_PRE_CUE:
				state_pre_cue();
				break;
			
			case STATE_PRE_WINDOW:
				state_pre_window();
				break;
			
			case STATE_RESPONSE_WINDOW:
				state_response_window();
				break;
			
			case STATE_REWARD:
				state_reward();
				break;
			
			case STATE_ABORT:
				state_abort();
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
		OnEachLoop checks
	*****************************************************/
	// Received new param from host: format "P _paramID _newValue" ('P' for Parameters)
	if (_command == 'P') 
	{
		_params[_arguments[0]] = _arguments[1];
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
	
	_state = STATE_IDLE;
}


/*****************************************************
	PRE_CUE - First state in trial
*****************************************************/
void state_pre_cue() 
{
	static long preCueDelay;
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
		preCueDelay = random(_params[RANDOM_DELAY_MIN], _params[RANDOM_DELAY_MAX]);

		// Reset variables
		_resultCode = -1;
		_firstLickRegistered = false;
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

	// Pre-cue delay completed --> PRE_WINDOW
	if (getTimeSinceTrialStart() >= preCueDelay)
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
		OnEachLoop checks
	*****************************************************/
	if (getTimeSinceCueOn() >= _params[CUE_DURATION])
	{
		setCueLED(false);
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
		// pre-window lick not allowed --> ABORT
		if (_params[ALLOW_EARLY_LICK] == 0)
		{
			setCueLED(false);
			_state = STATE_ABORT;
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

	// Correct lick --> REWARD
	if (_isLickOnset)
	{
		// First lick registration
		if (!_firstLickRegistered)
		{
			_firstLickRegistered = true;
			sendEventMarker(EVENT_FIRST_LICK, -1);
		}

		_state = STATE_REWARD;
		return;
	}

	// Response window elapsed --> ITI
	if (getTimeSinceCueOn() >= _params[INTERVAL_MAX])
	{
		_resultCode = CODE_NO_LICK;
		_state = STATE_INTERTRIAL;
		return;
	}

	_state = STATE_RESPONSE_WINDOW;
}


/*****************************************************
	REWARD - Turn on juice valve for some time
*****************************************************/
void state_reward()
{
	static long rewardDuration;
	static long timeRewardOn;
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);

		// Register result
		_resultCode = CODE_CORRECT;

		// Register time of state entry
		timeRewardOn = getTimeSinceCueOn();

		// Determine reward duration
		// Incremental reward:
		if (_params[INCREMENTAL_REWARD])
		{
			// Lick before or at target
			if (timeRewardOn <= _params[INTERVAL_TARGET])
			{
				rewardDuration = _params[REWARD_DURATION_MIN] + (timeRewardOn - _params[INTERVAL_MIN])*(_params[REWARD_DURATION_MAX] - _params[REWARD_DURATION_MIN])/(_params[INTERVAL_TARGET] - _params[INTERVAL_MIN]);
			}
			// Lick after target
			else
			{
				rewardDuration = _params[REWARD_DURATION_MAX] + (timeRewardOn - _params[INTERVAL_TARGET])*(_params[REWARD_DURATION_MIN] - _params[REWARD_DURATION_MAX])/(_params[INTERVAL_MAX] - _params[INTERVAL_TARGET]);
			}
			sendMessage("Reward duration: " + String(rewardDuration) + " ms.");
		}
		// Fixed reward:
		else
		{
			rewardDuration = _params[REWARD_DURATION_MAX];
		}

		// Turn on reward
		if (rewardDuration > 0)
		{
			setReward(true);
		}

		// Houselamp on
		setHouseLamp(true);
	}

	/*****************************************************
		OnEachLoop checks
	*****************************************************/
	// Turn off reward
	if (rewardDuration > 0 && getTimeSinceCueOn() - timeRewardOn >= rewardDuration)
	{
		setReward(false);
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

	// Trial duration elapsed and reward dispense complete --> INTERTRIAL
	if (getTimeSinceCueOn() >= _params[INTERVAL_MAX] && (rewardDuration <= 0 || getTimeSinceCueOn() - timeRewardOn >= rewardDuration))
	{
		_state = STATE_INTERTRIAL;
		return;
	}

	_state = STATE_REWARD;
}


/*****************************************************
	ABORT - Early lick timeout
*****************************************************/
void state_abort()
{
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);

		// Register result
		_resultCode = CODE_EARLY_LICK;

		// Register events
		sendEventMarker(EVENT_ABORT, -1);

		// Play abort tone
		playWhiteNoise(50, 200);
		// playSound(TONE_ABORT);

		// Houselamp on
		setHouseLamp(true);
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

	// Trial duration elapsed --> INTERTRIAL
	if (getTimeSinceCueOn() >= _params[INTERVAL_MAX])
	{
		_state = STATE_INTERTRIAL;
		return;
	}

	_state = STATE_ABORT;
}



/*****************************************************
	INTERTRIAL
*****************************************************/
void state_intertrial()
{
	static long timeIntertrial;
	static bool isParamsUpdateStarted;
	static bool isParamsUpdateDone;
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);

		// Register events
		sendEventMarker(EVENT_ITI, -1);

		// Send results
		sendResultCode(_resultCode);
		_resultCode = -1;

		// Houselamp on (if not already on)
		setHouseLamp(true);

		// Register time of state entry
		timeIntertrial = getTimeSinceCueOn();

		// Variables for handling parameter update
		isParamsUpdateStarted = false;
		isParamsUpdateDone = false;
	}

	/*****************************************************
		OnEachLoop checks
	*****************************************************/
	// Received new param from HOST: format "P paramID newValue"
	// Mark transmission start. Don't start next trial until we've finished.
	if (_command == 'P') 
	{
		isParamsUpdateStarted = true;
		_params[_arguments[0]] = _arguments[1];
	}

	// Parameter transmission complete:
	if (_command == 'O') {
		isParamsUpdateDone = true;
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

	// If ITI elapsed --> PRE_CUE
	if (getTimeSinceCueOn() - timeIntertrial >= _params[ITI] && (isParamsUpdateDone || !isParamsUpdateStarted))
	{
		_state = STATE_PRE_CUE;
		return;
	}

	_state = STATE_INTERTRIAL;
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
		digitalWrite(PIN_NIDAQ_CUE, HIGH);
		if (!cueLEDOn)
		{
			cueLEDOn = true;
			sendEventMarker(EVENT_CUE_ON, -1);
		}
	}
	else 
	{
		digitalWrite(PIN_LED_CUE, LOW);
		digitalWrite(PIN_NIDAQ_CUE, LOW);
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
		digitalWrite(PIN_NIDAQ_LICK, HIGH);
		_isLicking = true;
		_isLickOnset = true;
		sendEventMarker(EVENT_LICK, -1);
	}
	else
	{
		if (!getLickState() && _isLicking)
		{
			digitalWrite(PIN_NIDAQ_LICK, LOW);
			_isLicking = false;
			sendEventMarker(EVENT_LICK_OFF, -1);
		}
		_isLickOnset = false;
	}

}

// Play a tone defined in SoundEventFrequencyEnum
void playSound(SoundEventFrequencyEnum soundEventFrequency) 
{
	long duration = 200;

	if (soundEventFrequency == TONE_CUE)
	{
		duration = _params[CUE_DURATION];
	}

	noTone(PIN_SPEAKER);
	tone(PIN_SPEAKER, soundEventFrequency, duration);
}

void playWhiteNoise(unsigned long frequency, unsigned long duration)
{
	_whiteNoiseDuration = duration;
	_whiteNoiseFirstClick = micros();
	_whiteNoiseLastClick = micros();
}

void handleWhiteNoise() 
{
	if (micros() - _whiteNoiseFirstClick < _whiteNoiseDuration*1000)
	{
		_whiteNoiseIsPlaying = true;
		if ((micros() - _whiteNoiseLastClick) > _whiteNoiseInterval) 
		{
			_whiteNoiseLastClick = micros();
			digitalWrite(PIN_SPEAKER, random(2));
		}		
	}
	else
	{
		if (_whiteNoiseIsPlaying)
		{
			_whiteNoiseIsPlaying = false;
			digitalWrite(PIN_SPEAKER, 0);
		}
	}

}

// Toggle juice valve, register event when state is changed
void setReward(bool turnOn) 
{
	static bool rewardOn = false;
	if (turnOn)
	{
		digitalWrite(PIN_REWARD, HIGH);
		digitalWrite(PIN_NIDAQ_REWARD, HIGH);
		if (!rewardOn)
		{
			rewardOn = true;
			sendEventMarker(EVENT_REWARD_ON, -1);
		}		
	}
	else
	{
		digitalWrite(PIN_REWARD, LOW);
		digitalWrite(PIN_NIDAQ_REWARD, LOW);
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
void sendMessage(String message)	// Uses String object from arduino library
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

void sendResultCode(int resultCode)
{
	if (resultCode >= 0)
	{
		sendMessage("`" + String(resultCode));
	}
	else
	{
		sendMessage("ERROR: Invalid result code.");
	}
}

// GET COMMAND FROM HOST (single character)
char getCommand(String message)
{
	message.trim();				// Remove leading and trailing white space
	return message[0];			// 1st character in a message string is the command
}

// GET ARGUMENTS (of the command) from HOST (2 int array)
void getArguments(String message, int *_arguments)
{
	_arguments[0] = 0;
	_arguments[1] = 0;

	message.trim();				// Remove leading and trailing white space

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