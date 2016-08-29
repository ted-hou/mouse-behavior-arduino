/*****************************************************
	Arduino code for lever task
*****************************************************/
#define PIN_LED 		34	// DIGITAL OUT
#define PIN_SPEAKER		2	// PWM OUT
#define PIN_LEVER 		51	// DIGITAL IN

// I/O
String usbMessage = "";

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
	UPDATE_PARAMS,
	ABORT_TRIAL,
	QUIT
};
State currentState = WAIT_FOR_GO;
State previousState = WAIT_FOR_GO;

// Local and global timers
unsigned long time;
unsigned long globalTime;

// Initialize test parameters
int TIMEOUT_READY = 5000;

void setup()
{
	// Init pins
	pinMode(PIN_LED, OUTPUT);
	pinMode(PIN_SPEAKER, OUTPUT);
	pinMode(PIN_LEVER, INPUT_PULLUP);

	digitalWrite(PIN_LED, LOW);
	tone(PIN_SPEAKER, 512, 200);

	// Set up USB communication at 115200 baud 
	Serial.begin(115200);
	// Tell PC that we're running by sending 'S' message
	Serial.println("S");
}

void loop()
{
	// 1) Read from USB, if available
	if (Serial.available() > 0) 
	{
		// Read next char if available
		char inByte = Serial.read();
		if (inByte == '\n')
		{
			// The new-line character ('\n') indicates a complete message so interprete the message and then clear buffer
			interpretCommand(usbMessage);
			usbMessage = ""; // clear message buffer
		}
		else
		{
			// append character to message buffer
			usbMessage = usbMessage + inByte;
		}
	}

	// 2) update state machine
	switch ()
	{
		case :
		{
			break;
		}
		case :
		{
			break;
		}
		case :
		{
			break;
		}
		case :
		{
			break;
		}
		case :
		{
			break;
		}
		case :
		{
			break;
		}
		case :
		{
			break;
		}
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
	}

	// Transitions
	// Lever pressed -> RANDOM_WAIT
	if (getCommand() == 'G')
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

		// Reset timer
		time = millis();
	}

	// Transitions
	// Lever pressed -> RANDOM_WAIT
	if (getLever())
	{
		return RANDOM_WAIT;
	}
	// Timeout waiting for lever press -> ABORT_TRIAL
	if (millis() - time >= TIMEOUT_READY)
	{
		return ABORT_TRIAL;
	}
	// Otherwise stay in the same state
	return READY;
}

/*****************************************************
	Hardware controls
*****************************************************/
void setLight(bool turnOn)
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

// Read a message from USB port
String getMessage()
{
	String usbMessage = ""; 	// Initialize usbMessage to empty string, happens once at start of program
	
	if (Serial.available() > 0) 
	{
		// Read next char if available
		char inByte = Serial.read();
		if (inByte == '\n') {
			// The new-line character ('\n') indicates a complete message so interprete the message and then clear buffer
			interpretCommand(usbMessage);
			usbMessage = ""; // clear message buffer
		} else {
			// append character to message buffer
			usbMessage = usbMessage + inByte;
		}
	}
}

void interpretCommand(String message) 
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
	long arg1 = intString.toInt();

	// Parse second (optional) integer argument  
	parameters.trim();
	intString = "";
	while ((parameters.length() > 0) && (isDigit(parameters[0]))) 
	{
		intString += parameters[0];
		parameters.remove(0,1);
	}
	long arg2 = intString.toInt();

	// Dubgging output
	DEBUG(String("Command: ")+command);
	DEBUG(String("Argument 1: ")+arg1);
	DEBUG(String("Argument 2: ")+arg2);

	if (command == 'A') 
	{ // A: return the sum (addition)
		sendMessage('P', arg1 + arg2);
		
	} else if (command == 'D') 
	{ // D: return the difference
		sendMessage('P', arg1 - arg2);
	} else if (command == 'P') 
	{ // P: return the product
		sendMessage('P', arg1 * arg2);
	} else if (command == 'L') 
	{ // L: turn active LED on
		digitalWrite(active_LED, HIGH);
	} else if (command == 'O') 
	{ // O: turn active LED off
		digitalWrite(active_LED, LOW);
	} else if (command == 'B') 
	{ // B: return button state
		int buttonState = digitalRead(Button_pin);
		sendMessage('P', buttonState);
	} else if (command == 'S') 
	{ // S: switch active LED
		if (active_LED == LED1_pin) 
		{
				active_LED = LED2_pin;
				sendMessage('L', 2);
		} else 
		{
				active_LED = LED1_pin;      
				sendMessage('L', 1);
		}
	} else 
	{ // Unknown command
		Serial.println("#"); // "#" means error
	}
}