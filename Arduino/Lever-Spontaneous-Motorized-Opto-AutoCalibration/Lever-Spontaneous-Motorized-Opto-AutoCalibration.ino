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
enum class ServoState
{
	Init,
	Retracted,
	Deploying,
	Retracting,
	Deployed
};


/*****************************************************
	Analog Output Stuff
*****************************************************/
#define ANALOG_WRITE_RESOLUTION 12 // 12bits: 0-4095

/*****************************************************
	Arduino Pin Outs
*****************************************************/
// Digital OUT
#define PIN_REWARD				24
#define PIN_SERVO_LEVER			14
#define PIN_SERVO_TUBE			15
#define PIN_OPTOGEN_STIM		23
#define PIN_MOTOR_CONTROLLER_1	5
#define PIN_MOTOR_CONTROLLER_2	6


// Mirrors to blackrock
#define PIN_MIRROR_LICK 		9
#define PIN_MIRROR_LEVER 		10
#define PIN_MIRROR_REWARD		22

// PWM OUT
#define PIN_SPEAKER				21

// ANALOG OUT (DAC)
#define PIN_LASER_PWR_1			A21
#define PIN_LASER_PWR_2			A22

// Digital IN
#define PIN_LICK				25
#define PIN_LEVER				26
#define PIN_MOTOR_BUSY			7

static const int _digOutPins[] = 
{
	PIN_REWARD,
	PIN_SERVO_LEVER,
	PIN_SERVO_TUBE,
	PIN_OPTOGEN_STIM,
	PIN_MOTOR_CONTROLLER_1,
	PIN_MOTOR_CONTROLLER_2,
	PIN_MIRROR_LICK,
	PIN_MIRROR_LEVER,
	PIN_MIRROR_REWARD,
	PIN_SPEAKER
};

/*****************************************************
	Enums - DEFINE States
*****************************************************/
// All the states
enum class State
{
	Init,
	Idle,
	WaitForTouch,
	Reward,
	Timeout,
	Opto,
	RequestOpto,
	Count
};

// State names stored as strings, will be sent to host
// Names cannot contain spaces!!!
static const char *_stateNames[] = 
{
	"Init",
	"Idle",
	"WaitForTouch",
	"Reward",
	"Timeout",
	"Opto",
	"RequestOpto",
};

// Define which states accept parameter update from MATLAB
static const int _stateCanUpdateParams[] = 
{
	0,	// Init
	1,	// Idle
	1,	// WaitForTouch
	1,	// Reward
	1,	// Timeout
	0,	// Opto
	1	// RequestOpto
}; 

/*****************************************************
	Event Markers
*****************************************************/
enum class EventMarker
{
	TrialStart,				// New trial initiated
	Lick,						// Lick onset
	LickOff,					// Lick offset
	LeverPressed,			// Lever touch onset
	LeverReleased,			// Lever touch offset
	LeverHeld,
	RewardOn,				// Reward, juice valve on
	RewardOff,				// Reward, juice valve off
	ITI,						// At start of ITI
	LeverRetractStart,		// Lever retract start
	LeverRetractEnd,		// Lever retracted
	LeverDeployStart,		// Lever deploy start
	LeverDeployEnd,			// Lever deploy end
	TubeRetractStart,		// Tube retract start
	TubeRetractEnd,			// Tube retract end
	TubeDeployStart,		// Tube deploy start
	TubeDeployEnd,			// Tube deploy end
	OptoStimOn,			// Begin optogenetic stim (single pulse start)
	OptoStimOff,			// End optogenetic stim (single pulse end)
	MotorLeverPos1_Start,
	MotorLeverPos2_Start,
	MotorLeverPos3_Start,
	MotorLeverPos4_Start,
	MotorLeverPos1_Reached,
	MotorLeverPos2_Reached,
	MotorLeverPos3_Reached,
	MotorLeverPos4_Reached,	
	MotorLaser_Start,
	MotorLaser_Reached,
	Count
};

