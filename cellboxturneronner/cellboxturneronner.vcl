;Derived from cell-box-cycler, March 2023
;Goal: turn on contactor on either/both of two Zero Cypher 2 BMSs (on node 8, 9)

;---------------- INPUTS -----------------------------
	;MeterResetReq					alias Sw_1		;Pin J1-24
	;Motor temp sensor				switch 2 input	;Pin J1-08
	InterlockSw						alias Sw_3		;Pin J1-09
	FullPowerSw				        alias Sw_4		;Pin J1-10
	ReverseGearSwitch				alias Sw_5		;Pin J1-11
	NeutralSwitch					alias Sw_6		;Pin J1-12
	FwdSw							alias Sw_7		;Pin J1-22 also forward switch
	RevSw							alias Sw_8		;Pin J1-33 also reverse switch
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

packStatus2 equals can17
packActiveData2 equals can18
packTime2 equals can19
cellVoltage2 equals can20


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
create CellIndex variable
create CellVscanning variable


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
create LastDash2State variable
create temp variable
create DisplayState variable
DisplayState = 1

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
BMSModelYear = 15

;----------- Initialize other variables ------------------------


; Setup time delay at controller startup to send contactor open before
; sending contactor close request
setup_delay(DLY1, 200)


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
					@BalanceDelta,
					@BalanceDelta+USEHB,
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
					@CellIndex,
					@CellVscanning,
					@CellVscanning+USEHB,
					0,
					@VoltageCAN,
					@VoltageCAN+USEHB,
					0,
					0)			

Startup_CAN()
CAN_Set_Cyclic_Rate( 30 );actually x4ms 		
Setup_NMT_State(ENTER_OPERATIONAL)			;Set NMT state so we can detect global NMT commands
Startup_CAN_Cyclic()


main:
	
	
 if (DLY1_Output <> 0) {
	 BMSNoSafetyOverride = ON
	 BMSConnectModule = OFF ;send contactor open
	 BMSDisconnectModule = ON 
	 BMSOpenContactor = ON
	 BMSOpenFet = ON
	 BMSCloseFet = OFF
	 BMSCloseContactor = OFF
	 BMSKeyOn = ON
 }
 else {
	 BMSNoSafetyOverride = OFF
	 BMSConnectModule = ON ;send contactor close request
	 BMSDisconnectModule = OFF
	 BMSOpenContactor = OFF
	 BMSOpenFet = OFF
	 BMSCloseFet = ON
	 BMSCloseContactor = ON
	 BMSKeyOn = OFF
 }

;---------------- Spyglass state machine -------------------------
	if(DLY3_Output = 0)
	{
		if(DisplayState = 1){
			Put_Spy_Message("SOC", SOCpercent, "%", PSM_Decimal)
		}
		if(DisplayState = 2){
			Put_Spy_Message("Tb", HighestPackTemp, "C", PSM_Decimal)
		}

;		if(DisplayState = 7){
;			temp = Insulation_Res_kOhmsx10 /10
;			Put_Spy_Message("IR", temp, "O", PSM_Decimal)
;		}
		
		
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

		BkLt = ON
		Put_Spy_LED(SpyLEDs)
		Setup_Delay(DLY3, 150)
	}
	
	if(DLY2_Output=0)
	{
		DisplayState = DisplayState + 1
		if(DisplayState > 2){
			DisplayState = 1
		}
	Setup_Delay(DLY2, 1500)
	}

goto main
