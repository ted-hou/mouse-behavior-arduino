/*****************************************************
	Arduino code for lever task
*****************************************************/
bool DEBUG = false; // Set to false to disable debug messages

/*****************************************************
	Global stuff
*****************************************************/

// Macros
#define PIN_LED_ILLUM 	34	// DIGITAL OUT
#define PIN_LED_CUE 	35	// DIGITAL OUT
#define PIN_SPEAKER		2	// PWM OUT
#define PIN_LEVER 		53	// DIGITAL IN

// Enums
// All the states
enum State
{
	_INIT,					// (Private) Initial state used on first loop. So the `state == prevState` check (). 
	WAIT_FOR_GO,			// Idle state. Wait for go signal from host.
	READY,					// Ready, wait for lever press & hold
	RANDOM_WAIT,			// Wait a random amount of time before starting a trial.
	CUE_ON,					// Cue to start counting
	LEVER_RELEASED,			// Triggered when lever is released
	REWARD,					// Give reward.
	ABORT_TRIAL,			// Go to this state when something's wrong. Goes to intertrial so we can upload error info to host.
	INTERTRIAL				// Intertrial interval. Upload data and recieve new params.
};

// Sound cue types
enum SoundType
{
	TONE_REWARD,		// Correct tone
	TONE_ABORT,			// Error tone
	TONE_CUE 			// 'Start counting the interval' cue
};

// Parameters that can be updated by host
// Storing everything in array params[]. Using enum ParamName as array indices so it's easier to add/remove parameters. 
enum ParamName
{
	TIMEOUT_READY,
	RANDOM_WAIT_MIN,
	RANDOM_WAIT_MAX,
	INTERVAL_MIN,
	INTERVAL_MAX,
	REWARD_SIZE,
	ITI,
	NUM_PARAMS			// Used to count how many parameters there are so we can initialize the param array with the correct size. Insert additional parameter names before this.
};

int params[NUM_PARAMS] = {0};

// GVARs - values that need to be carried to the next loop, AND read/written in function scope
static unsigned long timer 				= 0;		// Timer
static unsigned long leverPressDuration = 0;
static State state 						= _INIT;	// This variable (current state) get passed into a state function, which determines what the next state should be, and updates it to the next state.
static State prevState 					= _INIT;	// Remembers the previous state from the last loop (actions should only be executed when you enter a state for the first time, comparing currentState vs prevState helps us keep track of that).
static char command 					= ' ';		// Command char received from host, resets on each loop
static int arguments[2] 				= {0};		// Two integers received from host , resets on each loop

/*****************************************************
	Main
*****************************************************/
void setup()
{
	// Init pins
	pinMode(PIN_LED_ILLUM, OUTPUT);		// LED for illumination
	pinMode(PIN_LED_CUE, OUTPUT);		// LED for 'start' cue
	pinMode(PIN_SPEAKER, OUTPUT);		// Speaker for cue/correct/error tone
	pinMode(PIN_LEVER, INPUT_PULLUP);	// Lever (`INPUT_PULLUP` means it'll be `LOW` when pressed, and `HIGH` when released)

	// Initialize parameters
	params[TIMEOUT_READY] 	= 20000;	// Timeout: subject does not press the lever to initiate trial
	params[RANDOM_WAIT_MIN] = 1000;		// Min random wait interval
	params[RANDOM_WAIT_MAX] = 2000;		// Max random wait interval
	params[INTERVAL_MIN] 	= 1250;		// Min lever hold duration to qualify for reward
	params[INTERVAL_MAX] 	= 1750;		// Max lever hold duration to qualify for reward
	params[REWARD_SIZE] 	= 100;		// Solenoid ON duration. Determines juice/water reward size. Need calibratio
	params[ITI] 			= 5000;		// Intertrial interval duration.

	// Illum LED off
	setIllumLED(false);
	// Cue LED off
	setCueLED(false);

	// Set up USB communication at 115200 baud 
	Serial.begin(115200);
	// Tell PC that we're running by sending 'S' message
	Serial.println("S");
}

