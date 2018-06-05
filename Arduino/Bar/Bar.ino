/*********************************************************************
	Arduino state machine
	Rotating Bar task
*********************************************************************/

/*****************************************************
	Commands
*****************************************************/
// G - Go
// O - Over
// P - Parameters
// R - Reset
// Q - Quit

// T - Turning Point
// A - Alpha
// W - Omega 
// E - Is this the End? (Max trial length)

/*****************************************************
	Arduino Pin Outs
*****************************************************/
// Digital OUT
#define PIN_REWARD		9  // Dedicated PIN from Sabatini Board
#define PIN_LICK_LED	11 // USER_1

// Digital IN
#define PIN_LICK		13 // USER_3
#define PIN_IR_LAMP		12 // USER_2

/*****************************************************
	Enums - DEFINE States
*****************************************************/
// All the states
enum State
{
	_STATE_INIT,				// (Private) Initial state used on first loop. 
	STATE_IDLE,					// Idle state. Wait for go signal from host.
	STATE_INTERTRIAL,			// Write data to HOST and DISK, receive new params
	STATE_START,				// random delay before cue presentation
	STATE_BAR_STAT,				// Moving dots, stationary bar, enforced no lick
	STATE_BAR_MOVE,				// Moving dots, moving bar, enforced no lick
	STATE_RESPONSE_WINDOW,		// First lick in this interval rewarded
	STATE_REWARD,				// Dispense reward, wait for trial timeout
	STATE_ABORT,				// No lick - timeout
	STATE_ABORT_EARLY,			// Early lick
	STATE_ABORT_BAR_STAT,	// Early lick during stat
	_NUM_STATES					// (Private) Used to count number of states
};

// State names stored as strings, will be sent to host
// Names cannot contain spaces!!!
static const char *_stateNames[] = 
{
	"_INIT",
	"IDLE",
	"INTERTRIAL",
	"START",
	"BAR_STAT",
	"BAR_MOVE",
	"RESPONSE_WINDOW",
	"REWARD",
	"ABORT",
	"ABORT_EARLY",
	"ABORT_BAR_STAT"
};

// Define which states accept parameter update from MATLAB
static const int _stateCanUpdateParams[] = {0,1,1,0,0,0,0,0,0,0,0}; 

/*****************************************************
	Event Markers
*****************************************************/
enum EventMarker
{
	EVENT_TRIAL_START,				// New trial initiated
	EVENT_LICK,						// Lick onset
	EVENT_LICK_OFF,					// Lick offset
	EVENT_FIRST_LICK,				// First lick in trial since cue on
	EVENT_STIM_ON,					// Stim appear
	EVENT_BAR_MOVE,					// Bar begins rotation
	EVENT_ALPHA,					// Proactive, response window open
	EVENT_TURNING_POINT,			// Bar reverse
	EVENT_OMEGA,					// Reactive, response window close
	EVENT_REWARD_ON,				// Reward, juice valve on
	EVENT_REWARD_OFF,				// Reward, juice valve off
	EVENT_ABORT,					// Trial aborted
	EVENT_ABORT_EARLY,				// Trial aborted due to early lick
	EVENT_ITI,						// ITI
	_NUM_OF_EVENT_MARKERS
};

static const char *_eventMarkerNames[] =
{
	"TRIAL_START",				// New trial initiated
	"LICK",						// Lick onset
	"LICK_OFF",					// Lick offset
	"FIRST_LICK",				// First lick in trial since cue on
	"STIM_ON",					// Bar appear
	"BAR_MOVE",					// Bar begins rotation
	"ALPHA",					// Proactive, response window open
	"TURNING_POINT",			// Bar reverse
	"OMEGA",					// Reactive, response window close
	"REWARD_ON",				// Reward, juice valve on
	"REWARD_OFF",				// Reward, juice valve off
	"ABORT",					// Trial aborted
	"ABORT_EARLY",				// Trial aborted due to early lick
	"ITI"						// ITI
};

