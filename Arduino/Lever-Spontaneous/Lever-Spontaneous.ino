/*********************************************************************
	Arduino state machine
	Spontaneous lever-touch task
*********************************************************************/

/*****************************************************
	Servo stuff
*****************************************************/
#include <Servo.h>
Servo _servoLever;
Servo _servoTube;
#define SERVO_READ_ACCURACY 1
enum ServoState
{
	_SERVOSTATE_INIT,
	SERVOSTATE_RETRACTED,
	SERVOSTATE_DEPLOYING,
	SERVOSTATE_RETRACTING,
	SERVOSTATE_DEPLOYED
};

/*****************************************************
	Arduino Pin Outs
*****************************************************/
// Digital OUT
#define PIN_REWARD				24
#define PIN_SERVO_LEVER			14
#define PIN_SERVO_TUBE			15

// Mirrors to blackrock
#define PIN_MIRROR_LICK 		9
#define PIN_MIRROR_LEVER 		10
#define PIN_MIRROR_REWARD		22

// PWM OUT
#define PIN_SPEAKER				21

// Digital IN
#define PIN_LICK				25
#define PIN_LEVER				26

static const int _digOutPins[] = 
{
	PIN_REWARD,
	PIN_MIRROR_LICK,
	PIN_MIRROR_LEVER,
	PIN_MIRROR_REWARD,
	PIN_SERVO_LEVER,
	PIN_SERVO_TUBE,
	PIN_SPEAKER
};

/*****************************************************
	Enums - DEFINE States
*****************************************************/
// All the states
enum State
{
	_STATE_INIT,
	STATE_IDLE,
	STATE_WAITFORTOUCH,
	STATE_REWARD,
	STATE_INTERTRIAL,
	_NUM_STATES
};

// State names stored as strings, will be sent to host
// Names cannot contain spaces!!!
static const char *_stateNames[] = 
{
	"_INIT",
	"IDLE",
	"WAITFORTOUCH",
	"REWARD",
	"INTERTRIAL"
};

// Define which states accept parameter update from MATLAB
static const int _stateCanUpdateParams[] = {0,1,1,1,1}; 

/*****************************************************
	Event Markers
*****************************************************/
enum EventMarker
{
	EVENT_TRIAL_START,				// New trial initiated
	EVENT_LICK,						// Lick onset
	EVENT_LICK_OFF,					// Lick offset
	EVENT_LEVER_PRESSED,			// Lever touch onset
	EVENT_LEVER_RELEASED,			// Lever touch offset
	EVENT_REWARD_ON,				// Reward, juice valve on
	EVENT_REWARD_OFF,				// Reward, juice valve off
	EVENT_ITI,						// At start of ITI
	EVENT_LEVER_RETRACT_START,		// Lever retract start
	EVENT_LEVER_RETRACT_END,		// Lever retracted
	EVENT_LEVER_DEPLOY_START,		// Lever deploy start
	EVENT_LEVER_DEPLOY_END,			// Lever deploy end
	EVENT_TUBE_RETRACT_START,		// Tube retract start
	EVENT_TUBE_RETRACT_END,			// Tube retract end
	EVENT_TUBE_DEPLOY_START,		// Tube deploy start
	EVENT_TUBE_DEPLOY_END,			// Tube deploy end
	_NUM_EVENT_MARKERS
};

static const char *_eventMarkerNames[] =
{
	"TRIAL_START",				// New trial initiated
	"LICK",						// Lick onset
	"LICK_OFF",					// Lick offset
	"LEVER_PRESSED",			// Lever touch onset
	"LEVER_RELEASED",			// Lever touch offset
	"REWARD_ON",				// Reward, juice valve on
	"REWARD_OFF",				// Reward, juice valve off
	"ITI",						// At start of ITI
	"LEVER_RETRACT_START",			// Lever retract start
	"LEVER_RETRACT_END",			// Lever retracted
	"LEVER_DEPLOY_START",			// Lever deploy start
	"LEVER_DEPLOY_END",				// Lever deploy end
	"TUBE_RETRACT_START",			// Tube retract start
	"TUBE_RETRACT_END",				// Tube retract end
	"TUBE_DEPLOY_START",			// Tube deploy start
	"TUBE_DEPLOY_END"				// Tube deploy end
};

