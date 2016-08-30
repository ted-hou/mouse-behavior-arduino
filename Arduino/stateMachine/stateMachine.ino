/*****************************************************
	Arduino code for lever task
*****************************************************/

/*****************************************************
	Global declarations/inits
*****************************************************/
#define PIN_LED 		34	// DIGITAL OUT
#define PIN_LIGHT 		35	// DIGITAL OUT
#define PIN_SPEAKER		2	// PWM OUT
#define PIN_LEVER 		51	// DIGITAL IN

// States
enum State
{
	WAIT_FOR_GO,
	READY,
	RANDOM_WAIT,
	CUE_ON,
	LEVER_RELEASED,
	REWARD,
	INTERTRIAL,
	ABORT_TRIAL
};
State currentState = WAIT_FOR_GO;
State previousState = WAIT_FOR_GO;

// Sound cue types
enum SoundType
{
	CORRECT,		// Correct tone
	INCORRECT,		// Error tone
	START_INTERVAL 	// 'Start counting the interval' cue
}

// Timer
unsigned long timer;

// Output
unsigned long leverPressDuration;

// Initialize parameters
unsigned int TIMEOUT_READY = 5000;
unsigned int RANDOM_WAIT_MIN = 1000;
unsigned int RANDOM_WAIT_MAX = 2000;
unsigned int TIMEOUT_RELEASE = 2000;
unsigned int INTERVAL_MIN = 500;
unsigned int INTERVAL_MAX = 2000;
unsigned int REWARD_SIZE = 100;
unsigned int ITI = 5000;

// Incoming messages from Serial port are parsed into structs.
typedef struct
{
	char command;
	unsigned int arg1;
	unsigned int arg2;
}MessageAsStruct;

/*****************************************************
	Main
*****************************************************/
void setup()
{
	// Init pins
	pinMode(PIN_LED, OUTPUT);
	pinMode(PIN_SPEAKER, OUTPUT);
	pinMode(PIN_LEVER, INPUT_PULLUP);

	// Lights off
	setLight(false);
	// LED off
	setLED(false);

	// Set up USB communication at 115200 baud 
	Serial.begin(115200);
	// Tell PC that we're running by sending 'S' message
	Serial.println("S");
}

void loop()
{
	// Declare and init once
	static State nextState = WAIT_FOR_GO;
	static String usbMessage = "";
	char inByte;
	MessageAsStruct MessageParsed; 

	// 1) Read from USB, if available
	if (Serial.available() > 0) 
	{
		// Read next char if available
		char inByte = Serial.read();
		// append character to message buffer
		if (inByte == '\n')
		{
			MessageParsed = parseMessage(usbMessage);
		}
		else
		{
			usbMessage = usbMessage + inByte;
		}
	}

	// 2) update state machine
	switch (nextState)
	{
		case WAIT_FOR_GO:
		{
			nextState = wait_for_go();
		} break;
		case READY:
		{
			nextState = ready();
		} break;
		case RANDOM_WAIT:
		{
			nextState = random_wait();
		} break;
		case CUE_ON:
		{
			nextState = cue_on();
		} break;
		case LEVER_RELEASED:
		{
			nextState = lever_released();
		} break;
		case REWARD:
		{
			nextState = reward();
		} break;
		case INTERTRIAL:
		{
			nextState = intertrial();
		} break;
		case ABORT_TRIAL:
		{
			nextState = abort_trial();
		} break;
	}
	// 3) Clear message buffer if new line ('\n') encountered, otherwise it's carried over to the next loop
	if (inByte == '\n')
	{
		usbMessage = "";
	}	
}

/*****************************************************
	States for the State Machine
*****************************************************/
/*** WAIT FOR GO ***/
State wait_for_go()
{
	// Actions - only execute upon state entry
	if (currentState != previousState)
	{
		previousState = currentState;

		// Lights off
		setLight(false);

		// LED off
		setLED(false);	
	}

	// Transitions
	// Lever pressed -> RANDOM_WAIT
	if (MessageParsed.command == 'G')
	{
		return READY;
	}
	// Otherwise stay in the same state
	return WAIT_FOR_GO;
}

