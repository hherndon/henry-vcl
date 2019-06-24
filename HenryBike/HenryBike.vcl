
;---------------- INPUTS -----------------------------
	BarSwitch						alias Sw_1		;Pin J1-24
	;Motor temp sensor				switch 2 input	;Pin J1-08
	;not used						alias Sw_3		;Pin J1-09
	;not used						alias Sw_4		;Pin J1-10
	;not used						alias Sw_5		;Pin J1-11
	;not used						alias Sw_6		;Pin J1-12
	;not used						alias Sw_7		;Pin J1-22 also forward switch
	;not used						alias Sw_8		;Pin J1-33 also reverse switch
	;not used						alias Sw_14		;Pin J1-19
	;not used						alias Sw_15		;Pin J1-20
	;not used						alias Sw_16		;Pin J1-14
	
;----------- State Machine Variables etc ----------------------------

create DisplayState variable
	DisplayState = 1
create temp variable
	
setup_Delay(DLY1, 1)
Setup_Delay(DLY3, 1)

SpyLEDs equals user_bit4
	Led1 bit SpyLEDs.1
	Led2 bit SpyLEDs.2
	Led3 bit SpyLEDs.4
	Led4 bit SpyLEDs.8
	Led5 bit SpyLEDs.16
	TroubleLed bit SpyLEDs.32
	BkLt bit SpyLEDs.8192

	
main:
;---------------- Spyglass state machine -------------------------
	if(DLY3_Output = 0)
	{
		if(DisplayState = 1){
			Put_Spy_Text("  GOOD")
		}
		if(DisplayState = 2){
			temp = Motor_Temperature/10
			Put_Spy_Text("  JOB")
		}
		if(DisplayState = 3){
			temp = Controller_Temperature/10
			Put_Spy_Text("  MAN")
		}
		if(DisplayState = 4){
		temp = Vehicle_speed/10
			Put_Spy_Message(" ", temp, " MPH", PSM_Decimal)
		}
		if(DisplayState = 5){
			temp = Capacitor_voltage / 64
			Put_Spy_Message("Vc", temp, "V", PSM_Decimal)
		}
		if(DisplayState = 6){
			temp = Battery_Current/10
			Put_Spy_Message("Ib", temp, "A", PSM_Decimal)
		}
		if(DisplayState = 7){
			temp = Insulation_Res_kOhmsx10 /10
			Put_Spy_Message("IR", temp, "O", PSM_Decimal)
		}
		
		
		if(Current_RMS>=3800){
			Led1 = ON
			Led2 = ON
			Led3 = ON
			Led4 = ON
			LED5 = ON
			;Put_Spy_LED(8223)
		}
		else if((Current_RMS>=2900) & (Current_RMS<3800)){
			LED1 = ON
			LED2 = ON
			LED3 = ON
			LED4 = ON
			LED5 = OFF
			;Put_Spy_LED(8207)
		}
		else if((Current_RMS>=2000) & (Current_RMS<2900)){
			LED1 = ON
			LED2 = ON
			LED3 = ON
			LED4 = OFF
			LED5 = OFF
			;Put_Spy_LED(8199)
		}
		else if((Current_RMS>=1100) & (Current_RMS<2000)){
			LED1 = ON
			LED2 = ON
			LED3 = OFF
			LED4 = OFF
			LED5 = OFF
			;Put_Spy_LED(8195)
		}
		else if((Current_RMS>=200) & (Current_RMS<1100)){
			LED1 = ON
			LED2 = OFF
			LED3 = OFF
			LED4 = OFF
			LED5 = OFF
			;Put_Spy_LED(8193)
		}
		else{
			Led1 = OFF
			LED2 = OFF
			LED3 = OFF
			LED4 = OFF
			LED5 = OFF
		;Put_Spy_LED(8192)
		}
		if(BarSwitch = ON){
		TroubleLed = ON
		Drive_Current_Limit = 32767
		}
		else{
		TroubleLed = OFF
		Drive_Current_Limit = 25000
		}
		BkLt = ON
		Put_Spy_LED(SpyLEDs)
		Setup_Delay(DLY3, 100)
	}
	
	if(DLY1_Output = 0){

		if(DisplayState = 1){
			Setup_Delay(DLY1, 300)
			DisplayState = 2
			goto break
		}
		if(DisplayState = 2) {
			Setup_Delay(DLY1, 300)
			DisplayState = 3
			goto break
		}
		if(DisplayState = 3){
			Setup_Delay(DLY1, 5000)
			DisplayState = 4
			goto break
		}
		if(DisplayState = 4){
			Setup_Delay(DLY1, 300)
			DisplayState = 1
			goto break
		}
		;if(DisplayState = 5){
		;	Setup_Delay(DLY1, 1500)
		;}
		;if(DisplayState = 6){
		;	Setup_Delay(DLY1, 1500)
		;}
		;if(DisplayState = 7){
		;	Setup_Delay(DLY1, 1500)
		;	DisplayState = 1
		;}
		break:

		}

goto main
