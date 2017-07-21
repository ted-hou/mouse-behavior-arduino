#include <Servo.h> 
 
int servoPin = 3;
 
Servo _servo;  
 
int angle = 0;   // _servo position in degrees 
 
void setup() 
{ 
  _servo.attach(servoPin); 
} 
 
 
void loop() 
{ 
  // scan from 0 to 180 degrees
  for(angle = 0; angle < 30; angle++)  
  {                                  
    _servo.write(angle);               
    delay(15);                   
  } 
  // now scan back from 180 to 0 degrees
  for(angle = 30; angle > 0; angle--)    
  {                                
    _servo.write(angle);           
    delay(15);       
  } 
} 