static const char *_eventMarkerNames[] =
{
	"TrialStart",
	"Lick",
	"LickOff",
	"LeverPressed",
	"LeverReleased",
	"LeverHeld",
	"RewardOn",
	"RewardOff",
	"ITI",
	"LeverRetractStart",
	"LeverRetractEnd",
	"LeverDeployStart",
	"LeverDeployEnd",
	"TubeRetractStart",
	"TubeRetractEnd",
	"TubeDeployStart",
	"TubeDeployEnd",
	"OptoStimOn",
	"OptoStimOff",
	"MotorLeverPos1_Start",
	"MotorLeverPos2_Start",
	"MotorLeverPos3_Start",
	"MotorLeverPos4_Start",
	"MotorLeverPos1_Reached",
	"MotorLeverPos2_Reached",
	"MotorLeverPos3_Reached",
	"MotorLeverPos4_Reached",
	"MotorLaser_Start",
	"MotorLaser_Reached"
};

/*****************************************************
	Result codes
*****************************************************/
enum class ResultCode
{
	Correct_1,			// Correct (motor pos 1)
	Correct_2,			// Correct (motor pos 2)
	Correct_3,			// Correct (motor pos 3)
	Correct_4,			// Correct (motor pos 4)
	Early_1,		// Early Press (motor pos 1)
	Early_2,		// Early Press (motor pos 2)
	Early_3,		// Early Press (motor pos 3)
	Early_4,		// Early Press (motor pos 4)
	Count
};

// We'll send result code translations to MATLAB at startup
static const char *_resultCodeNames[] =
{
	"Correct_1",
	"Correct_2",
	"Correct_3",
	"Correct_4",
	"Early_1",
	"Early_2",
	"Early_3",
	"Early_4",
};


/*****************************************************
	Audio cue frequencies in Hz
*****************************************************/
// Use integers. 1kHz - 100kHz for mice
enum class ToneFrequency
{
	Reward = 6272
};

/*****************************************************
	Parameters that can be updated by HOST
*****************************************************/
// Storing everything in array _params[]. Using enum ParamID as array indices so it's easier to add/remove parameters. 
enum class ParamID
{
	Debug,						// (Private) 1 to enable debug mode. Default 0.
	MinITI,						// ITI length min cutoff (ms)
	MeanITI,					// ITI length (mean of exponential distribution) (ms)
	MaxITI,						// ITI length max cutoff (ms)
	LeverHoldTime,				// Lever contact must be maintained for this duration (ms) before reward dispensed..
	LeverRetractTime,			// Lever will be retracted for this duration before redeploying
	RewardDuration,				// Reward duration (ms), also determines tone duration
	MinRewardCollectionTime,	// Min time juice tube is deployed (remember to make it longer than tube deploy time)
	ExtraRewardCollectionTime,	// Lick tube does not retract until last lick was this many ms before (ms)
	LeverRetractedPos,			// Servo (lever) position when lever is retracted
	LeverDeployedPos,			// Servo (lever) position when lever is deployed
	LeverRetractSpeed,			// Servo (lever) rotaiton speed when retracting, 0 for max speed
	LeverDeploySpeed,			// Servo (lever) rotation speed when deploying, 0 for max speed
	TubeRetractedPos,			// Servo (juice tube) position when juice tube is retracted (full is ~ 50)
	TubeDeployedPos,			// Servo (juice tube) position when juice tube is deployed (full is ~ 125)
	TubeRetractSpeed,			// Servo (juice tube) retract speed when retracting, 0 for max speed	
	TubeDeploySpeed,			// Servo (juice tube) advance speed when deploying, 0 for max speed
	OptoEnabled,				// 1 to enable optogen stim during ITI and idle
	OptoPulseDuration,			// Optogenetic stim, duration of single pulse (ms)
	OptoPulseInterval,			// Optogenetic stim, interval between pulses (ms)
	OptoNumPulses,				// Optogenetic stim, number of pulses to deliver	
	RandomDelayMin,				// Minimum random pre-stim delay (ms)
	RandomDelayMax,				// Maximum random pre-stim delay (ms)
	LeverMotorPos,				// 1-4, position for the lever motor
	Count						// (Private) Used to count how many parameters there are so we can initialize the param array with the correct size. Insert additional parameters before this.
};

