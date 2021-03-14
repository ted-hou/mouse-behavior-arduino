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

// E - Is this the End? (Max trial length)

/*****************************************************
	Servo stuff
*****************************************************/
Servo _servoTubeL;
Servo _servoTubeR;

/*****************************************************
	Arduino Pin Outs
*****************************************************/
// Teensy Board Pins
// Digital OUT
#define PIN_REWARD		24	// SOL_1, which is Juice 2  
#define PIN_IR_LAMP		8	// DIO_2
#define PIN_HOUSE_LAMP	9	// DIO_3?
// need to check pcb schematic

// PWM OUT
#define PIN_SERVO_TUBE_L	6	// DIO_0
#define PIN_SERVO_TUBE_R	7	// DIO_1

// Digital IN
#define PIN_LICK_L		25	// Dedicated, not broken out
#define PIN_LICK_R		26	// Dedicated, not broken out

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
	STATE_STIM_ON,				// White noise left or right
	STATE_DELAY,				// Enforced no lick
	STATE_RESPONSE_WINDOW,		// First lick in this interval rewarded
	STATE_REWARD,				// Dispense reward, wait for trial timeout
	STATE_POST_WINDOW,			// No lick - timeout
	STATE_ABORT,				// Basically a transition state for early licks
	STATE_ABORT_EARLY,			// Early lick
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
	"STIM_ON",
	"DELAY",
	"RESPONSE_WINDOW",
	"REWARD",
	"POST_WINDOW",
	"ABORT",
	"ABORT_EARLY",
};

// Define which states accept parameter update from MATLAB
static const int _stateCanUpdateParams[] = {0,1,1,0,0,0,0,0,0,0,0,0,0}; 

/*****************************************************
	Event Markers
*****************************************************/
enum EventMarker
{
	EVENT_TRIAL_START,				// New trial initiated
	EVENT_TUBE_L_RETRACT_START,		// Tube retract start
	EVENT_TUBE_L_RETRACT_END,		// Tube retract end
	EVENT_TUBE_L_DEPLOY_START,		// Tube deploy start
	EVENT_TUBE_L_DEPLOY_END,		// Tube deploy end
	EVENT_TUBE_R_RETRACT_START,		// Tube retract start
	EVENT_TUBE_R_RETRACT_END,		// Tube retract end
	EVENT_TUBE_R_DEPLOY_START,		// Tube deploy start
	EVENT_TUBE_R_DEPLOY_END,		// Tube deploy end
	EVENT_LICK,						// Lick onset
	EVENT_LICK_OFF,					// Lick offset
	EVENT_STIM_ON,					// Stim on
	EVENT_STIM_OFF,					// Stim off
	EVENT_GO_CUE_ON,				// Go cue on
	EVENT_GO_CUE_OFF,				// Go cue off
	EVENT_REWARD_ON,				// Reward, juice valve on
	EVENT_REWARD_OFF,				// Reward, juice valve off
	EVENT_ABORT,					// Trial aborted
	EVENT_ABORT_EARLY,				// Trial aborted due to early lick
	EVENT_ITI,						// ITI
	_NUM_OF_EVENT_MARKERS
};

static const char *_eventMarkerNames[] =
{
	"TRIAL_START",					// New trial initiated
	"TUBE_L_RETRACT_START",			// Tube retract start
	"TUBE_L_RETRACT_END",			// Tube retract end
	"TUBE_L_DEPLOY_START",			// Tube deploy start
	"TUBE_L_DEPLOY_END",			// Tube deploy end"
	"TUBE_RETRACT_R_START",			// Tube retract start
	"TUBE_RETRACT_R_END",			// Tube retract end
	"TUBE_DEPLOY_R_START",			// Tube deploy start
	"TUBE_DEPLOY_R_END",			// Tube deploy end
	"LICK",							// Lick onset
	"LICK_OFF",						// Lick offset
	"STIM_ON",						// Stim on
	"STIM_OFF",						// Stim off
	"GO_CUE_ON",					// Go cue on
	"GO_CUE_OFF",					// Go cue off
	"REWARD_ON",					// Reward, juice valve on
	"REWARD_OFF",					// Reward, juice valve off
	"ABORT",						// Trial aborted
	"ABORT_EARLY",					// Trial aborted due to early lick
	"ITI"							// ITI
};

