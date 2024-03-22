/*********************************************************************
	Arduino state machine
	Spontaneous lever-touch task
*********************************************************************/

/*********************************************************************
// Outputs
~ // Arduino is Ready
` // ResultCode
@ // stateCanUpdateParams
# // paramName
$ // State
% // AnalogOutValue
^ // Request move lever
& // EventMarker
* // resultCodeName
+ // eventMarkerName
: // analogWriteResolution
; // Request opto

// Inputs
R - reset
G - start
L - opto (manual)
Q - stop
S - read servo position
P [paramID] [(float)newValue] - param update
O - param transmission complete
T [(0/1)shutterOpen] - manual toggle shutter
A [channel] [value] - manual set analog output
^ [(1-4)leverPos] - MATLAB return lever motor target index (1 based)
; [(0/1)doOpto] - MATLAB finished setting up laser, can proceded to OPTO (1), or SKIP (0)
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
#define PIN_LEVERMOTOR_HI		5
#define PIN_LEVERMOTOR_LO		6

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
#define PIN_LEVERMOTOR_BUSY		7
#define PIN_LASERMOTOR_BUSY		4

static const int _digOutPins[] = 
{
	PIN_REWARD,
	PIN_SERVO_LEVER,
	PIN_SERVO_TUBE,
	PIN_OPTOGEN_STIM,
	PIN_LEVERMOTOR_HI,
	PIN_LEVERMOTOR_LO,
	PIN_MIRROR_LICK,
	PIN_MIRROR_LEVER,
	PIN_MIRROR_REWARD,
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
	STATE_TIMEOUT,
	STATE_MOVE_LEVER,
	STATE_REQUEST_OPTO,
	STATE_OPTO,
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
	"TIMEOUT",
	"MOVE_LEVER",
	"REQUEST_OPTO",
	"OPTO",
};

// Define which states accept parameter update from MATLAB
static const int _stateCanUpdateParams[] = 
{
	0,	// _STATE_INIT
	1,	// STATE_IDLE
	1,	// STATE_WAITFORTOUCH
	1,	// STATE_REWARD
	1,	// STATE_TIMEOUT
	1,	// STATE_MOVE_LEVER
	1,	// STATE_REQUEST_OPTO
	0,	// STATE_OPTO
}; 

/*****************************************************
	Event Markers
*****************************************************/
enum EventMarker
{
	EVENT_WAITFORTOUCH,				// New trial initiated
	EVENT_LICK,						// Lick onset
	EVENT_LICK_OFF,					// Lick offset
	EVENT_LEVER_PRESSED,			// Lever touch onset
	EVENT_LEVER_RELEASED,			// Lever touch offset
	EVENT_LEVER_HELD,
	EVENT_REWARD_ON,				// Reward, juice valve on
	EVENT_REWARD_OFF,				// Reward, juice valve off
	EVENT_TIMEOUT_START,			// At start of timeout
	EVENT_LEVER_RETRACT_START,		// Lever retract start
	EVENT_LEVER_RETRACT_END,		// Lever retracted
	EVENT_LEVER_DEPLOY_START,		// Lever deploy start
	EVENT_LEVER_DEPLOY_END,			// Lever deploy end
	EVENT_TUBE_RETRACT_START,		// Tube retract start
	EVENT_TUBE_RETRACT_END,			// Tube retract end
	EVENT_TUBE_DEPLOY_START,		// Tube deploy start
	EVENT_TUBE_DEPLOY_END,			// Tube deploy end
	EVENT_OPTO_STIM_ON,				// Begin optogenetic stim (single pulse start)
	EVENT_OPTO_STIM_OFF,			// End optogenetic stim (single pulse end)
	EVENT_LEVERMOTOR_POS1_START,
	EVENT_LEVERMOTOR_POS1_REACHED,
	EVENT_LEVERMOTOR_POS2_START,
	EVENT_LEVERMOTOR_POS2_REACHED,
	EVENT_LEVERMOTOR_POS3_START,
	EVENT_LEVERMOTOR_POS3_REACHED,
	EVENT_LEVERMOTOR_POS4_START,
	EVENT_LEVERMOTOR_POS4_REACHED,
	EVENT_REQUEST_OPTO,
	EVENT_LASERMOTOR_START,
	EVENT_LASERMOTOR_REACHED,
	_NUM_EVENT_MARKERS
};