// Store parameter names as strings, will be sent to host
// Names cannot contain spaces!!!
static const char *_paramNames[] = 
{
	"Debug",
	"MinITI",
	"MeanITI",
	"MaxITI",
	"LeverHoldTime",
	"LeverRetractTime",
	"RewardDuration",
	"MinRewardCollectionTime",
	"ExtraRewardCollectionTime",
	"LeverRetractedPos",
	"LeverDeployedPos",
	"LeverDeploySpeed",
	"LeverRetractSpeed",
	"TubeRetractedPos",
	"TubeDeployedPos",
	"TubeDeploySpeed",
	"TubeRetractSpeed",
	"OptoEnabled",			
	"OptoPulseDuration",	
	"OptoPulseInterval",	
	"OptoNumPulses",		
	"RandomDelayMin",
	"RandomDelayMax",
	"LeverMotorPos"
};

// Initialize parameters
long _params[ParamID::Count] = 
{
	0, 		// Debug
	0, 		// MinITI
	20000, 	// MeanITI
	20000, 	// MaxITI
	50, 	// LeverHoldTime
	1000, 	// LeverRetractTime
	50, 	// RewardDuration
	3000, 	// MinRewardCollectionTime
	1000, 	// ExtraRewardCollectionTime
	93, 	// LeverRetractedPos
	63, 	// LeverDeployedPos
	72, 	// LeverDeploySpeed
	72, 	// LeverRetractSpeed
	60, 	// TubeRetractedPos
	90, 	// TubeDeployedPos
	36, 	// TubeDeploySpeed
	72, 	// TubeRetractSpeed
	0, 		// OptoEnabled
	10, 	// OptoPulseDuration
	250, 	// OptoPulseInterval
	10, 	// OptoNumPulses
	3000, 	// RandomDelayMin
	6000, 	// RandomDelayMax
	1		// LeverMotorPos
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
static State _state					= State::Init;	// This variable (current _state) get passed into a _state function, which determines what the next _state should be, and updates it to the next _state.
static State _prevState				= State::Init;	// Remembers the previous _state from the last loop (actions should only be executed when you enter a _state for the first time, comparing currentState vs _prevState helps us keep track of that).
static char _command				= ' ';			// Command char received from host, resets on each loop
static int _arguments[2]			= {0};			// Two integers received from host , resets on each loop
static bool _isUpdatingParams 		= false;

static bool _isLicking 				= false;		// True if the little dude is licking
static bool _isLickOnset 			= false;		// True during lick onset
static long _timeLastLick			= 0;			// Time (ms) when last lick occured

static bool _isLeverPressed			= false;		// True as long as lever is pressed down
static bool _isLeverHeld 			= false;
static long _timeLastLeverPress		= 0;			// Time (ms) when last lever press occured
static long _timeLastLeverRelease	= 0;			// Time (ms) when last lever press occured
static long _timeLastLeverRetract 	= 0;			// Time (ms) when last lever retraction occured (due to touch)

static ServoState _servoStateTube	= ServoState::Init;				// Servo state
static long _servoStartTimeLever	= 0;							// When servo started moving retrieved using getTime()
static long _servoSpeedLever		= _params[ParamID::LeverRetractSpeed]; // Speed of servo movement (deg/s)
static long _servoStartPosLever		= _params[ParamID::LeverRetractedPos];	// Starting position of servo when rotation begins
static long _servoTargetPosLever	= _params[ParamID::LeverRetractedPos];	// Target position of servo

static ServoState _servoStateLever 	= ServoState::Init;				// Servo state
static long _servoStartTimeTube		= 0;							// When servo started moving retrieved using getTime()
static long _servoSpeedTube			= _params[ParamID::TubeRetractSpeed]; 	// Speed of servo movement (deg/s)
static long _servoStartPosTube		= _params[ParamID::TubeDeployedPos];	// Starting position of servo when rotation begins
static long _servoTargetPosTube		= _params[ParamID::TubeDeployedPos];	// Target position of servo

// Optogenetics stimulation
static bool _isOptogenStimOn 		= false;

// Motor
static int _motorPosition = 0;

/*****************************************************
	Setup
*****************************************************/
void setup()
{
	// Init digital output pins
	for(unsigned int i = 0; i < sizeof(_digOutPins)/sizeof(_digOutPins[0]); i++)
	{
		pinMode(_digOutPins[i], OUTPUT);
		digitalWrite(_digOutPins[i], LOW);
	}

	// Init input pins
	pinMode(PIN_LICK, INPUT);					// Lick detector (input)
	pinMode(PIN_LEVER, INPUT);					// Lever press detector (input)
	pinMode(PIN_MOTOR_BUSY, INPUT);

	analogWriteResolution(ANALOG_WRITE_RESOLUTION);
	pinMode(PIN_LASER_PWR_1, OUTPUT);
	pinMode(PIN_LASER_PWR_2, OUTPUT);

	// Initiate servo
	_servoLever.attach(PIN_SERVO_LEVER);
	_servoTube.attach(PIN_SERVO_TUBE);

	// Serial comms
	Serial.begin(115200);                       // Set up USB communication at 115200 baud 
}

void mySetup()
{
	// Set laser analog modulation to 0
	setOptogenStim(false);					// Optogenetic stim OFF

	// Reset variables
	_timeReset				= signedMillis();			// Reset to signedMillis() at every soft reset
	_timeTrialStart			= 0;			// Reset to 0 at start of trial
	_timeTrialEnd			= 0;			// Reset to 0 at ITI entry
	_resultCode				= -1;			// Result code. -1 if there is no result.
	_state					= State::Init;	// This variable (current _state) get passed into a _state function, which determines what the next _state should be, and updates it to the next _state.
	_prevState				= State::Init;	// Remembers the previous _state from the last loop (actions should only be executed when you enter a _state for the first time, comparing currentState vs _prevState helps us keep track of that).
	_command				= ' ';			// Command char received from host, resets on each loop
	_arguments[2]			= {0};			// Two integers received from host , resets on each loop
	_isUpdatingParams 		= false;

	_isLicking 				= false;		// True if the little dude is licking
	_isLickOnset 			= false;		// True during lick onset
	_timeLastLick			= 0;			// Time (ms) when last lick occured
	_isLeverPressed			= false;		// True as long as lever is pressed down
	_isLeverHeld 			= false;
	_timeLastLeverPress		= 0;			// Time (ms) when last lever press occured
	_timeLastLeverRelease	= 0;			// Time (ms) when last lever press occured
	_timeLastLeverRetract 	= 0;

	_servoStateTube			= ServoState::Init;				// Servo state
	_servoStartTimeLever	= 0;							// When servo started moving retrieved using getTime()
	_servoSpeedLever		= _params[ParamID::LeverRetractSpeed]; // Speed of servo movement (deg/s)
	_servoStartPosLever		= _params[ParamID::LeverRetractedPos];	// Starting position of servo when rotation begins
	_servoTargetPosLever	= _params[ParamID::LeverRetractedPos];	// Target position of servo

	_servoStateLever 		= ServoState::Init;				// Servo state
	_servoStartTimeTube		= 0;							// When servo started moving retrieved using getTime()
	_servoSpeedTube			= _params[ParamID::TubeRetractSpeed]; 	// Speed of servo movement (deg/s)
	_servoStartPosTube		= _params[ParamID::TubeDeployedPos];	// Starting position of servo when rotation begins
	_servoTargetPosTube		= _params[ParamID::TubeDeployedPos];	// Target position of servo

	_isOptogenStimOn 		= false;

	_motorPosition = 0;

	// Sends all parameters, states and error codes to Matlab, then tell PC that we're running by sending '~' message:
	hostInit();

	setAnalogOutput(1, 0);
	setAnalogOutput(2, 0);	
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
		handleAnalogOutput();	// Write to DAC channels to modulate laser pwoer
		handleManualOptoStim(); // Handles manual opto commands from serial "L [shutterNum(1/2, or 3 for both)] [state(0/1)]"

		// 3) Update state machine
		// Depending on what state we're in, call the appropriate state function, which will evaluate the transition conditions, and update the `_state` var to what the next state should be
		switch (_state) 
		{
			case State::Init:
				state_idle();
				break;
			
			case State::Idle:
				state_idle();
				break;
			
			case State::Timeout:
				state_timeout();
				break;

			case State::WaitForTouch:
				state_waitfortouch();
				break;
			
			case State::Reward:
				state_reward();
				break;

			case State::Opto:
				state_opto();
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
	static bool hasMotorReachedTarget;
	static long timeIdle;
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);

		hasMotorReachedTarget = false;
		timeIdle = getTime();
		// Reset output
		// setAnalogOutput(1, 0);
		// setAnalogOutput(2, 0);
		setOptogenStim(false);
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
	if (!hasMotorReachedTarget && getTime() - timeIdle > 1 && !isMotorBusy())
	{
		hasMotorReachedTarget = true;
		switch (_motorPosition)
		{
			case 0:
				sendEventMarker(EventMarker::MotorLeverPos1_Reached, -1);
				break;
			case 1:
				sendEventMarker(EventMarker::MotorLeverPos2_Reached, -1);
				break;
			case 2:
				sendEventMarker(EventMarker::MotorLeverPos3_Reached, -1);
				break;
			case 3:
				sendEventMarker(EventMarker::MotorLeverPos4_Reached, -1);
				break;
		}
	}

	/*****************************************************
		TRANSITION LIST
	*****************************************************/
	// GO signal from host --> INTERTRIAL
	if (_command == 'G' && !_isUpdatingParams) 
	{
		_state = State::Timeout;
		return;
	}

	// LASER command from host --> State::Opto
	if (_command == 'L')
	{
		_state = State::Opto;
		return;
	}

	_state = State::Idle;
}

/*****************************************************
	INTERTRIAL
*****************************************************/
void state_timeout()
{
	static long itiDuration;
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		sendState(_state);

		// Register events
		sendEventMarker(EventMarker::ITI, -1);

		// Retract lick tube immediately if first trial
		if (_prevState != State::Idle)
		{
			deployTube(false);
		}

		// Generate random interval length from exponential distribution
		// CDF  p=F(x|μ)=1-exp(-x/μ);
		// Inverse CDF is x=F^(−1)(p∣μ)=−μln(1−p).
		// For each draw, we let p = uniform_rand(0, 1), get corresponding value x from inverse CDF.
		itiDuration = -1*_params[ParamID::MeanITI]*log(1.0 - ((float)random(1UL << 31)) / (1UL << 31));
		// Apply min/max cutoffs
		itiDuration = max(itiDuration, _params[ParamID::MinITI]);
		itiDuration = min(itiDuration, _params[ParamID::MaxITI]);

		// Update state
		_prevState = _state;
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
		_state = State::Idle;
		return;
	}


	// If ITI elapsed && lick spout retracted && no licks for a bit && lever released for a few seconds
	if (!_isUpdatingParams && getTimeSinceTrialEnd() >= itiDuration)
	{			
		_state = State::WaitForTouch;
		return;
	}

	_state = State::Timeout;
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
		sendEventMarker(EventMarker::TrialStart, -1);
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
		_state = State::Idle;
		return;
	}

	// Touch --> REWARD
	if (_isLeverHeld && !_isUpdatingParams)
	{
		_timeTrialEnd = getTime();
		_state = State::Reward;
		return;
	}

	_state = State::WaitForTouch;
}

