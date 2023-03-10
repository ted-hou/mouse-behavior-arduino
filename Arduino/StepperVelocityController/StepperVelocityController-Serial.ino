#include "src/XNucleoDualStepperDriver/XNucleoDualStepperDriver.h"
#include "src/XNucleoDualStepperDriver/dSPINConstants.h"
#include <SPI.h>
#include <math.h>

// ###### Customize these variables for your setup ######

// === 1) Motor setup ===

// ## The following settings are for the Pololu #1206 stepper (670mA @ 4.5V)
const float Vsupply = 9;   // DC supply voltage
const float Vmotor = 5.6;   // motor's nominal voltage (in V)

const byte Ithresh = OCD_TH_1125mA; // over-current threshold
																		// Set this to be somewhat larger than the motor's rated current.
																		// (see src/XNucleo.../dSPINConstants.h for list of possible values)

// Velocity/accleration profile:
// From stop, motor will first jump to minSpeed, then accelerate
// at accelRate up to (at most) maxSpeed.
// Deceleration rate is also set to be accelRate.
const int minSpeed = 160; // in steps/s;
const int maxSpeed = 500; // in steps/s
const int accelRate = 1000; // in steps/s^2
const int fullSpeed = 5000; // in steps/s; use microsteps below this speed
const float goToLimitSpeed = maxSpeed; // in steps/s

// // ## The following settings are for the OpenBuilds NEMA17 (1.68A @ 2.77V) stepper
// const float Vsupply = 12;   // DC supply voltage
// const float Vmotor = 2.77;   // motor's nominal voltage (in V)
// const byte Ithresh = OCD_TH_2625mA; // over-current threshold (or use OCD_TH_2250mA)
// // Velocity/accleration profile:
// // From stop, motor will first jump to minSpeed, then accelerate
// // at accelRate up to (at most) maxSpeed.
// // Deceleration rate is also set to be accelRate.
// const int minSpeed = 160; // in steps/s;
// const int maxSpeed = 500; // in steps/s
// const int accelRate = 1000; // in steps/s^2
// const int fullSpeed = 5000; // in steps/s; use microsteps below this speed
// const float goToLimitSpeed = maxSpeed; // in steps/s


// === 2) Conversion to physical units ===

// Conversion from steps to physical units (cm, degrees, pixels, etc...):
// ======================================================================
// How many full steps in single motor revolution?
// (property of the stepper motor; typically 200)
const int FULL_STEPS_PER_MOTOR_REV = 200;
// Microstep mode
const int stepMode = STEP_FS_8; // no microsteps
const int MICROSTEPS_PER_MOTOR_REV = 8 * FULL_STEPS_PER_MOTOR_REV;
// How many phyical units of translation in one complete motor revolution?
//    (Units could be pixels, mm, degrees, etc...)
const float UNITS_PER_MOTOR_REV = 360;
// We can compute our conversion factor:
const float UNITS_PER_MICROSTEP = UNITS_PER_MOTOR_REV / (float)MICROSTEPS_PER_MOTOR_REV;


// ###### End user-customizable variables ######
// #############################################



// Extra boost for acceleration; Reduce power for holding still
const float Kaccl = 1.2; // fraction of full voltage for acceleration
const float Krun  = 1.0; // fraction of full voltage for const. vel.
const float Khold = 0.5; // fraction of full voltage for holding

// PID / Targetting
bool recentAlarm = false;
float currPos = 0;
long currSteps = 0;
float targetPos = 0;

float propGain = 25; // proportional gain for an unloaded Pololu #1206 stepper


// ========  SPI/Motor Settings  ==============
const int resetPin = 4;
const int SCKPin = 13;
const int CSPin = A2;
const int busyPin = A5;
const int flagPin = A4;
XNucleoStepper motor(0, CSPin, resetPin, busyPin);

void DEBUG(String message) 
{
	// Serial.println(message.c_str()); // comment this out when not debugging !!!!!!!
}


void setup()
{
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
	XNucleoStepper motor2(1, CSPin, resetPin);
	motor2.getAlarmStatusString();
	motor.getAlarmStatusString();
}

// For tracking internally generated stimuli
unsigned long startStimTime = 0;
unsigned long updateVelTime = 0;
unsigned long updateTargetTime = 0;
float sinAmp = 90;
float sinFreq = 1;

unsigned long prevTime = micros();
bool motorBusy = false;
bool prevMotorBusy = false;
unsigned long prevDebugTime = micros();
void loop()
{
	// debugging code to get loop time:
	// DEBUG(String(micros()-prevTime));
	// delay(100);
	// prevTime = micros();

	// 0) Check for flags
	if (digitalRead(flagPin)==LOW) {
		Serial.println(motor.getAlarmStatusString());
		recentAlarm = true;
		motor.softStop();
	}

	// 1) Read and interpret new Serial commands
	readUSB();
}