static const char *_eventMarkerNames[] =
{
	"WAITFORTOUCH",				// New trial initiated
	"LICK",						// Lick onset
	"LICK_OFF",					// Lick offset
	"LEVER_PRESSED",			// Lever touch onset
	"LEVER_RELEASED",			// Lever touch offset
	"LEVER_HELD",
	"REWARD_ON",				// Reward, juice valve on
	"REWARD_OFF",				// Reward, juice valve off
	"TIMEOUT_START",			// At start of timeout
	"LEVER_RETRACT_START",		// Lever retract start
	"LEVER_RETRACT_END",		// Lever retracted
	"LEVER_DEPLOY_START",		// Lever deploy start
	"LEVER_DEPLOY_END",			// Lever deploy end
	"TUBE_RETRACT_START",		// Tube retract start
	"TUBE_RETRACT_END",			// Tube retract end
	"TUBE_DEPLOY_START",		// Tube deploy start
	"TUBE_DEPLOY_END",			// Tube deploy end
	"OPTO_STIM_ON",				// Begin optogenetic stim (single pulse start)
	"OPTO_STIM_OFF",			// End optogenetic stim (single pulse end)
	"LEVERMOTOR_POS1_START",
	"LEVERMOTOR_POS1_REACHED",
	"LEVERMOTOR_POS2_START",
	"LEVERMOTOR_POS2_REACHED",
	"LEVERMOTOR_POS3_START",
	"LEVERMOTOR_POS3_REACHED",
	"LEVERMOTOR_POS4_START",
	"LEVERMOTOR_POS4_REACHED",
	"REQUEST_OPTO",
	"LASERMOTOR_START",
	"LASERMOTOR_REACHED",
};

/*****************************************************
	Result codes
*****************************************************/
// Don't think of these as trials results, think of them as "checkpoints" in the session
// for when you want to save data to disk
// Incorrect/early moves might occur too often and we don't want to trigger MATLAB callbacks too frequently
enum ResultCode
{
	CODE_CORRECT_1,
	CODE_CORRECT_2,
	CODE_CORRECT_3,
	CODE_CORRECT_4,
	CODE_LEVER_MOVED,
	CODE_OPTO,
	_NUM_RESULT_CODES
};

