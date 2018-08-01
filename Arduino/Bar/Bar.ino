#include <Servo.h>
/*********************************************************************
	Arduino state machine
	Rotating Bar task (w/ retractable lever)
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
	Servo stuff
*****************************************************/
Servo _servoLever;
Servo _servoTube;

/*****************************************************
	Arduino Pin Outs
*****************************************************/
// Teensy Board Pins
// Digital OUT
#define PIN_REWARD		24	// SOL_1, which is Juice 2  
#define PIN_IR_LAMP		8	// DIO_2

// PWM OUT
#define PIN_SERVO_LEVER	6	// DIO_0
#define PIN_SERVO_TUBE	7	// DIO_1

// Digital IN
#define PIN_LICK		25	// Dedicated, not broken out
#define PIN_LEVER		26	// Dedicated, not broken out

#define SERVO_READ_ACCURACY  2


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
	STATE_PRE_STIM,				// Deploy lever/tube
	STATE_BAR_STAT,				// Moving dots, stationary bar, enforced no lick
	STATE_BAR_MOVE,				// Moving dots, moving bar, enforced no lick
	STATE_RESPONSE_WINDOW,		// First lick in this interval rewarded
	STATE_REWARD,				// Dispense reward, wait for trial timeout
	STATE_OPERANT_REWARD,		// In operant turn, if mouse licks correctly go to reward
	STATE_ABORT,				// Basically a transition state for early licks
	STATE_ABORT_EARLY,			// Early lick
	STATE_ABORT_BAR_STAT,		// Early lick during stat
	STATE_ABORT_NO_MOVE			// No lick - timeout
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
	"PRE_STIM",
	"BAR_STAT",
	"BAR_MOVE",
	"RESPONSE_WINDOW",
	"REWARD",
	"OPERANT_REWARD",
	"ABORT",
	"ABORT_EARLY",
	"ABORT_BAR_STAT",
	"ABORT_NO_MOVE"
};

// Define which states accept parameter update from MATLAB
static const int _stateCanUpdateParams[] = {0,1,1,0,0,0,0,0,0,0,0}; 

/*****************************************************
	Event Markers
*****************************************************/
enum EventMarker
{
	EVENT_TRIAL_START,				// New trial initiated
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
	EVENT_FIRST_MOVE,				// First lick in trial since cue on
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
	"LICK",						// Lick onset
	"LICK_OFF",					// Lick offset
	"FIRST_MOVE",				// First lick in trial since cue on
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
	CODE_OPERANT,			// Operant (reward given if animal licks/presses to make bar reverse)
	CODE_MOVE_REWARD,		// If animal presses/licks, rewarded
	CODE_PAVLOVIAN,			// Pavlovian (Reward given when bar reverses)
	CODE_EARLY_MOVE,		// Early Lick/Press (-> Abort)
	CODE_NO_MOVE,			// No Lick/Press (Timeout -> ITI)
	_NUM_RESULT_CODES		// (Private) Used to count how many codes there are.
};

