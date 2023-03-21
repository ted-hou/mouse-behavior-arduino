#include <Servo.h>
/*********************************************************************
	Arduino state machine
	Delayed lever press task (w/ retractable lever)
*********************************************************************/

/*****************************************************
	Servo stuff
*****************************************************/
Servo _servoLever;
Servo _servoTube;

/*****************************************************
	Arduino Pin Outs
*****************************************************/
// Digital OUT
#define PIN_HOUSE_LAMP			15
#define PIN_HOUSE_LAMP_2		20
#define PIN_LED_CUE				8
#define PIN_REWARD				12
#define PIN_OPTOGEN_STIM		23
#define PIN_OPTOGEN_GALVO		11
#define PIN_MOTOR_CONTROLLER_1	5
#define PIN_MOTOR_CONTROLLER_2	6
#define PIN_MOTOR_BUSY			7

// Mirrors to blackrock
#define PIN_MIRROR_LICK 		9
#define PIN_MIRROR_LEVER 		10
#define PIN_MIRROR_REWARD		22

// PWM OUT
#define PIN_SPEAKER				21
#define PIN_SERVO_LEVER			14
#define PIN_SERVO_TUBE			4

// Digital IN
#define PIN_LICK				25
#define PIN_LEVER				26

#define SERVO_READ_ACCURACY 1

static const int _digOutPins[] = {15, 20, 8, 22, 23, 11, 5, 6, 7, 9, 10, 22, 21};

/*****************************************************
	Enums - DEFINE States
*****************************************************/
// All the states
enum State
{
	_STATE_INIT,			// (Private) Initial state used on first loop. 
	STATE_IDLE,				// Idle state. Wait for go signal from host.
	STATE_INTERTRIAL,		// House lamps ON (if not already), write data to HOST and DISK, receive new params
	STATE_PRE_CUE,			// Deploy lever/tube 
	STATE_PRE_WINDOW,		// (+/-) Enforced no lick before response window opens
	STATE_RESPONSE_WINDOW,	// First lick in this interval rewarded (operant). Reward delivered at target time (pavlov)
	STATE_REWARD,			// Dispense reward, wait for trial timeout
	STATE_ABORT,			// Pre window lick - House lamps ON, timeout
	STATE_OPTOGEN_STIM,		// Optogenetic stimulation
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
	"ABORT",
	"OPTOGEN_STIM"
};

// Define which states accept parameter update from MATLAB
static const int _stateCanUpdateParams[] = {0,1,1,0,0,0,0,0,0}; 

/*****************************************************
	Event Markers
*****************************************************/
enum EventMarker
{
	EVENT_TRIAL_START,				// New trial initiated
	EVENT_WINDOW_OPEN,				// Response window open
	EVENT_TARGET_TIME,				// Target time
	EVENT_WINDOW_CLOSED,			// Response window closed
	EVENT_LEVER_PRESSED,			// Lever press onset
	EVENT_LEVER_RELEASED,			// Lever press offset
	EVENT_LEVER_RETRACT_START,		// Lever retract start
	EVENT_LEVER_RETRACT_END,		// Lever retracted
	EVENT_LEVER_DEPLOY_START,		// Lever deploy start
	EVENT_LEVER_DEPLOY_END,			// Lever deploy end
	EVENT_TUBE_RETRACT_START,		// Tube retract start
	EVENT_TUBE_RETRACT_END,			// Tube retract end
	EVENT_TUBE_DEPLOY_START,		// Tube deploy start
	EVENT_TUBE_DEPLOY_END,			// Tube deploy end
	EVENT_LICK,						// Lick onset
	EVENT_LICK_OFF,					// Lick offset
	EVENT_CUE_ON,					// Begin tone/LED cue presentation
	EVENT_CUE_OFF,					// End tone/LED cue presentation
	EVENT_HOUSELAMP_ON,				// House lamp on
	EVENT_HOUSELAMP_OFF,			// House lamp off
	EVENT_REWARD_ON,				// Reward, juice valve on
	EVENT_REWARD_OFF,				// Reward, juice valve off
	EVENT_ABORT,					// Trial aborted
	EVENT_ITI,						// ITI
	EVENT_OPTOGEN_STIM_ON,			// Begin optogenetic stim (single pulse start)
	EVENT_OPTOGEN_STIM_OFF,			// End optogenetic stim (single pulse end)
	EVENT_OPTOGEN_STIM_START,		// Begin optogenetic stim (pulse train start)
	EVENT_OPTOGEN_STIM_END,			// End optogenetic stim (pulse train end)
	EVENT_OPTOGEN_GALVO_ON,			// Begin galvo voltage
	EVENT_OPTOGEN_GALVO_OFF,		// End galvo voltage
	EVENT_MOTOR_POS_1_STARTED,
	EVENT_MOTOR_POS_2_STARTED,
	EVENT_MOTOR_POS_3_STARTED,
	EVENT_MOTOR_POS_4_STARTED,
	EVENT_MOTOR_POS_1_REACHED,
	EVENT_MOTOR_POS_2_REACHED,
	EVENT_MOTOR_POS_3_REACHED,
	EVENT_MOTOR_POS_4_REACHED,
	_NUM_EVENT_MARKERS
};