// We'll send result code translations to MATLAB at startup
static const char *_resultCodeNames[] =
{
	"CORRECT_1",
	"CORRECT_2",
	"CORRECT_3",
	"CORRECT_4",
	"LEVER_MOVED",
	"OPTO",
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
	TIMEOUT_MIN,					// ITI length min cutoff (ms)
	TIMEOUT_MEAN,					// ITI length (mean of exponential distribution) (ms)
	TIMEOUT_MAX,					// ITI length max cutoff (ms)
	LEVER_HOLD_TIME,				// Lever contact must be maintained for this duration (ms) before reward dispensed..
	LEVER_RETRACT_TIME,				// Lever will be retracted for this duration before redeploying
	REWARD_DURATION,				// Reward duration (ms), also determines tone duration
	MIN_REWARD_COLLECTION_TIME,		// Min time juice tube is deployed (remember to make it longer than tube deploy time)
	EXTRA_LICK_TIME,				// Lick tube does not retract until last lick was this many ms before (ms)
	LEVER_POS_RETRACTED,			// Servo (lever) position when lever is retracted
	LEVER_POS_DEPLOYED,				// Servo (lever) position when lever is deployed
	LEVER_SPEED_DEPLOY,				// Servo (lever) rotation speed when deploying, 0 for max speed
	LEVER_SPEED_RETRACT,			// Servo (lever) rotaiton speed when retracting, 0 for max speed
	TUBE_POS_RETRACTED,				// Servo (juice tube) position when juice tube is retracted (full is ~ 50)
	TUBE_POS_DEPLOYED,				// Servo (juice tube) position when juice tube is deployed (full is ~ 125)
	TUBE_SPEED_DEPLOY,				// Servo (juice tube) advance speed when deploying, 0 for max speed
	TUBE_SPEED_RETRACT,				// Servo (juice tube) retract speed when retracting, 0 for max speed	
	OPTO_ENABLED,					// 1 to enable optogen stim during ITI and idle
	OPTO_PULSE_DURATION,			// Optogenetic stim, duration of single pulse (ms)
	OPTO_PULSE_INTERVAL,			// Optogenetic stim, interval between pulses (ms)
	OPTO_NUM_PULSES,				// Optogenetic stim, number of pulses to deliver	
	OPTO_WARMUP_TIME,				// In REQUEST_OPTO, laser will be kept on this long before advancing to OPTO
	OPTO_RANDOM_DELAY_MIN,			// Minimum random pre-stim delay (ms)
	OPTO_RANDOM_DELAY_MAX,			// Maximum random pre-stim delay (ms)
	LEVER_MOTOR_POS,				// 1-4, change this to set the twobit lever motor control
	NUM_REWARDS_PER_LEVER_MOVE,		// Move the lever after this many correct trials
	WAITFORTOUCH_TO_OPTO_TIMEOUT,	// Go to opto if this much time has elapsed in waitfortouch.
	_NUM_PARAMS						// (Private) Used to count how many parameters there are so we can initialize the param array with the correct size. Insert additional parameters before this.
};

// Store parameter names as strings, will be sent to host
// Names cannot contain spaces!!!
static const char *_paramNames[] = 
{
	"_DEBUG",						// (Private) 1 to enable debug mode. Default 0.
	"TIMEOUT_MIN",					// ITI length min cutoff (ms)
	"TIMEOUT_MEAN",					// ITI length (mean of exponential distribution) (ms)
	"TIMEOUT_MAX",					// ITI length max cutoff (ms)
	"LEVER_HOLD_TIME",				// Lever contact must be maintained for this duration (ms) before reward dispensed..
	"LEVER_RETRACT_TIME",			// Lever will be retracted for this duration before redeploying
	"REWARD_DURATION",				// Reward duration (ms), also determines tone duration
	"MIN_REWARD_COLLECTION_TIME",	// Min time juice tube is deployed (remember to make it longer than tube deploy time)
	"EXTRA_LICK_TIME",				// Lick tube does not retract until last lick was this many ms before (ms)
	"LEVER_POS_RETRACTED",			// Servo (lever) position when lever is retracted
	"LEVER_POS_DEPLOYED",			// Servo (lever) position when lever is deployed
	"LEVER_SPEED_DEPLOY",			// Servo (lever) rotation speed when deploying, 0 for max speed
	"LEVER_SPEED_RETRACT",			// Servo (lever) rotaiton speed when retracting, 0 for max speed
	"TUBE_POS_RETRACTED",			// Servo (juice tube) position when juice tube is retracted (full is ~ 50)
	"TUBE_POS_DEPLOYED",			// Servo (juice tube) position when juice tube is deployed (full is ~ 125)
	"TUBE_SPEED_DEPLOY",			// Servo (juice tube) advance speed when deploying, 0 for max speed
	"TUBE_SPEED_RETRACT",			// Servo (juice tube) retract speed when retracting, 0 for max speed	
	"OPTO_ENABLED",					// 1 to enable optogen stim during ITI and idle
	"OPTO_PULSE_DURATION",			// Optogenetic stim, duration of single pulse (ms)
	"OPTO_PULSE_INTERVAL",			// Optogenetic stim, interval between pulses (ms)
	"OPTO_NUM_PULSES",				// Optogenetic stim, number of pulses to deliver	
	"OPTO_WARMUP_TIME",				// In REQUEST_OPTO, laser will be kept on this long before advancing to OPTO
	"OPTO_RANDOM_DELAY_MIN",		// Minimum random pre-stim delay (ms)
	"OPTO_RANDOM_DELAY_MAX",		// Maximum random pre-stim delay (ms)
	"LEVER_MOTOR_POS",				// 1-4, change this to set the twobit lever motor control
	"NUM_REWARDS_PER_LEVER_MOVE",	// Move the lever after this many correct trials
	"WAITFORTOUCH_TO_OPTO_TIMEOUT",
};