/*****************************************************
	REWARD - Present juice for some time
*****************************************************/
void state_reward()
{
	static long timeRewardOn;
	static bool isRewardOn;
	static bool isRewardComplete;
	static bool isTubeRetracted;
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
		isTubeRetracted = false;

		noTone(PIN_SPEAKER);
		tone(PIN_SPEAKER, ToneFrequency::Reward, _params[ParamID::RewardDuration]);
	}

	/*****************************************************
		OnEachLoop checks
	*****************************************************/
	// Deploy spout and dispense reward
	if (!isRewardOn && !isRewardComplete)
	{
		timeRewardOn = getTime();
		isRewardOn = true;
		if (_params[ParamID::RewardDuration] > 0)
		{
			deployTube(true);
			setReward(true);
		}			
	}

	// Turn off reward when the time comes
	if (isRewardOn && !isRewardComplete && getTime() - timeRewardOn >= _params[ParamID::RewardDuration])
	{
		isRewardOn = false;
		isRewardComplete = true;
		if (_params[ParamID::RewardDuration] > 0)
		{
			setReward(false);
		}
	}

	// Retract lick tube when the time comes
	if (!isTubeRetracted && getTime() - timeRewardOn >= _params[ParamID::MinRewardCollectionTime] && getTimeSinceLastLick() >= _params[ParamID::ExtraRewardCollectionTime])
	{
		isTubeRetracted = true;
		deployTube(false);
	}


	/*****************************************************
		TRANSITION LIST
	*****************************************************/
	// Quit signal from host --> IDLE
	if (_command == 'Q') 
	{
		_state = State::Idle;
		return;
	}

	// Reward dispensed and tube retracted fully --> INTERTRIAL
	if (isRewardComplete && _servoStateTube == ServoState::Retracted && !_isUpdatingParams)
	{
		_state = State::Timeout;
		return;			
	}

	_state = State::Reward;
}

