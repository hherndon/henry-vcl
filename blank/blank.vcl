precharge_time = 1000
precharge_drop_threshold = -1920


Mainloop:
if(Sw_2 = ON){
		put_pwm(PWM2, 0x7fff)
		put_pwm(PWM1, 0x7fff)
	}
	else{
		put_pwm(PWM2, 0x0)
		put_pwm(PWM1, 0x0)
	}
goto Mainloop