// Initialize parameters
long _params[_NUM_PARAMS] = 
{
	0,		// _DEBUG
	0,		// TIMEOUT_MIN
	20000,	// TIMEOUT_MEAN
	20000,	// TIMEOUT_MAX
	50,		// LEVER_HOLD_TIME
	1000,	// LEVER_RETRACT_TIME
	50,		// REWARD_DURATION
	3000,	// MIN_REWARD_COLLECTION_TIME
	1000,	// EXTRA_LICK_TIME
	93,		// LEVER_POS_RETRACTED
	63,		// LEVER_POS_DEPLOYED
	72,		// LEVER_SPEED_DEPLOY
	72,		// LEVER_SPEED_RETRACT
	60,		// TUBE_POS_RETRACTED
	90,		// TUBE_POS_DEPLOYED
	36,		// TUBE_SPEED_DEPLOY
	72,		// TUBE_SPEED_RETRACT
	0,		// OPTO_ENABLED
	10,		// OPTO_PULSE_DURATION
	250,	// OPTO_PULSE_INTERVAL
	10,		// OPTO_NUM_PULSES
	8000, 	// OPTO_WARMUP_TIME
	3000,	// OPTO_RANDOM_DELAY_MIN
	6000,	// OPTO_RANDOM_DELAY_MAX
	1, 		// LEVER_MOTOR_POS
	10,		// NUM_REWARDS_PER_LEVER_MOVE
	30000,	// WAITFORTOUCH_TO_OPTO_TIMEOUT
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
static int _arguments[2]			= {0, 0};			// Two integers received from host , resets on each loop
static bool _isUpdatingParams 		= false;

static bool _isLicking 				= false;		// True if the little dude is licking
static bool _isLickOnset 			= false;		// True during lick onset
static long _timeLastLick			= 0;			// Time (ms) when last lick occured

static bool _isLeverPressed			= false;		// True as long as lever is pressed down
static bool _isLeverHeld 			= false;
static bool _forceRetractLever		= false;		// Lever will not autocycle on touch but will stay retracted
static long _timeLastLeverPress		= 0;			// Time (ms) when last lever press occured
static long _timeLastLeverRelease	= 0;			// Time (ms) when last lever press occured
static long _timeLastLeverRetract 	= 0;			// Time (ms) when last lever retraction occured (due to touch)

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
	pinMode(PIN_LEVERMOTOR_BUSY, INPUT);		// High when motor is moving
	pinMode(PIN_LASERMOTOR_BUSY, INPUT);

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
	_state					= _STATE_INIT;	// This variable (current _state) get passed into a _state function, which determines what the next _state should be, and updates it to the next _state.
	_prevState				= _STATE_INIT;	// Remembers the previous _state from the last loop (actions should only be executed when you enter a _state for the first time, comparing currentState vs _prevState helps us keep track of that).
	_command				= ' ';			// Command char received from host, resets on each loop
	_arguments[0]			= 0;			// Two integers received from host , resets on each loop
	_arguments[1]			= 0;			// Two integers received from host , resets on each loop
	_isUpdatingParams 		= false;

	_isLicking 				= false;		// True if the little dude is licking
	_isLickOnset 			= false;		// True during lick onset
	_timeLastLick			= 0;			// Time (ms) when last lick occured
	_isLeverPressed			= false;		// True as long as lever is pressed down
	_isLeverHeld 			= false;
	_forceRetractLever		= false;
	_timeLastLeverPress		= 0;			// Time (ms) when last lever press occured
	_timeLastLeverRelease	= 0;			// Time (ms) when last lever press occured
	_timeLastLeverRetract 	= 0;

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
			case _STATE_INIT:
				state_idle();
				break;
			
			case STATE_IDLE:
				state_idle();
				break;
			
			case STATE_TIMEOUT:
				state_timeout();
				break;

			case STATE_WAITFORTOUCH:
				state_waitfortouch();
				break;
			
			case STATE_REWARD:
				state_reward();
				break;

			case STATE_MOVE_LEVER:
				state_move_lever();
				break;

			case STATE_REQUEST_OPTO:
				state_request_opto();
				break;

			case STATE_OPTO:
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
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);

		// Reset output
		// setAnalogOutput(1, 0);
		// setAnalogOutput(2, 0);
		setOptogenStim(false);
		noTone(PIN_SPEAKER);
		setReward(false);
		deployLever(true);
		deployTube(true);
		setLeverPos(1);
		_resultCode = -1;
		_isUpdatingParams = false;
	}

	/*****************************************************
		OnEachLoop checks
	*****************************************************/

	/*****************************************************
		TRANSITION LIST
	*****************************************************/
	// GO signal from host --> WAITFORPRESS
	if (_command == 'G') 
	{
		_state = STATE_WAITFORTOUCH;
		return;
	}

	// LASER command from host --> STATE_OPTO
	if (_command == 'L')
	{
		_state = STATE_OPTO;
		return;
	}


	_state = STATE_IDLE;
}