/*****************************************************
	Result codes
*****************************************************/
enum ResultCode
{
	CODE_CORRECT,			// Correct (there are no wrong answers here litte buddy, way to go!)
	_NUM_RESULT_CODES
};

// We'll send result code translations to MATLAB at startup
static const char *_resultCodeNames[] =
{
	"CORRECT"
};


/*****************************************************
	Audio cue frequencies in Hz
*****************************************************/
// Use integers. 1kHz - 100kHz for mice
enum SoundEventFrequencyEnum
{
	TONE_REWARD     = 6272
};

/*****************************************************
	Parameters that can be updated by HOST
*****************************************************/
// Storing everything in array _params[]. Using enum ParamID as array indices so it's easier to add/remove parameters. 
enum ParamID
{
	_DEBUG,							// (Private) 1 to enable debug mode. Default 0.
	ITI_MIN,						// ITI length min cutoff (ms)
	ITI_MEAN,						// ITI length (mean of exponential distribution) (ms)
	ITI_MAX,						// ITI length max cutoff (ms)
	ITI_LICK_TIMEOUT,				// ITI cannot end unless last lick was this many ms before (ms)
	ITI_PRESS_TIMEOUT,				// ITI cannot end unless last lever has been released for this many ms (ms)
	REWARD_DURATION,				// Reward duration (ms), also determines tone duration
	MIN_REWARD_COLLECTION_TIME,		// Min time juice tube is deployed (remember to make it longer than tube deploy time)
	LEVER_POS_RETRACTED,			// Servo (lever) position when lever is retracted
	LEVER_POS_DEPLOYED,				// Servo (lever) position when lever is deployed
	LEVER_SPEED_DEPLOY,				// Servo (lever) rotation speed when deploying, 0 for max speed
	LEVER_SPEED_RETRACT,			// Servo (lever) rotaiton speed when retracting, 0 for max speed
	TUBE_POS_RETRACTED,				// Servo (juice tube) position when juice tube is retracted (full is ~ 50)
	TUBE_POS_DEPLOYED,				// Servo (juice tube) position when juice tube is deployed (full is ~ 125)
	TUBE_SPEED_DEPLOY,				// Servo (juice tube) advance speed when deploying, 0 for max speed
	TUBE_SPEED_RETRACT,				// Servo (juice tube) retract speed when retracting, 0 for max speed	
	_NUM_PARAMS						// (Private) Used to count how many parameters there are so we can initialize the param array with the correct size. Insert additional parameters before this.
};

// Store parameter names as strings, will be sent to host
// Names cannot contain spaces!!!
static const char *_paramNames[] = 
{
	"_DEBUG",
	"ITI_MIN",
	"ITI_MEAN",
	"ITI_MAX",
	"ITI_LICK_TIMEOUT",
	"ITI_PRESS_TIMEOUT",
	"REWARD_DURATION",
	"MIN_REWARD_COLLECTION_TIME",
	"LEVER_POS_RETRACTED",
	"LEVER_POS_DEPLOYED",
	"LEVER_SPEED_DEPLOY",
	"LEVER_SPEED_RETRACT",
	"TUBE_POS_RETRACTED",
	"TUBE_POS_DEPLOYED",
	"TUBE_SPEED_DEPLOY",
	"TUBE_SPEED_RETRACT",
};

// Initialize parameters
long _params[_NUM_PARAMS] = 
{
	0, // _DEBUG
	1000, // ITI_MIN
	5000, // ITI_MEAN
	10000, // ITI_MAX
	4000, // ITI_LICK_TIMEOUT
	4000, // ITI_PRESS_TIMEOUT
	100, // REWARD_DURATION
	6000, // MIN_REWARD_COLLECTION_TIME
	64, // LEVER_POS_RETRACTED
	64, // LEVER_POS_DEPLOYED
	36, // LEVER_SPEED_DEPLOY
	36, // LEVER_SPEED_RETRACT
	60, // TUBE_POS_RETRACTED
	90, // TUBE_POS_DEPLOYED
	36, // TUBE_SPEED_DEPLOY
	36 // TUBE_SPEED_RETRACT
};

