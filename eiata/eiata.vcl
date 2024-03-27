create DisplayState variable
create delaymult variable
create temp variable

main:

	
if(PWM1_Output > 0){
		put_pwm(PWM2, 0x7fff)
	}
	else{
		put_pwm(PWM2, 0x0)
	}
	
	
	if(DLY3_Output = 0)
	{	
		if(DisplayState = 1){
			temp = Motor_Temperature/10
			Put_Spy_Message("Tm", temp, "C", PSM_Decimal)
		}
		if(DisplayState = 2){
			temp = Controller_Temperature/10
			Put_Spy_Message("Tc", temp, "C", PSM_Decimal)
		}
		if(DisplayState = 3){
			temp = Insulation_Res_kOhmsx10 /10
			Put_Spy_Message("IR", temp, "k", PSM_Decimal)
		}
	
	if(delaymult> 10){
		DisplayState = DisplayState + 1
		delaymult = 0
		}
	delaymult = delaymult +1
	
	if(DisplayState > 3){
		DisplayState = 1
		}
		
	Setup_Delay(DLY3, 150)
	
	}
		
goto main