/*****************************************************
	Result codes
*****************************************************/
enum ResultCode
{
	CODE_CORRECT,			// Correct (1st lick w/in window)
	CODE_PAV,				// Pavlovian (Reward given when bar reverses)
	CODE_EARLY_LICK,		// Early Lick (-> Abort)
	CODE_NO_LICK,			// No Lick (Timeout -> ITI)
	_NUM_RESULT_CODES		// (Private) Used to count how many codes there are.
};

// We'll send result code translations to MATLAB at startup
static const char *_resultCodeNames[] =
{
	"CORRECT",
	"PAV",
	"EARLY_LICK",
	"NO_LICK"
};

/*****************************************************
	Parameters that can be updated by HOST
*****************************************************/
// Storing everything in array _params[]. Using enum ParamID as array indices so it's easier to add/remove parameters. 
enum ParamID
{
	_DEBUG,						// (Private) 1 to enable debug mode. Default 0.
	BAR_STAT_DURATION, 			// Length of moving dots, stationary bar
	ITI_DURATION,				// ITI length, fixed
	REWARD_DURATION,			// Reward duration (ms)
	WINDOW_DURATION,			// Time from Alpha to Turning Point (or from Turning Point to Omega)
	TRAINING_PHASE,				// For proactive, switches possible locations of cue (cardinal to anywhere)	
	OMEGA_TO_ITI_DURATION,		// Time from Omega to ITI (ms)
	ALLOW_EARLY_LICK,			// 0 to abort trial if animal licks after in pre-window
	ALLOW_LICK_BAR_STAT,		// Allow early lick when stim first comes on
	PAVLOVIAN,					// Pavlovian = 1, Operant = 0
	REACTIVE,					// Proactive = 0, Reactive = 1
	TIMING,						// Elapsed time informative = 1, Not = 0
	SPATIAL_FREQUENCY,			// Distance (degrees) between bar locations
	BAR_SPEED,					// In hops/seconds
	DOTS,						// 1 to show moving dots
	MU,							// Mean trial length 
	SIGMA,						// Standard deviation for trial length
 	_NUM_PARAMS					// (Private) Used to count how many parameters there are so we can initialize the param array with the correct size. Insert additional parameters before this.
};

// Store parameter names as strings, will be sent to host
// Names cannot contain spaces!!!
static const char *_paramNames[] = 
{
	"_DEBUG",					// (Private) 1 to enable debug mode. Default 0.
	"BAR_STAT_DURATION", 		// Length of moving dots, stationary bar
	"ITI_DURATION",				// ITI length, fixed
	"REWARD_DURATION",			// Reward duration (ms)
	"WINDOW_DURATION",			// Time from Alpha to Turning Point (or from Turning Point to Omega)
	"OMEGA_TO_ITI_DURATION",	// Time from Omega to ITI (ms)
	"TRAINING_PHASE",			// For proactive, switches possible locations of cue (cardinal to anywhere)			
	"ALLOW_EARLY_LICK",			// 0 to abort trial if animal licks after in pre-window
	"ALLOW_LICK_BAR_STAT",		// Allow early lick when stim first comes on
	"PAVLOVIAN",				// Pavlovian = 1, Operant = 0
	"REACTIVE",					// Is this a reactive or proactive paradigm?
	"TIMING",					// Elapsed time informative = 1, Not = 0
	"SPATIAL_FREQUENCY",		// Distance (degrees) between bar locations; degrees/hop
	"BAR_SPEED",				// In hops/seconds
	"DOTS",						// 1 to show moving dots
	"MU",						// Mean trial length 
	"SIGMA"						// Standard deviation for trial length
};

// Initialize parameters
long _params[_NUM_PARAMS] = 
{
	0,		// _DEBUG
	1000,	// BAR_STAT_DURATION
	8000,	// ITI_DURATION
	100,	// REWARD_DURATION
	1000,	// WINDOW_DURATION
	3000,	// OMEGA_TO_ITI_DURATION
	0,		// TRAINING_PHASE
	0,		// ALLOW_EARLY_LICK
	1,		// ALLOW_LICK_BAR_STAT
	0,		// PAVLOVIAN
	0, 		// REACTIVE
	0,		// TIMING
	4,		// SPATIAL_FREQUENCY
	4,		// BAR_SPEED
	1,		// DOTS
	3,		// MU
	1		// SIGMA
};