/*****************************************************
	Other Global Variables 
*****************************************************/
// Variables declared here can be carried to the next loop, AND read/written in function scope as well as main scope
// (previously defined):
static long _timeReset				= 0;			// Reset to signedMillis() at every soft reset
static long _timeTrialStart			= 0;			// Reset to 0 at start of trial
static long _timeTrialEnd			= 0;			// Reset to 0 at ITI entry
static int _resultCode				= -1;			// Result code. -1 if there is no result.
static State _state					= _STATE_INIT;	// This variable (current _state) get passed into a _state function, which determines what the next _state should be, and updates it to the next _state.
static State _prevState				= _STATE_INIT;	// Remembers the previous _state from the last loop (actions should only be executed when you enter a _state for the first time, comparing currentState vs _prevState helps us keep track of that).
static char _command				= ' ';			// Command char received from host, resets on each loop
static int _arguments[2]			= {0};			// Two integers received from host , resets on each loop
static bool _isUpdatingParams 		= false;

static bool _isLicking 				= false;		// True if the little dude is licking
static bool _isLickOnset 			= false;		// True during lick onset
static long _timeLastLick			= 0;			// Time (ms) when last lick occured

static bool _isLeverPressed			= false;		// True as long as lever is pressed down
static bool _isLeverPressOnset 		= false;		// True when lever first pressed
static long _timeLastLeverPress		= 0;			// Time (ms) when last lever press occured
static long _timeLastLeverRelease	= 0;			// Time (ms) when last lever press occured

static ServoState _servoStateTube	= _SERVOSTATE_INIT;				// Servo state
static long _servoStartTimeLever	= 0;							// When servo started moving retrieved using getTime()
static long _servoSpeedLever		= _params[LEVER_SPEED_RETRACT]; // Speed of servo movement (deg/s)
static long _servoStartPosLever		= _params[LEVER_POS_RETRACTED];	// Starting position of servo when rotation begins
static long _servoTargetPosLever	= _params[LEVER_POS_RETRACTED];	// Target position of servo

static ServoState _servoStateLever 	= _SERVOSTATE_INIT;				// Servo state
static long _servoStartTimeTube		= 0;							// When servo started moving retrieved using getTime()
static long _servoSpeedTube			= _params[TUBE_SPEED_RETRACT]; 	// Speed of servo movement (deg/s)
static long _servoStartPosTube		= _params[TUBE_POS_DEPLOYED];	// Starting position of servo when rotation begins
static long _servoTargetPosTube		= _params[TUBE_POS_DEPLOYED];	// Target position of servo
/*****************************************************
	Setup
*****************************************************/
void setup()
{
	// Init output pins
	for(unsigned int i = 0; i < sizeof(_digOutPins)/sizeof(_digOutPins[0]); i++)
	{
		pinMode(_digOutPins[i], OUTPUT);
		digitalWrite(_digOutPins[i], LOW);
	}

	// Init input pins
	pinMode(PIN_LICK, INPUT);					// Lick detector (input)
	pinMode(PIN_LEVER, INPUT);					// Lever press detector (input)

	// Initiate servo
	_servoLever.attach(PIN_SERVO_LEVER);
	_servoTube.attach(PIN_SERVO_TUBE);

	// Serial comms
	Serial.begin(115200);                       // Set up USB communication at 115200 baud 
}