/*****************************************************
	INTERTRIAL
*****************************************************/
void state_timeout()
{
	static long timeoutDuration;
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		sendState(_state);

		// Register events
		sendEventMarker(EVENT_TIMEOUT_START, -1);

		// Retract lick tube immediately if first trial
		if (_prevState != STATE_IDLE)
		{
			deployTube(false);
		}

		_timeTrialEnd = getTime();

		// Generate random interval length from exponential distribution
		// CDF  p=F(x|μ)=1-exp(-x/μ);
		// Inverse CDF is x=F^(−1)(p∣μ)=−μln(1−p).
		// For each draw, we let p = uniform_rand(0, 1), get corresponding value x from inverse CDF.
		timeoutDuration = -1*_params[TIMEOUT_MEAN]*log(1.0 - ((float)random(1UL << 31)) / (1UL << 31));
		// Apply min/max cutoffs
		timeoutDuration = max(timeoutDuration, _params[TIMEOUT_MIN]);
		timeoutDuration = min(timeoutDuration, _params[TIMEOUT_MAX]);

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
		_state = STATE_IDLE;
		return;
	}

	if (getTimeSinceTrialEnd() >= timeoutDuration)
	{			
		_state = STATE_WAITFORTOUCH;
		return;
	}

	_state = STATE_TIMEOUT;
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
		sendEventMarker(EVENT_WAITFORTOUCH, -1);
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
	if (_isLeverHeld)
	{
		_state = STATE_REWARD;
		return;
	}

	// No touch --> OPTO
	if (_params[OPTO_ENABLED] != 0 && getTimeSinceTrialStart() >= _params[WAITFORTOUCH_TO_OPTO_TIMEOUT])
	{
		_state = STATE_REQUEST_OPTO;
		return;
	}

	_state = STATE_WAITFORTOUCH;
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
	static int nRewardsSinceLeverMoved = 0;
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);

		// Send results
		int leverPos = getLeverPos();
		switch (leverPos)
		{
			case 1:
				_resultCode = CODE_CORRECT_1;
				break;
			case 2:
				_resultCode = CODE_CORRECT_2;
				break;
			case 3:
				_resultCode = CODE_CORRECT_3;
				break;
			case 4:
				_resultCode = CODE_CORRECT_4;
				break;
		}
		sendResultCode(_resultCode);
		// Reset variables
		timeRewardOn = 0;
		isRewardOn = false;
		isRewardComplete = false;
		isTubeRetracted = false;

		// Increment reward count
		nRewardsSinceLeverMoved++;

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

	// Retract lick tube when the time comes
	if (!isTubeRetracted && getTime() - timeRewardOn >= _params[MIN_REWARD_COLLECTION_TIME] && getTimeSinceLastLick() >= _params[EXTRA_LICK_TIME])
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
		_state = STATE_IDLE;
		return;
	}

	// Reward dispensed and tube retracted fully --> TIMEOUT
	if (isRewardComplete && _servoStateTube == SERVOSTATE_RETRACTED)
	{
		// MOVE_LEVER
		if (nRewardsSinceLeverMoved >= _params[NUM_REWARDS_PER_LEVER_MOVE])
		{
			nRewardsSinceLeverMoved = 0;
			_state = STATE_MOVE_LEVER;
			return;
		}
		// TIMEOUT
		else
		{
			_state = STATE_TIMEOUT;
			return;
		}	
	}

	_state = STATE_REWARD;
}