void readUSB() {
	// Read from USB, if available
	static String usbMessage = ""; // initialize usbMessage to empty string,
																 // happens once at start of program
	while (Serial.available() > 0) {
		// keep read single chars if available
		char inByte = Serial.read();
		if ((inByte == '\n') || (inByte == ';')) {
			// the new-line character ('\n') or ';' indicate a complete message
			// so interprete the message and then clear buffer
			interpretCommand(usbMessage);
			usbMessage = ""; // clear message buffer
			break; // exit while loop after interpreting command (even if more chars remain)
		} else {
			// append character to message buffer
			usbMessage = usbMessage + inByte;
		}
	}
}

void interpretCommand(String message) {
	long int startCommandTime = micros();
	message.trim(); // remove leading and trailing white space
	int len = message.length();
	if (len==0) {
		Serial.println("#"); // "#" means error
		return;
	}
	char command = message[0]; // the command is the first char of a message
	String parameters = message.substring(1);
	parameters.trim();

	float arg1 = parameters.toFloat();
	// Does this command have an argument?
	bool hasArg = (parameters.length() > 0);

	DEBUG(String("Command: ")+command);
	DEBUG(String("Argument 1: ")+arg1);
	if (!hasArg) DEBUG("-- No Arg --");

	// initialize variables needed in switch
	float gotoPos, gotoMovement;

	switch (command) {

		case 'S': // S: set max speed
		case 's':
			if (hasArg) {
				motor.setMaxSpeed(arg1);
				Serial.print("Setting ");
			}
			Serial.print("MaxSpeed: ");
			Serial.print(motor.getMaxSpeed());
			Serial.println(" steps/s");
			break;

		case 'A': // A: set accel rate
		case 'a':
			if (hasArg) {
				motor.setAcc(arg1);
				motor.setDec(arg1);
				Serial.print("Setting ");
			}
			Serial.print("AccelRate: ");
			Serial.print(motor.getAcc());
			Serial.println(" steps/s^2");
			break;

		case 'X': // X: soft stop
		case 'x':
			recentAlarm = false;
			motor.softStop();
			Serial.println("Stopping");
			break;

		case 'Q': // Q: Hi-Z (free movements)
		case 'q':
			recentAlarm = false;
			motor.softHiZ();
			Serial.println("High-Z (free movement)");
			break;

		case 'F': // F: forward
		case 'f':
			recentAlarm = false;
			if (arg1 >= 0) {
				motor.move(FWD, arg1/UNITS_PER_MICROSTEP);
			} else {
				motor.move(REV, -arg1/UNITS_PER_MICROSTEP);
			}
			Serial.print("Moving Forward ");
			Serial.print(arg1);
			Serial.println(" units");
			// while (motor.busyCheck()) {
			//   delay(1);
			// }
			break;

		case 'B': // B/R: Reverse
		case 'b':
		case 'R':
		case 'r':
			recentAlarm = false;
			if (arg1 >= 0) {
				motor.move(REV, arg1/UNITS_PER_MICROSTEP);
			} else {
				motor.move(FWD, -arg1/UNITS_PER_MICROSTEP);
			}
			Serial.print("Moving Backward ");
			Serial.print(arg1);
			Serial.println(" units");
			// while (motor.busyCheck()) {
			//   delay(1);
			// }
			break;

		case 'G': // G: Go to position
		case 'g':
			recentAlarm = false;
			Serial.print("Moving to position ");
			Serial.println(arg1);
			// This won't work with circular track:
			//  motor.goTo(arg1/UNITS_PER_MICROSTEP);
			// Do this instead:
			gotoPos = arg1;
			currPos = getCurrPos();
			gotoMovement = gotoPos - currPos;
			if (gotoMovement >= 0) {
				motor.move(FWD, gotoMovement/UNITS_PER_MICROSTEP);
			} else {
				motor.move(REV, -gotoMovement/UNITS_PER_MICROSTEP);
			}
			// while (motor.busyCheck()) {
			//   delay(1);
			// }
			break;

		case 'Z': // Z: Re-zero at current position
		case 'z':
			// reset position to limit switch
			recentAlarm = false;
			Serial.println("Zeroing");
			motor.resetPos();
			currPos = 0;
			targetPos = 0;
			break;

		case 'H': // H: Home — reset zero position at limit switch
		case 'h':
			// (don't go home if there was a recent alarm - limit switch may already be pressed)
			if (!recentAlarm) {
				Serial.print("Homing... ");
				motor.goUntil(RESET_ABSPOS, REV, goToLimitSpeed);
				while (motor.busyCheck()) {
					delay(1);
				}
				motor.releaseSw(RESET_ABSPOS, FWD);
				while (motor.busyCheck()) {
					delay(1);
				}
				motor.resetPos();
				Serial.println("Done");
			}
			break;

		case 'W': // W: Report position ([W]here am I?)
		case 'w':
			currSteps = motor.getPos();
			currPos = getCurrPos();
			Serial.print("Current location: ");
			Serial.print(currPos);
			Serial.print("\t\t (");
			Serial.print(currSteps);
			Serial.println(" steps)");
			break;

		case '?': // ?: Report motor status
			Serial.println(motor.getFullStatusString());
			break;

		case '!': // !: Check Flag status
			// TODO check flag status first....
			Serial.println(motor.getAlarmStatusString());
			break;

		case '$': // '$' re-configure motor
			configMotor(&motor);
			break;

		default: // unknown command
			Serial.println("#"); // "#" means error
	} // switch(command)

	DEBUG(String("Time: ")+(micros()-startCommandTime));
}