void mySetup()
{
	// Reset variables
	_timeReset				= 0;			// Reset to signedMillis() at every soft reset
	_timeTrialStart			= 0;			// Reset to 0 at start of trial
	_timeTrialEnd			= 0;			// Reset to 0 at ITI entry
	_resultCode				= -1;			// Result code. -1 if there is no result.
	_state					= _STATE_INIT;	// This variable (current _state) get passed into a _state function, which determines what the next _state should be, and updates it to the next _state.
	_prevState				= _STATE_INIT;	// Remembers the previous _state from the last loop (actions should only be executed when you enter a _state for the first time, comparing currentState vs _prevState helps us keep track of that).
	_command				= ' ';			// Command char received from host, resets on each loop
	_arguments[2]			= {0};			// Two integers received from host , resets on each loop
	_isUpdatingParams 		= false;

	_isLicking 				= false;		// True if the little dude is licking
	_isLickOnset 			= false;		// True during lick onset
	_timeLastLick			= 0;			// Time (ms) when last lick occured
	_isLeverPressed			= false;		// True as long as lever is pressed down
	_isLeverPressOnset 		= false;		// True when lever first pressed
	_timeLastLeverPress		= 0;			// Time (ms) when last lever press occured
	_timeLastLeverRelease	= 0;			// Time (ms) when last lever press occured

	_servoStateTube			= _SERVOSTATE_INIT;				// Servo state
	_servoStartTimeLever	= 0;							// When servo started moving retrieved using getTime()
	_servoSpeedLever		= _params[LEVER_SPEED_RETRACT]; // Speed of servo movement (deg/s)
	_servoStartPosLever		= _params[LEVER_POS_RETRACTED];	// Starting position of servo when rotation begins
	_servoTargetPosLever	= _params[LEVER_POS_RETRACTED];	// Target position of servo

	_servoStateLever 		= _SERVOSTATE_INIT;				// Servo state
	_servoStartTimeTube		= 0;							// When servo started moving retrieved using getTime()
	_servoSpeedTube			= _params[TUBE_SPEED_RETRACT]; 	// Speed of servo movement (deg/s)
	_servoStartPosTube		= _params[TUBE_POS_DEPLOYED];	// Starting position of servo when rotation begins
	_servoTargetPosTube		= _params[TUBE_POS_DEPLOYED];	// Target position of servo

	// Sends all parameters, states and error codes to Matlab, then tell PC that we're running by sending '~' message:
	hostInit();

	randomSeed(analogRead(0));
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

		// 2) Other onEachLoop routines
		handleLick();			// Check for licks on/offset
		handleLever();			// Check for lever press on/offset
		handleServoTube();		// Tube servo control
		handleServoLever();		// Lever servo control
		handleParamUpdate();	// Writes to _isUpdatingParams

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

			case STATE_WAITFORTOUCH:
				state_waitfortouch();
				break;
			
			case STATE_REWARD:
				state_reward();
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
		noTone(PIN_SPEAKER);
		setReward(false);
		deployLever(true);
		deployTube(true);
		_resultCode = -1;
		_isUpdatingParams = false;
	}

	/*****************************************************
		OnEachLoop checks
	*****************************************************/

	/*****************************************************
		TRANSITION LIST
	*****************************************************/
	// GO signal from host --> INTERTRIAL
	if (_command == 'G' && !_isUpdatingParams) 
	{
		_state = STATE_INTERTRIAL;
		return;
	}

	_state = STATE_IDLE;
}

