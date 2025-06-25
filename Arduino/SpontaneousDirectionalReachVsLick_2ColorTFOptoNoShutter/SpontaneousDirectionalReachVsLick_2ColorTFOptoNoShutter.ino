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
J - idle -> reward -> idle
*********************************************************************/

/*****************************************************
	Servo stuff
*****************************************************/
#include <PWMServo.h>
PWMServo  _servoLever;
PWMServo  _servoTube;
#define SERVO_READ_ACCURACY 2
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
#define PIN_SERVO_LEVER			20  // 14
#define PIN_SERVO_TUBE			14  // 15
#define PIN_OPTOGEN_STIM		23
#define PIN_LEVERMOTOR_HI		5
#define PIN_LEVERMOTOR_LO		6
// #define PIN_OPTO_1				15
// #define PIN_OPTO_2				16
#define PIN_LED_LEFT			8 // left LED (animal's perspective)
#define PIN_LED_RIGHT			11

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
#define PIN_LICK				_params[LICK_PIN]
#define PIN_LEVER				_params[LEVER_PIN]
#define PIN_LEVERMOTOR_BUSY		7
#define PIN_LASERMOTOR_BUSY		4

#define PIN_LICK_ACCEL 			A4
#define PIN_LEVER_ACCEL			A5

static const int _digOutPins[] = 
{
	PIN_REWARD,
	PIN_SERVO_LEVER,
	PIN_SERVO_TUBE,
	PIN_LEVERMOTOR_HI,
	PIN_LEVERMOTOR_LO,
	// PIN_OPTO_1,
	// PIN_OPTO_2,
	PIN_MIRROR_LICK,
	PIN_MIRROR_LEVER,
	PIN_MIRROR_REWARD,
	PIN_SPEAKER,
	PIN_LED_LEFT,
	PIN_LED_RIGHT,
	8,
	11
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
	STATE_TIMEOUT,
	STATE_REWARD,
	STATE_REQUEST_TASK,
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
	"TIMEOUT",
	"REWARD",
	"REQUEST_TASK",
	"REQUEST_OPTO",
	"OPTO",
};

// Define which states accept parameter update from MATLAB
static const int _stateCanUpdateParams[] = 
{
	0,	// _STATE_INIT
	1,	// STATE_IDLE
	1,	// STATE_WAITFORTOUCH
	1,	// STATE_TIMEOUT
	1,	// STATE_REWARD
	1,	// STATE_REQUEST_TASK
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
	EVENT_OPTO1_ON,					// Begin optogenetic stim (single pulse start) on laser 1 (dac1)
	EVENT_OPTO1_OFF,				// End optogenetic stim (single pulse end) on laser 1 (dac1)
	EVENT_OPTO2_ON,					// Begin optogenetic stim (single pulse start) on laser 2 (dac2)
	EVENT_OPTO2_OFF,				// End optogenetic stim (single pulse end) on laser 2 (dac2)
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
	"OPTO1_ON",				// Begin optogenetic stim (single pulse start) on laser 1 (dac1)
	"OPTO1_OFF",			// End optogenetic stim (single pulse end) on laser 1 (dac1)
	"OPTO2_ON",				// Begin optogenetic stim (single pulse start) on laser 2 (dac2)
	"OPTO2_OFF",			// End optogenetic stim (single pulse end) on laser 2 (dac2)
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
	CODE_CORRECT_LICK,
	CODE_CORRECT_PRESS_1,
	CODE_CORRECT_PRESS_2,
	CODE_CORRECT_PRESS_3,
	CODE_CORRECT_PRESS_4,
	CODE_TASK_CHANGE,
	CODE_OPTO,
	_NUM_RESULT_CODES
};

// We'll send result code translations to MATLAB at startup
static const char *_resultCodeNames[] =
{
	"CORRECT_LICK",
	"CORRECT_PRESS_1",
	"CORRECT_PRESS_2",
	"CORRECT_PRESS_3",
	"CORRECT_PRESS_4",
	"TASK_CHANGE",
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
	USE_LEVER, 						// 1 for lever task, 0 for lick task
	USE_LEFT_PAW,
	TIMEOUT_MIN,					// ITI length min cutoff (ms)
	TIMEOUT_MEAN,					// ITI length (mean of exponential distribution) (ms)
	TIMEOUT_MAX,					// ITI length max cutoff (ms)
	LEVER_HOLD_TIME,				// Lever contact must be maintained for this duration (ms) before reward dispensed..
	LEVER_RETRACT_TIME,				// Lever will be retracted for this duration before redeploying (start of retract to start of deploy)
	TUBE_RETRACT_TIME,				// Tube will be retracted for this duration before redeploying (start of retract to start of deploy)
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
	OPTO_LASER_ID, 					// 1 for DAC1 (blue laser), 2 for DAC2 (red laser), any other number for both!
	OPTO_AOUT1_VALUE,				// Analog output value to use for modulation of laser power
	OPTO_AOUT2_VALUE,				// Analog output value to use for modulation of laser power
	OPTO_PULSE_DURATION,			// Optogenetic stim, duration of single pulse (ms)
	OPTO_PULSE_INTERVAL,			// Optogenetic stim, interval between pulses (ms)
	OPTO_NUM_PULSES,				// Optogenetic stim, number of pulses to deliver	
	OPTO_FIXED_DELAY,				// In REQUEST_OPTO, after receiving ';' from MATLAB, wait this long before advancing to OPTO
	OPTO_RANDOM_DELAY_MIN,			// Minimum random pre-stim delay (ms)
	OPTO_RANDOM_DELAY_MAX,			// Maximum random pre-stim delay (ms)
	NUM_REWARDS_PER_BLOCK,			// A block ends after this many correct trials
	REQUEST_TASK_AFTER_BLOCK, 		// 1: Request new task parameters from MATLAB at the end of each block
	REQUEST_OPTO_AFTER_BLOCK,		// 1: Request new opto parameters from MATLAB at the end of each block.
	WAITFORTOUCH_TO_OPTO_TIMEOUT,	// Go to opto if this much time has elapsed in waitfortouch.
	LICK_PIN,
	LEVER_PIN,
	LOW_IS_TOUCH,					// 1: using janelia, 0: using teensybox
	ACCEL_BASED_LICK,				// 1: use accelerometer-based lick detection
	ACCEL_BASED_LEVER,				// 1: use accelerometer-based lever detection
	ACCEL_THRESHOLD_LICK,			// Accelerometer threshold for lick detection (HLF: I pulled out the Y channel of two accelerometers, fed into A4 and A5. Both are powered by teensy 3V3 and grounded to AGND)
	ACCEL_THRESHOLD_LEVER,			// Accelerometer threshold for lick detection (HLF: I pulled out the Y channel of two accelerometers, fed into A4 and A5. Both are powered by teensy 3V3 and grounded to AGND)
	ACCEL_SMOOTH_FACTOR_LICK,		// 0<alpha<1. Highpass is applied to accel Y before thresholding. To do high pass, we substract the low pass i.e., exponential smoothing: s0 = x0; s(t) = alpha*x(t) + (1-alpha)*s(t-1); 
	ACCEL_SMOOTH_FACTOR_LEVER,		// 0<alpha<1. Highpass is applied to accel Y before thresholding. To do high pass, we substract the low pass i.e., exponential smoothing: s0 = x0; s(t) = alpha*x(t) + (1-alpha)*s(t-1); 
	ACCEL_SMOOTH_SAMPLE_PERIOD_LICK,// in ms, sampling period for accelerometer
	ACCEL_SMOOTH_SAMPLE_PERIOD_LEVER,// in ms, sampling period for accelerometer
	ACCEL_BLANK_POST_MOVE_TUBE,  	// in ms, ignore accel-based-lick during tube deploy/retract and for this duration after STATE_DEPLOYED/STATE_RETRACTED
	ACCEL_BLANK_POST_MOVE_LEVER, 	// in ms, ignore accel-based-lever during lever deploy/retract and for this duration after STATE_DEPLOYED/STATE_RETRACTED	
	_NUM_PARAMS						// (Private) Used to count how many parameters there are so we can initialize the param array with the correct size. Insert additional parameters before this.
};