/*****************************************************
	Other Global Variables 
*****************************************************/
// Variables declared here can be carried to the next loop, AND read/written in function scope as well as main scope
// (previously defined):
static long _timeReset				= 0;			// Reset to signedMillis() at every soft reset
static long _timeTrialStart			= 0;			// Reset to 0 at start of trial
static long _timeStimOn				= 0;			// Reset to 0 at cue on
static long _timeAlpha				= 0;			//	
static long _timeTurningPoint		= 0;
static long _timeOmega				= 0;			//	
static int _resultCode				= -1;			// Result code. -1 if there is no result.
static State _state					= _STATE_INIT;	// This variable (current _state) get passed into a _state function, which determines what the next _state should be, and updates it to the next _state.
static State _prevState				= _STATE_INIT;	// Remembers the previous _state from the last loop (actions should only be executed when you enter a _state for the first time, comparing currentState vs _prevState helps us keep track of that).
static char _command				= ' ';			// Command char received from host, resets on each loop
static int _arguments[2]			= {0};			// Two integers received from host , resets on each loop

static bool _isLicking 				= false;		// True if the little dude is licking
static bool _isLickOnset 			= false;		// True during lick onset
static bool _firstLickRegistered 	= false;		// True when first lick is registered for this trial
static long _timeLastLick			= 0;			// Time (ms) when last lick occured

/*****************************************************
	Setup
*****************************************************/
void setup()
{
	// Init pins
	pinMode(PIN_IR_LAMP, OUTPUT);	// IR LED for camera recording
	pinMode(PIN_REWARD, OUTPUT);	// Reward, set to HIGH to open juice valve
	pinMode(PIN_LICK_LED, OUTPUT);	// Lick LED, set to HIGH when lick detected
	pinMode(PIN_LICK, INPUT);		// Lick detector

	// Serial comms
	Serial.begin(115200);			// Set up USB communication at 115200 baud 
}

void mySetup()
{
	// Reset output
	setIRLamp(true);                          	 // IR Lamp ON

	// Reset variables
	_timeReset				= 0;			// Reset to signedMillis() at every soft reset
	_timeTrialStart			= 0;			// Reset to 0 at start of trial
	_timeStimOn				= 0;
	_timeAlpha				= 0;
	_timeTurningPoint		= 0;
	_timeOmega				= 0;
	_resultCode				= -1;			// Result code. -1 if there is no result.
	_state					= _STATE_INIT;	// This variable (current _state) get passed into a _state function, which determines what the next _state should be, and updates it to the next _state.
	_prevState				= _STATE_INIT;	// Remembers the previous _state from the last loop (actions should only be executed when you enter a _state for the first time, comparing currentState vs _prevState helps us keep track of that).
	_command				= ' ';			// Command char received from host, resets on each loop
	_arguments[2]			= {0};			// Two integers received from host , resets on each loop

	_isLicking 				= false;		// True if the little dude is licking
	_isLickOnset 			= false;		// True during lick onset
	_firstLickRegistered 	= false;		// True when first lick is registered for this trial
	_timeLastLick			= 0;			// Time (ms) when last lick occured

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

		// 2) Check for licks and lever pressed
		handleLick();
		// 2.1) If lick pin is HIGH, set lick LED HIGH
		handleLickLED();
		// 2.2) Check for alpha, turning point and omega from matlab and send back event markers because we dumb
		handleVisualStim();

		// 3) Update state machine
		// Depending on what state we're in, call the appropriate state function, which will evaluate the transition conditions, and update the `_state` var to what the next state should be
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
			
			case STATE_START:
				state_start();
				break;
			
			case STATE_BAR_STAT:
				state_bar_stat();
				break;
			
			case STATE_BAR_MOVE:
				state_bar_move();
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

			case STATE_ABORT_EARLY:
				state_abort_early();
				break;

			case STATE_ABORT_BAR_STAT:
				state_abort_bar_stat();
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
		setIRLamp(true);
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
	// GO signal from host --> STATE_START
	if (_command == 'G') 
	{
		_state = STATE_START;
		return;
	}
	
	_state = STATE_IDLE;
}