/*****************************************************
	INTERTRIAL
*****************************************************/
void state_intertrial()
{
	static long itiDuration;
	static bool isTubeRetracted;
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

		// Retract lick tube immediately if first trial
		isTubeRetracted = false;
		if (_resultCode == -1)
		{
			isTubeRetracted = true;
			deployTube(false);
		}

		// Generate random interval length from exponential distribution
		// CDF  p=F(x|μ)=1-exp(-x/μ);
		// Inverse CDF is x=F^(−1)(p∣μ)=−μln(1−p).
		// For each draw, we let p = uniform_rand(0, 1), get corresponding value x from inverse CDF.
		itiDuration = -1*_params[ITI_MEAN]*log(1.0 - ((float)random(1UL << 31)) / (1UL << 31));
		// Apply min/max cutoffs
		itiDuration = max(itiDuration, _params[ITI_MIN]);
		itiDuration = min(itiDuration, _params[ITI_MAX]);
	}

	/*****************************************************
		OnEachLoop checks
	*****************************************************/
	// If rewarded, retract lick tube before random delay starts
	if (!isTubeRetracted)
	{
		if (getTimeSinceTrialEnd() >= _params[MIN_REWARD_COLLECTION_TIME] && getTimeSinceLastLick() >= _params[ITI_LICK_TIMEOUT])
		{
			isTubeRetracted = true;
			deployTube(false);
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


	// If ITI elapsed && lick spout retracted && no licks for a bit && lever released for a few seconds
	if (!_isUpdatingParams && _servoStateTube == SERVOSTATE_RETRACTED)
	{
		// sendMessage(String(getTimeSinceTrialEnd()) + " >= " + String(itiDuration));
		// sendMessage("_isLeverPressed = " + String(_isLeverPressed));
		// sendMessage("timeSinceLastLick = " + String(getTimeSinceLastLick()) + " vs " + String(_params[ITI_LICK_TIMEOUT]));
		// sendMessage("timeSinceLastLeverRelease = " + String(getTimeSinceLastLeverRelease()) + " vs " + String(_params[ITI_PRESS_TIMEOUT]));
		// sendMessage("STOP");
		if (getTimeSinceTrialEnd() >= itiDuration && !_isLeverPressed && getTimeSinceLastLick() >= _params[ITI_LICK_TIMEOUT] && getTimeSinceLastLeverRelease() >= _params[ITI_PRESS_TIMEOUT])		
		{
			_state = STATE_WAITFORTOUCH;
			return;
		}
	}

	_state = STATE_INTERTRIAL;
}

/*****************************************************
	RESPONSE_WINDOW - Touch triggers reward
*****************************************************/
void state_waitfortouch() 
{
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);

		_timeTrialStart = getTime();

		// Register events
		sendEventMarker(EVENT_TRIAL_START, -1);
	}

	/*****************************************************
		OnEachLoop checks
	*****************************************************/

	/*****************************************************
		TRANSITION LIST
	*****************************************************/
	// Quit signal from host --> IDLE
	if (_command == 'Q') 
	{
		_state = STATE_IDLE;
		return;
	}

	// Touch --> REWARD
	if (_isLeverPressOnset && !_isUpdatingParams)
	{
		_timeTrialEnd = getTime();
		_state = STATE_REWARD;
		return;
	}

	_state = STATE_WAITFORTOUCH;
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

		// Send results
		_resultCode = CODE_CORRECT;
		sendResultCode(_resultCode);
		// Reset variables
		timeRewardOn = 0;
		isRewardOn = false;
		isRewardComplete = false;

		noTone(PIN_SPEAKER);
		tone(PIN_SPEAKER, TONE_REWARD, _params[REWARD_DURATION]);
	}

	/*****************************************************
		OnEachLoop checks
	*****************************************************/
	// Deploy spout and dispense reward
	if (!isRewardOn && !isRewardComplete)
	{
		timeRewardOn = getTime();
		isRewardOn = true;
		if (_params[REWARD_DURATION] > 0)
		{
			deployTube(true);
			setReward(true);
		}			
	}

	// Turn off reward when the time comes
	if (isRewardOn && !isRewardComplete && getTime() - timeRewardOn >= _params[REWARD_DURATION])
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
	if (isRewardComplete && !_isUpdatingParams)
	{
		_state = STATE_INTERTRIAL;
		return;
	}

	_state = STATE_REWARD;
}