// Store parameter names as strings, will be sent to host
// Names cannot contain spaces!!!
static const char *_paramNames[] = 
{
	"_DEBUG",						// (Private) 1 to enable debug mode. Default 0.
	"USE_LEVER", 					// 1 for lever task, 0 for lick task
	"USE_LEFT_PAW",
	"TIMEOUT_MIN",					// ITI length min cutoff (ms)
	"TIMEOUT_MEAN",					// ITI length (mean of exponential distribution) (ms)
	"TIMEOUT_MAX",					// ITI length max cutoff (ms)
	"LEVER_HOLD_TIME",				// Lever contact must be maintained for this duration (ms) before reward dispensed..
	"LEVER_RETRACT_TIME",			// Lever will be retracted for this duration before redeploying (start of retract to start of deploy)
	"TUBE_RETRACT_TIME",			// Tube will be retracted for this duration before redeploying (start of retract to start of deploy)
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
	"OPTO_LASER_ID", 				// 1 for DAC1 (blue laser), 2 for DAC2 (red laser), any other number for both!
	"OPTO_AOUT1_VALUE",				// Analog output value to use for modulation of laser power
	"OPTO_AOUT2_VALUE",				// Analog output value to use for modulation of laser power
	"OPTO_PULSE_DURATION",			// Optogenetic stim, duration of single pulse (ms)
	"OPTO_PULSE_INTERVAL",			// Optogenetic stim, interval between pulses (ms)
	"OPTO_NUM_PULSES",				// Optogenetic stim, number of pulses to deliver	
	"OPTO_FIXED_DELAY",				// In REQUEST_OPTO, laser will be kept on this long before advancing to OPTO
	"OPTO_RANDOM_DELAY_MIN",		// Minimum random pre-stim delay (ms)
	"OPTO_RANDOM_DELAY_MAX",		// Maximum random pre-stim delay (ms)
	"NUM_REWARDS_PER_BLOCK",		// A block ends after this many correct trials
	"REQUEST_TASK_AFTER_BLOCK", 	// 1: Auto switch to other task (lick vs. lever) at the end of each block
	"REQUEST_OPTO_AFTER_BLOCK",		// 1: Go to opto at end of each block.
	"WAITFORTOUCH_TO_OPTO_TIMEOUT",	// Go to opto if this much time has elapsed in waitfortouch.
	"LICK_PIN",
	"LEVER_PIN",
	"LOW_IS_TOUCH",					// 1: using janelia, 0: using teensybox
	"ACCEL_BASED_LICK",				// 1: use accelerometer-based lick detection
	"ACCEL_BASED_LEVER",			// 1: use accelerometer-based lever detection
	"ACCEL_THRESHOLD_LICK",			// Accelerometer threshold for lick detection (HLF: I pulled out the Y channel of two accelerometers, fed into A4 and A5. Both are powered by teensy 3V3 and grounded to AGND)
	"ACCEL_THRESHOLD_LEVER",		// Accelerometer threshold for lick detection (HLF: I pulled out the Y channel of two accelerometers, fed into A4 and A5. Both are powered by teensy 3V3 and grounded to AGND)
	"ACCEL_SMOOTH_FACTOR_LICK",		// alpha=factor*1000, must satisfy: 0<alpha<1. Highpass is applied to accel Y before thresholding. To do high pass, we substract the low pass i.e., exponential smoothing: s0 = x0; s(t) = alpha*x(t) + (1-alpha)*s(t-1); 
	"ACCEL_SMOOTH_FACTOR_LEVER",	// alpha=factor*1000, must satisfy: 0<alpha<1. Highpass is applied to accel Y before thresholding. To do high pass, we substract the low pass i.e., exponential smoothing: s0 = x0; s(t) = alpha*x(t) + (1-alpha)*s(t-1); 
	"ACCEL_SMOOTH_SAMPLE_PERIOD_LICK",// in ms, sampling period for accelerometer
	"ACCEL_SMOOTH_SAMPLE_PERIOD_LEVER",// in ms, sampling period for accelerometer
	"ACCEL_BLANK_POST_MOVE_TUBE",  	// in ms, ignore accel-based-lick during tube deploy/retract and for this duration after STATE_DEPLOYED/STATE_RETRACTED
	"ACCEL_BLANK_POST_MOVE_LEVER", 	// in ms, ignore accel-based-lever during lever deploy/retract and for this duration after STATE_DEPLOYED/STATE_RETRACTED
};