// We'll send result code translations to MATLAB at startup
static const char *_resultCodeNames[] =
{
	"CORRECT",
	"OPERANT",
	"MOVE_REWARD",
	"PAVLOVIAN",
	"EARLY_MOVE",
	"NO_MOVE"
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
	_DEBUG,						// (Private) 1 to enable debug mode. Default 0.
	BAR_STAT_DURATION, 			// Length of moving dots, stationary bar
	ITI_DURATION,				// ITI length, fixed
	REWARD_DURATION,			// Reward duration (ms)
	WINDOW_DURATION,			// Time from Alpha to Turning Point (or from Turning Point to Omega)
	OMEGA_TO_ITI_DURATION,		// Time from Omega to ITI (ms)
	USE_LEVER,					// 0 to use lick to trigger reward. 1 to use lever press.
	ALLOW_EARLY_PRESS,			// 1 to abort trial if animal presses early
	ALLOW_LICK_BAR_STAT,		// Allow early lick when stim first comes on
	ALLOW_EARLY_LICK,			// 0 to abort trial if animal licks after in pre-window
	EARLY_MOVE_PUNISHMENT,		// 1 = Flashing screen in early move abort
	NO_MOVE_PUNISHMENT,			// 1 = Flashing screen in no move abort
	MOVE_REWARD,				// If mouse presses lever/licks, gets reward
	PAVLOVIAN,					// Pavlovian = 1, Operant = 0
	REACTIVE,					// Proactive = 0, Reactive = 1
	TIMING,						// Elapsed time informative = 1, Not = 0
	OPERANT_TURN,				// Mouse move causes bar to reverse direction
	END_THETA,					// Define location of turning point
	TRIANGLE_CUE,				// 0 = flashing bar cue, 1 = flashing triangle cue
	CUE_LOCATIONS,				// For proactive, switches possible locations of cue (cardinal to anywhere)	
	SPATIAL_FREQUENCY,			// Distance (degrees) between bar locations
	BAR_SPEED,					// In hops/seconds
	NUM_HOPS,					// In num. of hops, how long the bar stays stationary at Turning Point
	DOTS,						// 1 to show moving dots
	MU,							// Mean trial length 
	SIGMA,						// Standard deviation for trial length
	LEVER_POS_RETRACTED,		// Servo (lever) position when lever is retracted
	LEVER_POS_DEPLOYED,			// Servo (lever) position when lever is deployed
	LEVER_SPEED_DEPLOY,			// Servo (lever) rotation speed when deploying, 0 for max speed
	LEVER_SPEED_RETRACT,		// Servo (lever) rotaiton speed when retracting, 0 for max speed
	TUBE_POS_RETRACTED,			// Servo (juice tube) position when juice tube is retracted (full is ~ 50)
	TUBE_POS_DEPLOYED,			// Servo (juice tube) position when juice tube is deployed (full is ~ 125)
	TUBE_SPEED_DEPLOY,			// Servo (juice tube) advance speed when deploying, 0 for max speed
	TUBE_SPEED_RETRACT,			// Servo (juice tube) retract speed when retracting, 0 for max speed
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
	"USE_LEVER",				// 0 to use lick to trigger reward. 1 to use lever press
	"ALLOW_EARLY_PRESS",		// 1 to abort trial if animal presses early
	"ALLOW_LICK_BAR_STAT",		// Allow early lick when stim first comes on
	"ALLOW_EARLY_LICK",			// 0 to abort trial if animal licks after in pre-window
	"EARLY_MOVE_PUNISHMENT",	// 1 = Flashing screen in early move abort
	"NO_MOVE_PUNISHMENT",		// 1 = Flashing screen in no move abort
	"MOVE_REWARD",				// If mouse presses lever/licks, gets reward
	"PAVLOVIAN",				// Pavlovian = 1, Operant = 0
	"REACTIVE",					// Is this a reactive or proactive paradigm?
	"TIMING",					// Elapsed time informative = 1, Not = 0
	"OPERANT_TURN",				// Mouse move causes bar to reverse direction
	"END_THETA",				// Define location of turning point
	"TRIANGLE_CUE",				// 0 = flashing bar cue, 1 = flashing triangle cue
	"CUE_LOCATIONS",			// For proactive, switches possible locations of cue (cardinal to anywhere)			
	"SPATIAL_FREQUENCY",		// Distance (degrees) between bar locations; degrees/hop
	"BAR_SPEED",				// In hops/seconds
	"NUM_HOPS",					// In num. of hops, how long the bar stays stationary at Turning Point
	"DOTS",						// 1 to show moving dots
	"MU",						// Mean trial length 
	"SIGMA",					// Standard deviation for trial length
	"LEVER_POS_RETRACTED",		// Servo (lever) position when lever is retracted
	"LEVER_POS_DEPLOYED",		// Servo (lever) position when lever is deployed
	"LEVER_SPEED_DEPLOY",		// Servo (lever) rotation speed when deploying, 0 for max speed
	"LEVER_SPEED_RETRACT",		// Servo (lever) rotaiton speed when retracting, 0 for max speed
	"TUBE_POS_RETRACTED",		// Servo (juice tube) position when juice tube is retracted (full is ~ 50)
	"TUBE_POS_DEPLOYED",		// Servo (juice tube) position when juice tube is deployed (full is ~ 125)
	"TUBE_SPEED_DEPLOY",		// Servo (juice tube) advance speed when deploying, 0 for max speed
	"TUBE_SPEED_RETRACT"		// Servo (juice tube) retract speed when retracting, 0 for max speed
};