/*****************************************************
	HARDWARE CONTROLS
*****************************************************/
// Lick detection
bool getLickState() 
{
	if (digitalRead(PIN_LICK) == HIGH) 
	{
		digitalWrite(PIN_MIRROR_LICK, HIGH);
		return true;
	}
	else 
	{
		digitalWrite(PIN_MIRROR_LICK, LOW);
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

// Lever detection
bool getLeverState() 
{
	if (digitalRead(PIN_LEVER) == HIGH) 
	{
		digitalWrite(PIN_MIRROR_LEVER, HIGH);
		return true;
	}
	else 
	{
		digitalWrite(PIN_MIRROR_LEVER, LOW);
		return false;
	}
}

void handleLever() 
{
	if (getLeverState() && !_isLeverPressed)
	{
		_isLeverPressed = true;
		_isLeverPressOnset = true;
		sendEventMarker(EVENT_LEVER_PRESSED, -1);
		_timeLastLeverPress = getTime();
	}
	else
	{
		if (!getLeverState() && _isLeverPressed)
		{
			_isLeverPressed = false;
			sendEventMarker(EVENT_LEVER_RELEASED, -1);
			_timeLastLeverRelease = getTime();
		}
		_isLeverPressOnset = false;
	}
}

// Use servo to retract/present lever to the little dude
void deployLever(bool deploy)
{
	if (deploy) 
	{
		if (_servoStateLever != SERVOSTATE_DEPLOYED)
		{
			_servoStateLever = SERVOSTATE_DEPLOYING;
			sendEventMarker(EVENT_LEVER_DEPLOY_START, -1);
		}
		_servoStartTimeLever = getTime();
		_servoSpeedLever = _params[LEVER_SPEED_DEPLOY];
		_servoStartPosLever = _servoLever.read();
		_servoTargetPosLever = _params[LEVER_POS_DEPLOYED];
	}
	else 
	{
		if (_servoStateLever != SERVOSTATE_RETRACTED)
		{
			_servoStateLever = SERVOSTATE_RETRACTING;
			sendEventMarker(EVENT_LEVER_RETRACT_START, -1);
		}
		_servoStartTimeLever = getTime();
		_servoSpeedLever = _params[LEVER_SPEED_RETRACT];
		_servoStartPosLever = _servoLever.read();
		_servoTargetPosLever = _params[LEVER_POS_RETRACTED];
	}
}

// Use servo to retract/present lever to the little dude
void deployTube(bool deploy)
{
	if (deploy)
	{
		if (_servoStateTube != SERVOSTATE_DEPLOYED)
		{
			_servoStateTube = SERVOSTATE_DEPLOYING;
			sendEventMarker(EVENT_TUBE_DEPLOY_START, -1);
		}
		_servoStartTimeTube = getTime();
		_servoSpeedTube = _params[TUBE_SPEED_DEPLOY];
		_servoStartPosTube = _servoTube.read();
		_servoTargetPosTube = _params[TUBE_POS_DEPLOYED];
	}
	else
	{
		if (_servoStateTube != SERVOSTATE_RETRACTED)
		{
			_servoStateTube = SERVOSTATE_RETRACTING;
			sendEventMarker(EVENT_TUBE_RETRACT_START, -1);
		}
		_servoStartTimeTube = getTime();
		_servoSpeedTube = _params[TUBE_SPEED_RETRACT];
		_servoStartPosTube = _servoTube.read();
		_servoTargetPosTube = _params[TUBE_POS_RETRACTED];
	}
}

void handleServoLever()
{
	static long servoNewPosLever;

	// Handle servo read requests
	if (_command == 'S')
	{
		sendMessage("Lever position = " + String(_servoLever.read()) + ", target = " + String(_servoTargetPosLever));
	}

	// Handle movement completion events
	if (_servoStateLever == SERVOSTATE_DEPLOYING && abs(_servoLever.read() - _params[LEVER_POS_DEPLOYED]) <= SERVO_READ_ACCURACY)
	{
		_servoStateLever = SERVOSTATE_DEPLOYED;
		sendEventMarker(EVENT_LEVER_DEPLOY_END, -1);
	}

	if (_servoStateLever == SERVOSTATE_RETRACTING && abs(_servoLever.read() - _params[LEVER_POS_RETRACTED]) <= SERVO_READ_ACCURACY)
	{
		_servoStateLever = SERVOSTATE_RETRACTED;
		sendEventMarker(EVENT_LEVER_RETRACT_END, -1);
	}

	// 0 - use max speed
	if (_servoSpeedLever == 0)
	{
		_servoLever.write(_servoTargetPosLever);
	}
	// Use specified speed
	else
	{
		if (_servoLever.read() < _servoTargetPosLever)
		{
			servoNewPosLever = round(_servoStartPosLever + _servoSpeedLever*(getTime() - _servoStartTimeLever)/1000);
			if (servoNewPosLever <= _servoTargetPosLever)
			{
				_servoLever.write(servoNewPosLever);
			}
		}
		else
		{
			if (_servoLever.read() > _servoTargetPosLever)
			{
				servoNewPosLever = round(_servoStartPosLever - _servoSpeedLever*(getTime() - _servoStartTimeLever)/1000);
				if (servoNewPosLever >= _servoTargetPosLever)
				{
					_servoLever.write(servoNewPosLever);
				}
			}
		}
	}
}

void handleServoTube()
{
	static long servoNewPosTube;

	// Handle servo read requests
	if (_command == 'S')
	{
		sendMessage("Tube position = " + String(_servoTube.read()) + ", target = " + String(_servoTargetPosTube));
	}

	// Handle movement completion events
	if (_servoStateTube == SERVOSTATE_DEPLOYING && abs(_servoTube.read() - _params[TUBE_POS_DEPLOYED]) <= SERVO_READ_ACCURACY)
	{
		_servoStateTube = SERVOSTATE_DEPLOYED;
		sendEventMarker(EVENT_TUBE_DEPLOY_END, -1);
	}

	if (_servoStateTube == SERVOSTATE_RETRACTING && abs(_servoTube.read() - _params[TUBE_POS_RETRACTED]) <= SERVO_READ_ACCURACY)
	{
		_servoStateTube = SERVOSTATE_RETRACTED;
		sendEventMarker(EVENT_TUBE_RETRACT_END, -1);
	}

	if (_servoSpeedTube == 0)
	{
		_servoTube.write(_servoTargetPosTube);
	}
	else
	{
		if (_servoTube.read() < _servoTargetPosTube)
		{
			servoNewPosTube = round(_servoStartPosTube + _servoSpeedTube*(getTime() - _servoStartTimeTube)/1000);
			if (servoNewPosTube <= _servoTargetPosTube)
			{
				_servoTube.write(servoNewPosTube);
			}
		}
		else
		{
			if (_servoTube.read() > _servoTargetPosTube)
			{
				servoNewPosTube = round(_servoStartPosTube - _servoSpeedTube*(getTime() - _servoStartTimeTube)/1000);
				if (servoNewPosTube >= _servoTargetPosTube)
				{
					_servoTube.write(servoNewPosTube);
				}
			}
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
		digitalWrite(PIN_MIRROR_REWARD, HIGH);
		if (!rewardOn)
		{
			rewardOn = true;
			sendEventMarker(EVENT_REWARD_ON, -1);
		}		
	}
	else
	{
		digitalWrite(PIN_REWARD, LOW);
		digitalWrite(PIN_MIRROR_REWARD, LOW);
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

void sendDebugMessage(String message)
{
	if (_params[_DEBUG] > 0)
	{
		Serial.println(message);
	}
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
	for (int iCode = 0; iCode < _NUM_EVENT_MARKERS; iCode++)
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

void handleParamUpdate()
{
	if (_stateCanUpdateParams[_state] > 0)
	{
		// Received new param from host: format "P _paramID _newValue" ('P' for Parameters)
		if (_command == 'P') 
		{
			_isUpdatingParams = true;
			_params[_arguments[0]] = _arguments[1];
		}

		// Parameter transmission complete:
		if (_command == 'O') 
		{
			_isUpdatingParams = false;
		}	
	}
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

// Returns time since trial start in milliseconds
long getTimeSinceTrialEnd()
{
	long time = signedMillis() - _timeTrialEnd;
	return time;
}

// Returns time since last lick in milliseconds
long getTimeSinceLastLick()
{
	long time = signedMillis() - _timeLastLick;
	return time;
}

// Returns time since last lever press in milliseconds
long getTimeSinceLastLeverPress()
{
	long time = signedMillis() - _timeLastLeverPress;
	return time;
}

// Returns time since last lever release in milliseconds
long getTimeSinceLastLeverRelease()
{
	long time = signedMillis() - _timeLastLeverRelease;
	return time;
}