/*****************************************************
	START - First state in trial
*****************************************************/
void state_start() 
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

		// Register trial start time
		_timeTrialStart = signedMillis();

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

	// Early lick detected --> ABORT
	if (_isLickOnset && _params[ALLOW_EARLY_LICK] == 0)
	{
		// Register result
		_resultCode = CODE_EARLY_LICK;
		_state = STATE_ABORT;
		return;
	}

	// Go immediately --> BAR_STAT
	if (getTimeSinceTrialStart() >= 0)
	{
		_state = STATE_BAR_STAT;
		return;
	}

	_state = STATE_START;
}

/*****************************************************
	BAR_STAT - Moving dots, stationary bar
*****************************************************/
void state_bar_stat() 
{
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);

		sendEventMarker(EVENT_STIM_ON, -1);
		
		// Register cue on time
		_timeStimOn = signedMillis();
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
		// Allow early lick during bar stat
		if (_params[ALLOW_LICK_BAR_STAT] == 0)
		{
			// Register result
			_resultCode = CODE_EARLY_LICK;
			_state = STATE_ABORT_BAR_STAT;
			return;	
		}
	}

	// bar_stat elapsed --> BAR_MOVE
	if (getTimeSinceStimOn() >= _params[BAR_STAT_DURATION])
	{
		_state = STATE_BAR_MOVE;
		return;
	}

	_state = STATE_BAR_STAT;
}

/*****************************************************
	BAR_MOVE - Moving dots, moving bar
*****************************************************/
void state_bar_move() 
{
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);

		sendEventMarker(EVENT_BAR_MOVE, -1);
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
		// Using lick & early lick not allowed --> ABORT
		if (_params[ALLOW_EARLY_LICK] == 0)
		{
			// Register result
			_resultCode = CODE_EARLY_LICK;
			_state = STATE_ABORT_EARLY;
			return;
		}
	}

	// bar_move elapsed --> RESPONSE_WINDOW
	if (_params[REACTIVE] == 1)
	{
		if (_command == 'T')
		{
			_state = STATE_RESPONSE_WINDOW;
			return;
		}
	}
	else
	{
		if (_command == 'A') // A for AlphaReached
		{
			_state = STATE_RESPONSE_WINDOW;
			return;
		} 
	} 

	_state = STATE_BAR_MOVE;
}
/*****************************************************
	RESPONSE_WINDOW - Licking triggers reward
*****************************************************/
void state_response_window() 
{
	// Declare local variable
	static long rand_delay = 0;

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

	if (_isLickOnset)
	{
		// First lick registration
		if (!_firstLickRegistered)
		{
			_firstLickRegistered = true;
			sendEventMarker(EVENT_FIRST_LICK, -1);
		}
		_resultCode = CODE_CORRECT;
		_state = STATE_REWARD;
		return;
	}
	// Pavlovian
	else if (_params[PAVLOVIAN] == 1)
	{
		if (_params[REACTIVE] == 1)
		{
			rand_delay = 0;
			if (getTimeSinceStimOn() - _timeTurningPoint >= rand_delay)
			{
				_resultCode = CODE_PAV;
				_state = STATE_REWARD;
				return;
			}
		}
		else if (_params[REACTIVE] == 0)
			// deliver reward some time in this window from alpha to turning pt
		{
			rand_delay = random(0, 750);
			if (getTimeSinceStimOn() - _timeAlpha >= rand_delay)
			{
				_resultCode = CODE_PAV;
				_state = STATE_REWARD;
				return;
			}
		}
	}
	// Response window elapsed --> ITI
	else
	{
		if (_params[REACTIVE] == 0)
		{
			if (_command == 'T')
			{
				_resultCode = CODE_NO_LICK;
				_state = STATE_ABORT;
				return;
			}
		}
		else
		{
			if (_command == 'W')
			{
				_resultCode = CODE_NO_LICK;
				_state = STATE_ABORT;
				return;
			}
		}
	}

	_state = STATE_RESPONSE_WINDOW;
}

