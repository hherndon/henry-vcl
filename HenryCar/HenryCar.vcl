; PARAMETER_ENTRY "Program"
;		TYPE		PROGRAM
;		Level		0
;	END
; PARAMETER_ENTRY "BMS Data"
;		TYPE		Monitor
;		Level		1
;	END
; parameter_entry "State^of^Charge"
; 	type Monitor
; 	width 16bit
; 	address user7
; 	units %
; end
; parameter_entry "Cell^balance^delta"
; 	type Monitor
; 	width 16bit
; 	address user8
; 	units mV
; end
; parameter_entry "Battery^Pack^Temperature"
; 	type Monitor
; 	width 16bit
; 	address user9
;	units oC
; end
; parameter_entry "Battery^Current"
; 	type Monitor
; 	width 16bit
; 	address user10
;	signed YES
;	units amp
; end
; parameter_entry "Discharge^Rate^Limit"
; 	type Monitor
; 	width 16bit
; 	address user18
;	signed YES
;	units amp
; end
; parameter_entry "Charge^Rate^Limit"
; 	type Monitor
; 	width 16bit
; 	address user17
;	signed YES
;	units amp
; end
; parameter_entry "BMS^Voltage"
; 	type Monitor
; 	width 16bit
; 	address mtd1_output
;	signed YES
;	units volt
; end

;---------------- INPUTS -----------------------------
	DashSwitch1						alias Sw_1		;Pin J1-24
	;Motor temp sensor				switch 2 input	;Pin J1-08
	;Interlock_sw					alias Sw_3		;Pin J1-09
	StartSwitch						alias Sw_4		;Pin J1-10
	;ReverseGearSwitch				alias Sw_5		;Pin J1-11
	NeutralSwitch					alias Sw_6		;Pin J1-12
	KeyOn							alias Sw_7		;Pin J1-22 also forward switch
	ClutchPedal						alias Sw_8		;Pin J1-33 also reverse switch
	DashSwitch3						alias Sw_14		;Pin J1-19
	DashSwitch4						alias Sw_15		;Pin J1-20
	DashSwitch2						alias Sw_16		;Pin J1-14
	
;---------------- CAN Variables -----------------------------	
; Mailboxes
packControl equals can1
packStatus equals can2
packActiveData equals can3
packTime equals can4
; do not use can5-can14
cellVoltage equals can15
vehicleData equals can20

; Message Variables
create BMSNode variable
create BMSNumberNodes variable
create BMSModelYear variable
create SOCpercent variable
create BalanceDelta variable
create HighestPackTemp variable
create DischargeAmps variable
create ChargeCrateLimit variable
create DischargeCrateLimit variable
create VoltageCAN variable
create voltage_difference variable

BMSControlLow equals user_bit1
    BMSCloseFet 			bit BMSControlLow.1
    BMSOpenFet 				bit BMSControlLow.2
    BMSCloseContactor 		bit BMSControlLow.4
    BMSOpenContactor 		bit BMSControlLow.8
    BMSDisconnectModule 	bit BMSControlLow.16
    BMSConnectModule 		bit BMSControlLow.32
    BMSKeyOn 				bit BMSControlLow.64
    BMSChargerConnected 	bit BMSControlLow.128
BMSControlHigh equals user_bit2 
    BMSChargingEnabled 		bit BMSControlHigh.1
    BMSInhibitIsolationTest bit BMSControlHigh.2
    BMSNoSafetyOverride 	bit BMSControlHigh.64
    BMSSafetyOverride 		bit BMSControlHigh.128


;----------- State Machine Variables etc ----------------------------
create DriveState variable
create NeutralState variable
create DisplayState variable
create temp variable
create TachDataState variable
create StartupPulse variable

LastSwitchStates equals user_bit3
    LastDash1State bit LastSwitchStates.1
	LastDash2State bit LastSwitchStates.2
	
SpyLEDs equals user_bit4
	Led1 bit SpyLEDs.1
	Led2 bit SpyLEDs.2
	Led3 bit SpyLEDs.4
	Led4 bit SpyLEDs.8
	Led5 bit SpyLEDs.16
	TroubleLed bit SpyLEDs.32
	BkLt bit SpyLEDs.8192

;----------- Initialize BMS state variables -------------------
BMSNoSafetyOverride = ON
BMSConnectModule = OFF		;SEND BMS OPEN CONTACTOR COMMAND FIRST
BMSDisconnectModule = ON
BMSOpenContactor = ON
BMSOpenFet = ON
BMSCloseFet = OFF
BMSCloseContactor = OFF
BMSKeyOn = ON
BMSNode = 8
BMSNumberNodes = 1
BMSModelYear = 14
DisplayState = 1