/*****************************************************
	STIM
*****************************************************/
void state_opto()
{
	static State entryState;
	static long timeEnter;
	static long timePulseStart;
	static long timePulseEnd;
	static long numPulsesComplete;
	static long randomDelay;
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		setOptogenStim(false);

		// Write down previous state, return to it when done
		entryState = _prevState;

		// Register new state
		_prevState = _state;
		sendState(_state);

		// Generate random interval length
		if (entryState == State::Timeout)
		{
			randomDelay = random(_params[ParamID::RandomDelayMin], _params[ParamID::RandomDelayMax]);
		}

		// Register time of state entry
		timeEnter = getTime();
		numPulsesComplete = 0;
	}

	/*****************************************************
		OnEachLoop checks
	*****************************************************/
	if (numPulsesComplete < _params[ParamID::OptoNumPulses])
	{
		// If stim is on, check if it needs to be turned off
		if (_isOptogenStimOn)
		{
			if (getTime() - timePulseStart >= _params[ParamID::OptoPulseDuration])
			{
				setOptogenStim(false);
				timePulseEnd = getTime();
				numPulsesComplete = numPulsesComplete + 1;
			}
		}
		// If stim is off, check if it needs to be turned on
		else
		{
			if (getTime() - timePulseEnd >= _params[ParamID::OptoPulseInterval])
			{
				setOptogenStim(true);
				timePulseStart = getTime();
			}
		}
	}

	/*****************************************************
		TRANSITION LIST
	*****************************************************/
	// Quit signal from host --> IDLE
	if (_command == 'Q') 
	{
		_state = State::Idle;
		return;
	}

	// Stim train complete --> PRE_CUE (after random delay) or IDLE
	if (numPulsesComplete >= _params[ParamID::OptoNumPulses])
	{
		if (entryState == State::Timeout)
		{
			if (getTime() - timePulseEnd >= randomDelay)
			{
				_state = State::WaitForTouch;
				return;
			}
		}
		else
		{
			_state = State::Idle;
			return;
		}
	}

	_state = State::Opto;
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
		sendEventMarker(EventMarker::Lick, -1);
	}
	else
	{
		if (!getLickState() && _isLicking)
		{
			_isLicking = false;
			sendEventMarker(EventMarker::LickOff, -1);
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
	// Lever contact
	if (getLeverState())
	{
		// Onset
		if (!_isLeverPressed)
		{
			_isLeverPressed = true;
			sendEventMarker(EventMarker::LeverPressed, -1);
			_timeLastLeverPress = getTime();
		}
		// Press-and-hold timeout reached
		if (!_isLeverHeld && getTimeSinceLastLeverPress() >= _params[ParamID::LeverHoldTime])
		{
			_isLeverHeld = true;
			sendEventMarker(EventMarker::LeverHeld, -1);
			deployLever(false);
			_timeLastLeverRetract = getTime();
		}
	}
	// not in contact
	else
	{
		// Offset
		if (_isLeverPressed)
		{
			_isLeverPressed = false;
			_isLeverHeld = false;
			sendEventMarker(EventMarker::LeverReleased, -1);
			_timeLastLeverRelease = getTime();
		}
	}

	if (_servoStateLever == ServoState::Retracted && getTimeSinceLastLeverRetract() >= _params[ParamID::LeverRetractTime])
	{
		deployLever(true);
	} 
}

// Use servo to retract/present lever to the little dude
void deployLever(bool deploy)
{
	if (deploy) 
	{
		if (_servoStateLever != ServoState::Deployed)
		{
			_servoStateLever = ServoState::Deploying;
			sendEventMarker(EventMarker::LeverDeployStart, -1);
		}
		_servoStartTimeLever = getTime();
		_servoSpeedLever = _params[ParamID::LeverDeploySpeed];
		_servoStartPosLever = _servoLever.read();
		_servoTargetPosLever = _params[ParamID::LeverDeployedPos];
	}
	else 
	{
		if (_servoStateLever != ServoState::Retracted)
		{
			_servoStateLever = ServoState::Retracting;
			sendEventMarker(EventMarker::LeverRetractStart, -1);
		}
		_servoStartTimeLever = getTime();
		_servoSpeedLever = _params[ParamID::LeverRetractSpeed];
		_servoStartPosLever = _servoLever.read();
		_servoTargetPosLever = _params[ParamID::LeverRetractedPos];
	}
}

// Use servo to retract/present lever to the little dude
void deployTube(bool deploy)
{
	if (deploy)
	{
		if (_servoStateTube != ServoState::Deployed)
		{
			_servoStateTube = ServoState::Deploying;
			sendEventMarker(EventMarker::TubeDeployStart, -1);
		}
		_servoStartTimeTube = getTime();
		_servoSpeedTube = _params[ParamID::TubeDeploySpeed];
		_servoStartPosTube = _servoTube.read();
		_servoTargetPosTube = _params[ParamID::TubeDeployedPos];
	}
	else
	{
		if (_servoStateTube != ServoState::Retracted)
		{
			_servoStateTube = ServoState::Retracting;
			sendEventMarker(EventMarker::TubeRetractStart, -1);
		}
		_servoStartTimeTube = getTime();
		_servoSpeedTube = _params[ParamID::TubeRetractSpeed];
		_servoStartPosTube = _servoTube.read();
		_servoTargetPosTube = _params[ParamID::TubeRetractedPos];
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
	if (_servoStateLever == ServoState::Deploying && abs(_servoLever.read() - _params[ParamID::LeverDeployedPos]) <= SERVO_READ_ACCURACY)
	{
		_servoStateLever = ServoState::Deployed;
		sendEventMarker(EventMarker::LeverDeployEnd, -1);
	}

	if (_servoStateLever == ServoState::Retracting && abs(_servoLever.read() - _params[ParamID::LeverRetractedPos]) <= SERVO_READ_ACCURACY)
	{
		_servoStateLever = ServoState::Retracted;
		sendEventMarker(EventMarker::LeverRetractEnd, -1);
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
	if (_servoStateTube == ServoState::Deploying && abs(_servoTube.read() - _params[ParamID::TubeDeployedPos]) <= SERVO_READ_ACCURACY)
	{
		_servoStateTube = ServoState::Deployed;
		sendEventMarker(EventMarker::TubeDeployEnd, -1);
	}

	if (_servoStateTube == ServoState::Retracting && abs(_servoTube.read() - _params[ParamID::TubeRetractedPos]) <= SERVO_READ_ACCURACY)
	{
		_servoStateTube = ServoState::Retracted;
		sendEventMarker(EventMarker::TubeRetractEnd, -1);
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
			sendEventMarker(EventMarker::RewardOn, -1);
		}		
	}
	else
	{
		digitalWrite(PIN_REWARD, LOW);
		digitalWrite(PIN_MIRROR_REWARD, LOW);
		if (rewardOn)
		{
			rewardOn = false;
			sendEventMarker(EventMarker::RewardOff, -1);
		}				
	}
}

// Toggle optogenetic stimulation
void setOptogenStim(bool turnOn) 
{
	if (turnOn) 
	{
		_isOptogenStimOn = true;
		digitalWrite(PIN_OPTOGEN_STIM, HIGH);
		sendEventMarker(EventMarker::OptoStimOn, -1);
	}
	else 
	{
		_isOptogenStimOn = false;
		digitalWrite(PIN_OPTOGEN_STIM, LOW);
		sendEventMarker(EventMarker::OptoStimOff, -1);
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
	if (_params[ParamID::Debug] > 0)
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

void sendAnalogOutValue(int channel, int value, long timestamp)
{
	if (timestamp == -1)
	{
		sendMessage("% " + String(channel) + " " + String(value) + " " + String(getTime()));
	}
	else
	{
		sendMessage("% " + String(channel) + " " + String(value) + " " + String(timestamp));
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
	for (int iState = 0; iState < State::Count; iState++)
	{
			sendMessage("@ " + String(iState) + " " + _stateNames[iState] + " " + String(_stateCanUpdateParams[iState]));
	}

	// Send event marker names
	for (int iCode = 0; iCode < EventMarker::Count; iCode++)
	{
			sendMessage("+ " + String(iCode) + " " + _eventMarkerNames[iCode]);
	}

	// Send param names and default values
	for (int iParam = 0; iParam < ParamID::Count; iParam++)
	{
			sendMessage("# " + String(iParam) + " " + _paramNames[iParam] + " " + String(_params[iParam]));
	}

	// Send result code names
	for (int iCode = 0; iCode < ResultCode::Count; iCode++)
	{
			sendMessage("* " + String(iCode) + " " + _resultCodeNames[iCode]);
	}
	// Send analog write resolution
	sendMessage(": " + String(ANALOG_WRITE_RESOLUTION));
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

void handleManualOptoStim()
{
	// Handles manual shutter command: T [state]
	// state: 0 or 1
	if (_command == 'T') // T for shutter
	{
		setOptogenStim(_arguments[0] > 0);
	}
}

void handleAnalogOutput()
{
	if (_command == 'A')
	{
		setAnalogOutput(_arguments[0], _arguments[1]);
	}
}

void setAnalogOutput(int channel, int value)
{
	switch (channel)
	{
	    case 1:
	    	analogWrite(PIN_LASER_PWR_1, value);
	    	break;
	    case 2:
	    	analogWrite(PIN_LASER_PWR_2, value);
	    	break;
	}
	sendAnalogOutValue(channel, value, -1);
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
	long time = getTime() - _timeTrialStart;
	return time;
}

// Returns time since trial start in milliseconds
long getTimeSinceTrialEnd()
{
	long time = getTime() - _timeTrialEnd;
	return time;
}

// Returns time since last lick in milliseconds
long getTimeSinceLastLick()
{
	long time = getTime() - _timeLastLick;
	return time;
}

// Returns time since last lever press in milliseconds
long getTimeSinceLastLeverPress()
{
	long time = getTime() - _timeLastLeverPress;
	return time;
}

// Returns time since last lever release in milliseconds
long getTimeSinceLastLeverRelease()
{
	long time = getTime() - _timeLastLeverRelease;
	return time;
}

long getTimeSinceLastLeverRetract()
{
	long time = getTime() - _timeLastLeverRetract;
	return time;
}