/*****************************************************
	MOVE LEVER to a random pos (chosen here)
*****************************************************/
void state_move_lever()
{
	static long timeLeverStart;
	static bool leverPosReceived;
	static int leverPos;
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);

		// Retract lever and disable auto-cycling
		forceRetractLever(true);

		// Send message to MATLAB to request new lever position
		leverPosReceived = false;
		leverPos = 0;
		sendMessage("^");
	}

	/*****************************************************
		OnEachLoop checks
	*****************************************************/
	// Receiver motor position from MATLAB
	// ^ [(1-4)leverPosIndex]
	if (_command == '^')
	{
		leverPosReceived = true;
		timeLeverStart = getTime();
		leverPos = _arguments[0];
		setLeverPos(leverPos);
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

	// Lever reached target --> REQUEST OPTO
	// Wait at least 100ms for motor command to reach motor arduino
	// I've tried waiting as little as 1ms before: that worked as well.
	if (leverPosReceived && getTime() - timeLeverStart > 100 && digitalRead(PIN_LEVERMOTOR_BUSY) == LOW)
	{
		switch (leverPos)
		{
			case 1:
				sendEventMarker(EVENT_LEVERMOTOR_POS1_REACHED, -1);
				break;
			case 2:
				sendEventMarker(EVENT_LEVERMOTOR_POS2_REACHED, -1);
				break;
			case 3:
				sendEventMarker(EVENT_LEVERMOTOR_POS3_REACHED, -1);
				break;
			case 4:
				sendEventMarker(EVENT_LEVERMOTOR_POS4_REACHED, -1);
				break;
		}

		_resultCode = CODE_LEVER_MOVED;
		sendResultCode(_resultCode);

		if (_params[OPTO_ENABLED] == 0)
		{
			forceRetractLever(false);
			_state = STATE_TIMEOUT;
			return;
		}
		else
		{
			_state = STATE_REQUEST_OPTO;
			return;
		}
	}

	_state = STATE_MOVE_LEVER;
}

