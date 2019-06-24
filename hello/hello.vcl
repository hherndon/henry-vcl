main:

if(Sw_1 = ON){
	Setup_Delay(DLY1, 3000)
	}
	
if(DLY1_Output > 0){
	put_pwm(PWM2, 0x7fff)
	}
else{
	put_pwm(PWM2, 0)
	}
	
	
goto main