// Get current position in physical units. Correct for circular track, if needed.
float getCurrPos() 
{
	return motor.getPos() * UNITS_PER_MICROSTEP;
}

void configSPI() 
{
	pinMode(resetPin, OUTPUT);
	pinMode(MOSI, OUTPUT);
	pinMode(MISO, INPUT);
	pinMode(SCKPin, OUTPUT);
	pinMode(CSPin, OUTPUT);
	digitalWrite(CSPin, HIGH);
	digitalWrite(resetPin, LOW);
	digitalWrite(resetPin, HIGH);
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

	serial.println(String("POS: ") + motor->getPos());
	serial.println(String("OCThreshold: ") + motor->getOCThreshold());
	serial.println(String("RunKVAL: ") + motor->getRunKVAL());
	serial.println(String("AccKVAL: ") + motor->getAccKVAL());
	serial.println(String("DecKVAL: ") + motor->getDecKVAL());
	serial.println(String("HoldKVAL: ") + motor->getHoldKVAL());
	serial.println(String("MinSpeed: ") + motor->getMinSpeed());
	serial.println(String("MaxSpeed: ") + motor->getMaxSpeed());
	serial.println(String("FullSpeed: ") + motor->getFullSpeed());
	serial.println(String("Acc: ") + motor->getAcc());
	serial.println(String("Dec: ") + motor->getDec());
	serial.println(String("StepMode: ") + motor->getStepMode());

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
	float Kval = Vmotor/Vsupply * 255;
	motor->setRunKVAL(round(Krun*Kval));
	// DEBUG(String("RunKVAL: ") + motor->getRunKVAL());
	motor->setAccKVAL(round(Kaccl*Kval));
	// DEBUG(String("AccKVAL: ") + motor->getAccKVAL());
	motor->setDecKVAL(round(Kaccl*Kval));
	// DEBUG(String("DecKVAL: ") + motor->getDecKVAL());
	motor->setHoldKVAL(round(Khold*Kval));
	// DEBUG(String("HoldKVAL: ") + motor->getHoldKVAL());

	// When a move command is issued, max speed is the speed the
	//  motor tops out at while completing the move, in steps/s
	motor->setMinSpeed(minSpeed);
	// DEBUG(String("MinSpeed: ") + motor->getMinSpeed());
	motor->setMaxSpeed(maxSpeed);
	// DEBUG(String("MaxSpeed: ") + motor->getMaxSpeed());
	motor->setFullSpeed(maxSpeed);       // microstep below this speed
	// DEBUG(String("FullSpeed: ") + motor->getFullSpeed());


	// Acceleration and deceleration in steps/s/s. Increasing this
	//  value makes the motor reach its full speed more quickly,
	//  at the cost of possibly causing it to slip and miss steps.
	motor->setAcc(accelRate);
	// DEBUG(String("Acc: ") + motor->getAcc());
	motor->setDec(accelRate);
	// DEBUG(String("Dec: ") + motor->getDec());

	motor->configStepMode(stepMode);    // microsteps per step
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

	DEBUG(String("POS: ") + motor->getPos());
	DEBUG(String("OCThreshold: ") + motor->getOCThreshold());
	DEBUG(String("RunKVAL: ") + motor->getRunKVAL());
	DEBUG(String("AccKVAL: ") + motor->getAccKVAL());
	DEBUG(String("DecKVAL: ") + motor->getDecKVAL());
	DEBUG(String("HoldKVAL: ") + motor->getHoldKVAL());
	DEBUG(String("MinSpeed: ") + motor->getMinSpeed());
	DEBUG(String("MaxSpeed: ") + motor->getMaxSpeed());
	DEBUG(String("FullSpeed: ") + motor->getFullSpeed());
	DEBUG(String("Acc: ") + motor->getAcc());
	DEBUG(String("Dec: ") + motor->getDec());
	DEBUG(String("StepMode: ") + motor->getStepMode());


}
