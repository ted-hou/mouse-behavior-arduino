/*****************************************************
	Arduino code for lever task
*****************************************************/

/*****************************************************
	Global declarations/inits
*****************************************************/
#define PIN_LED_A 		34	// DIGITAL OUT
#define PIN_LED_B 		35	// DIGITAL OUT

// States
enum State
{
	_INIT,
	STATE_A,
	STATE_B
};

// Initialize parameters
unsigned int TIMEOUT_CUE_ON = 2000;

/*****************************************************
	Main
*****************************************************/
void setup()
{
	// Init pins
	pinMode(PIN_LED_A, OUTPUT);
	pinMode(PIN_LED_B, OUTPUT);

	// LEDs off
	setLED_A(false);
	setLED_B(false);

	// Set up USB communication at 115200 baud 
	Serial.begin(115200);
	// Tell PC that we're running by sending 'S' message
	Serial.println("S");
}

unsigned long timer;

void loop()
{
	char command = '0';
	static State nextState = _INIT;
	static State prevState = _INIT;

	// 1) Read from USB, if available
	static String usbMessage = ""; 	// Initialize usbMessage to empty string, happens once at start of program
	
	if (Serial.available() > 0) {
		// Read next char if available
		char inByte = Serial.read();
		if (inByte == '#') 
		{
			// The pound sign ('#') indicates a complete message so interprete the message and then clear buffer
			command = usbMessage[0];
			// Serial.println(command);
			usbMessage = ""; // clear message buffer
		}
		else
		{
			// append character to message buffer
			usbMessage = usbMessage + inByte;
		}
	}

	// 2) update state machine
	switch (nextState)
	{
		case _INIT:
		{
			state_a(&nextState, &prevState, &timer, command);
		} break;
		case STATE_A:
		{
			state_a(&nextState, &prevState, &timer, command);
		} break;
		case STATE_B:
		{
			state_b(&nextState, &prevState, &timer, command);
		} break;
	}
	// Serial.println(String(state, DEC));
}

/*****************************************************
	States for the State Machine
*****************************************************/
/*** WAIT FOR GO ***/
void state_a(State *nextState, State *prevState, unsigned long *timer, char command)
{
	// Actions - only execute upon state entry
	if (*prevState != *nextState)
	{
		*prevState = *nextState;

		// Cue on
		Serial.println("State A.");

		// LED A on
		setLED_A(true);

		// LED B on
		setLED_B(false);
	}

	// Transitions
	// Lever pressed -> RANDOM_WAIT
	if (command == 'B')
	{
		*nextState = STATE_B;
		return;
	}
	// Otherwise stay in the same state
	*nextState = STATE_A;
	return;
}

/*** CUE_ON ***/
void state_b(State *nextState, State *prevState, unsigned long *timer, char command)
{
	// Actions - only execute upon state entry
	if (*prevState != *nextState)
	{
		*prevState = *nextState;

		// Cue on
		Serial.println("State B.");

		// LED A off
		setLED_A(false);

		// LED B on
		setLED_B(true);

		// Start timer
		*timer = millis(); 
	}

	// Transitions
	// Serial input ('QUIT' signal) -> WAIT_FOR_GO
	if (command == 'A')
	{
		*nextState = STATE_A;
		return;
	}
	// Lever released -> LEVER_RELEASED
	if (millis() - *timer >= TIMEOUT_CUE_ON)
	{
		*nextState = STATE_A;
		return;
	}
	// Otherwise stay in the same state
	*nextState = STATE_B;
	return;
}


/*****************************************************
	Hardware controls
*****************************************************/
void setLED_A(bool turnOn)
{
	if (turnOn)
	{
		digitalWrite(PIN_LED_A, HIGH);
	}
	else
	{
		digitalWrite(PIN_LED_A, LOW);
	}
}

void setLED_B(bool turnOn)
{
	if (turnOn)
	{
		digitalWrite(PIN_LED_B, HIGH);
	}
	else
	{
		digitalWrite(PIN_LED_B, LOW);
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

char getCommand(String message)
{
	message.trim(); // Remove leading and trailing white space

	// Parse command string
	char command = message[0];
	return command;	
}

int* getArguments(String message)
{
	message.trim(); // Remove leading and trailing white space

	// Remove command (first character) from string
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

	int arrArguments[] = {arg1, arg2};
	return arrArguments;
}