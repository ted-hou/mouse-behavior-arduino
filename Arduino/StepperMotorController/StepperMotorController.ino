#include "src/XNucleoDualStepperDriver/XNucleoDualStepperDriver.h"
#include "src/XNucleoDualStepperDriver/dSPINConstants.h"
#include <SPI.h>
#include <math.h>


// ###### Customize these variables for your setup ######

// === 1) Motor setup ===

// ## The following settings are for the Pololu #1206 stepper (670mA @ 4.5V)
#define V_SUPPLY 9   // DC supply voltage
#define V_MOTOR 5.6   // motor's nominal voltage (in V)
#define Ithresh OCD_TH_1125mA // over-current threshold
// Velocity/accleration profile:
// From stop, motor will first jump to minSpeed, then accelerate
// at accelRate up to (at most) maxSpeed.
// Deceleration rate is also set to be accelRate.
// const int minSpeed = 160; // in steps/s;
// const int maxSpeed = 500; // in steps/s
// const int accelRate = 1000; // in steps/s^2

// === 2) Conversion to physical units ===

// Conversion from steps to physical units (cm, degrees, pixels, etc...):
// ======================================================================
// How many full steps in single motor revolution?
// (property of the stepper motor; typically 200)
#define FULL_STEPS_PER_MOTOR_REV 200
#define MICROSTEPS_PER_MOTOR_REV (8 * FULL_STEPS_PER_MOTOR_REV)
// How many phyical units of translation in one complete motor revolution?
//    (Units could be pixels, mm, degrees, etc...)
// We can compute our conversion factor:
#define UNITS_PER_MICROSTEP (_params[UNITS_PER_REV] / (float)MICROSTEPS_PER_MOTOR_REV)

// Extra boost for acceleration; Reduce power for holding still
#define K_ACCL 1.2 // fraction of full voltage for acceleration
#define K_RUN  1.0 // fraction of full voltage for const. vel.
#define K_HOLD 0.5 // fraction of full voltage for holding

// ========  SPI/Motor Settings  ==============
#define PIN_RESET 4
#define PIN_SCK 13
#define PIN_CS A2
#define PIN_BUSY A5
#define PIN_FLAG A4
XNucleoStepper motor(0, PIN_CS, PIN_RESET, PIN_BUSY);
XNucleoStepper motor2(1, PIN_CS, PIN_RESET);

#define PIN_MOTOR_TARGET_1 5
#define PIN_MOTOR_TARGET_2 6
#define PIN_MOTOR_BUSY 7

/*****************************************************
	States, Events, Results
*****************************************************/
enum State {_STATE_INIT, STATE_IDLE, STATE_MOVING, STATE_AT_TARGET, _NUM_STATES};
static const char *_stateNames[] = {"_INIT", "IDLE", "MOVING", "AT_TARGET"};
static const int _stateCanUpdateParams[] = {0, 1, 0, 1};

enum EventMarker {EVENT_MOVE_START, EVENT_MOVE_STOP, _NUM_EVENT_MARKERS};
static const char *_eventMarkerNames[] = {"MOVE_START", "MOVE_STOP"};

enum ResultCode {CODE_SUCCESS, CODE_ABORT, _NUM_RESULT_CODES};
static const char *_resultCodeNames[] = {"SUCCESS", "ABORT"};

enum ParamID
{
	_DEBUG,
	UNITS_PER_REV,
	MOTOR_MIN_SPEED,
	MOTOR_MAX_SPEED,
	MOTOR_ACCEL,
	TARGET_1,
	TARGET_2,
	TARGET_3,
	TARGET_4,
	TARGET_TOLERANCE,
	_NUM_PARAMS
};

static const char *_paramNames[] = 
{
	"_DEBUG",
	"UNITS_PER_REV",
	"MOTOR_MIN_SPEED",
	"MOTOR_MAX_SPEED",
	"MOTOR_ACCEL",
	"TARGET_1",
	"TARGET_2",
	"TARGET_3",
	"TARGET_4",
	"TARGET_TOLERANCE"
};

float _params[_NUM_PARAMS] =
{
	0,		// _DEBUG
	10,		// UNITS_PER_REV (should be ~9.4mm per 360 deg, we'll round to 10)
	10,		// MOTOR_MIN_SPEED
	20,		// MOTOR_MAX_SPEED
	20,		// MOTOR_ACCEL
	-125,	// TARGET_1
	-50,	// TARGET_2
	50,		// TARGET_3
	125,	// TARGET_4
	1		// TARGET_TOLERANCE
};