// Initialize parameters
long _params[_NUM_PARAMS] = 
{
	0,		// _DEBUG
	1, 		// USE_LEVER
	0, 		// USE_LEFT_PAW
	0,		// TIMEOUT_MIN
	20000,	// TIMEOUT_MEAN
	10000,	// TIMEOUT_MAX
	0,		// LEVER_HOLD_TIME
	1000,	// LEVER_RETRACT_TIME
	1000, 	// TUBE_RETRACT_TIME
	100,	// REWARD_DURATION
	3000,	// MIN_REWARD_COLLECTION_TIME
	1000,	// EXTRA_LICK_TIME
	115,	// LEVER_POS_RETRACTED
	95,		// LEVER_POS_DEPLOYED
	36,		// LEVER_SPEED_DEPLOY
	36,		// LEVER_SPEED_RETRACT
	70,		// TUBE_POS_RETRACTED
	90,		// TUBE_POS_DEPLOYED
	36,		// TUBE_SPEED_DEPLOY
	36,		// TUBE_SPEED_RETRACT
	0,		// OPTO_ENABLED
	1,		// OPTO_LASER_ID
	0,		// OPTO_AOUT1_VALUE
	0,		// OPTO_AOUT2_VALUE
	10,		// OPTO_PULSE_DURATION
	500,	// OPTO_PULSE_INTERVAL
	10,		// OPTO_NUM_PULSES
	1000, 	// OPTO_FIXED_DELAY
	1000,	// OPTO_RANDOM_DELAY_MIN
	3000,	// OPTO_RANDOM_DELAY_MAX
	10,		// NUM_REWARDS_PER_BLOCK
	1,		// REQUEST_TASK_AFTER_BLOCK
	0,		// REQUEST_OPTO_AFTER_BLOCK
	30000,	// WAITFORTOUCH_TO_OPTO_TIMEOUT
	25, 	// LICK_PIN
	26, 	// LEVER_PIN
	0, 		// LOW_IS_TOUCH
	0,		// ACCEL_BASED_LICK
	0,		// ACCEL_BASED_LEVER
	0,		// ACCEL_THRESHOLD_LICK
	0,		// ACCEL_THRESHOLD_LEVER
	300,	// ACCEL_SMOOTH_FACTOR_LICK
	300,	// ACCEL_SMOOTH_FACTOR_LEVER
	1, 		// ACCEL_SMOOTH_SAMPLE_PERIOD_LICK
	1, 		// ACCEL_SMOOTH_SAMPLE_PERIOD_LEVER
	100,	// ACCEL_BLANK_POST_MOVE_TUBE
	100,	// ACCEL_BLANK_POST_MOVE_LEVER
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

static bool _isLicking 				= false;		// True if the little dude is licking (in contact with spout)
static bool _isLickOnset 			= false;		// True during lick onset (onset of spout contact)
static long _timeLastLick			= 0;			// Time (ms) when last lick onset occured

static bool _isLeverPressed			= false;		// True as long as lever is pressed down
static bool _isLeverHeld 			= false;
static bool _leverCyclingEnabled	= true;			// Lever will autocycle on touch
static bool _tubeCyclingEnabled		= true;			// Tube will autocycle on lick
static long _timeLastLeverPress		= 0;			// Time (ms) when last lever press occured
static long _timeLastLeverRelease	= 0;			// Time (ms) when last lever press occured
static long _timeLastLeverRetract 	= 0;			// Time (ms) when last lever retraction occured (due to touch)
static long _timeLastTubeRetract 	= 0;			// Time (ms) when last tube retraction occured (due to touch)
static bool _isLeverCycling 		= false;		// Only true when the bar is being recycled (from retract start to deploy end)
static bool _isTubeCycling			= false;		// Only true when the tube is being recycled (from retract start to deploy end)

static ServoState _servoStateTube	= _SERVOSTATE_INIT;				// Servo state
static long _servoStartTimeLever	= 0;							// When servo started moving retrieved using getTime()
static long _servoStopTimeLever		= 0;							// When servo started moving retrieved using getTime()
static long _servoSpeedLever		= _params[LEVER_SPEED_RETRACT]; // Speed of servo movement (deg/s)
static long _servoStartPosLever		= _params[LEVER_POS_RETRACTED];	// Starting position of servo when rotation begins
static long _servoTargetPosLever	= _params[LEVER_POS_RETRACTED];	// Target position of servo

static ServoState _servoStateLever 	= _SERVOSTATE_INIT;				// Servo state
static long _servoStartTimeTube		= 0;							// When servo started moving retrieved using getTime()
static long _servoStopTimeTube		= 0;							// When servo started moving retrieved using getTime()
static long _servoSpeedTube			= _params[TUBE_SPEED_RETRACT]; 	// Speed of servo movement (deg/s)
static long _servoStartPosTube		= _params[TUBE_POS_DEPLOYED];	// Starting position of servo when rotation begins
static long _servoTargetPosTube		= _params[TUBE_POS_DEPLOYED];	// Target position of servo

static int _nRewardsSinceBlockStart = 0;

static bool _isOpto1On = false;
static bool _isOpto2On = false;

static long _accelValueLick = 0;
static long _accelValueLever = 0;
static long _accelLowPassLick = 0;
static long _accelLowPassLever = 0;
static long _accelHighPassLick = 0;
static long _accelHighPassLever = 0;
static long _accelLastUpdateMillisLick = 0;
static long _accelLastUpdateMillisLever = 0;

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
	pinMode(15, INPUT);
	pinMode(16, INPUT);
	pinMode(25, INPUT);
	pinMode(26, INPUT);
	pinMode(PIN_LEVERMOTOR_BUSY, INPUT);		// High when motor is moving
	pinMode(PIN_LASERMOTOR_BUSY, INPUT);

	analogWriteResolution(ANALOG_WRITE_RESOLUTION);
	pinMode(PIN_LASER_PWR_1, OUTPUT);
	pinMode(PIN_LASER_PWR_2, OUTPUT);

	pinMode(PIN_LICK_ACCEL, INPUT);
	pinMode(PIN_LEVER_ACCEL, INPUT);

	// Initiate servo
	_servoLever.attach(PIN_SERVO_LEVER);
	_servoTube.attach(PIN_SERVO_TUBE);

	// Serial comms
	Serial.begin(115200);                       // Set up USB communication at 115200 baud 
}