/*****************************************************
	REQUEST OPTO (MOVES LASER MOTOR, TURNS ON LASER and all that)
*****************************************************/
void state_request_opto()
{
	static long timeRequest;
	static long timeMatlabReturn;
	static bool laserMotorStarted;
	static bool laserMotorReached;
	static bool isOptoAvailable;
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);

		// Keep lever retracted
		forceRetractLever(true);

		sendMessage(";"); // Request opto, tell MATLAB to move the laser mirror, and turn on the laser.
		timeRequest = getTime();
		timeMatlabReturn = 0;
		laserMotorStarted = false;
		laserMotorReached = false;
		isOptoAvailable = false;

		sendEventMarker(EVENT_REQUEST_OPTO, -1);
	}

	/*****************************************************
		OnEachLoop checks
	*****************************************************/
	// Monitor PIN_LASERMOTOR_BUSY
	if (!laserMotorStarted)
	{
		if (digitalRead(PIN_LASERMOTOR_BUSY) == HIGH)
		{
			laserMotorStarted = true;
			sendEventMarker(EVENT_LASERMOTOR_START, -1);
		}
	}
	else if (laserMotorStarted && !laserMotorReached)
	{
		if (digitalRead(PIN_LASERMOTOR_BUSY) == LOW)
		{
			laserMotorReached = true;
			sendEventMarker(EVENT_LASERMOTOR_REACHED, -1);
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

	// MATLAB sent ";", laser motor and laser power modulation commands have been sent by MATLAB
	if (_command == ';')
	{
		if (_arguments[0] == 0)
		{
			isOptoAvailable = false;
			_state = STATE_TIMEOUT;
			return;
		}
		else
		{
			timeMatlabReturn = getTime();
			isOptoAvailable = true;
		}
	}

	// Make sure the motor has finished moving, since MATLAB does not monitor this
	if (isOptoAvailable && getTime() - timeRequest > 500 && getTime() - timeMatlabReturn >= _params[OPTO_WARMUP_TIME] && digitalRead(PIN_LASERMOTOR_BUSY) == LOW)
	{
		_state = STATE_OPTO;
		return;
	}

	_state = STATE_REQUEST_OPTO;
}

/*****************************************************
	STIM
*****************************************************/
void state_opto()
{
	static State entryState;
	static long timeEnter;
	static long timePulseStart = 0;
	static long timePulseEnd = 0;
	static long numPulsesComplete;
	static long randomDelayPre;
	static long randomDelayPost;
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
		if (entryState != STATE_IDLE)
		{
			randomDelayPre = random(_params[OPTO_RANDOM_DELAY_MIN], _params[OPTO_RANDOM_DELAY_MAX]);
			randomDelayPost = random(_params[OPTO_RANDOM_DELAY_MIN], _params[OPTO_RANDOM_DELAY_MAX]);
		}

		// Register time of state entry
		timeEnter = getTime();
		numPulsesComplete = 0;
		timePulseStart = 0;
		timePulseEnd = 0;
	}

	/*****************************************************
		OnEachLoop checks
	*****************************************************/
	if (numPulsesComplete < _params[OPTO_NUM_PULSES])
	{
		// If stim is off, check if it needs to be turned on
		if (!isOptogenStimOn())
		{
			// Delay first pulse by random interval unless manually opto-ing in IDLE.
			if (entryState == STATE_IDLE || getTime() - timeEnter >= randomDelayPre)
			{
				if (numPulsesComplete == 0 || getTime() - timePulseEnd >= _params[OPTO_PULSE_INTERVAL])
				{
					setOptogenStim(true);
					timePulseStart = getTime();
				}
			}
		}
		// If stim is on, check if it needs to be turned off
		else if (getTime() - timePulseStart >= _params[OPTO_PULSE_DURATION])
		{
			setOptogenStim(false);
			timePulseEnd = getTime();
			numPulsesComplete = numPulsesComplete + 1;
		}
	}

	/*****************************************************
		TRANSITION LIST
	*****************************************************/
	// Quit signal from host --> IDLE
	if (_command == 'Q') 
	{
		setOptogenStim(false);
		_state = STATE_IDLE;
		return;
	}

	// Stim train complete --> TIMEOUT (after random delay) or IDLE
	if (numPulsesComplete >= _params[OPTO_NUM_PULSES])
	{
		// Return after random delay, unless manually triggering opto from IDLE
		if (entryState != STATE_IDLE)
		{
			if (getTime() - timePulseEnd >= randomDelayPost)
			{
				setAnalogOutput(1, 0);
				setAnalogOutput(2, 0);
				forceRetractLever(false);
				_state = STATE_TIMEOUT;
				_resultCode = CODE_OPTO;
				sendResultCode(_resultCode);
				return;
			}
		}
		else
		{
			_state = STATE_IDLE;
			return;
		}
	}

	_state = STATE_OPTO;
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
	// Lever contact
	if (getLeverState())
	{
		// Onset
		if (!_isLeverPressed)
		{
			_isLeverPressed = true;
			sendEventMarker(EVENT_LEVER_PRESSED, -1);
			_timeLastLeverPress = getTime();
		}
		// Press-and-hold timeout reached
		if (!_isLeverHeld && getTimeSinceLastLeverPress() >= _params[LEVER_HOLD_TIME])
		{
			_isLeverHeld = true;
			sendEventMarker(EVENT_LEVER_HELD, -1);
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
			sendEventMarker(EVENT_LEVER_RELEASED, -1);
			_timeLastLeverRelease = getTime();
		}
	}

	if (!_forceRetractLever && _servoStateLever == SERVOSTATE_RETRACTED && getTimeSinceLastLeverRetract() >= _params[LEVER_RETRACT_TIME])
	{
		deployLever(true);
	} 
}