bool _isMotorParam[_NUM_PARAMS] =
{
	false,	// _DEBUG
	true,	// UNITS_PER_REV
	true,	// MOTOR_MIN_SPEED
	true,	// MOTOR_MAX_SPEED
	true,	// MOTOR_ACCEL
	false,	// TARGET_1
	false,	// TARGET_2
	false,	// TARGET_3
	false,	// TARGET_4
	false	// TARGET_TOLERANCE
};

// Framework variables
static long _timeReset = 0;
static int _resultCode = -1;
static State _state = _STATE_INIT;
static State _prevState = _STATE_INIT;
static char _command = ' ';
static float _arguments[2] = {0};
static float motorTarget = 0;
static bool useMoveCommand = false;
static float moveCommandDistance = 0;

void setup()
{
	pinMode(PIN_MOTOR_TARGET_1, INPUT);
	pinMode(PIN_MOTOR_TARGET_2, INPUT);
	pinMode(PIN_MOTOR_BUSY, OUTPUT);
	digitalWrite(PIN_MOTOR_BUSY, LOW);

	Serial.begin(115200);

	// Start by setting up the pins and the SPI peripheral.
	//  The library doesn't do this for you!
	configSPI();
	configMotor(&motor);

	// // Try to use stall detection
	// // 2021-05-13 OM: Can't get it working well. Skipping for now.
	// motor.setParam(STALL_TH, 26); // values from 0-127; represent 31.25 mA – 4 A

	// reset alarms on both motors (to turn off (red) alarm LED
	// on XNucleo board)
	motor.getAlarmStatusString();
	motor2.getAlarmStatusString();
}

void mySetup()
{
	// Reset variables
	motorTarget = 0;
	useMoveCommand = false;
	moveCommandDistance = 0;
	_timeReset				= 0;			// Reset to signedMillis() at every soft reset
	_resultCode				= -1;			// Result code. -1 if there is no result.
	_state					= _STATE_INIT;	// This variable (current _state) get passed into a _state function, which determines what the next _state should be, and updates it to the next _state.
	_prevState				= _STATE_INIT;	// Remembers the previous _state from the last loop (actions should only be executed when you enter a _state for the first time, comparing currentState vs _prevState helps us keep track of that).
	_command				= ' ';			// Command char received from host, resets on each loop
	_arguments[0]			= 0;			// Two integers received from host , resets on each loop
	_arguments[1]			= 0;			// Two integers received from host , resets on each loop

	unlockMotor();
	hostInit();
}

void loop()
{
	mySetup();

	while (true)
	{
		// Check USB for MESSAGE from HOST, if available. String is read byte by byte.
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

		// Stop motor if error
		if (digitalRead(PIN_FLAG)==LOW) {
			Serial.println(motor.getAlarmStatusString());
			unlockMotor();
		}

		// Update state machine
		switch (_state)
		{
			case _STATE_INIT:
			case STATE_IDLE:
				state_idle();
				break;
			case STATE_MOVING:
				state_moving();
				break;
			case STATE_AT_TARGET:
				state_at_target();
				break;
		}
	}
}

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
		unlockMotor();
		useMoveCommand = false;
		digitalWrite(PIN_MOTOR_BUSY, LOW);
	}

	/*****************************************************
		OnEachLoop checks
	*****************************************************/
	// Received new param from host: format "P _paramID _newValue" ('P' for Parameters)
	if (_command == 'P') 
	{
		int iParam = (int)_arguments[0];
		_params[iParam] = _arguments[1];
		if (_isMotorParam[iParam])
		{
			updateMotor(&motor);
		}
	}

	// Set current pos as zero
	if (_command == 'Z')
	{
		zero();
	}

	// Unlock motor to allow moving by hand (softstop)
	if (_command == 'U')
	{
		unlockMotor();
	}

	// Lock motor to (softHiZ)
	if (_command == 'L')
	{
		lockMotor();
	}

	/*****************************************************
		TRANSITION LIST
	*****************************************************/
	// Move by distance command "M distFloat"
	if (_command == 'M')
	{
		useMoveCommand = true;
		moveCommandDistance = _arguments[0];
		motorTarget = getPos() + moveCommandDistance;
		_state = STATE_MOVING;
		return;
	}

	if (_command == 'G')
	{
		useMoveCommand = false;
		motorTarget = parseMotorTarget();
		_state = STATE_MOVING;
		return;
	}

	_state = STATE_IDLE;
}