static const char *_eventMarkerNames[] =
{
	"TRIAL_START",					// New trial initiated
	"WINDOW_OPEN",					// Response window open
	"TARGET_TIME",					// Target time
	"WINDOW_CLOSED",				// Response window closed
	"LEVER_PRESSED",				// Lever press onset
	"LEVER_RELEASED",				// Lever press offset
	"LEVER_RETRACT_START",			// Lever retract start
	"LEVER_RETRACT_END",			// Lever retracted
	"LEVER_DEPLOY_START",			// Lever deploy start
	"LEVER_DEPLOY_END",				// Lever deploy end
	"TUBE_RETRACT_START",			// Tube retract start
	"TUBE_RETRACT_END",				// Tube retract end
	"TUBE_DEPLOY_START",			// Tube deploy start
	"TUBE_DEPLOY_END",				// Tube deploy end
	"LICK",							// Lick onset
	"LICK_OFF",						// Lick offset
	"CUE_ON",						// Begin tone/LED cue presentation
	"CUE_OFF",						// End tone/LED cue presentation
	"HOUSELAMP_ON",					// House lamp on
	"HOUSELAMP_OFF",				// House lamp off
	"REWARD_ON",					// Reward, juice valve on
	"REWARD_OFF",					// Reward, juice valve off
	"ABORT",						// Trial aborted
	"ITI",							// ITI
	"OPTOGEN_STIM_ON",				// Begin optogenetic stim (single pulse start)
	"OPTOGEN_STIM_OFF",				// End optogenetic stim (single pulse end)
	"OPTOGEN_STIM_START",			// Begin optogenetic stim (pulse train start)
	"OPTOGEN_STIM_END",				// End optogenetic stim (pulse train end)
	"OPTOGEN_GALVO_ON",				// End optogenetic stim (pulse train end)
	"OPTOGEN_GALVO_OFF",			// Begin galvo voltage
	"MOTOR_POS_1_STARTED",
	"MOTOR_POS_2_STARTED",
	"MOTOR_POS_3_STARTED",
	"MOTOR_POS_4_STARTED",
	"MOTOR_POS_1_REACHED",
	"MOTOR_POS_2_REACHED",
	"MOTOR_POS_3_REACHED",
	"MOTOR_POS_4_REACHED"
};

/*****************************************************
	Result codes
*****************************************************/
enum ResultCode
{
	CODE_CORRECT,			// Correct (1st lick w/in window)
	CODE_PAVLOVIAN,			// Pavlovian reward
	CODE_EARLY_MOVE,		// Early Press (-> Abort)
	CODE_NO_MOVE,			// No Press (Timeout -> ITI)
	_NUM_RESULT_CODES		// (Private) Used to count how many codes there are.
};

// We'll send result code translations to MATLAB at startup
static const char *_resultCodeNames[] =
{
	"CORRECT",
	"PAVLOVIAN",
	"EARLY_MOVE",
	"NO_MOVE"
};


/*****************************************************
	Audio cue frequencies in Hz
*****************************************************/
// Use integers. 1kHz - 100kHz for mice
enum SoundEventFrequencyEnum
{
	TONE_CUE     = 6272
};

/*****************************************************
	Servo state
*****************************************************/
enum ServoState
{
	_SERVOSTATE_INIT,
	SERVOSTATE_RETRACTED,
	SERVOSTATE_DEPLOYING,
	SERVOSTATE_RETRACTING,
	SERVOSTATE_DEPLOYED
};