void forceRetractLever(bool force)
{
	_forceRetractLever = force;
	_timeLastLeverRetract = getTime();
	deployLever(!force);
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

// Toggle optogenetic stimulation
void setOptogenStim(bool turnOn) 
{
	if (turnOn) 
	{
		if (!isOptogenStimOn())
		{
			digitalWrite(PIN_OPTOGEN_STIM, HIGH);
			sendEventMarker(EVENT_OPTO_STIM_ON, -1);	
		}
	}
	else
	{
		if (isOptogenStimOn())
		{
			digitalWrite(PIN_OPTOGEN_STIM, LOW);
			sendEventMarker(EVENT_OPTO_STIM_OFF, -1);
		}
	}
} 

bool isOptogenStimOn()
{
	return (digitalRead(PIN_OPTOGEN_STIM) == HIGH);
}

// Move lever (laterally) (to 1-based position index)
void setLeverPos(int position)
{
	if (position < 1 || position > 4)
	{
		return;
	}

	switch (position)
	{
		case 1: // 00
			digitalWrite(PIN_LEVERMOTOR_HI, LOW);
			digitalWrite(PIN_LEVERMOTOR_LO, LOW);
			sendEventMarker(EVENT_LEVERMOTOR_POS1_START, -1);
			break;
		case 2: // 01
			digitalWrite(PIN_LEVERMOTOR_HI, LOW);
			digitalWrite(PIN_LEVERMOTOR_LO, HIGH);
			sendEventMarker(EVENT_LEVERMOTOR_POS2_START, -1);
			break;
		case 3: // 10
			digitalWrite(PIN_LEVERMOTOR_HI, HIGH);
			digitalWrite(PIN_LEVERMOTOR_LO, LOW);
			sendEventMarker(EVENT_LEVERMOTOR_POS3_START, -1);
			break;
		case 4: // 11
			digitalWrite(PIN_LEVERMOTOR_HI, HIGH);
			digitalWrite(PIN_LEVERMOTOR_LO, HIGH);
			sendEventMarker(EVENT_LEVERMOTOR_POS4_START, -1);
			break;
	}
}

int getLeverPos()
{
	bool hi = digitalRead(PIN_LEVERMOTOR_HI);
	bool lo = digitalRead(PIN_LEVERMOTOR_LO);

	if (hi == LOW && lo == LOW)
	{
		return 1;
	}
	else if (hi == LOW && lo == HIGH)
	{
		return 2;
	}
	else if (hi == HIGH && lo == LOW)
	{
		return 3;
	}
	else // if (hi == HIGH && lo == HIGH)
	{
		return 4;
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