;----------- Initialize other variables ------------------------
VCL_App_Ver = 100
DriveState = 1
NeutralState = 1
TachDataState = 1
DisplayState = 2
StartupPulse = 7000 ; How many RPM should tach show during startup pulse


;----------- Tach output variables, automates ----------------
;
; Abs_motor_RPM -> 0| DATA |
;                   | SEL1 | -> 0| DATA |
; Current_RMS ---> 1|SWITCH|     | SEL2 | -> Automate_frequency_output
; CONSTANT SPEED   -----------> 1|SWITCH| 
setup_select(SEL1, @Abs_motor_RPM, @Current_RMS)
setup_select(SEL2, @SEL1_output, @StartupPulse)
set_select(SEL1, 0)
set_select(SEL2, 0)

Frequency_output_duty_cycle = 16384
Automate_frequency_output(@SEL2_output, 0, 10000, 0, 175) ;for proper scaling 0, 7000, 0, 175

automate_muldiv(MTD1, @VoltageCAN, 256, 1000)
automate_muldiv(MTD2, @VoltageCAN, 16384, 1000)

automate_filter(FLT1, @Mapped_Brake, 100, 0, 50)

; Setup time delay at controller startup for EPS enable tach pulse,
; 2 seconds from KSI on to allow time for dash to boot
setup_delay(DLY2, 1400)

;------------ Setup mailboxes ----------------------------
disable_mailbox(packControl)
Shutdown_CAN_Cyclic()

Setup_Mailbox(packControl, 0, 0, 0x506, C_CYCLIC, C_XMT, 0, 0)
Setup_Mailbox_Data(packControl,8,
					@BMSNode,	  		
                    @BMSControlLow,
					@BMSControlHigh,			 
					@BMSNumberNodes,	 
					@BMSModelYear,		  
					0,	 
					0,	   
					0)	
enable_mailbox(packControl)

Setup_Mailbox(packStatus, 0, 0, 0x188, C_EVENT, C_RCV, 0, 0)
Setup_Mailbox_Data(packStatus,8,
					@SOCpercent,
					0,
					0,
					0,
					0,
					0,
					@BalanceDelta,
					0)
					
Setup_Mailbox(packActiveData, 0, 0, 0x408, C_EVENT, C_RCV, 0, 0)
Setup_Mailbox_Data(packActiveData, 8,
					0,
					@HighestPackTemp,
					0,
					@DischargeAmps,
					@DischargeAmps+USEHB,
					0,
					0,
					0)

Setup_Mailbox(packTime, 0, 0, 0x508, C_EVENT, C_RCV, 0, 0)
Setup_Mailbox_Data(packTime, 8,
					0,
					0,
					0,
					0,
					@ChargeCrateLimit,
					@ChargeCrateLimit+USEHB,
					@DischargeCrateLimit,
					@DischargeCrateLimit+USEHB)

Setup_Mailbox(cellVoltage, 0, 0, 0x388, C_EVENT, C_RCV, 0, 0)
Setup_Mailbox_Data(cellVoltage, 8,
					0,
					0,
					0,
					0,
					@VoltageCAN,
					@VoltageCAN+USEHB,
					0,
					0)	

Setup_Mailbox(can20, 0, 0, 0x550, C_CYCLIC, C_XMT, 0, 0)
Setup_Mailbox_Data(can20,8,
					@Motor_RPM+USEHB,	  		
                    @Motor_RPM,
					@Irms+USEHB,			 
					@Irms,	 
					@IqReq+USEHB,		  
					@IqReq,	 
					0,	   
					0)	
enable_mailbox(can20)				
					
Startup_CAN()
CAN_Set_Cyclic_Rate( 30 );actually 120ms 		
Setup_NMT_State(ENTER_OPERATIONAL)			;Set NMT state so we can detect global NMT commands
Startup_CAN_Cyclic()

;enable_precharge()

main:
;---------------- BMS controlled Main contactor control ------------------
	voltage_difference = Capacitor_voltage - MTD2_output
	if((main_state = 5) and ((voltage_difference < 3*64) or (voltage_difference > -3*64))) ; If main is closed and volts front and back are within 3
	{
BMSNoSafetyOverride = ON
BMSConnectModule = ON
BMSDisconnectModule = OFF
BMSOpenContactor = OFF
BMSOpenFet = OFF
BMSCloseFet = ON
BMSCloseContactor = ON
BMSKeyOn = ON
	}
	
if(PWM1_Output > 0){
		put_pwm(PWM2, 0x7fff)
	}
	else{
		put_pwm(PWM2, 0x0)
	}
	