/*****************************************************
	Parameters that can be updated by HOST
*****************************************************/
// Storing everything in array _params[]. Using enum ParamID as array indices so it's easier to add/remove parameters. 
enum ParamID
{
	_DEBUG,							// (Private) 1 to enable debug mode. Default 0.
	USE_LEVER,						// 0 to use lick to trigger reward. 1 to use lever press.
	ALLOW_EARLY_PRESS,				// 1 to abort trial if animal presses early
	ALLOW_EARLY_LICK,				// 1 to abort trial if animal licks early
	PAVLOVIAN, 						// 1 to issue reward at INTERVAL_TARGET in lick task
	DELAY_REWARD,					// After correct move, wait this amount of time before delivering reward(ms).
	DELAY_REWARD_TILL_END,			// 1 to always give reward at end of trial (overrides previous parameter).
	INTERVAL_MIN,					// Time to start of reward window (ms)
	INTERVAL_TARGET,				// Target time (ms)
	INTERVAL_MAX,					// Time to end of reward window (ms)
	ITI_MIN,						// Intertrial interval duration, min (ms)
	ITI_MAX,						// Intertrial interval duration, max (ms)
	ITI_LICK_TIMEOUT,				// ITI ends if last lick was this many ms before, and ITI_MIN has expired (ms)
	RANDOM_DELAY_MIN,				// Minimum random pre-Cue delay (ms)
	RANDOM_DELAY_MAX,				// Maximum random pre-Cue delay (ms)
	CUE_DURATION,					// Duration of the cue tone and LED flash (ms)
	REWARD_DURATION,				// Reward duration (ms)
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
	OPTO_GALVO_MARGIN,				// Time margin used to set galvo before stim train, and unset after stim train (ms) 
	ALLOW_MOTOR_POS_1,
	ALLOW_MOTOR_POS_2,
	ALLOW_MOTOR_POS_3,
	ALLOW_MOTOR_POS_4,
	_NUM_PARAMS						// (Private) Used to count how many parameters there are so we can initialize the param array with the correct size. Insert additional parameters before this.
};

// Store parameter names as strings, will be sent to host
// Names cannot contain spaces!!!
static const char *_paramNames[] = 
{
	"_DEBUG",
	"USE_LEVER",
	"ALLOW_EARLY_PRESS",
	"ALLOW_EARLY_LICK",
	"PAVLOVIAN",
	"DELAY_REWARD",
	"DELAY_REWARD_TILL_END",
	"INTERVAL_MIN",
	"INTERVAL_TARGET",
	"INTERVAL_MAX",
	"ITI_MIN",
	"ITI_MAX",
	"ITI_LICK_TIMEOUT",
	"RANDOM_DELAY_MIN",
	"RANDOM_DELAY_MAX",
	"CUE_DURATION",
	"REWARD_DURATION",
	"LEVER_POS_RETRACTED",
	"LEVER_POS_DEPLOYED",
	"LEVER_SPEED_DEPLOY",
	"LEVER_SPEED_RETRACT",
	"TUBE_POS_RETRACTED",
	"TUBE_POS_DEPLOYED",
	"TUBE_SPEED_DEPLOY",
	"TUBE_SPEED_RETRACT",
	"OPTO_ENABLED",
	"OPTO_PULSE_DURATION",
	"OPTO_PULSE_INTERVAL",
	"OPTO_NUM_PULSES",
	"OPTO_GALVO_MARGIN",
	"ALLOW_MOTOR_POS_1",
	"ALLOW_MOTOR_POS_2",
	"ALLOW_MOTOR_POS_3",
	"ALLOW_MOTOR_POS_4"
};