/*** READY ***/
State ready()
{
	// Actions - only execute upon state entry
	if (currentState != previousState)
	{
		previousState = currentState;

		// Light on
		setLight(true);

		// Start local timer
		timer = millis();
	}

	// Transitions
	// Serial input ('QUIT' signal) -> WAIT_FOR_GO
	if (MessageParsed.command == 'Q')
	{
		return WAIT_FOR_GO;
	}
	// Lever pressed -> RANDOM_WAIT
	if (getLever())
	{
		return RANDOM_WAIT;
	}
	// Timeout waiting for lever press -> ABORT_TRIAL
	if (millis() - timer >= TIMEOUT_READY)
	{
		return ABORT_TRIAL;
	}
	// Otherwise stay in the same state
	return READY;
}

/*** RANDOM WAIT ***/
State random_wait()
{
	// Actions - only execute upon state entry
	if (currentState != previousState)
	{
		previousState = currentState;

		// Start random timer
		static long randomWaitInterval = random(RANDOM_WAIT_MIN, RANDOM_WAIT_MAX);
		timer = millis();
	}

	// Transitions
	// Serial input ('QUIT' signal) -> WAIT_FOR_GO
	if (MessageParsed.command == 'Q')
	{
		return WAIT_FOR_GO;
	}
	// Lever released -> ABORT_TRIAL
	if (!getLever())
	{
		return ABORT_TRIAL;
	}
	// Random wait complete -> CUE_ON
	if (millis() - timer >= randomWaitInterval)
	{
		return CUE_ON;
	}
	// Otherwise stay in the same state
	return RANDOM_WAIT;
}

/*** CUE_ON ***/
State cue_on()
{
	// Actions - only execute upon state entry
	if (currentState != previousState)
	{
		previousState = currentState;

		// Light on
		setLED(true);

		// Sound cue
		playSound(START_INTERVAL);

		// Start timer
		timer = millis(); 
	}

	// Transitions
	// Serial input ('QUIT' signal) -> WAIT_FOR_GO
	if (MessageParsed.command == 'Q')
	{
		return WAIT_FOR_GO;
	}
	// Lever released -> LEVER_RELEASED
	if (!getLever())
	{
		return LEVER_RELEASED;
	}
	// Otherwise stay in the same state
	return CUE_ON;
}

/*** LEVER_RELEASED ***/
State lever_released()
{
	// Actions - only execute upon state entry
	if (currentState != previousState)
	{
		previousState = currentState;

		// Store interval length
		leverPressDuration = millis() - timer;
	}

	// Transitions
	// Serial input ('QUIT' signal) -> WAIT_FOR_GO
	if (MessageParsed.command == 'Q')
	{
		return WAIT_FOR_GO;
	}
	// Interval correct -> REWARD
	if (leverPressDuration <= INTERVAL_MAX && leverPressDuration >= INTERVAL_MIN)
	{
		return REWARD;
	}
	// Interval incorrect -> ABORT_TRIAL
	else
	{
		return ABORT_TRIAL;
	}
}

/*** REWARD ***/
State reward()
{
	// Actions - only execute upon state entry
	if (currentState != previousState)
	{
		previousState = currentState;

		// Give reward
		giveReward(REWARD_SIZE);

		// Sound cue: correct
		playSound(CORRECT);
	}

	// Transitions
	// Serial input ('QUIT' signal) -> WAIT_FOR_GO
	if (MessageParsed.command == 'Q')
	{
		return WAIT_FOR_GO;
	}
	// Always -> INTERTRIAL
	return INTERTRIAL;
}