// Initialize parameters
long _params[_NUM_PARAMS] = 
{
	0,		// _DEBUG
	1000,	// BAR_STAT_DURATION
	12000,	// ITI_DURATION
	50,		// REWARD_DURATION
	2000,	// WINDOW_DURATION
	1500,	// OMEGA_TO_ITI_DURATION
	1,		// USE_LEVER
	0,		// ALLOW_EARLY_PRESS
	0,		// ALLOW_LICK_BAR_STAT
	0,		// ALLOW_EARLY_LICK
	1,		// EARLY_MOVE_PUNISHMENT
	1,		// NO_MOVE_PUNISHMENT
	0,		// MOVE_REWARD
	0,		// PAVLOVIAN
	0, 		// REACTIVE
	0,		// TIMING	
	0,		// OPERANT_TURN
	90,		// END_THETA
	1,		// TRIANGLE_CUE
	1,		// CUE_LOCATIONS
	4,		// SPATIAL_FREQUENCY
	4,		// BAR_SPEED
	0,		// NUM_HOPS
	0,		// DOTS
	6,		// MU
	2,		// SIGMA
	120,	// LEVER_POS_RETRACTED
	98,		// LEVER_POS_DEPLOYED
	90,		// LEVER_SPEED_DEPLOY
	90,		// LEVER_SPEED_RETRACT
	85,		// TUBE_POS_RETRACTED (~ 50 == 0 mm)
	100,	// TUBE_POS_DEPLOYED (~ 125 == 30 mm)
	18,		// TUBE_SPEED_DEPLOY
	18		// TUBE_SPEED_RETRACT
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
static bool _firstMoveRegistered 	= false;		// True when first lick is registered for this trial
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

/*****************************************************
	Setup
*****************************************************/
void setup()
{
	// Init pins
	pinMode(PIN_IR_LAMP, OUTPUT);	// IR LED for camera recording
	pinMode(PIN_REWARD, OUTPUT);	// Reward, set to HIGH to open juice valve
	pinMode(PIN_LICK, INPUT);		// Lick detector
	pinMode(PIN_LEVER, INPUT);		// Lever press detector

	// Setting unused pins low
	pinMode(4, OUTPUT);
	digitalWrite(4, LOW);
	pinMode(5, OUTPUT);
	digitalWrite(5, LOW);
	pinMode(9, OUTPUT);
	digitalWrite(9, LOW);
	pinMode(10, OUTPUT);
	digitalWrite(10, LOW);
	pinMode(11, OUTPUT);
	digitalWrite(11, LOW);
	pinMode(20, OUTPUT);
	digitalWrite(20, LOW);
	pinMode(21, OUTPUT);
	digitalWrite(21, LOW);
	pinMode(22, OUTPUT);
	digitalWrite(22, LOW);
	pinMode(23, OUTPUT);
	digitalWrite(23, LOW);

	// Initiate servo
	_servoLever.attach(PIN_SERVO_LEVER);
	_servoTube.attach(PIN_SERVO_TUBE);

	// Serial comms
	Serial.begin(115200);			// Set up USB communication at 115200 baud 
}

void mySetup()
{
	// Reset output
	// setIRLamp(true);                        // IR Lamp ON

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
	_firstMoveRegistered 	= false;		// True when first lick is registered for this trial
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
		// 2.1)
		handleLever();
		// 2.2) Check for alpha, turning point and omega from matlab and send back event markers because we dumb
		handleVisualStim();
		// 2.3) Tube servo control
		handleServoTube();		
		// 2.4) Lever servo control
		handleServoLever();

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

			case STATE_PRE_STIM:
				state_pre_stim();
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

			case STATE_OPERANT_REWARD:
				state_operant_reward();
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

			case STATE_ABORT_NO_MOVE:
				state_abort_no_move();
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
		// setIRLamp(true);
		setReward(false);
		deployLever(false);
		deployTube(true);
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
		_firstMoveRegistered = false;
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
		// Register result
		_resultCode = CODE_EARLY_MOVE;
		_state = STATE_ABORT;
		return;
	}

	// Go immediately --> PRE_STIM
	if (getTimeSinceTrialStart() >= 0)
	{
		_state = STATE_PRE_STIM;
		return;
	}

	_state = STATE_START;
}