/*****************************************************
	Result codes
*****************************************************/
enum ResultCode
{
	CODE_CORRECT,			// Correct lick L or R
	CODE_INCORRECT,			// Incorrect lick L or R
	CODE_PAVLOVIAN,			// Pavlovian (Reward given at tone)
	CODE_EARLY_LICK,		// Early Lick (-> Abort)
	CODE_LATE_LICK,			// Lick after response window (-> Abort)
	CODE_NO_LICK,			// No Lick (Timeout -> ITI)
	_NUM_RESULT_CODES		// (Private) Used to count how many codes there are.
};

// We'll send result code translations to MATLAB at startup
static const char *_resultCodeNames[] =
{
	"CORRECT",
	"INCORRECT",
	"PAVLOVIAN",
	"EARLY_LICK",
	"LATE_LICK",
	"NO_LICK"
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
	STIM_DURATION, 				// White noise stim length
	GO_CUE_DURATION,			// Tone length
	ITI_DURATION,				// ITI length, fixed
	LICK_TIMEOUT,				// Delay ends if premature lick --> 
	REWARD_DURATION,			// Reward duration (ms)
	DELAY_DURATION,				// Delay length
	ALLOW_EARLY_LICK,			// 0 to abort trial if animal licks after in pre-window
	NO_LICK_TIMEOUT,			// Timeout before next trial
	LICK_REWARD,				// If mouse presses licks, gets reward
	PAVLOVIAN,					// Pavlovian = 1, Operant = 0
	TIMING,						// Elapsed time informative = 1, Not = 0
	MU,							// Mean trial length 
	SIGMA,						// Standard deviation for trial length
	MIN_TRIAL_LENGTH,			// Minimum possible trial length in seconds
	TUBE_L_POS_RETRACTED,		// Servo (juice tube) position when juice tube is retracted (full is ~ 50)
	TUBE_L_POS_DEPLOYED,		// Servo (juice tube) position when juice tube is deployed (full is ~ 125)
	TUBE_L_SPEED_DEPLOY,		// Servo (juice tube) advance speed when deploying, 0 for max speed
	TUBE_L_SPEED_RETRACT,		// Servo (juice tube) retract speed when retracting, 0 for max speed
	TUBE_R_POS_RETRACTED,		// Servo (juice tube) position when juice tube is retracted (full is ~ 50)
	TUBE_R_POS_DEPLOYED,		// Servo (juice tube) position when juice tube is deployed (full is ~ 125)
	TUBE_R_SPEED_DEPLOY,		// Servo (juice tube) advance speed when deploying, 0 for max speed
	TUBE_R_SPEED_RETRACT,		// Servo (juice tube) retract speed when retracting, 0 for max speed
 	_NUM_PARAMS					// (Private) Used to count how many parameters there are so we can initialize the param array with the correct size. Insert additional parameters before this.
};