void loop()
{
	// 1) Read from USB, if available. String is read byte by byte.
	static String usbMessage 	= ""; 		// Initialize usbMessage to empty string, only happens once on first loop
	command = ' ';
	arguments[0] = 0;
	arguments[1] = 0;

	if (Serial.available() > 0) 
	{
		// Read next char if available
		char inByte = Serial.read();
		// The pound sign ('#') indicates a complete message
		if (inByte == '#') 
		{
			// Parse the string, and updates `command`, and `arguments`
			command = getCommand(usbMessage);
			getArguments(usbMessage, arguments);
			if (DEBUG) {"Roger. " + command + String(arguments[0]) + String(arguments[1]);}
			// Clear message buffer
			usbMessage = ""; 
		}
		else
		{
			// append character to message buffer
			usbMessage = usbMessage + inByte;
		}
	}

	// 2) update state machine
	// Depending on what state we're in , call the appropriate state function, which will evaluate the transition conditions, and update `state` to what the next state should be
	switch (state)
	{
		case _INIT:
		{
			wait_for_go();
		} break;
		case WAIT_FOR_GO:
		{
			wait_for_go();
		} break;
		case READY:
		{
			ready();
		} break;
		case RANDOM_WAIT:
		{
			random_wait();
		} break;
		case CUE_ON:
		{
			cue_on();
		} break;
		case LEVER_RELEASED:
		{
			lever_released();
		} break;
		case REWARD:
		{
			reward();
		} break;
		case ABORT_TRIAL:
		{
			abort_trial();
		} break;
		case INTERTRIAL:
		{
			intertrial();
		} break;
	}
}

/*****************************************************
	States for the State Machine
*****************************************************/
/*** WAIT_FOR_GO ***/
void wait_for_go()
{
	// Actions - only execute once on state entry
	if (state != prevState)
	{
		prevState = state;

		// Debug message - state entry
		if (DEBUG) {sendString("Idle.");}

		// Illumination LED off
		setIllumLED(true);

		// Cue LED off
		setCueLED(false);
	}

	// Transitions
	// Serial input (GO signal) -> READY
	if (command == 'G')
	{
		state = READY;
		return;
	}
	// Otherwise stay in the same state
	state = WAIT_FOR_GO;
}

/*** READY ***/
void ready()
{
	// Actions - only execute once on state entry
	if (state != prevState)
	{
		prevState = state;

		// Debug message - state entry
		if (DEBUG) {sendString("Ready. Press and hold lever.");}

		// Illumination LED on
		setIllumLED(true);

		// Start timer
		timer = millis();
	}

	// Transitions
	// Serial input (QUIT signal) -> WAIT_FOR_GO
	if (command == 'Q')
	{
		state = WAIT_FOR_GO;
		return;
	}
	// Lever pressed -> RANDOM_WAIT
	if (getLeverState())
	{
		if (DEBUG) {sendString("Lever pressed. Keep holding please.");}
		state = RANDOM_WAIT;
		return;
	}
	// Timeout w/o pressing the lever-> ABORT_TRIAL
	if (millis() - timer >= params[TIMEOUT_READY])
	{
		if (DEBUG) {sendString("Time out waiting for lever. Aborting.");}
		state = ABORT_TRIAL;
		return;
	}
	state = READY;
}

/*** RANDOM_WAIT ***/
void random_wait()
{
	static unsigned long waitInterval;

	// Actions - only execute once on state entry
	if (state != prevState)
	{
		prevState = state;

		// Randomize interval length and start timer
		waitInterval = random(params[RANDOM_WAIT_MIN], params[RANDOM_WAIT_MAX]);
		timer = millis();

		// Debug message - state entry
		if (DEBUG) {sendString("Random wait: " + String(waitInterval) + " ms");}
	}

	// Transitions
	// Serial input (QUIT signal) -> WAIT_FOR_GO
	if (command == 'Q')
	{
		state = WAIT_FOR_GO;
		return;
	}
	// Lever released -> ABORT_TRIAL
	if (!getLeverState())
	{
		if (DEBUG) {sendString("Lever released during random wait.");}
		state = ABORT_TRIAL;
		return;
	}
	// Random wait complete-> CUE_ON
	if (millis() - timer >= waitInterval)
	{
		if (DEBUG) {sendString("Random wait complete.");}
		state = CUE_ON;
		return;
	}
	state = RANDOM_WAIT;
}