void mySetup()
{
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

	_isLicking 				= false;		// True if the little dude is licking (in contact with spout)
	_isLickOnset 			= false;		// True during lick onset (onset of spout contact)
	_timeLastLick			= 0;			// Time (ms) when last lick onset occured

	_isLeverPressed			= false;		// True as long as lever is pressed down
	_isLeverHeld 			= false;
	_leverCyclingEnabled	= true;			// Lever will autocycle on touch
	_tubeCyclingEnabled		= true;			// Tube will autocycle on lick
	_timeLastLeverPress		= 0;			// Time (ms) when last lever press occured
	_timeLastLeverRelease	= 0;			// Time (ms) when last lever press occured
	_timeLastLeverRetract 	= 0;			// Time (ms) when last lever retraction occured (due to touch)
	_timeLastTubeRetract 	= 0;			// Time (ms) when last tube retraction occured (due to touch)
	_isLeverCycling 		= false;
	_isTubeCycling			= false;

	_servoStateTube			= _SERVOSTATE_INIT;				// Servo state
	_servoStartTimeLever	= 0;							// When servo started moving retrieved using getTime()
	_servoStopTimeLever		= 0;							// When servo started moving retrieved using getTime()
	_servoSpeedLever		= _params[LEVER_SPEED_RETRACT]; // Speed of servo movement (deg/s)
	_servoStartPosLever		= _params[LEVER_POS_RETRACTED];	// Starting position of servo when rotation begins
	_servoTargetPosLever	= _params[LEVER_POS_RETRACTED];	// Target position of servo

	_servoStateLever 		= _SERVOSTATE_INIT;				// Servo state
	_servoStartTimeTube		= 0;							// When servo started moving retrieved using getTime()
	_servoStopTimeTube		= 0;							// When servo started moving retrieved using getTime()
	_servoSpeedTube			= _params[TUBE_SPEED_RETRACT]; 	// Speed of servo movement (deg/s)
	_servoStartPosTube		= _params[TUBE_POS_DEPLOYED];	// Starting position of servo when rotation begins
	_servoTargetPosTube		= _params[TUBE_POS_DEPLOYED];	// Target position of servo

	_nRewardsSinceBlockStart = 0;
	_isOpto1On = false;
	_isOpto2On = false;

	_accelValueLick = 0;
	_accelValueLever = 0;
	_accelLowPassLick = analogRead(PIN_LICK_ACCEL);
	_accelLowPassLever = analogRead(PIN_LEVER_ACCEL);
	_accelHighPassLick = 0;
	_accelHighPassLever = 0;
	_accelLastUpdateMillisLick = 0;
	_accelLastUpdateMillisLever = 0;

	// Sends all parameters, states and error codes to Matlab, then tell PC that we're running by sending '~' message:
	hostInit();

	// Set laser analog modulation to 0
	setOptogenStim(1, false);					// Optogenetic stim OFF
	setOptogenStim(2, false);					// Optogenetic stim OFF
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
		handleAccelLick();
		handleAccelLever();
		handleLick();			// Check for licks on/offset
		handleLever();			// Check for lever press on/offset
		handleServoTube();		// Tube servo control
		handleServoLever();		// Lever servo control
		handleParamUpdate();	// Writes to _isUpdatingParams
		handleAnalogOutput();	// Write to DAC channels to modulate laser pwoer

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

			case STATE_WAITFORTOUCH:
				state_waitfortouch();
				break;
			
			case STATE_TIMEOUT:
				state_timeout();
				break;

			case STATE_REWARD:
				state_reward();
				break;

			case STATE_REQUEST_TASK:
				state_request_task();
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
		setOptogenStim(1, false);
		setOptogenStim(2, false);
		noTone(PIN_SPEAKER);
		setReward(false);
		_leverCyclingEnabled = true;
		_tubeCyclingEnabled = true;
		deployLever(true);
		deployTube(true);
		setLeverPos(1);
		_resultCode = -1;
		_isUpdatingParams = false;
		_nRewardsSinceBlockStart = 0;
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

	// J for manual reward while in IDLE (will deploy tube, deliver juice then retract, return to IDLE)
	if (_command == 'J')
	{
		_state = STATE_REWARD;
		return;
	}

	_state = STATE_IDLE;
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

		_leverCyclingEnabled = false;
		_tubeCyclingEnabled = false;
		// Lick task: keep lever retracted
		if (_params[USE_LEVER] == 0)
		{
			deployLever(false);
			deployTube(true);
		}
		// Reach task: keep lever retracted
		else
		{
			deployLever(true);
			deployTube(false);
		}

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
	// Lick task
	if (_params[USE_LEVER] == 0)
	{
		if (getLickState())
		{
			_state = STATE_REWARD;
			return;
		}
	}
	// Lever task
	else
	{
		if (_isLeverHeld)
		{
			_state = STATE_REWARD;
			return;
		}
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
	INTERTRIAL
*****************************************************/
void state_timeout()
{
	static long timeoutDuration;
	static bool isWaitingForLeverCycling;
	static bool isWaitingForTubeCycling;
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		sendState(_state);

		// Lick task: keep lever retracted
		// STATE_REWARD
		// STATE_REQUEST_TASK
		// STATE_REQUEST_OPTO
		// STATE_OPTO
		if (_params[USE_LEVER] == 0)
		{
			_leverCyclingEnabled = false;
			_tubeCyclingEnabled = true;
			deployLever(false);
		}
		// Reach task: keep lever retracted
		else
		{
			_leverCyclingEnabled = true;
			_tubeCyclingEnabled = false;
			deployTube(false);
		}

		isWaitingForLeverCycling = _params[USE_LEVER] != 0 && _isLeverCycling;
		isWaitingForTubeCycling = _params[USE_LEVER] == 0 && _isTubeCycling;

		// Lever task and waiting for lever cycling
		if (!isWaitingForLeverCycling && !isWaitingForTubeCycling)
		{
			// Register events
			sendEventMarker(EVENT_TIMEOUT_START, -1);
			_timeTrialEnd = getTime();

			// Generate random interval length from exponential distribution
			// CDF  p=F(x|μ)=1-exp(-x/μ);
			// Inverse CDF is x=F^(−1)(p∣μ)=−μln(1−p).
			// For each draw, we let p = uniform_rand(0, 1), get corresponding value x from inverse CDF.
			timeoutDuration = -1*_params[TIMEOUT_MEAN]*log(1.0 - ((float)random(1UL << 31)) / (1UL << 31));
			// Apply min/max cutoffs
			timeoutDuration = max(timeoutDuration, _params[TIMEOUT_MIN]);
			timeoutDuration = min(timeoutDuration, _params[TIMEOUT_MAX]);
		}

		// Update state
		_prevState = _state;
	}

	/*****************************************************
		OnEachLoop checks
	*****************************************************/
	// If lever is cycling, wait for it to finish cycling
	if (!isWaitingForLeverCycling)
	{
		// Check if flag needs to be set to true
		isWaitingForLeverCycling = _params[USE_LEVER] != 0 && _isLeverCycling;
	}
	// When lever is done cycling, we draw a new timeout interval
	else if (!_isLeverCycling)
	{
		isWaitingForLeverCycling = false;

		// Generate random interval length from exponential distribution
		// CDF  p=F(x|μ)=1-exp(-x/μ);
		// Inverse CDF is x=F^(−1)(p∣μ)=−μln(1−p).
		// For each draw, we let p = uniform_rand(0, 1), get corresponding value x from inverse CDF.
		timeoutDuration = -1*_params[TIMEOUT_MEAN]*log(1.0 - ((float)random(1UL << 31)) / (1UL << 31));
		// Apply min/max cutoffs
		timeoutDuration = max(timeoutDuration, _params[TIMEOUT_MIN]);
		timeoutDuration = min(timeoutDuration, _params[TIMEOUT_MAX]);

		// Register events
		sendEventMarker(EVENT_TIMEOUT_START, -1);
		_timeTrialEnd = getTime();
	}

	// If tube is cycling, wait for it to finish cycling
	if (!isWaitingForTubeCycling)
	{
		// Check if flag needs to be set to true
		isWaitingForTubeCycling = _params[USE_LEVER] == 0 && _isTubeCycling;
	}
	// When tube is done cycling, we draw a new timeout interval
	else if (!_isTubeCycling)
	{
		isWaitingForTubeCycling = false;

		// Generate random interval length from exponential distribution
		// CDF  p=F(x|μ)=1-exp(-x/μ);
		// Inverse CDF is x=F^(−1)(p∣μ)=−μln(1−p).
		// For each draw, we let p = uniform_rand(0, 1), get corresponding value x from inverse CDF.
		timeoutDuration = -1*_params[TIMEOUT_MEAN]*log(1.0 - ((float)random(1UL << 31)) / (1UL << 31));
		// Apply min/max cutoffs
		timeoutDuration = max(timeoutDuration, _params[TIMEOUT_MIN]);
		timeoutDuration = min(timeoutDuration, _params[TIMEOUT_MAX]);

		// Register events
		sendEventMarker(EVENT_TIMEOUT_START, -1);
		_timeTrialEnd = getTime();
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

	if (!isWaitingForLeverCycling && !isWaitingForTubeCycling && getTimeSinceTrialEnd() >= timeoutDuration)
	{			
		_state = STATE_WAITFORTOUCH;
		return;
	}

	_state = STATE_TIMEOUT;
}

/*****************************************************
	REWARD - Present juice for some time
*****************************************************/
void state_reward()
{
	static State entryState;
	static long timeRewardOn;
	static bool isRewardComplete;
	static bool isTubeRetracted;
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		entryState = _prevState;
		_prevState = _state;
		sendState(_state);

		// Send results
		if (_params[USE_LEVER] == 0)
		{
			_resultCode = CODE_CORRECT_LICK;
		}
		else
		{
			int leverPos = getLeverPos();
			switch (leverPos)
			{
				case 1:
					_resultCode = CODE_CORRECT_PRESS_1;
					break;
				case 2:
					_resultCode = CODE_CORRECT_PRESS_2;
					break;
				case 3:
					_resultCode = CODE_CORRECT_PRESS_3;
					break;
				case 4:
					_resultCode = CODE_CORRECT_PRESS_4;
					break;
			}
		}
		sendResultCode(_resultCode);


		// Increment reward count
		_nRewardsSinceBlockStart++;

		noTone(PIN_SPEAKER);
		tone(PIN_SPEAKER, TONE_REWARD, _params[REWARD_DURATION]);

		// Deploy spout and dispense reward
		timeRewardOn = getTime();
		isRewardComplete = false;
		isTubeRetracted = false;

		if (_params[REWARD_DURATION] > 0)
		{
			_tubeCyclingEnabled = false;
			deployTube(true);
			// Lever task: keep lever deployed
			if (_params[USE_LEVER] != 0)
			{
				_leverCyclingEnabled = false;
				deployLever(true);
			}

			setReward(true);
		}
	}

	/*****************************************************
		OnEachLoop checks
	*****************************************************/
	// Turn off reward when the time comes
	if (!isRewardComplete && getTime() - timeRewardOn >= _params[REWARD_DURATION])
	{
		isRewardComplete = true;
		if (_params[REWARD_DURATION] > 0)
		{
			setReward(false);
		}
	}

	// Retract lick tube (and/or lever) when the time comes
	if (!isTubeRetracted && getTime() - timeRewardOn >= _params[MIN_REWARD_COLLECTION_TIME] && getTimeSinceLastLick() >= _params[EXTRA_LICK_TIME])
	{
		isTubeRetracted = true;
		// Lever task: retract lever and tube
		if (_params[USE_LEVER] != 0)
		{
			_leverCyclingEnabled = true;
			deployLever(false);
			_tubeCyclingEnabled = false;
			deployTube(false);
		}
		// Lick task: retract tube
		else
		{
			_tubeCyclingEnabled = true;
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

	// Reward dispensed and tube retracted fully --> TIMEOUT
	if (isRewardComplete && isTubeRetracted && ((_params[USE_LEVER] != 0 && _servoStateLever == SERVOSTATE_RETRACTED) || (_params[USE_LEVER] == 0 && _servoStateTube == SERVOSTATE_RETRACTED)))
	{
		// IDLE
		if (entryState == STATE_IDLE)
		{
			_state = STATE_IDLE;
			return;
		}
		// REQUEST_TASK
		if (_nRewardsSinceBlockStart >= _params[NUM_REWARDS_PER_BLOCK])
		{
			_nRewardsSinceBlockStart = 0;
			if (_params[REQUEST_TASK_AFTER_BLOCK] != 0)
			{
				_state = STATE_REQUEST_TASK;
			}
			else if (_params[REQUEST_OPTO_AFTER_BLOCK] != 0)
			{
				_state = STATE_REQUEST_OPTO;
			}
			else
			{
				_state = STATE_TIMEOUT;
			}
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
	ASK MATLAB for new lever position and task parameters (switch to lick e.g.)
*****************************************************/
void state_request_task()
{
	static long timeTaskReceived;
	static bool taskReceived;
	static int leverPos;
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);

		// Retract lever/tube and disable auto-cycling
		_tubeCyclingEnabled = false;
		_leverCyclingEnabled = false;
		deployTube(false);
		deployLever(false);

		// Send message to MATLAB to request new lever position
		taskReceived = false;
		leverPos = -1;
		sendMessage("^");
	}

	/*****************************************************
		OnEachLoop checks
	*****************************************************/
	// Receiver motor position from MATLAB
	// ^ [(1-4)leverPosIndex]
	if (_command == '^')
	{
		taskReceived = true;

		leverPos = _arguments[0];
		timeTaskReceived = getTime();
		// 0: lick task, 1-4: directional reach task
		if (leverPos > 0)
		{
			setLeverPos(leverPos);			
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

	// Lever reached target --> REQUEST OPTO
	// Wait at least 100ms for motor command to reach motor arduino
	// I've tried waiting as little as 1ms before: that worked as well.
	if (taskReceived && getTime() - timeTaskReceived > 100)
	{
		if (leverPos == 0 || digitalRead(PIN_LEVERMOTOR_BUSY) == LOW)
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

			_resultCode = CODE_TASK_CHANGE;
			sendResultCode(_resultCode);

			if (_params[OPTO_ENABLED] == 0)
			{
				if (_params[USE_LEVER] != 0)
				{
					_leverCyclingEnabled = true;
				}
				else
				{
					_tubeCyclingEnabled = true;
				}
				_state = STATE_TIMEOUT;
				return;
			}
			else if (_params[REQUEST_OPTO_AFTER_BLOCK] != 0)
			{
				_state = STATE_REQUEST_OPTO;
				return;
			}
			else
			{
				_state = STATE_OPTO;
				return;
			}
		}
	}

	_state = STATE_REQUEST_TASK;
}

/*****************************************************
	REQUEST OPTO (MOVES LASER MOTOR, TURNS ON LASER and all that)
*****************************************************/
void state_request_opto()
{
	static long timeRequest;
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

		// Retract lever/tube and disable auto-cycling
		_tubeCyclingEnabled = false;
		_leverCyclingEnabled = false;
		deployTube(false);
		deployLever(false);

		sendMessage(";"); // Request opto, tell MATLAB to move the laser mirror
		timeRequest = getTime();
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
			if (_params[USE_LEVER] != 0)
			{
				_leverCyclingEnabled = true;
			}
			else
			{
				_tubeCyclingEnabled = true;
			}
			_state = STATE_TIMEOUT;
			return;
		}
		else
		{
			isOptoAvailable = true;
		}
	}

	// Make sure the motor has finished moving, since MATLAB does not monitor this
	if (isOptoAvailable && getTime() - timeRequest > 500 && digitalRead(PIN_LASERMOTOR_BUSY) == LOW)
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
		// Write down previous state, return to it when done
		entryState = _prevState;

		// Register new state
		_prevState = _state;
		sendState(_state);

		// Turn off opto
		setOptogenStim(1, false);
		setOptogenStim(2, false);

		// Retract lever/tube and disable auto-cycling
		_tubeCyclingEnabled = false;
		_leverCyclingEnabled = false;
		deployTube(false);
		deployLever(false);

		// Generate random interval length
		if (entryState != STATE_IDLE)
		{
			randomDelayPre = random(_params[OPTO_RANDOM_DELAY_MIN], _params[OPTO_RANDOM_DELAY_MAX]) + _params[OPTO_FIXED_DELAY];
			randomDelayPost = random(_params[OPTO_RANDOM_DELAY_MIN], _params[OPTO_RANDOM_DELAY_MAX]) + _params[OPTO_FIXED_DELAY];
		}
		else
		{
			randomDelayPre = 0;
			randomDelayPost = 0;
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
		if (!isOptogenStimOn(_params[OPTO_LASER_ID]))
		{
			// Delay first pulse by random interval unless manually opto-ing in IDLE.
			if (entryState == STATE_IDLE || getTime() - timeEnter >= randomDelayPre)
			{
				if (numPulsesComplete == 0 || getTime() - timePulseEnd >= _params[OPTO_PULSE_INTERVAL])
				{
					setOptogenStim(_params[OPTO_LASER_ID], true);
					timePulseStart = getTime();
				}
			}
		}
		// If stim is on, check if it needs to be turned off
		else if (getTime() - timePulseStart >= _params[OPTO_PULSE_DURATION])
		{
			setOptogenStim(_params[OPTO_LASER_ID], false);
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
		setOptogenStim(1, false);
		setOptogenStim(2, false);
		_state = STATE_IDLE;
		return;
	}

	// Stim train complete --> TIMEOUT (after random delay) or IDLE
	if (numPulsesComplete >= _params[OPTO_NUM_PULSES])
	{
		// Return after random delay, unless manually triggering opto from IDLE
		if (entryState == STATE_IDLE)
		{
			_state = STATE_IDLE;
			return;
		}
		else
		{
			if (getTime() - timePulseEnd >= randomDelayPost)
			{
				_resultCode = CODE_OPTO;
				sendResultCode(_resultCode);

				if (_params[USE_LEVER] != 0)
				{
					_leverCyclingEnabled = true;
				}
				else
				{
					_tubeCyclingEnabled = true;
				}
				_state = STATE_TIMEOUT;
				return;
			}
		}
	}

	_state = STATE_OPTO;
}


/*****************************************************
	HARDWARE CONTROLS
*****************************************************/
// Lever detection
bool getLeverState() 
{
	if (_params[ACCEL_BASED_LEVER])
	{
		if (_params[ACCEL_BLANK_POST_MOVE_LEVER] >= 0)
		{
			if (_servoStateLever == SERVOSTATE_DEPLOYING || _servoStateLever == SERVOSTATE_RETRACTING)
			{
				digitalWrite(PIN_MIRROR_LEVER, LOW);
				return false;
			}
			if (getTime() <= _servoStopTimeLever + _params[ACCEL_BLANK_POST_MOVE_LEVER])
			{
				digitalWrite(PIN_MIRROR_LEVER, LOW);
				return false;
			}
		}

		if (_accelHighPassLever >= _params[ACCEL_THRESHOLD_LEVER]) 
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
	else if (_params[LOW_IS_TOUCH] == 0)
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
	else
	{
		if (digitalRead(PIN_LEVER) == LOW) 
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
}

// Lick detection
bool getLickState() 
{
	if (_params[ACCEL_BASED_LICK])
	{
		if (_params[ACCEL_BLANK_POST_MOVE_TUBE] >= 0)
		{
			if (_servoStateTube == SERVOSTATE_DEPLOYING || _servoStateTube == SERVOSTATE_RETRACTING)
			{
				digitalWrite(PIN_MIRROR_LICK, LOW);
				return false;
			}
			if (getTime() <= _servoStopTimeTube + _params[ACCEL_BLANK_POST_MOVE_TUBE])
			{
				digitalWrite(PIN_MIRROR_LICK, LOW);
				return false;
			}
		}

		if (_accelHighPassLick >= _params[ACCEL_THRESHOLD_LICK]) 
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
	else if (_params[LOW_IS_TOUCH] == 0)
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
	else
	{
		if (digitalRead(PIN_LICK) == LOW) 
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
			if (_leverCyclingEnabled)
			{
				deployLever(false);
				_timeLastLeverRetract = getTime();
				_isLeverCycling = true;
			}
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

	if (_leverCyclingEnabled)
	{
		// Redeploy lever
		if ((_servoStateLever != SERVOSTATE_DEPLOYED && _servoStateLever != SERVOSTATE_DEPLOYING) && getTimeSinceLastLeverRetract() >= _params[LEVER_RETRACT_TIME])
		{
			deployLever(true);
		}
		if (_isLeverCycling && _servoStateLever == SERVOSTATE_DEPLOYED)
		{
			_isLeverCycling = false;
		}
	}
	else
	{
		_isLeverCycling = false;
	}
}

// Must be called once and only once on each loop. Returns true during lick onset
void handleLick() 
{
	// Spout contact
	if (getLickState())
	{
		// Onset
		if (!_isLicking)
		{
			_isLicking = true;
			_isLickOnset = true;
			_timeLastLick = getTime();
			sendEventMarker(EVENT_LICK, -1);
			if (_tubeCyclingEnabled)
			{
				deployTube(false);
				_timeLastTubeRetract = getTime();
				_isTubeCycling = true;
			}
		}
	}
	// not in contact
	else
	{
		_isLickOnset = false;
		// Offset
		if (_isLicking)
		{
			_isLicking = false;
			sendEventMarker(EVENT_LICK_OFF, -1);
		}
	}

	if (_tubeCyclingEnabled)
	{
		if ((_servoStateTube != SERVOSTATE_DEPLOYED && _servoStateTube != SERVOSTATE_DEPLOYING) && getTimeSinceLastTubeRetract() >= _params[TUBE_RETRACT_TIME])
		{
			deployTube(true);
		}
		if (_isTubeCycling && _servoStateTube == SERVOSTATE_DEPLOYED)
		{
			_isTubeCycling = false;
		}
	}
	else
	{
		_isTubeCycling = false;
	}
}

void handleAccelLick()
{
	static float alpha;

	if (getTime() - _accelLastUpdateMillisLick >= _params[ACCEL_SMOOTH_SAMPLE_PERIOD_LICK])
	{
		alpha = ((float)_params[ACCEL_SMOOTH_FACTOR_LICK]) / 1000.0;
		_accelValueLick = analogRead(PIN_LICK_ACCEL);
		_accelLowPassLick = alpha*_accelValueLick + (1-alpha)*_accelLowPassLick;
		_accelHighPassLick = _accelValueLick - _accelLowPassLick;
		_accelLastUpdateMillisLick = getTime();

		sendDebugMessage("ALK: " + String(_accelValueLick) + String(_accelLowPassLick) + String(_accelHighPassLick));
	}
}

void handleAccelLever()
{
	static float alpha;

	if (getTime() - _accelLastUpdateMillisLever >= _params[ACCEL_SMOOTH_SAMPLE_PERIOD_LEVER])
	{
		alpha = ((float)_params[ACCEL_SMOOTH_FACTOR_LEVER]) / 1000.0;
		_accelValueLever = analogRead(PIN_LEVER_ACCEL);
		_accelLowPassLever = alpha*_accelValueLever + (1-alpha)*_accelLowPassLever;
		_accelHighPassLever = _accelValueLever - _accelLowPassLever;
		_accelLastUpdateMillisLever = getTime();

		sendDebugMessage("ALK: " + String(_accelValueLever) + String(_accelLowPassLever) + String(_accelHighPassLever));		
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
		// _servoLever.write(_servoTargetPosLever);
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
		_servoTargetPosLever = _params[LEVER_POS_RETRACTED];;
		_timeLastLeverRetract = getTime();
		// _servoLever.write(_servoTargetPosLever);
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
		// _servoTube.write(_servoTargetPosTube);
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
		_servoTargetPosTube = _params[TUBE_POS_RETRACTED];;
		_timeLastTubeRetract = getTime();
		// _servoTube.write(_servoTargetPosTube);
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
	if (_servoSpeedLever == 0 && abs(_servoLever.read() - _servoTargetPosLever) <= SERVO_READ_ACCURACY)
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
		_servoStopTimeTube = getTime();
		_servoStateTube = SERVOSTATE_DEPLOYED;
		sendEventMarker(EVENT_TUBE_DEPLOY_END, -1);
	}

	if (_servoStateTube == SERVOSTATE_RETRACTING && abs(_servoTube.read() - _params[TUBE_POS_RETRACTED]) <= SERVO_READ_ACCURACY)
	{
		_servoStopTimeLever = getTime();
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
// Always writes, only emits event on value change
void setOptogenStim(int channel, bool turnOn) 
{
	// Do both channels if not specified
	if (channel != 1 && channel != 2)
	{
		setOptogenStim(1, turnOn);
		setOptogenStim(2, turnOn);
		return;
	}

	if (turnOn)
	{
		if (!isOptogenStimOn(channel))
		{
			switch (channel)
			{
				case 1:
					sendEventMarker(EVENT_OPTO1_ON, -1);
					break;
				case 2:
					sendEventMarker(EVENT_OPTO2_ON, -1);
					break;
			}
		}
		switch (channel)
		{
			case 1:
				setAnalogOutput(1, _params[OPTO_AOUT1_VALUE]);
				_isOpto1On = true;
				// digitalWrite(PIN_OPTO_1, HIGH);
				break;
			case 2:
				setAnalogOutput(2, _params[OPTO_AOUT2_VALUE]);
				_isOpto2On = true;
				// digitalWrite(PIN_OPTO_2, HIGH);
				break;
		}
	}
	else
	{
		if (isOptogenStimOn(channel))
		{
			switch (channel)
			{
				case 1:
					sendEventMarker(EVENT_OPTO1_OFF, -1);
					break;
				case 2:
					sendEventMarker(EVENT_OPTO2_OFF, -1);	
					break;
			}
		}
		switch (channel)
		{
			case 1:
				setAnalogOutput(1, 0);
				_isOpto1On = false;
				// digitalWrite(PIN_OPTO_1, LOW);
				break;
			case 2:
				setAnalogOutput(2, 0);
				_isOpto2On = false;
				// digitalWrite(PIN_OPTO_2, LOW);
				break;
		}
	}
}

bool isOptogenStimOn(int channel)
{
	switch (channel)
	{
		case 1:
			// return (digitalRead(PIN_OPTO_1) == HIGH);
			return _isOpto1On;
		case 2:
			// return (digitalRead(PIN_OPTO_2) == HIGH);
			return _isOpto2On;
		default:
			return (_isOpto1On || _isOpto2On);
			// return (digitalRead(PIN_OPTO_1) == HIGH || digitalRead(PIN_OPTO_2) == HIGH);
	}
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
			if (_params[USE_LEVER] == 0)
			{
				digitalWrite(PIN_LED_LEFT, LOW);
				digitalWrite(PIN_LED_RIGHT, LOW);
			}
			else
			{
				if (_params[USE_LEFT_PAW] == 0)
				{
					digitalWrite(PIN_LED_LEFT, LOW);
					digitalWrite(PIN_LED_RIGHT, HIGH);
				}
				else
				{
					digitalWrite(PIN_LED_LEFT, HIGH);
					digitalWrite(PIN_LED_RIGHT, LOW);
				}
			}
			break;
		case 2: // 01
			digitalWrite(PIN_LEVERMOTOR_HI, LOW);
			digitalWrite(PIN_LEVERMOTOR_LO, HIGH);
			sendEventMarker(EVENT_LEVERMOTOR_POS2_START, -1);
			if (_params[USE_LEVER] == 0)
			{
				digitalWrite(PIN_LED_LEFT, LOW);
				digitalWrite(PIN_LED_RIGHT, LOW);
			}
			else
			{
				if (_params[USE_LEFT_PAW] == 0)
				{
					digitalWrite(PIN_LED_LEFT, HIGH);
					digitalWrite(PIN_LED_RIGHT, LOW);
				}
				else
				{
					digitalWrite(PIN_LED_LEFT, LOW);
					digitalWrite(PIN_LED_RIGHT, HIGH);
				}
			}
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

			// Toggle left/right green LEDs on param change
			if (_arguments[0] == USE_LEFT_PAW || _arguments[0] == USE_LEVER)
			{
				int position = getLeverPos();	
				switch (position)
				{
					case 1: // 00
						if (_params[USE_LEVER] == 0)
						{
							digitalWrite(PIN_LED_LEFT, LOW);
							digitalWrite(PIN_LED_RIGHT, LOW);
						}
						else
						{
							if (_params[USE_LEFT_PAW] == 0)
							{
								digitalWrite(PIN_LED_LEFT, LOW);
								digitalWrite(PIN_LED_RIGHT, HIGH);
							}
							else
							{
								digitalWrite(PIN_LED_LEFT, HIGH);
								digitalWrite(PIN_LED_RIGHT, LOW);
							}
						}
						break;
					case 2: // 01
						if (_params[USE_LEVER] == 0)
						{
							digitalWrite(PIN_LED_LEFT, LOW);
							digitalWrite(PIN_LED_RIGHT, LOW);
						}
						else
						{
							if (_params[USE_LEFT_PAW] == 0)
							{
								digitalWrite(PIN_LED_LEFT, HIGH);
								digitalWrite(PIN_LED_RIGHT, LOW);
							}
							else
							{
								digitalWrite(PIN_LED_LEFT, LOW);
								digitalWrite(PIN_LED_RIGHT, HIGH);
							}
						}
						break;
				}
			}
		}

		// Parameter transmission complete:
		if (_command == 'O') 
		{
			_isUpdatingParams = false;
		}	
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

long getTimeSinceLastTubeRetract()
{
	long time = getTime() - _timeLastTubeRetract;
	return time;
}