/*** INTERTRIAL ***/
State intertrial()
{
	// Actions - only execute upon state entry
	if (currentState != previousState)
	{
		previousState = currentState;

		// Start timer
		timer = millis();

		// Lights off
		setLight(false);

		// LED off
		setLED(false);

		// Send interval length (as integer) and reset GVAR
		sendMessage('I', leverPressDuration);
		leverPressDuration = 0;
	}

	// Transitions
	// Serial input ('QUIT' signal) -> WAIT_FOR_GO
	if (MessageParsed.command == 'Q')
	{
		return WAIT_FOR_GO;
	}
	// Serial input new param received ('P' for Params)
	if (MessageParsed.command == 'P')
	{
		updateParam(MessageParsed.arg1, MessageParsed.arg2);
		return INTERTRIAL;
	}
	// ITI Complete
	if (millis() - timer >= ITI)
	{
		return READY;
	}
	// Otherwise stay in the same state
	return INTERTRIAL;
}

/*** ABORT_TRIAL ***/
State abort_trial()
{
	// Actions - only execute upon state entry
	if (currentState != previousState)
	{
		previousState = currentState;

		// Start timer
		timer = millis();

		// Sound cue: incorrect
		playSound(INCORRECT);
	}

	// Transitions
	// Serial input ('QUIT' signal) -> WAIT_FOR_GO
	if (MessageParsed.command == 'Q')
	{
		return WAIT_FOR_GO;
	}
	// Always -> INTERTRIAL
	return INTERTRIAL;
}


/*****************************************************
	Hardware controls
*****************************************************/
void setLight(bool turnOn)
{
	if (turnOn)
	{
		digitalWrite(PIN_LIGHT, HIGH);
	}
	else
	{
		digitalWrite(PIN_LIGHT, LOW);
	}
}

void setLED(bool turnOn)
{
	if (turnOn)
	{
		digitalWrite(PIN_LED, HIGH);
	}
	else
	{
		digitalWrite(PIN_LED, LOW);
	}
}

bool getLever()
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

void playSound(SoundType soundType)
{
	if (soundType == CORRECT)
	{
		// Play correct tone
		return;
	}
	if (soundType == INCORRECT)
	{
		// Play incorrect tone
		return;
	}
	if (soundType == START_INTERVAL)
	{
		// Play start interval tone
		return;
	}
}

void giveReward(int size)
{
	// Give some reward
}

/*****************************************************
	Serial comms
*****************************************************/
// Send a message over the USB port
// Message consists of single charater command and an integer value
void sendMessage(char c, int val) 
{
	String message = String(c);
	message += " ";
	message += val;
	Serial.println(message);
}

MessageAsStruct parseMessage(String message)
{
	message.trim(); // Remove leading and trailing white space
	int len = message.length();
	if (len==0) 
	{
		Serial.println("#"); // "#" means error
		return;
	}

	// Parse command string
	char command = message[0]; // The command is the first char of a message
	String parameters = message.substring(1);
	parameters.trim();

	// Parse first (optional) integer argument
	String intString = "";
	while ((parameters.length() > 0) && (isDigit(parameters[0]))) 
	{
		intString += parameters[0];
		parameters.remove(0,1);
	}
	int arg1 = intString.toInt();

	// Parse second (optional) integer argument  
	parameters.trim();
	intString = "";
	while ((parameters.length() > 0) && (isDigit(parameters[0]))) 
	{
		intString += parameters[0];
		parameters.remove(0,1);
	}
	int arg2 = intString.toInt();

	// Return everything as a struct
	MessageAsStruct parsed;
	parsed.command 	= command;
	parsed.arg1 	= arg1;
	parsed.arg2 	= arg2;

	return parsed;
}

void updateParam(int arg1, int arg2)
{
	switch (arg1)
	{
		case 1:
		{
			TIMEOUT_READY = arg2;
		} break;
		case 2:
		{
			RANDOM_WAIT_MIN = arg2;
		} break;
		case 3:
		{
			RANDOM_WAIT_MAX = arg2;
		} break;
		case 4:
		{
			TIMEOUT_RELEASE = arg2;
		} break;
		case 5:
		{
			INTERVAL_MIN = arg2;
		} break;
		case 6:
		{
			INTERVAL_MAX = arg2;
		} break;
		case 7:
		{
			REWARD_SIZE = arg2;
		} break;
		case 8:
		{
			ITI = arg2;
		} break;
	}
}