/*****************************************************
	PRE_STIM - Deploy lever/tube
*****************************************************/
void state_pre_stim() 
{
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);

		// Lever task: deploy lever
		if (_params[USE_LEVER] == 1)
		{
			deployLever(true);
			deployTube(true);
		}
		// Lick task: deploy tube, no lever
		else
		{
			deployLever(false);
			deployTube(true);
		}

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

	// Early lick/lever-press detected --> ABORT
	if ((_isLeverPressOnset && _params[ALLOW_EARLY_PRESS] == 0) || (_isLickOnset && _params[ALLOW_EARLY_LICK] == 0))
	{
		_resultCode = CODE_EARLY_MOVE;
		_state = STATE_ABORT;
		return;
	}

	// Lever/tube deployed --> BAR_MOVE
	// Lever mode: make sure both are deployed
	if (_params[USE_LEVER] == 1)
	{
		if (_servoStateLever == SERVOSTATE_DEPLOYED && _servoStateTube == SERVOSTATE_DEPLOYED)
		{
			_state = STATE_BAR_STAT;
			return;
		}
	}

	// Lick detected
	if (_isLickOnset)
	{
		// First lick registration
		if (!_firstMoveRegistered)
		{
			_firstMoveRegistered = true;
			sendEventMarker(EVENT_FIRST_MOVE, -1);
		}
	}

	// Tube mode: make sure tube is deployed
	if (_servoStateTube == SERVOSTATE_DEPLOYED)
	{
		_state = STATE_BAR_STAT;
		return;
	}

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

	// Lever/tube deployed --> BAR_MOVE
	// Lever mode: make sure both are deployed
	if (_params[USE_LEVER] == 1)
	{
		if (_servoStateLever == SERVOSTATE_DEPLOYED && _servoStateTube == SERVOSTATE_DEPLOYED)
		{
			_state = STATE_BAR_MOVE;
			return;
		}
	}

	// Move detected
	if (_isLickOnset || _isLeverPressOnset)
	{
		// First move registration
		if ((_isLickOnset && _params[USE_LEVER] == 0) || (_isLeverPressOnset && _params[USE_LEVER] == 1))
		{
			if (!_firstMoveRegistered)
			{
				_firstMoveRegistered = true;
				sendEventMarker(EVENT_FIRST_MOVE, -1);
			}
		}
	}
	
	// Early lick/lever-press detected --> ABORT
	if ((_isLickOnset && (_params[ALLOW_LICK_BAR_STAT] == 0)) || (_isLeverPressOnset && (_params[ALLOW_EARLY_PRESS] == 0)))
	{
		// Register result
		_resultCode = CODE_EARLY_MOVE;
		_state = STATE_ABORT_BAR_STAT;
		return;	
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

	// Move detected
	// First move registration fir task related movement
	if ((_isLickOnset && _params[USE_LEVER] == 0) || (_isLeverPressOnset && _params[USE_LEVER] == 1))
	{
		if (_params[MOVE_REWARD] == 1 && _params[OPERANT_TURN] == 1)
		{
			if (!_firstMoveRegistered)
			{
				_firstMoveRegistered = true;
				sendEventMarker(EVENT_FIRST_MOVE, -1);
				_resultCode = CODE_OPERANT;
				_state = STATE_OPERANT_REWARD;
				return;
			}
		}
		else if (_params[MOVE_REWARD] == 1 && _params[OPERANT_TURN] == 0)
		{
			if (!_firstMoveRegistered)
			{
				_firstMoveRegistered = true;
				sendEventMarker(EVENT_FIRST_MOVE, -1);
				_resultCode = CODE_MOVE_REWARD;
				_state = STATE_REWARD;
				return;
			}
		}
		else 
		{
			if (!_firstMoveRegistered)
			{
				_firstMoveRegistered = true;
				sendEventMarker(EVENT_FIRST_MOVE, -1);
			}
		}
	}

	// Early lick/lever-press detected --> ABORT
	if ((_isLickOnset && (_params[ALLOW_EARLY_LICK] == 0)) || (_isLeverPressOnset && (_params[ALLOW_EARLY_PRESS] == 0)))
	{
		// Register result
		_resultCode = CODE_EARLY_MOVE;
		_state = STATE_ABORT_EARLY;
		return;	
	}

	// bar_move elapsed --> RESPONSE_WINDOW
	if (_params[PAVLOVIAN] == 1)
	{
		if (_params[REACTIVE] == 1)
		{
			if (_command == 'T')
			{
				_resultCode = CODE_PAVLOVIAN;
				_state = STATE_REWARD;
				return;
			}
		}
		else // PROACTIVE
		{
			if (_command == 'A')
			{
				_state = STATE_RESPONSE_WINDOW;
				return;
			} 
		}
	}
	else
	{
		if (_params[REACTIVE] == 1)
		{
			if (_command == 'T')
			{
				_state = STATE_RESPONSE_WINDOW;
				return;
			}
		}
		else // PROACTIVE
		{
			if (_command == 'A')
			{
				_state = STATE_RESPONSE_WINDOW;
				return;
			}
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
	static long randDelay;

	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);

		randDelay = random((_params[WINDOW_DURATION] - 400), _params[WINDOW_DURATION] + 1);
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

	// Correct lick/press --> REWARD
	if (_isLickOnset || _isLeverPressOnset)
	{
		if ((_isLickOnset && _params[USE_LEVER] == 0) || (_isLeverPressOnset && _params[USE_LEVER] == 1))
		{
			// First lick registration
			if (!_firstMoveRegistered)
			{
				_firstMoveRegistered = true;
				sendEventMarker(EVENT_FIRST_MOVE, -1);
			}
			if (_params[OPERANT_TURN] == 0)
			{
				_resultCode = CODE_CORRECT;
				_state = STATE_REWARD;
				return;
			}
			else
			{
				_resultCode = CODE_OPERANT;
				_state = STATE_OPERANT_REWARD;
				return;
			}
		}
	}
	// Pavlovian
	else if (_params[PAVLOVIAN] == 1)
	{
		if (_params[REACTIVE] == 0)
		// deliver reward some time in this window from alpha to turning pt
		{
			if ((getTimeSinceStimOn() - _timeAlpha) >= randDelay)
			{
				_resultCode = CODE_PAVLOVIAN;
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
				_resultCode = CODE_NO_MOVE;
				_state = STATE_ABORT_NO_MOVE;
				return;
			}
		}
		else
		{
			if (_command == 'W')
			{
				_resultCode = CODE_NO_MOVE;
				_state = STATE_ABORT_NO_MOVE;
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
	if ((_isLickOnset && (_params[USE_LEVER] == 0)) || (_isLeverPressOnset && (_params[USE_LEVER] == 1)))
	{
		// First lick registration
		if (!_firstMoveRegistered)
		{
			_firstMoveRegistered = true;
			sendEventMarker(EVENT_FIRST_MOVE, -1);
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
	OPERANT_REWARD - Does exactly what reward does. This was LFH's idea
*****************************************************/
void state_operant_reward()
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
	if ((_isLickOnset && (_params[USE_LEVER] == 0)) || (_isLeverPressOnset && (_params[USE_LEVER] == 1)))
	{
		// First lick registration
		if (!_firstMoveRegistered)
		{
			_firstMoveRegistered = true;
			sendEventMarker(EVENT_FIRST_MOVE, -1);
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

	_state = STATE_OPERANT_REWARD;
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

		// Retract lever/tube based on trial type
		if (_params[USE_LEVER] == 1)
		{
			deployLever(false);
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

		// Retract lever/tube based on trial type
		if (_params[USE_LEVER] == 1)
		{
			deployLever(false);
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

	if (_command == 'W')
	{
		_state = STATE_ABORT;
		return;
	}

	_state = STATE_ABORT_EARLY;
}

/*****************************************************
	ABORT - Only happens in early move trial
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
	
		// Retract lever/tube based on trial type
		if (_params[USE_LEVER] == 1)
		{
			deployLever(false);
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
	if (_command == 'E')
	{
		_state = STATE_INTERTRIAL;
		return;
	}

	_state = STATE_ABORT;
}

/*****************************************************
	ABORT_NO_MOVE - No lick timeout
*****************************************************/
void state_abort_no_move()
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
	
		// Retract lever/tube based on trial type
		if (_params[USE_LEVER] == 1)
		{
			deployLever(false);
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
	if (_command == 'E')
	{
		_state = STATE_INTERTRIAL;
		return;
	}

	_state = STATE_ABORT_NO_MOVE;
}

/*****************************************************
	INTERTRIAL
*****************************************************/
void state_intertrial()
{
	static long timeIntertrial;
	static bool isParamsUpdateStarted;
	static bool isParamsUpdateDone;
	static bool isLeverRetracted;
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

		// Send results
		sendResultCode(_resultCode);
		_resultCode = -1;

		// Register time of state entry
		timeIntertrial = getTimeSinceStimOn();

		// Variables for handling parameter update
		isParamsUpdateStarted = false;
		isParamsUpdateDone = false;

		// Set lever/tube retracted to false
		isLeverRetracted = false;
		isTubeRetracted = false;
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

	if (getTimeSinceStimOn() - timeIntertrial >= (_params[ITI_DURATION] / 2))
	{
		// Retract lever/tube based on trial type
		if ((_params[USE_LEVER] == 1) && isLeverRetracted == false)
		{
			deployLever(false);
			isLeverRetracted = true;
		}
		else if ((_params[USE_LEVER] == 0) && isTubeRetracted == false)
		{
			deployTube(false);
			isTubeRetracted = true;
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

// Lever detection
bool getLeverState() 
{
	if (digitalRead(PIN_LEVER) == HIGH) 
	{
		return true;
	}
	else 
	{
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