void state_moving() 
{
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);

		moveTo(motorTarget);

		digitalWrite(PIN_MOTOR_BUSY, HIGH);
	}

	/*****************************************************
		TRANSITION LIST
	*****************************************************/
	if (_command == 'Q') 
	{
		_state = STATE_IDLE;
		return;
	}

	if (!motor.busyCheck()) 
	{
		sendDebugMessage("Target reached, current position: " + String(getPos()));
		if (useMoveCommand)
		{
			_state = STATE_IDLE;
			return;
		}
		else
		{
			_state = STATE_AT_TARGET;
			return;
		}
	}

	_state = STATE_MOVING;
}

void state_at_target() 
{
	/*****************************************************
		ACTION LIST
	*****************************************************/
	if (_state != _prevState) 
	{
		// Register new state
		_prevState = _state;
		sendState(_state);
		sendResultCode(CODE_SUCCESS);
		unlockMotor();
		digitalWrite(PIN_MOTOR_BUSY, LOW);
	}

	/*****************************************************
		OnEachLoop checks
	*****************************************************/
	// Received new param from host: format "P _paramID _newValue" ('P' for Parameters)
	if (_command == 'P') 
	{
		int iParam = (int)_arguments[0];
		_params[iParam] = _arguments[1];
		if (_isMotorParam[iParam])
		{
			updateMotor(&motor);
		}
	}


	/*****************************************************
		TRANSITION LIST
	*****************************************************/
	if (_command == 'Q') 
	{
		_state = STATE_IDLE;
		return;
	}

	if (abs(parseMotorTarget() - motorTarget) > _params[TARGET_TOLERANCE])
	{
		useMoveCommand = false;
		motorTarget = parseMotorTarget();
		_state = STATE_MOVING;
		return;
	}
	_state = STATE_AT_TARGET;
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
		Serial.println(message.c_str());
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

// GET ARGUMENTS (of the command) from HOST (2 float array)
void getArguments(String message, float *_arguments)
{
	_arguments[0] = 0;
	_arguments[1] = 0;

	message.trim();				// Remove leading and trailing white space

	// Remove command (first character) from string
	String parameters = message;
	parameters.remove(0,1);
	parameters.trim();

	// Parse first (optional) float argument if it exists
	String flaotString = "";
	while ((parameters.length() > 0) && (isDigit(parameters[0]) || parameters[0]=='-' || parameters[0]=='.')) 
	{
		flaotString += parameters[0];
		parameters.remove(0,1);
	}
	_arguments[0] = flaotString.toFloat();


	// Parse second (optional) integer argument if it exists
	parameters.trim();
	flaotString = "";
	while ((parameters.length() > 0) && (isDigit(parameters[0]) || parameters[0]=='-' || parameters[0]=='.')) 
	{
		flaotString += parameters[0];
		parameters.remove(0,1);
	}
	_arguments[1] = flaotString.toFloat();
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

/*****************************************************
	Motor
*****************************************************/
void configSPI() 
{
	pinMode(PIN_RESET, OUTPUT);
	pinMode(MOSI, OUTPUT);
	pinMode(MISO, INPUT);
	pinMode(PIN_SCK, OUTPUT);
	pinMode(PIN_CS, OUTPUT);
	digitalWrite(PIN_CS, HIGH);
	digitalWrite(PIN_RESET, LOW);
	digitalWrite(PIN_RESET, HIGH);
	SPI.begin();
	SPI.setDataMode(SPI_MODE3);
}

void configMotor(XNucleoStepper* motor)
{
	Serial.println("Configuring motor...");

	// Before we do anything, we need to tell each board which SPI
	//  port we're using. Most of the time, there's only the one,
	//  but it's possible for some larger Arduino boards to have more
	//  than one, so don't take it for granted.
	motor->SPIPortConnect(&SPI);

	// DEBUG(String("POS: ") + motor->getPos());
	// DEBUG(String("OCThreshold: ") + motor->getOCThreshold());
	// DEBUG(String("RunKVAL: ") + motor->getRunKVAL());
	// DEBUG(String("AccKVAL: ") + motor->getAccKVAL());
	// DEBUG(String("DecKVAL: ") + motor->getDecKVAL());
	// DEBUG(String("HoldKVAL: ") + motor->getHoldKVAL());
	// DEBUG(String("MinSpeed: ") + motor->getMinSpeed());
	// DEBUG(String("MaxSpeed: ") + motor->getMaxSpeed());
	// DEBUG(String("FullSpeed: ") + motor->getFullSpeed());
	// DEBUG(String("Acc: ") + motor->getAcc());
	// DEBUG(String("Dec: ") + motor->getDec());
	// DEBUG(String("StepMode: ") + motor->getStepMode());

	// Set the Overcurrent Threshold. The OC detect circuit
	//  is quite sensitive; even if the current is only momentarily
	//  exceeded during acceleration or deceleration, the driver
	//  will shutdown. This is a per channel value; it's useful to
	//  consider worst case, which is startup.
	motor->setOCThreshold(Ithresh);
	// DEBUG(String("OCThreshold: ") + motor->getOCThreshold());

	// KVAL is a modifier that sets the effective voltage applied
	//  to the motor. KVAL/255 * Vsupply = effective motor voltage.
	//  This lets us hammer the motor harder during some phases
	//  than others, and to use a higher voltage to achieve better
	//  torqure performance even if a motor isn't rated for such a
	//  high current.
	float Kval = (float)V_MOTOR/(float)V_SUPPLY * 255;
	motor->setRunKVAL(round(K_RUN*Kval));
	// DEBUG(String("RunKVAL: ") + motor->getRunKVAL());
	motor->setAccKVAL(round(K_ACCL*Kval));
	// DEBUG(String("AccKVAL: ") + motor->getAccKVAL());
	motor->setDecKVAL(round(K_ACCL*Kval));
	// DEBUG(String("DecKVAL: ") + motor->getDecKVAL());
	motor->setHoldKVAL(round(K_HOLD*Kval));
	// DEBUG(String("HoldKVAL: ") + motor->getHoldKVAL());

	// When a move command is issued, max speed is the speed the
	//  motor tops out at while completing the move, in steps/s
	motor->setMinSpeed(getMinSpeed());
	// DEBUG(String("MinSpeed: ") + motor->getMinSpeed());
	motor->setMaxSpeed(getMaxSpeed());
	// DEBUG(String("MaxSpeed: ") + motor->getMaxSpeed());
	motor->setFullSpeed(getMaxSpeed()*2);       // microstep below this speed
	// DEBUG(String("FullSpeed: ") + motor->getFullSpeed());


	// Acceleration and deceleration in steps/s/s. Increasing this
	//  value makes the motor reach its full speed more quickly,
	//  at the cost of possibly causing it to slip and miss steps.
	motor->setAcc(getAccel());
	// DEBUG(String("Acc: ") + motor->getAcc());
	motor->setDec(getAccel());
	// DEBUG(String("Dec: ") + motor->getDec());

	motor->configStepMode(STEP_FS_8);    // microsteps per step
	// DEBUG(String("StepMode: ") + motor->getStepMode());

	// // Not sure if we need any of these:
	// motor->configSyncPin(BUSY_PIN, 0);// BUSY pin low during operations;
	//                                   //  second paramter ignored.
	// motor->setSlewRate(SR_530V_us);   // Upping the edge speed increases torque.
	// motor->setPWMFreq(PWM_DIV_2, PWM_MUL_2); // 31.25kHz PWM freq
	// motor->setOCShutdown(OC_SD_DISABLE); // don't shutdown on OC
	// motor->setVoltageComp(VS_COMP_DISABLE); // don't compensate for motor V
	// motor->setSwitchMode(SW_USER);    // Switch is not hard stop
	// motor->setOscMode(INT_16MHZ_OSCOUT_16MHZ); // 16MHz internal oscil

	sendDebugMessage(String("POS: ") + motor->getPos());
	sendDebugMessage(String("OCThreshold: ") + motor->getOCThreshold());
	sendDebugMessage(String("RunKVAL: ") + motor->getRunKVAL());
	sendDebugMessage(String("AccKVAL: ") + motor->getAccKVAL());
	sendDebugMessage(String("DecKVAL: ") + motor->getDecKVAL());
	sendDebugMessage(String("HoldKVAL: ") + motor->getHoldKVAL());
	sendDebugMessage(String("MinSpeed: ") + motor->getMinSpeed());
	sendDebugMessage(String("MaxSpeed: ") + motor->getMaxSpeed());
	sendDebugMessage(String("FullSpeed: ") + motor->getFullSpeed());
	sendDebugMessage(String("Acc: ") + motor->getAcc());
	sendDebugMessage(String("Dec: ") + motor->getDec());
	sendDebugMessage(String("StepMode: ") + motor->getStepMode());
}

void updateMotor(XNucleoStepper* motor)
{
	motor->setMinSpeed(getMinSpeed());
	motor->setMaxSpeed(getMaxSpeed());
	motor->setFullSpeed(getMaxSpeed()*2);
	motor->setAcc(getAccel());
	motor->setDec(getAccel());

	sendDebugMessage(String("MinSpeed: ") + motor->getMinSpeed());
	sendDebugMessage(String("MaxSpeed: ") + motor->getMaxSpeed());
	sendDebugMessage(String("FullSpeed: ") + motor->getFullSpeed());
	sendDebugMessage(String("Acc: ") + motor->getAcc());
	sendDebugMessage(String("Dec: ") + motor->getDec());
}

void setMaxSpeed(float speed)
{
	motor.setMaxSpeed(speed);
}

void setAccel(float acc)
{
	motor.setAcc(acc);
	motor.setDec(acc);
}

void unlockMotor()
{
	motor.softHiZ();
}

void lockMotor()
{
	motor.softStop();
}

void move(float distance)
{
	if (abs(distance) < 1)
	{
		sendDebugMessage("Move command not executed, distance = " + String(distance/UNITS_PER_MICROSTEP));
		return;
	}
	sendDebugMessage("Move command, distance = " + String(distance/UNITS_PER_MICROSTEP));
	if (distance >= 0)
	{
		motor.move(FWD, distance/UNITS_PER_MICROSTEP);
	}
	else
	{
		motor.move(REV, -distance/UNITS_PER_MICROSTEP);
	}
}

void moveTo(float pos)
{
	sendDebugMessage("MoveTo command, from " + String(getPos()) + " to " + String(pos));
	move(pos - getPos());
}

void zero()
{
	motorTarget = 0;
	motor.resetPos();
}

int getMinSpeed()
{
	return round(_params[MOTOR_MIN_SPEED] / _params[UNITS_PER_REV] * FULL_STEPS_PER_MOTOR_REV);
}

int getMaxSpeed()
{
	return round(_params[MOTOR_MAX_SPEED] / _params[UNITS_PER_REV] * FULL_STEPS_PER_MOTOR_REV);
}

int getAccel()
{
	return round(_params[MOTOR_ACCEL] / _params[UNITS_PER_REV] * FULL_STEPS_PER_MOTOR_REV);
}

float parseMotorTarget()
{
	// sendDebugMessage("PIN1 = " + String(digitalRead(PIN_MOTOR_TARGET_1)) + "," + "PIN2 = " + String(digitalRead(PIN_MOTOR_TARGET_2)));
	int targetIndex = 0;
	if (digitalRead(PIN_MOTOR_TARGET_1) == LOW)
	{
		if (digitalRead(PIN_MOTOR_TARGET_2) == LOW)
		{
			targetIndex = 0;
		}
		else
		{
			targetIndex = 1;
		}
	}
	else
	{
		if (digitalRead(PIN_MOTOR_TARGET_2) == LOW)
		{
			targetIndex = 2;
		}
		else
		{
			targetIndex = 3;
		}
	}

	float targetPos;

	switch (targetIndex)
	{
		case 0:
			targetPos = _params[TARGET_1];
			break;
		case 1:
			targetPos = _params[TARGET_2];
			break;
		case 2:
			targetPos = _params[TARGET_3];
			break;
		case 3:
			targetPos = _params[TARGET_4];
			break;
	}
	return targetPos;
}

bool atPos(float target, float tolerance)
{
	if (abs(target - getPos()) <= tolerance)
	{
		return true;
	}
	else
	{
		return false;
	}
}


float getPos() 
{
	// sendDebugMessage("getPos request returned: " + String(motor.getPos()) + " * " + String(UNITS_PER_MICROSTEP));
	return motor.getPos() * UNITS_PER_MICROSTEP;
}