/*** CUE_ON ***/
void cue_on()
{
	// Actions - only execute once on state entry
	if (state != prevState)
	{
		prevState = state;

		// Debug message - state entry
		if (DEBUG) {sendString("Cue on. Hold for " + String(params[INTERVAL_MIN]) + " - " + String(params[INTERVAL_MAX]) + " ms");}

		// Cue LED ON
		setCueLED(true);

		// Cue tone - start counting
		playSound(TONE_CUE);

		// Start timer
		timer = millis();
	}

	// Transitions
	// Serial input (QUIT signal) -> WAIT_FOR_GO
	if (command == 'Q')
	{
		state = WAIT_FOR_GO;
		return;
	}
	// Lever released -> LEVER_RELEASED
	if (!getLeverState())
	{
		state = LEVER_RELEASED;
		return;
	}
	state = CUE_ON;
}

/*** LEVER_RELEASED ***/
void lever_released()
{
	// Actions - only execute once on state entry
	if (state != prevState)
	{
		prevState = state;

		// Calculate lever press duration
		leverPressDuration = millis() - timer;

		// Debug message - state entry
		if (DEBUG) {sendString("Lever released. Held for " + String(leverPressDuration) + " ms.");}
	}

	// Transitions
	// Serial input (QUIT signal) -> WAIT_FOR_GO
	if (command == 'Q')
	{
		state = WAIT_FOR_GO;
		return;
	}
	// Interval correct -> REWARD
	if (leverPressDuration >= params[INTERVAL_MIN] && leverPressDuration <= params[INTERVAL_MAX])
	{
		state = REWARD;
		return;
	}
	// Interval incorrect -> ABORT_TRIAL
	else
	{
		state = ABORT_TRIAL;
		return;
	}
}

/*** REWARD ***/
void reward()
{
	// Actions - only execute once on state entry
	if (state != prevState)
	{
		prevState = state;

		// Debug message - state entry
		if (DEBUG) {sendString("Reward.");}

		// Give reward
		giveReward(params[REWARD_SIZE]);
	}

	// Transitions
	// Serial input (QUIT signal) -> WAIT_FOR_GO
	if (command == 'Q')
	{
		state = WAIT_FOR_GO;
		return;
	}
	// Always -> INTERTRIAL
	state = INTERTRIAL;
}

/*** ABORT_TRIAL ***/
void abort_trial()
{
	// Actions - only execute once on state entry
	if (state != prevState)
	{
		prevState = state;

		// Debug message - state entry
		if (DEBUG) {sendString("Trial aborted.");}

		// Error tone
		playSound(TONE_ABORT);

		// Set lever press duration to 0
		leverPressDuration = 0;
	}

	// Transitions
	// Serial input (QUIT signal) -> WAIT_FOR_GO
	if (command == 'Q')
	{
		state = WAIT_FOR_GO;
		return;
	}
	// Always -> INTERTRIAL
	state = INTERTRIAL;
}