/*****************************************************
	REWARD - Turn on juice valve for some time
*****************************************************/
void state_reward()
{
	static long timeRewardOn;
	static bool isRewardOn;
	static bool isRewardComplete;
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);

		// Reset variables
		timeRewardOn = 0;
		isRewardOn = false;
		isRewardComplete = false;
	}

	/*****************************************************
		OnEachLoop checks
	*****************************************************/
	// Lick detected
	if (_isLickOnset)
	{
		// First lick registration
		if (!_firstLickRegistered)
		{
			_firstLickRegistered = true;
			sendEventMarker(EVENT_FIRST_LICK, -1);
			return;
		}
	}

	// Immediate reward
	if (!isRewardOn && !isRewardComplete)
	{
		timeRewardOn = getTimeSinceStimOn();
		isRewardOn = true;
		if (_params[REWARD_DURATION] > 0)
		{
			setReward(true);
		}			
	}

	// Turn off reward when the time comes
	if (isRewardOn && !isRewardComplete && getTimeSinceStimOn() - timeRewardOn >= _params[REWARD_DURATION])
	{
		isRewardOn = false;
		isRewardComplete = true;
		if (_params[REWARD_DURATION] > 0)
		{
			setReward(false);
		}
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
	if (isRewardComplete && _command == 'E')
	{
		_state = STATE_INTERTRIAL;
		return;
	}

	_state = STATE_REWARD;
}

/*****************************************************
	ABORT - Early lick during bar_stat
*****************************************************/
void state_abort_bar_stat()
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
		sendEventMarker(EVENT_ABORT_EARLY, -1);
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

	if (_command == 'W')
	{
		_state = STATE_ABORT;
		return;
	}

	_state = STATE_ABORT_BAR_STAT;
}

/*****************************************************
	ABORT - Early lick timeout
*****************************************************/
void state_abort_early()
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
		sendEventMarker(EVENT_ABORT_EARLY, -1);
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

	if (_command == 'W')
	{
		_state = STATE_ABORT;
		return;
	}

	_state = STATE_ABORT_EARLY;
}

/*****************************************************
	ABORT - No lick timeout
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

		// Register events
		sendEventMarker(EVENT_ABORT, -1);
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
	if (_command == 'E')
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

		// Register time of state entry
		timeIntertrial = getTimeSinceStimOn();

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
	if (_command == 'O') 
	{
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

	// If ITI elapsed --> START
	if (isParamsUpdateDone || !isParamsUpdateStarted)
	{
		if (getTimeSinceStimOn() - timeIntertrial >= _params[ITI_DURATION])
		{
			_state = STATE_START;
			return;
		}
	}

	_state = STATE_INTERTRIAL;
}

/*****************************************************
	HARDWARE CONTROLS
*****************************************************/
// Toggle IR Lamp
void setIRLamp(bool turnOn) 
{
	if (turnOn) 
	{
		digitalWrite(PIN_IR_LAMP, HIGH);
	}
	else 
	{
		digitalWrite(PIN_IR_LAMP, LOW);
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
		_timeLastLick = getTime();
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

void handleLickLED()
{
	if (digitalRead(PIN_LICK) == HIGH)
	{
		digitalWrite(PIN_LICK_LED, HIGH);
	}
	else
	{
		digitalWrite(PIN_LICK_LED, LOW);
	}
}

void handleVisualStim()
{
	// Send markers for window events
	if (_command == 'A') // A for AlphaReached
	{
		sendEventMarker(EVENT_ALPHA, -1);
		_timeAlpha = getTimeSinceStimOn();
	} 

	if (_command == 'T') // TurningPointReached
	{
		sendEventMarker(EVENT_TURNING_POINT, -1);
		_timeTurningPoint = getTimeSinceStimOn();
	}

	if (_command == 'W') // OmegaReached
	{
		sendEventMarker(EVENT_OMEGA, -1);
		_timeOmega = getTimeSinceStimOn();
	}
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
long getTimeSinceStimOn()
{
	long time = signedMillis() - _timeStimOn;
	return time;
}

// Returns time since last lick in milliseconds
long getTimeSinceLastLick()
{
	long time = signedMillis() - _timeLastLick;
	return time;
}
