/*****************************************************
	Arduino code for lever task
*****************************************************/

/*****************************************************
	Global declarations/inits
*****************************************************/
#define PIN_LED 		34	// DIGITAL OUT
#define PIN_LIGHT 		35	// DIGITAL OUT

// States
enum State
{
	WAIT_FOR_GO,
	CUE_ON
};
State currentState = WAIT_FOR_GO;
State previousState = WAIT_FOR_GO;

// Timer
unsigned long timer;

// Initialize parameters
unsigned int TIMEOUT_CUE_ON = 2000;

// Incoming messages from Serial port are parsed into structs.
typedef struct
{
	char command;
	unsigned int arg1;
	unsigned int arg2;
}MessageAsStruct;

MessageAsStruct MessageParsed; 

/*****************************************************
	Main
*****************************************************/
void setup()
{
	// Init pins
	pinMode(PIN_LED, OUTPUT);
	pinMode(PIN_LIGHT, OUTPUT);

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
	static char inByte;

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
		case CUE_ON:
		{
			nextState = cue_on();
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

		sendMessage('G', 0);

		// Lights off
		setLight(true);

		// LED off
		setLED(false);	
	}

	// Transitions
	// Lever pressed -> RANDOM_WAIT
	if (MessageParsed.command == 'G')
	{
		return CUE_ON;
	}
	if ()
	{
		return CUE_ON;
	}
	// Otherwise stay in the same state
	return WAIT_FOR_GO;
}

/*** CUE_ON ***/
State cue_on()
{
	// Actions - only execute upon state entry
	if (currentState != previousState)
	{
		previousState = currentState;

		// LED on
		setLED(true);

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
	if (millis() - timer >= TIMEOUT_CUE_ON)
	{
		return WAIT_FOR_GO;
	}
	// Otherwise stay in the same state
	return CUE_ON;
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