;---------------- Spyglass state machine -------------------------
	if(DLY3_Output = 0)
	{
		if(DisplayState = 1){
			Put_Spy_Message("SOC", SOCpercent, "%", PSM_Decimal)
		}
		if(DisplayState = 2){
			temp = Motor_Temperature/10
			Put_Spy_Message("Tm", temp, "C", PSM_Decimal)
		}
		if(DisplayState = 3){
			temp = Controller_Temperature/10
			Put_Spy_Message("Tc", temp, "C", PSM_Decimal)
		}
		if(DisplayState = 4){
			Put_Spy_Message("Tb", HighestPackTemp, "C", PSM_Decimal)
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
		
		
		if(SOCpercent>=90){
			Led1 = ON
			Led2 = ON
			Led3 = ON
			Led4 = ON
			LED5 = ON
			;Put_Spy_LED(8223)
		}
		else if((SOCpercent>=70) & (SOCpercent<90)){
			LED1 = ON
			LED2 = ON
			LED3 = ON
			LED4 = ON
			LED5 = OFF
			;Put_Spy_LED(8207)
		}
		else if((SOCpercent>=50) & (SOCpercent<70)){
			LED1 = ON
			LED2 = ON
			LED3 = ON
			LED4 = OFF
			LED5 = OFF
			;Put_Spy_LED(8199)
		}
		else if((SOCpercent>=30) & (SOCpercent<50)){
			LED1 = ON
			LED2 = ON
			LED3 = OFF
			LED4 = OFF
			LED5 = OFF
			;Put_Spy_LED(8195)
		}
		else if((SOCpercent>=10) & (SOCpercent<30)){
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
		if(Neutral_Braking_TrqM < 10){
		TroubleLed = ON
		}
		else{
		TroubleLed = OFF
		}
		BkLt = ON
		Put_Spy_LED(SpyLEDs)
		Setup_Delay(DLY3, 150)
	}
	if((DashSwitch2 = ON) & (LastDash2State = OFF)){
		DisplayState = DisplayState + 1
		if(DisplayState > 7){
			DisplayState = 1
		}
	}
	LastDash2State = DashSwitch2
	
;-------------- Interlock latching state machine -----------
	if(DriveState = 1){
		Clear_interlock()
		if(StartSwitch = ON){
			DriveState = 2
		}
	}
	else if(DriveState = 2){
		Set_interlock()
	}
	else{
		Clear_interlock()
	}
;------------------Tach Data Select --------------------------
	if(TachDataState = 1){ ;Display Amps*10
		set_select(SEL1, 1)
		if((DashSwitch1 = ON) & (LastDash1State = OFF)){
			TachDataState = 2
		}
	}
	else if(TachDataState = 2){ ;Display RPM
		set_select(SEL1, 0)
		if((DashSwitch1 = ON) & (LastDash1State = OFF)){
			TachDataState = 1
		}
	}
	LastDash1State = DashSwitch1
	
;--------------- Tach pulse on startup for EPS ------------------
; DLY2 counter setup in KSI initiation
	if(DLY2_Output <> 0){
		set_select(SEL2,1)
	}
	else{
		set_select(SEL2, 0)
	}

;-------------- Neutral braking disable state machine -----------

; -- "Flatfoot shifting" zero out throttle multiplier when clutch pedal observed (Only when brake pot is >0)
	if((ClutchPedal = ON) & (Mapped_Brake > 1))
	{
		Throttle_Multiplier = 0
	}
	else{
		Throttle_Multiplier = 128
	}
		

	if(NeutralState = 1)
	{
		;turn neutral braking on
		;Neutral_Braking_TrqM = 6550 ;20 percent
		;Neutral_Braking_TrqM = Mapped_Brake

		if((Neutral_Braking_TrqM < Mapped_Brake) & (AD_Pot_2_Wiper < 640)) ; Ramping up NB command
		{
			if(Mapped_Brake - Neutral_Braking_TrqM > 50)
			{
				Neutral_Braking_TrqM = Neutral_Braking_TrqM + 50
			}
			else
			{
				Neutral_Braking_TrqM = Mapped_Brake
			}
		}
		if((Neutral_Braking_TrqM > Mapped_Brake) & (AD_Pot_2_Wiper < 640)) ; Ramping down NB command
		{
			if(Neutral_Braking_TrqM - Mapped_Brake > 150)
			{
				Neutral_Braking_TrqM = Neutral_Braking_TrqM - 150
			}
			else{
				Neutral_Braking_TrqM = Mapped_Brake
			}
		}
		;State exit criteria: Neutral switch is observed
		if((NeutralSwitch = ON) or (ClutchPedal = ON))
		{
			NeutralState = 2
		}
	}
	else if(NeutralState = 2)
	{
		;turn neutral braking off
		Neutral_Braking_TrqM = 0
		if((NeutralSwitch = OFF) and (ClutchPedal = OFF) and ((Mapped_Throttle > 1) or (Motor_RPM = 0))) ; out of neutral and >10% throttle or motor stopped
		{
			NeutralState = 1
		}
	}
	else
	{
		Neutral_Braking_TrqM = 0
	}


goto main
