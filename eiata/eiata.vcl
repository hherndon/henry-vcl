;---------------- INPUTS -----------------------------
	DashSwitch2						alias Sw_1		;Pin J1-24 (Red ring lower left)
	;Motor temp sensor				switch 2 input	;Pin J1-08
	;Interlock_sw					alias Sw_3		;Pin J1-09
	;?								alias Sw_4		;Pin J1-10
	;?								alias Sw_5		;Pin J1-11
	;?								alias Sw_6		;Pin J1-12
	;?								alias Sw_7		;Pin J1-22 also forward switch
	;?								alias Sw_8		;Pin J1-33 also reverse switch
	;?								alias Sw_14		;Pin J1-19
	DashSwitch3						alias Sw_15		;Pin J1-20 (Blue ring lower middle)
	DashSwitch1						alias Sw_16		;Pin J1-14 (Blue ring upper left)

create DisplayState variable
create delaymult variable
create temp variable
create TachDataState variable
TachDataState=1
create SpyDataState variable
SpyDataState=1

SpyLEDs equals user_bit4
	Led1 bit SpyLEDs.1
	Led2 bit SpyLEDs.2
	Led3 bit SpyLEDs.4
	Led4 bit SpyLEDs.8
	Led5 bit SpyLEDs.16
	TroubleLed bit SpyLEDs.32
	BkLt bit SpyLEDs.8192
	
Setup_Switches(7); 28 ms debounce

LastSwitchStates equals user_bit3
    LastDash1State bit LastSwitchStates.1

LastSwitchState2 equals user_bit4
	LastDash3State bit LastSwitchState2.1

;----------- Tach output variables, automates ----------------
;
; Abs_motor_RPM -> 0| DATA |
;                   | SEL1 | -> Automate_frequency_output
; Current_RMS ---> 1|SWITCH|

setup_map(MAP1, 2, 0, 0, 10000, 5000, 0, 0, 0, 0, 0,0,0,0,0,0)
automate_map(MAP1, Current_RMS)

setup_select(SEL1, @Abs_motor_RPM, @MAP1_output)
set_select(SEL1, 0)

Frequency_output_duty_cycle = 16384
Automate_frequency_output(@SEL1_output, 0, 10000, 0, 320) ;for proper scaling 0, 10000,0,320



main:

;--- Main contactor drive copy pwm command to driver 2 higher current output for GV coil --- 
if(PWM1_Output > 0){
		put_pwm(PWM2, 0x7fff)
	}
	else{
		put_pwm(PWM2, 0x0)
	}
	
;------------------Tach Data Select --------------------------
	if(TachDataState = 1){ ;Display rpms
		set_select(SEL1, 0)
		if((DashSwitch1 = ON) & (LastDash1State = OFF)){
			TachDataState = 2
		}
	}
	else if(TachDataState = 2){ ;Display amps
		set_select(SEL1, 1)
		if((DashSwitch1 = ON) & (LastDash1State = OFF)){
			TachDataState = 1
		}
	}
	LastDash1State = DashSwitch1

;------------------Gauge Data Select --------------------------
	if((DashSwitch3 = ON) & (LastDash3State = OFF)){
	if(SpyDataState = 1){ ;Display Tc
		SpyDataState = 2
	}
	else if(SpyDataState = 2){ ;Display Tm
		SpyDataState = 1
		}
	}
	LastDash3State = DashSwitch3

	
;--- Neutral braking pot input ----
	if(AD_Pot_2_Wiper < 640) ; If brake pot input is valid
		{
			Neutral_Braking_TrqM = Mapped_Brake
		}
	
;---- Spyglass output ---- 
	if(DLY3_Output = 0)
	{	
		if(SpyDataState = 1){
			temp = Motor_Temperature/10
			Put_Spy_Message("Tm", temp, "C", PSM_Decimal)
			Led1 = OFF
			LED2 = OFF
			LED3 = OFF
			LED4 = OFF
			LED5 = OFF
			if(temp > 50)
				{LED1 = ON}
			if(temp > 70)
				{LED2 = ON}
			if(temp > 90)
				{LED3 = ON}
			if(temp > 110)
				{LED4 = ON}
			if(temp > 130)
				{LED5 = ON}
		}
		if(SpyDataState = 2){
			temp = Controller_Temperature/10
			Put_Spy_Message("Tc", temp, "C", PSM_Decimal)
			Led1 = OFF
			LED2 = OFF
			LED3 = OFF
			LED4 = OFF
			LED5 = OFF
			if(temp > 35)
				{LED1 = ON}
			if(temp > 50)
				{LED2 = ON}
			if(temp > 60)
				{LED3 = ON}
			if(temp > 70)
				{LED4 = ON}
			if(temp > 80)
				{LED5 = ON}
		}
		if(SpyDataState = 3){
			temp = Insulation_Res_kOhmsx10 /10
			Put_Spy_Message("IR", temp, "k", PSM_Decimal)
		}

		TroubleLed = OFF
		if(MotorTempCutback < 4096){
			TroubleLED = ON
		}
		if(ControllerTempCutback < 4096){
			TroubleLED = ON
		}
		if(UndervoltageCutback < 4096){
			TroubleLED = ON
		}
		if(OvervoltageCutback < 4096){
			TroubleLED = ON
		}
		BkLt = ON

	Put_Spy_LED(SpyLEDs)

	
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