// Store parameter names as strings, will be sent to host
// Names cannot contain spaces!!!
static const char *_paramNames[] = 
{
	"_DEBUG",					// (Private) 1 to enable debug mode. Default 0.
	"STIM_DURATION", 			// White noise stim length
	"GO_CUE_DURATION",			// Tone length
	"ITI_DURATION",				// ITI length, fixed
	"LICK_TIMEOUT",				// Delay ends if premature lick 
	"REWARD_DURATION",			// Reward duration (ms)
	"DELAY_DURATION",			// Delay length
	"ALLOW_EARLY_LICK",			// 0 to abort trial if animal licks after in pre-window
	"NO_LICK_TIMEOUT",			// Timeout before next trial
	"LICK_REWARD",				// If mouse presses licks, gets reward
	"PAVLOVIAN",				// Pavlovian = 1, Operant = 0
	"TIMING",					// Elapsed time informative = 1, Not = 0
	"MU",						// Mean trial length 
	"SIGMA",					// Standard deviation for trial length
	"MIN_TRIAL_LENGTH",			// Minimum possible trial length in seconds
	"TUBE_L_POS_RETRACTED",		// Servo (juice tube) position when juice tube is retracted (full is ~ 50)
	"TUBE_L_POS_DEPLOYED",		// Servo (juice tube) position when juice tube is deployed (full is ~ 125)
	"TUBE_L_SPEED_DEPLOY",		// Servo (juice tube) advance speed when deploying, 0 for max speed
	"TUBE_L_SPEED_RETRACT",		// Servo (juice tube) retract speed when retracting, 0 for max speed
	"TUBE_R_POS_RETRACTED",		// Servo (juice tube) position when juice tube is retracted (full is ~ 50)
	"TUBE_R_POS_DEPLOYED",		// Servo (juice tube) position when juice tube is deployed (full is ~ 125)
	"TUBE_R_SPEED_DEPLOY",		// Servo (juice tube) advance speed when deploying, 0 for max speed
	"TUBE_R_SPEED_RETRACT",		// Servo (juice tube) retract speed when retracting, 0 for max speed
};