// Initialize parameters
long _params[_NUM_PARAMS] = 
{
	0,		// _DEBUG
	1,		// USE_LEVER
	0,		// ALLOW_EARLY_PRESS
	0,		// ALLOW_EARLY_LICK
	0, 		// PAVLOVIAN
	0,		// DELAY_REWARD
	0,		// DELAY_REWARD_TILL_END
	4000,	// INTERVAL_MIN
	7000,	// INTERVAL_TARGET
	10000,	// INTERVAL_MAX
	2000,	// ITI_MIN
	4000,	// ITI_MAX
	500,	// ITI_LICK_TIMEOUT
	2000,	// RANDOM_DELAY_MIN
	3000,	// RANDOM_DELAY_MAX
	99,		// CUE_DURATION
	100, 	// REWARD_DURATION
	110,	// LEVER_POS_RETRACTED
	80,		// LEVER_POS_DEPLOYED
	42,		// LEVER_SPEED_DEPLOY
	42,		// LEVER_SPEED_RETRACT
	60,		// TUBE_POS_RETRACTED (~ 50 == 0 mm)
	90,		// TUBE_POS_DEPLOYED (~ 125 == 30 mm)
	36,		// TUBE_SPEED_DEPLOY
	36,		// TUBE_SPEED_RETRACT
	0,		// OPTO_ENABLED,
	10,		// OPTO_PULSE_DURATION,
	250,	// OPTO_PULSE_INTERVAL,
	5,		// OPTO_NUM_PULSES
	500, 	// OPTO_GALVO_MARGIN
	1,		// ALLOW_MOTOR_POS_1
	1,		// ALLOW_MOTOR_POS_2
	1,		// ALLOW_MOTOR_POS_3
	1		// ALLOW_MOTOR_POS_4
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
static long _timeLastLick			= 0;			// Time (ms) when last lick occured

static bool _isLeverPressed			= false;		// True as long as lever is pressed down
static bool _isLeverPressOnset 		= false;		// True when lever first pressed
static long _timeLastLeverPress		= 0;			// Time (ms) when last lever press occured

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

// For white noise generator
static bool _whiteNoiseIsPlaying 			= false;	
static unsigned long _whiteNoiseInterval 	= 50;					// Determines frequency (us)
static unsigned long _whiteNoiseDuration 	= 200;					// Noise duration (ms)
static unsigned long _whiteNoiseFirstClick 	= 0;					// (us)
static unsigned long _whiteNoiseLastClick 	= 0;					// (us)

// Optogenetics stimulation
static bool _isOptogenStimOn 		= false;		// Whether optogenetic stimulation is currently on
static bool _isGalvoOn 				= false;		// Whether galvo is deployed

// Motor
static int _motorPosition = 0;

/*****************************************************
	Setup
*****************************************************/
void setup()
{
	// Turn off
	for(unsigned int i = 0; i < sizeof(_digOutPins)/sizeof(_digOutPins[0]); i++)
	{
		pinMode(_digOutPins[i], OUTPUT);
		digitalWrite(_digOutPins[i], LOW);
	}

	// Init pins
	pinMode(PIN_HOUSE_LAMP, OUTPUT);            // LED for illumination
	pinMode(PIN_HOUSE_LAMP_2, OUTPUT);          // LED for illumination
	pinMode(PIN_LED_CUE, OUTPUT);               // LED for 'start' cue
	pinMode(PIN_SPEAKER, OUTPUT);               // Speaker for cue tone
	pinMode(PIN_REWARD, OUTPUT);				// Reward, set to HIGH to open juice valve
	pinMode(PIN_OPTOGEN_STIM, OUTPUT);			// Laser/LED for optogentics stim
	pinMode(PIN_OPTOGEN_GALVO, OUTPUT);			// Galvo mirror trigger
	pinMode(PIN_MOTOR_BUSY, OUTPUT);
	pinMode(PIN_MOTOR_CONTROLLER_1, OUTPUT);
	pinMode(PIN_MOTOR_CONTROLLER_2, OUTPUT);

	pinMode(PIN_LICK, INPUT);					// Lick detector (input)
	pinMode(PIN_LEVER, INPUT);					// Lever press detector (input)

	pinMode(PIN_MIRROR_LICK, OUTPUT);			// Lick detector (mirrored output to blackrock)
	pinMode(PIN_MIRROR_LEVER, OUTPUT);			// Lever press detector (mirrored output to blackrock)
	pinMode(PIN_MIRROR_REWARD, OUTPUT);			

	// Initiate servo
	_servoLever.attach(PIN_SERVO_LEVER);
	_servoTube.attach(PIN_SERVO_TUBE);

	// Serial comms
	Serial.begin(115200);                       // Set up USB communication at 115200 baud 
}

void mySetup()
{
	// Reset output
	setHouseLamp(true);						// House Lamp ON
	setCueLED(false);						// Cue LED OFF
	setOptogenStim(false);					// Optogenetic stim OFF
	setGalvo(false);

	// Reset variables
	_timeReset				= 0;			// Reset to signedMillis() at every soft reset
	_timeTrialStart			= 0;			// Reset to 0 at start of trial
	_timeCueOn				= 0;			// Reset to 0 at cue on
	_resultCode				= -1;			// Result code. -1 if there is no result.
	_state					= _STATE_INIT;	// This variable (current _state) get passed into a _state function, which determines what the next _state should be, and updates it to the next _state.
	_prevState				= _STATE_INIT;	// Remembers the previous _state from the last loop (actions should only be executed when you enter a _state for the first time, comparing currentState vs _prevState helps us keep track of that).
	_command				= ' ';			// Command char received from host, resets on each loop
	_arguments[0]			= 0;			// Two integers received from host , resets on each loop
	_arguments[1]			= 0;			// Two integers received from host , resets on each loop

	_isLicking 				= false;		// True if the little dude is licking
	_isLickOnset 			= false;		// True during lick onset
	_timeLastLick			= 0;			// Time (ms) when last lick occured

	_isLeverPressed			= false;		// True as long as lever is pressed down
	_isLeverPressOnset 		= false;		// True when lever first pressed
	_timeLastLeverPress		= 0;			// Time (ms) when last lever press occured

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

	_whiteNoiseIsPlaying 	= false;	
	_whiteNoiseInterval 	= 50;					// Determines frequency (us)
	_whiteNoiseDuration 	= 200;					// Noise duration (ms)
	_whiteNoiseFirstClick 	= 0;					// (us)
	_whiteNoiseLastClick 	= 0;					// (us)

	_isOptogenStimOn 		= false;		// Whether optogenetic stimulation is currently on
	_isGalvoOn				= false;		// Whether galvo mirror is deployed

	_motorPosition = 0;

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

		// 2) Other onEachLoop routines
		handleLick();			// Check for licks on/offset
		handleLever();			// Check for lever press on/offset
		handleServoTube();		// Tube servo control
		handleServoLever();		// Lever servo control
		handleWhiteNoise();		// White noise generation

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

			case STATE_OPTOGEN_STIM:
				state_optogen_stim();
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

		// Reset output
		setHouseLamp(false);
		setCueLED(false);
		setOptogenStim(false);
		setGalvo(false);
		noTone(PIN_SPEAKER);
		setReward(false);
		deployLever(false);
		_motorPosition = translateLever(0);
		hasMotorReachedTarget = false;
		deployTube(true);
		timeIdle = getTime();
	}

	/*****************************************************
		OnEachLoop checks
	*****************************************************/
	// Received new param from host: format "P _paramID _newValue" ('P' for Parameters)
	if (_command == 'P') 
	{
		_params[_arguments[0]] = _arguments[1];
	}

	if (!hasMotorReachedTarget && getTime() - timeIdle > 1 && !isMotorBusy())
	{
		hasMotorReachedTarget = true;
		switch (_motorPosition)
		{
			case 0:
				sendEventMarker(EVENT_MOTOR_POS_1_REACHED, -1);
				break;
			case 1:
				sendEventMarker(EVENT_MOTOR_POS_2_REACHED, -1);
				break;
			case 2:
				sendEventMarker(EVENT_MOTOR_POS_3_REACHED, -1);
				break;
			case 3:
				sendEventMarker(EVENT_MOTOR_POS_4_REACHED, -1);
				break;
		}
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
	
	// LASER command from host --> STATE_OPTOGEN_STIM
	if (_command == 'L')
	{
		_state = STATE_OPTOGEN_STIM;
		return;
	}

	_state = STATE_IDLE;
}

/*****************************************************
	INTERTRIAL
*****************************************************/
void state_intertrial()
{
	static long timeIntertrial;
	static long randomDelay;
	static bool isTubeRetracted;
	static bool isParamsUpdateStarted;
	static bool isParamsUpdateDone;
	static bool hasMotorReachedTarget;
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

		// Retract lick tube immediately if incorrect
		isTubeRetracted = false;
		if (_resultCode != CODE_CORRECT)
		{
			isTubeRetracted = true;
			deployTube(false);
		}

		// Send results
		sendResultCode(_resultCode);
		_resultCode = -1;

		// Houselamp off
		setHouseLamp(false);

		// Retract lever and move to new place
		if (_params[USE_LEVER] == 1)
		{
			deployLever(false);
			_motorPosition = translateLever(-1);
		}
		else
		{
			_motorPosition = translateLever(0);
		}
		hasMotorReachedTarget = false;

		// Register time of state entry
		timeIntertrial = getTimeSinceCueOn();

		// Generate random interval length
		randomDelay = random(_params[RANDOM_DELAY_MIN], _params[RANDOM_DELAY_MAX]);

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

	// If rewarded, retract lick tube before random delay starts
	if (!isTubeRetracted)
	{
		if ((getTimeSinceCueOn() - timeIntertrial >= _params[ITI_MAX]) || (getTimeSinceCueOn() - timeIntertrial >= _params[ITI_MIN] && getTimeSinceLastLick() >= _params[ITI_LICK_TIMEOUT]))
		{
			isTubeRetracted = true;
			deployTube(false);
		}
	}

	if (!hasMotorReachedTarget && getTimeSinceCueOn() - timeIntertrial > 1 && !isMotorBusy())
	{
		hasMotorReachedTarget = true;
		switch (_motorPosition)
		{
			case 0:
				sendEventMarker(EVENT_MOTOR_POS_1_REACHED, -1);
				break;
			case 1:
				sendEventMarker(EVENT_MOTOR_POS_2_REACHED, -1);
				break;
			case 2:
				sendEventMarker(EVENT_MOTOR_POS_3_REACHED, -1);
				break;
			case 3:
				sendEventMarker(EVENT_MOTOR_POS_4_REACHED, -1);
				break;
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

	// If ITI elapsed --> either RANDOM_DELAY or OPTOGEN_STIM if enabled
	if ((_params[USE_LEVER] == 0 || !isMotorBusy()) && (isParamsUpdateDone || !isParamsUpdateStarted))
	{
		if (_params[OPTO_ENABLED] == 0)
		{
			if ((getTimeSinceCueOn() - timeIntertrial >= _params[ITI_MAX] + randomDelay) || (getTimeSinceCueOn() - timeIntertrial >= _params[ITI_MIN] + randomDelay && getTimeSinceLastLick() >= _params[ITI_LICK_TIMEOUT]))
			{
				_state = STATE_PRE_CUE;
				return;
			}
		}
		else
		{
			if ((getTimeSinceCueOn() - timeIntertrial >= _params[ITI_MAX]) || (getTimeSinceCueOn() - timeIntertrial >= _params[ITI_MIN] && getTimeSinceLastLick() >= _params[ITI_LICK_TIMEOUT]))
			{
				_state = STATE_OPTOGEN_STIM;
				return;
			}
		}
	}

	_state = STATE_INTERTRIAL;
}

/*****************************************************
	PRE_CUE - Deploy lever/tube and then present cue
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

		// Lever task: deploy lever, no tube
		if (_params[USE_LEVER] == 1)
		{
			deployLever(true);
			deployTube(false);
		}
		// Lick task: deploy tube, no lever
		else
		{
			deployLever(false);
			deployTube(true);
		}

		// Register trial start time
		_timeTrialStart = signedMillis();

		// Reset variables
		_resultCode = -1;
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

	// Early lick/lever-press detected --> ABORT
	if ((_isLeverPressOnset && _params[ALLOW_EARLY_PRESS] == 0) || (_isLickOnset && _params[ALLOW_EARLY_LICK] == 0))
	{
		_state = STATE_ABORT;
		return;
	}

	// Lever/tube deployed --> PRE_WINDOW
	// Lever mode: make sure both are deployed
	if (_params[USE_LEVER] == 1)
	{
		if (_servoStateLever == SERVOSTATE_DEPLOYED)
		{
			_state = STATE_PRE_WINDOW;
			return;
		}
	}
	// Tube mode: make sure tube is deployed
	else
	{
		if (_servoStateTube == SERVOSTATE_DEPLOYED)
		{
			_state = STATE_PRE_WINDOW;
			return;
		}
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
		setHouseLamp(true);
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

	// Early lick/lever-press detected --> ABORT
	if ((_isLeverPressOnset && _params[ALLOW_EARLY_PRESS] == 0) || (_isLickOnset && _params[ALLOW_EARLY_LICK] == 0))
	{
		_state = STATE_ABORT;
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
	RESPONSE_WINDOW - Licking triggers reward
*****************************************************/
void state_response_window() 
{
	static bool isTargetTimeReached;
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

		// Reset variables
		isTargetTimeReached = false;
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

	// Early press in lick task/lick in lever task detected --> ABORT
	if ((_isLeverPressOnset && _params[ALLOW_EARLY_PRESS] == 0 && _params[USE_LEVER] == 0) || (_isLickOnset && _params[ALLOW_EARLY_LICK] == 0 && _params[USE_LEVER] == 1))
	{
		_state = STATE_ABORT;
		return;
	}

	// Correct lick/press --> REWARD
	if ((_isLickOnset && _params[USE_LEVER] == 0) || (_isLeverPressOnset && _params[USE_LEVER] == 1))
	{
		_resultCode = CODE_CORRECT;
		_state = STATE_REWARD;
		return;
	}

	// Target time reached
	if (!isTargetTimeReached && getTimeSinceCueOn() >= _params[INTERVAL_TARGET])
	{
		isTargetTimeReached = true;

		// Register events
		sendEventMarker(EVENT_TARGET_TIME, -1);

		// If pavlovian lick task, go to reward
		if (_params[USE_LEVER] == 0 && _params[PAVLOVIAN] == 1)
		{
			_resultCode = CODE_PAVLOVIAN;
			_state = STATE_REWARD;
			return;
		}
	}

	// Response window elapsed --> ITI
	if (getTimeSinceCueOn() >= _params[INTERVAL_MAX])
	{
		// Register events
		sendEventMarker(EVENT_WINDOW_CLOSED, -1);

		_resultCode = CODE_NO_MOVE;
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
	static long timeCorrectMove;
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
		timeCorrectMove = getTimeSinceCueOn();
		timeRewardOn = 0;
		isRewardOn = false;
		isRewardComplete = false;
	}

	/*****************************************************
		OnEachLoop checks
	*****************************************************/
	// Pavlovian rewards are immediate
	if (_resultCode == CODE_PAVLOVIAN)
	{
		if (!isRewardOn && !isRewardComplete)
		{
			timeRewardOn = getTimeSinceCueOn();
			isRewardOn = true;
			if (_params[REWARD_DURATION] > 0)
			{
				if (_params[USE_LEVER] == 1)
				{
					deployTube(true);
				}
				setReward(true);
			}			
		}		
	}
	// Immediate/slightly delayed reward
	else if (_params[DELAY_REWARD_TILL_END] == 0)
	{
		if (!isRewardOn && !isRewardComplete && getTimeSinceCueOn() - timeCorrectMove >= _params[DELAY_REWARD])
		{
			timeRewardOn = getTimeSinceCueOn();
			isRewardOn = true;
			if (_params[REWARD_DURATION] > 0)
			{
				if (_params[USE_LEVER] == 1)
				{
					deployTube(true);
				}
				setReward(true);
			}			
		}
	}
	// Delay reward till end of trial
	else
	{
		// Start dispensing reward at end of trial
		if (!isRewardOn && !isRewardComplete && getTimeSinceCueOn() >= _params[INTERVAL_MAX])
		{
			timeRewardOn = getTimeSinceCueOn();
			isRewardOn = true;
			if (_params[REWARD_DURATION] > 0)
			{
				if (_params[USE_LEVER] == 1)
				{
					deployTube(true);
				}
				setReward(true);
			}
		}
	}

	// Turn off reward when the time comes
	if (isRewardOn && !isRewardComplete && getTimeSinceCueOn() - timeRewardOn >= _params[REWARD_DURATION])
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
	if (isRewardComplete && getTimeSinceCueOn() >= _params[INTERVAL_MAX])
	{
		// Register events
		sendEventMarker(EVENT_WINDOW_CLOSED, -1);

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
		_resultCode = CODE_EARLY_MOVE;

		// Register events
		sendEventMarker(EVENT_ABORT, -1);

		// Play abort tone
		playWhiteNoise(50, 200);

		// Cue LED off just in case
		setCueLED(false);

		// Retract lever/tube based on trial type
		if (_params[USE_LEVER] == 1)
		{
			deployLever(false);
			deployTube(false);
		}
		else
		{
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

	// Trial duration elapsed --> INTERTRIAL
	if (getTimeSinceCueOn() >= _params[INTERVAL_MAX])
	{
		_state = STATE_INTERTRIAL;
		return;
	}

	_state = STATE_ABORT;
}

/*****************************************************
	STIM
*****************************************************/
void state_optogen_stim()
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
		// Write down previous state, return to it when done
		entryState = _prevState;

		// Register new state
		_prevState = _state;
		sendState(_state);

		// Generate random interval length
		if (entryState == STATE_INTERTRIAL)
		{
			randomDelay = random(_params[RANDOM_DELAY_MIN], _params[RANDOM_DELAY_MAX]);
		}

		// Register events
		sendEventMarker(EVENT_OPTOGEN_STIM_START, -1);

		// Register time of state entry
		timeEnter = getTime();
		numPulsesComplete = 0;

		// Set galvo
		setGalvo(true);
	}

	/*****************************************************
		OnEachLoop checks
	*****************************************************/
	if (getTime() - timeEnter >= _params[OPTO_GALVO_MARGIN] && numPulsesComplete < _params[OPTO_NUM_PULSES])
	{
		// If stim is on, check if it needs to be turned off
		if (_isOptogenStimOn)
		{
			if (getTime() - timePulseStart >= _params[OPTO_PULSE_DURATION])
			{
				setOptogenStim(false);
				timePulseEnd = getTime();
				numPulsesComplete = numPulsesComplete + 1;
				if (numPulsesComplete >= _params[OPTO_NUM_PULSES])
				{
					sendEventMarker(EVENT_OPTOGEN_STIM_END, -1);
				}
			}
		}
		// If stim is off, check if it needs to be turned on
		else
		{
			if (getTime() - timePulseEnd >= _params[OPTO_PULSE_INTERVAL])
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
		sendEventMarker(EVENT_OPTOGEN_STIM_END, -1);
		_state = STATE_IDLE;
		return;
	}

	// Stim train complete --> PRE_CUE (after random delay) or IDLE
	if (getTime() >= timePulseEnd + _params[OPTO_GALVO_MARGIN] && numPulsesComplete >= _params[OPTO_NUM_PULSES])
	{
		setGalvo(false);
		if (entryState == STATE_INTERTRIAL)
		{
			if (getTime() - timePulseEnd >= randomDelay)
			{
				_state = STATE_PRE_CUE;
				return;
			}
		}
		else
		{
			_state = STATE_IDLE;
			return;
		}
	}

	_state = STATE_OPTOGEN_STIM;
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
		digitalWrite(PIN_HOUSE_LAMP_2, HIGH);
		if (!houseLampOn)
		{
			houseLampOn = true;
			sendEventMarker(EVENT_HOUSELAMP_ON, -1);
		}
	}
	else 
	{
		digitalWrite(PIN_HOUSE_LAMP, LOW);
		digitalWrite(PIN_HOUSE_LAMP_2, LOW);
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

// Toggle optogenetic stimulation (via AOM or LED)
void setOptogenStim(bool turnOn) 
{
	if (turnOn) 
	{
		if (!_isOptogenStimOn)
		{
			_isOptogenStimOn = true;
			digitalWrite(PIN_OPTOGEN_STIM, HIGH);
			sendEventMarker(EVENT_OPTOGEN_STIM_ON, -1);
		}
	}
	else 
	{
		if (_isOptogenStimOn)
		{
			_isOptogenStimOn = false;
			digitalWrite(PIN_OPTOGEN_STIM, LOW);
			sendEventMarker(EVENT_OPTOGEN_STIM_OFF, -1);
		}
	}
} 

// Toggle galvo
void setGalvo(bool turnOn)
{
	if (turnOn)
	{
		if (!_isGalvoOn)
		{
			_isGalvoOn = true;
			digitalWrite(PIN_OPTOGEN_GALVO, HIGH);
			sendEventMarker(EVENT_OPTOGEN_GALVO_ON, -1);
		}
	}
	else
	{
		if (_isGalvoOn)
		{
			_isGalvoOn = false;
			digitalWrite(PIN_OPTOGEN_GALVO, LOW);
			sendEventMarker(EVENT_OPTOGEN_GALVO_OFF, -1);
		}
	}
}

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
		}
		_isLeverPressOnset = false;
	}
}

int translateLever(int position)
{
	if (position < 0 || position >= 4)
	{
		int allowedPositions[4] = {};
		int nAllowedPositions = 0;
		if (_params[ALLOW_MOTOR_POS_1] > 0)
		{
			allowedPositions[nAllowedPositions] = 0;
			nAllowedPositions += 1;
		};
		if (_params[ALLOW_MOTOR_POS_2] > 0)
		{
			allowedPositions[nAllowedPositions] = 1;
			nAllowedPositions += 1;
		};
		if (_params[ALLOW_MOTOR_POS_3] > 0)
		{
			allowedPositions[nAllowedPositions] = 2;
			nAllowedPositions += 1;
		};
		if (_params[ALLOW_MOTOR_POS_4] > 0)
		{
			allowedPositions[nAllowedPositions] = 3;
			nAllowedPositions += 1;
		};

		if (nAllowedPositions == 0)
		{
			return 0;
		}

		position = allowedPositions[random(nAllowedPositions)];
	}
	switch (position)
	{
		case 0:
			digitalWrite(PIN_MOTOR_CONTROLLER_1, LOW);
			digitalWrite(PIN_MOTOR_CONTROLLER_2, LOW);
			sendEventMarker(EVENT_MOTOR_POS_1_STARTED, -1);
			break;
		case 1:
			digitalWrite(PIN_MOTOR_CONTROLLER_1, LOW);
			digitalWrite(PIN_MOTOR_CONTROLLER_2, HIGH);
			sendEventMarker(EVENT_MOTOR_POS_2_STARTED, -1);
			break;
		case 2:
			digitalWrite(PIN_MOTOR_CONTROLLER_1, HIGH);
			digitalWrite(PIN_MOTOR_CONTROLLER_2, LOW);
			sendEventMarker(EVENT_MOTOR_POS_3_STARTED, -1);
			break;
		case 3:
			digitalWrite(PIN_MOTOR_CONTROLLER_1, HIGH);
			digitalWrite(PIN_MOTOR_CONTROLLER_2, HIGH);
			sendEventMarker(EVENT_MOTOR_POS_4_STARTED, -1);
			break;
	}
	sendDebugMessage("Moving to target " + String(position + 1));
	return position;
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

bool isMotorBusy()
{
	return (digitalRead(PIN_MOTOR_BUSY) == HIGH);
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