/*** INTERTRIAL ***/
void intertrial()
{
	static bool isParamsUpdateStarted;	// Set to true upon receiving a new parameter
	static bool isParamsUpdateDone;		// Set to true upon receiving "Over" signal

	// Actions - only execute once on state entry
	if (state != prevState)
	{
		prevState = state;

		// Debug message - state entry
		if (DEBUG) {sendString("Intertrial.");}

		// Illum LED OFF
		setIllumLED(false);

		// Cue LED OFF
		setCueLED(false);

		// Reset booleans used to track transmission progress
		isParamsUpdateStarted = false;
		isParamsUpdateDone = false;

		// Serial output - upload trial results to host ('I' for Interval)
		sendCommandAndArgument('I', leverPressDuration);

		// Start timer
		timer = millis();
	}

	// Transitions
	// Serial input (QUIT signal) -> WAIT_FOR_GO
	if (command == 'Q')
	{
		state = WAIT_FOR_GO;
		return;
	}
	// Received new param from host: format "P _paramID _newValue" ('P' for Parameters)
	if (command == 'P')
	{
		isParamsUpdateStarted = true;			// Let loop know we've started transmitting parameters. Don't start next trial until we've finished.
		params[arguments[0]] = arguments[1];	// Update parameter. Serial input "P 0 1000" changes the 1st parameter to 1000.
		if (DEBUG) {sendString("Parameter " + String(arguments[0]) + " changed to " + String(arguments[1]));} 
		state = INTERTRIAL;
		return;
	}
	// Param transmission complete: host sends 'O' for Over.
	if (command == 'O') 
	{
		isParamsUpdateDone = true;
		state = INTERTRIAL;
		return;
	};
	// End when ITI ends. If param update initiated, should also wait for update completion signal ('O' for Over).
	if (millis() - timer >= params[ITI] && (isParamsUpdateDone || !isParamsUpdateStarted))
	{
		state = READY;
		return;
	}
	// Otherwise stay in same state
	state = INTERTRIAL;
}
/*****************************************************
	Hardware controls
*****************************************************/
void setIllumLED(bool turnOn)
{
	if (turnOn)
	{
		digitalWrite(PIN_LED_ILLUM, HIGH);
	}
	else
	{
		digitalWrite(PIN_LED_ILLUM, LOW);
	}
}

void setCueLED(bool turnOn)
{
	if (turnOn)
	{
		digitalWrite(PIN_LED_CUE, HIGH);
	}
	else
	{
		digitalWrite(PIN_LED_CUE, LOW);
	}
}

bool getLeverState()
{
	if (digitalRead(PIN_LEVER) == HIGH)
	{
		return false;
	}
	else
	{
		return true;
	}
}

void playSound(SoundType soundType)
{
	if (soundType == TONE_REWARD)
	{
		// Play correct tone
		return;
	}
	if (soundType == TONE_ABORT)
	{
		// Play incorrect tone
		return;
	}
	if (soundType == TONE_CUE)
	{
		// Play start interval tone
		return;
	}
}

void giveReward(int size)
{
	// Give some reward

	if (DEBUG) {sendString("Nom nom nom. " + String(size) + ".");}
}

/*****************************************************
	Serial comms
*****************************************************/
// Send a single char command + int argument pair over the USB port
void sendCommandAndArgument(char c, int val) 
{
	String message = String(c);
	message += " ";
	message += val;
	Serial.println(message);
}

// Send a string message to host 
void sendString(String message)
{
	Serial.println(message);
}

// Get command (single character) received from host
char getCommand(String message)
{
	message.trim(); // Remove leading and trailing white space

	// Parse command string
	return message[0];
}

// Get arguments (2 element array)
void getArguments(String message, int *arguments)
{
	arguments[0] = 0;
	arguments[1] = 0;

	message.trim(); // Remove leading and trailing white space

	// Remove command (first character) from string
	String parameters = message;
	parameters.remove(0,1);
	parameters.trim();

	// Parse first (optional) integer argument
	String intString = "";
	while ((parameters.length() > 0) && (isDigit(parameters[0]))) 
	{
		intString += parameters[0];
		parameters.remove(0,1);
	}
	arguments[0] = intString.toInt();

	// Parse second (optional) integer argument  
	parameters.trim();
	intString = "";
	while ((parameters.length() > 0) && (isDigit(parameters[0]))) 
	{
		intString += parameters[0];
		parameters.remove(0,1);
	}
	arguments[1] = intString.toInt();
}