// Initialize parameters
long _params[_NUM_PARAMS] = 
{
	0,		// _DEBUG
	1000,	// STIM_DURATION
	100,	// GO_CUE_DURATION
	10000,	// ITI_DURATION
	1500,	// LICK_TIMEOUT
	60,		// REWARD_DURATION
	3000,	// DELAY_DURATION
	0,		// ALLOW_EARLY_LICK
	1,		// EARLY_LICK_TIMEOUT
	0,		// LICK_REWARD
	0,		// PAVLOVIAN
	0, 		// REACTIVE
	0,		// TIMING	
	4,		// MU
	2,		// SIGMA
	2,		// MIN_TRIAL_LENGTH
	85,		// TUBE_POS_RETRACTED (~ 50 == 0 mm)
	100,	// TUBE_POS_DEPLOYED (~ 125 == 30 mm)
	18,		// TUBE_SPEED_DEPLOY
	18		// TUBE_SPEED_RETRACT
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
static long _timeReset						= 0;			// Reset to signedMillis() at every soft reset
static long _timeTrialStart					= 0;			// Reset to 0 at start of trial
static long _timeStimOn						= 0;			// Reset to 0 at cue on
static int _resultCode						= -1;			// Result code. -1 if there is no result.
static State _state							= _STATE_INIT;	// This variable (current _state) get passed into a _state function, which determines what the next _state should be, and updates it to the next _state.
static State _prevState						= _STATE_INIT;	// Remembers the previous _state from the last loop (actions should only be executed when you enter a _state for the first time, comparing currentState vs _prevState helps us keep track of that).
static char _command						= ' ';			// Command char received from host, resets on each loop
static int _arguments[2]					= {0};			// Two integers received from host , resets on each loop

static bool _isLicking 						= false;		// True if the little dude is licking
static bool _isLickOnset 					= false;		// True during lick onset
static bool _firstLickRegistered 			= false;		// True when first lick is registered for this trial
static long _timeLastLick					= 0;			// Time (ms) when last lick occured
		
static ServoState _servoStateTubeL 			= _SERVOSTATE_INIT;					// Servo state
static long _servoStartTimeTubeL			= 0;								// When servo started moving retrieved using getTime()
static long _servoSpeedTubeL				= _params[TUBE_L_SPEED_RETRACT];	// Speed of servo movement (deg/s)
static long _servoStartPosTubeL				= _params[TUBE_L_POS_DEPLOYED];		// Starting position of servo when rotation begins
static long _servoTargetPosTubeL			= _params[TUBE_L_POS_DEPLOYED];		// Target position of servo

static ServoState _servoStateTubeR 			= _SERVOSTATE_INIT;					// Servo state
static long _servoStartTimeTubeR			= 0;								// When servo started moving retrieved using getTime()
static long _servoSpeedTubeR				= _params[TUBE_R_SPEED_RETRACT];	// Speed of servo movement (deg/s)
static long _servoStartPosTubeR				= _params[TUBE_R_POS_DEPLOYED];		// Starting position of servo when rotation begins
static long _servoTargetPosTubeR			= _params[TUBE_R_POS_DEPLOYED];		// Target position of servo

/*****************************************************
	Setup
*****************************************************/
void setup()
{
	// Init pins
	pinMode(PIN_REWARD, OUTPUT);		// Reward, set to HIGH to open juice valve
	pinMode(PIN_IR_LAMP, OUTPUT);		// IR LED for camera recording
	pinMode(PIN_HOUSE_LAMP, OUTPUT);	// LED
	pinMode(PIN_LICK_L, INPUT);			// Lick detector
	pinMode(PIN_LICK_R, INPUT);			// Lick detector


	// Setting unused pins low
	pinMode(4, OUTPUT);
	digitalWrite(4, LOW);
	pinMode(5, OUTPUT);
	digitalWrite(5, LOW);
	// ppinMode(9, OUTPUT);
	// ddigitalWrite(9, LOW);
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
	_servoLever.attach(PIN_SERVO_TUBE_L);
	_servoTube.attach(PIN_SERVO_TUBE_R);

	// Serial comms
	Serial.begin(115200);			// Set up USB communication at 115200 baud 
}

void mySetup()
{
	// Reset output
	// setIRLamp(true);                        // IR Lamp ON

	// Reset variables
	_timeReset						= 0;			// Reset to signedMillis() at every soft reset
	_timeTrialStart					= 0;			// Reset to 0 at start of trial
	_timeStimOn						= 0;
	_resultCode						= -1;			// Result code. -1 if there is no result.
	_state							= _STATE_INIT;	// This variable (current _state) get passed into a _state function, which determines what the next _state should be, and updates it to the next _state.
	_prevState						= _STATE_INIT;	// Remembers the previous _state from the last loop (actions should only be executed when you enter a _state for the first time, comparing currentState vs _prevState helps us keep track of that).
	_command						= ' ';			// Command char received from host, resets on each loop
	_arguments[2]					= {0};			// Two integers received from host , resets on each loop
		
	_isLicking 						= false;		// True if the little dude is licking
	_isLickOnset 					= false;		// True during lick onset
	_firstLickRegistered 			= false;		// True when first lick is registered for this trial
	_timeLastLick					= 0;			// Time (ms) when last lick occured

	_servoStateTubeL				= _SERVOSTATE_INIT;					// Servo state
	_servoStartTimeTubeL			= 0;								// When servo started moving retrieved using getTime()
	_servoSpeedTubeL				= _params[TUBE_L_SPEED_RETRACT]; 	// Speed of servo movement (deg/s)
	_servoStartPosTubeL				= _params[TUBE_L_POS_DEPLOYED];		// Starting position of servo when rotation begins
	_servoTargetPosTubeL			= _params[TUBE_L_POS_DEPLOYED];		// Target position of servo

	_servoStateTubeR				= _SERVOSTATE_INIT;					// Servo state
	_servoStartTimeTubeR			= 0;								// When servo started moving retrieved using getTime()
	_servoSpeedTubeR				= _params[TUBE_R_SPEED_RETRACT]; 	// Speed of servo movement (deg/s)
	_servoStartPosTubeR				= _params[TUBE_R_POS_DEPLOYED];		// Starting position of servo when rotation begins
	_servoTargetPosTubeR			= _params[TUBE_R_POS_DEPLOYED];		// Target position of servo

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
		// 2.1) Tube servo control
		handleServoTubeL();		
		// 2.2) Lever servo control
		handleServoLeverR();

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
			
			case STATE_STIM_ON:
				state_stim_on();
				break;

			case STATE_DELAY:
				state_delay();
				break;

			case STATE_RESPONSE_WINDOW:
				state_response_window();
				break;
			
			case STATE_REWARD:
				state_reward();
				break;

			case STATE_POST_WINDOW:
				state_post_window();
				break;

			case STATE_ABORT:
				state_abort();
				break;

			case STATE_ABORT_EARLY:
				state_abort_early();
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
		deployTubeL(true);
		deployTubeR(true);
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
	if ((_isLickOnset && _params[ALLOW_EARLY_LICK] == 0))
	{
		// Register result
		_resultCode = CODE_IGNORE;
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
	PRE_STIM - Deploy tubes
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

		deployTubeL(true);
		deployTubeR(true);

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

	// Early lick/lever-press detected --> ABORT
	if (_isLickOnset && _params[ALLOW_EARLY_LICK] == 0)
	{
		_resultCode = CODE_IGNORE;
		_state = STATE_ABORT;
		return;
	}

	// Tube deployed --> STIM_ON
	// Tube mode: make sure tube is deployed
	if (_servoStateTube == SERVOSTATE_DEPLOYED)
	{
		_state = STATE_STIM_ON;
		return;
	}
	
}

/*****************************************************
	STIM_ON
*****************************************************/
void state_stim_on() 
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



		// PLAY STIM	




	}

	/*****************************************************
		OnEachLoop checks
	*****************************************************/
	// First lick registration
	if (_isLickOnset)
	{
		if (!_firstLickRegistered)
		{
			_firstLickRegistered = true;
			sendEventMarker(EVENT_FIRST_LICK, -1);
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

	// Early lick detected --> ABORT
	if (_isLickOnset && (_params[ALLOW_EARLY_LICK] == 0)
	{
		// Register result
		_resultCode = CODE_EARLY_LICK;
		_state = STATE_ABORT;
		return;	
	}

	// stim_on elapsed --> DELAY
	if getTimeSinceStimOn() >= _params[STIM_DURATION]
	{
		_state = STATE_DELAY;
		return;
	}

	_state = STATE_STIM_ON;


/*****************************************************
	DELAY
*****************************************************/
void state_delay() 
{
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);

		sendEventMarker(EVENT_DELAY, -1);
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


	if (!_firstLickRegistered)
	{
		_firstLickRegistered = true;
		sendEventMarker(EVENT_FIRST_LICK, -1);
	}

	// Early lick detected --> ABORT
	if (_isLickOnset && (_params[ALLOW_EARLY_LICK] == 0))
	{
		// Register result
		_resultCode = CODE_EARLY_LICK;
		_state = STATE_ABORT_EARLY;
		return;	
	}

	// _delay elapsed --> RESPONSE_WINDOW
	if getTimeSinceStimOn() >= _params[DELAY_DURATION]
	{
		_state = STATE_RESPONSE_WINDOW;
		return;
	}

	_state = STATE_DELAY;
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
		if _isLickOnset
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
				_state = STATE_POST_WINDOW;
				return;
			}
		}
		else
		{
			if (_command == 'W')
			{
				_state = STATE_POST_WINDOW;
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
	if _isLickOnset
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
			// if (_params[USE_LEVER] == 1)
			// {
			// 	deployTube(true);
			// }
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
	Post Window - No lick or late lick timeout
*****************************************************/
void state_post_window()
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

	if _isLickOnset
	{
		// First lick registration
		if (!_firstLickRegistered)
		{
			_firstLickRegistered = true;
			sendEventMarker(EVENT_FIRST_LICK, -1);
			_resultCode = CODE_LATE_LICK;

			// Retract tubes
			deployTubeL(false);
			deployTubeR(false);
				
			_state = STATE_ABORT;
			return;
	}

	// Trial duration elapsed --> INTERTRIAL
	if (_command == 'E')
	{
		if (!_firstLickegistered)
		{
			_resultCode = CODE_NO_LICK;
			sendEventMarker(EVENT_ABORT, -1);

		}
		_state = STATE_INTERTRIAL;
		return;
	}

	_state = STATE_POST_WINDOW;
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

		// Retract tubes
		deployTubeL(false);
		deployTubeR(false);
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
	
		// Retract tubes
		deployTubeL(false);
		deployTubeR(false);
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

		// Set tube retracted to false
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

	if (getTimeSinceStimOn() - timeIntertrial >= (_params[ITI_DURATION]) / 2)
	{
		deployLeverL(false);
		deployLeverR(false);
		isLeverRetracted = true;
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
		if (((getTimeSinceStimOn() - timeIntertrial) >= _params[ITI_DURATION]) && (getTimeSinceLastLick() >= _params[LICK_TIMEOUT]))
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

// Toggle House Lamp
void setHouseLamp(bool turnOn) 
{
	if (turnOn) 
	{
		digitalWrite(PIN_HOUSE_LAMP, HIGH);
	}
	else 
	{
		digitalWrite(PIN_HOUSE_LAMP, LOW);
	}
}

// Lick detection
bool getLickStateR() 
{
	if (digitalRead(PIN_LICK_R) == HIGH) 
	{
		return true;
	}
	else 
	{
		return false;
	}
}

// Lick detection
bool getLickStateL() 
{
	if (digitalRead(PIN_LICK_L) == HIGH) 
	{
		return true;
	}
	else 
	{
		return false;
	}
}

// Must be called once and only once on each loop. Returns true during lick onset
void handleLickR() 
{
	if (getLickStateR() && !_isLicking)
	{
		_isLicking = true;
		_isLickOnset = true;
		_timeLastLick = getTime();
		sendEventMarker(EVENT_LICK, -1);
	}
	else
	{
		if (!getLickStateR() && _isLicking)
		{
			_isLicking = false;
			sendEventMarker(EVENT_LICK_OFF, -1);
		}
		_isLickOnset = false;
	}
}

void handleLickL() 
{
	if (getLickStateL() && !_isLicking)
	{
		_isLicking = true;
		_isLickOnset = true;
		_timeLastLick = getTime();
		sendEventMarker(EVENT_LICK, -1);
	}
	else
	{
		if (!getLickStateL() && _isLicking)
		{
			_isLicking = false;
			sendEventMarker(EVENT_LICK_OFF, -1);
		}
		_isLickOnset = false;
	}
}

// Use servo to retract/present lever to the little dude
void deployTubeR(bool deploy)
{
	if (deploy)
	{
		if (_servoStateTubeR != SERVOSTATE_DEPLOYED)
		{
			_servoStateTubeR = SERVOSTATE_DEPLOYING;
			sendEventMarker(EVENT_TUBE_DEPLOY_START, -1);
		}
		_servoStartTimeTubeR = getTime();
		_servoSpeedTubeR = _params[TUBE_R_SPEED_DEPLOY];
		_servoStartPosTubeR = _servoTube.read();
		_servoTargetPosTubeR = _params[TUBE_R_POS_DEPLOYED];
	}
	else
	{
		if (_servoStateTubeR != SERVOSTATE_RETRACTED)
		{
			_servoStateTubeR = SERVOSTATE_RETRACTING;
			sendEventMarker(EVENT_TUBE_R_RETRACT_START, -1);
		}
		_servoStartTimeTubeR = getTime();
		_servoSpeedTubeR = _params[TUBE_SPEED_RETRACT];
		_servoStartPosTubeR = _servoTube.read();
		_servoTargetPosTubeR = _params[TUBE_R_POS_RETRACTED];
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

// Returns time since stim on in milliseconds
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
