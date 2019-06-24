;---------------- INPUTS -----------------------------
	;MeterResetReq					alias Sw_1		;Pin J1-24
	;Motor temp sensor				switch 2 input	;Pin J1-08
	InterlockSw						alias Sw_3		;Pin J1-09
	FullPowerSw				        alias Sw_4		;Pin J1-10
	;ReverseGearSwitch				alias Sw_5		;Pin J1-11
	;NeutralSwitch					alias Sw_6		;Pin J1-12
	FwdSw							alias Sw_7		;Pin J1-22 also forward switch
	RevSw							alias Sw_8		;Pin J1-33 also reverse switch
	;DashSwitch3						alias Sw_14		;Pin J1-19
	;DashSwitch4						alias Sw_15		;Pin J1-20
	;DashSwitch2						alias Sw_16		;Pin J1-14

	
;---------------- CAN Variables -----------------------------	
; Mailboxes
packControl equals can1
packStatus equals can2
packActiveData equals can3
packTime equals can4
; do not use can5-can14
cellVoltage equals can15
ISAcurrentMsg equals can16
ISAvoltageMsg equals can17
ISAcommandMsg equals can18
ISAampSecondMsg equals can19
ISAwattHourMsg equals can20

ISAcommandDelay equals DLY1
ISAcommandDelayOutput equals dly1_output

ContactorCloseDelay equals DLY2
ContactorCloseDelayOutput equals dly2_output

Charger1 equals PWM1
Charger2 equals PWM3
ChargeEnable equals PWM2
ChargeOutput equals PWM5


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
create ISAvoltage variable
create ISAcurrent variable
create ISAampSeconds variable
create ISAampSecondsHB variable
create ISAwattHours variable
create ISAcAh variable

; Command Message Variables
create ISACommandID variable
create ISACommandData0 variable
create ISACommandData1 variable
create ISACommandData2 variable
create ISACommandData3 variable
create ISACommandData4 variable
create ISACommandData5 variable
create ISACommandData6 variable

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
create CyclerState variable
create temp variable

SpyLEDs equals user_bit4
	Led1 bit SpyLEDs.1
	Led2 bit SpyLEDs.2
	Led3 bit SpyLEDs.4
	Led4 bit SpyLEDs.8
	Led5 bit SpyLEDs.16
	TroubleLed bit SpyLEDs.32
	BkLt bit SpyLEDs.8192
	
TripByte equals user_bit5
	Tripped bit TripByte.1
	TrippedHi bit TripByte.2

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


create CellVmin variable
create CellVmax variable
create newMin variable
create newMax variable
create LastCellIndex variable
create BalanceDeltaFromMinMax variable
create CellVCutoffHigh variable
CellVCutoffHigh = 4200
create CellVCutoffLow variable
create PackTempCutoff variable
PackTempCutoff = 60
create ISACurrentFiltUni variable
create ISACurrentFiltUniLastloop variable
create ChargeTermmA variable
ChargeTermmA = 2000


automate_muldiv(MTD1, @VoltageCAN, 256, 100)
automate_abs(ABS1, @Throttle_pot_raw)
automate_muldiv(MTD2, @abs1_output, 100, 790)
automate_filter(FLT1, @mtd2_output, 1000, 3200, 4)

automate_filter(FLT2, @ISACurrent, 100, 0, 4)
automate_abs(ABS2, @flt2_output)



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
Setup_Mailbox(ISAcurrentMsg, 0, 0, 0x521, C_EVENT, C_RCV, 0, 0)
Setup_Mailbox_Data(ISAcurrentMsg, 6,
					0,
					0,
					0,
					0,
					@ISAcurrent+USEHB,
					@ISAcurrent,0,0)			
Setup_Mailbox(ISAvoltageMsg, 0, 0, 0x522, C_EVENT, C_RCV, 0, 0)
Setup_Mailbox_Data(ISAvoltageMsg, 6,
					0,
					0,
					0,
					0,
					@ISAvoltage+USEHB,
					@ISAvoltage,0,0)	
					
Setup_Mailbox(ISAcommandMsg, 0, 0, 0x411, C_EVENT, C_XMT, 0, 0)
Setup_Mailbox_Data(ISAcommandMsg, 8,
					@ISACommandId,
					@ISACommandData0,
					@ISACommandData1,
					@ISACommandData2,
					@ISACommandData3,
					@ISACommandData4,
					@ISACommandData5,
					@ISACommandData6)

Setup_Mailbox(ISAampSecondMsg, 0, 0, 0x527, C_EVENT, C_RCV, 0, 0)
Setup_Mailbox_Data(ISAampSecondMsg, 6,
					0,
					0,
					@ISAampSecondsHB+USEHB,
					@ISAampSecondsHB,
					@ISAampSeconds+USEHB,
					@ISAampSeconds,0,0)

Setup_Mailbox(ISAwattHourMsg, 0, 0, 0x528, C_EVENT, C_RCV, 0, 0)
Setup_Mailbox_Data(ISAwattHourMsg, 6,
					0,
					0,
					0,
					0,
					@ISAwattHours+USEHB,
					@ISAwattHours,0,0)
					
Startup_CAN()
CAN_Set_Cyclic_Rate( 30 );actually 120ms 		
Setup_NMT_State(ENTER_OPERATIONAL)			;Set NMT state so we can detect global NMT commands
Startup_CAN_Cyclic()

call ISA_init


main:

CellVCutoffLow = flt1_output
ISACurrentFiltUni = abs2_output

; assemble signed 16 bit number representing As/32
temp = ((ISAampSeconds >> 5)&0x7ff) | (ISAampSecondsHB << 11)
;convert from amp-seconds/32 to centiAmpHours
ISAcAh = muldiv(temp, 8, 9) 

;discharge DUT
if((RevSw = ON) && (FwdSw = Off)){
	if(Tripped = OFF){
		call turn_on_discharge
	}
	else{
		call turn_off_discharge
		}
	if((CellVscanning < CellVCutoffLow) OR (CellVmin < CellVCutoffLow) OR (HighestPackTemp > PackTempCutoff))
	{
		Tripped = ON
	}
}
else if (FwdSw = OFF){
	call turn_off_discharge
	Tripped = OFF
	}
	
;charge DUT
if((FwdSw = ON) && (RevSw = OFF)){
	if(TrippedHi = OFF){
		call turn_on_charge
	}
	else{
		call turn_off_charge
		}
	if((CellVscanning > CellVCutoffHigh) 
	OR (CellVmax > CellVCutoffHigh) 
	OR (HighestPackTemp > PackTempCutoff)
	OR ((ISACurrentFiltUniLastloop=1) AND (ISACurrentFiltUni < chargeTermmA)))
	{
		TrippedHi = ON
	}
}
else if (RevSw = OFF) {
	call turn_off_charge
	TrippedHi = OFF
	}
if(ISACurrentFiltUni>ChargeTermmA+10){
	ISACurrentFiltUniLastloop = 1
	}
else{
	ISACurrentFiltUniLastloop = 0
	}

	



if((LastCellIndex>0) & (CellIndex = 0)){
	CellVmin = newmin
	CellVmax = newmax
	newMin = CellVscanning
	newMax = CellVscanning
	}
	LastCellIndex = CellIndex
	
	BalanceDeltaFromMinMax = CellVmax - CellVmin
	
if(CellVscanning > newmax){
	newmax = CellVscanning
	}
	
if(CellVscanning < newmin){
	newmin = CellVscanning
	}
	
; if (ContactorReq == ON) {
	; BMSNoSafetyOverride = ON
	; BMSConnectModule = ON
	; BMSDisconnectModule = OFF
	; BMSOpenContactor = OFF
	; BMSOpenFet = OFF
	; BMSCloseFet = ON
	; BMSCloseContactor = ON
	; BMSKeyOn = ON
; } else {
	; BMSNoSafetyOverride = OFF
	; BMSConnectModule = OFF
	; BMSDisconnectModule = ON
	; BMSOpenContactor = ON
	; BMSOpenFet = ON
	; BMSCloseFet = OFF
	; BMSCloseContactor = OFF
	; BMSKeyOn = OFF
; }

goto main

set_second_charger:
	if (FullPowerSw = ON) {
		put_pwm(Charger2, 0x3fff)
	} else {
		put_pwm(Charger2, 0x0)
	}
	return

turn_on_charge:	
	put_pwm(ChargeEnable, 0)
	put_pwm(Charger1, 0x3fff)
	call set_second_charger
	put_pwm(ChargeOutput, 0x3fff)
	return
	
turn_off_discharge:
	put_pwm(Charger1, 0x0)
	put_pwm(Charger2, 0x0)
	put_pwm(ChargeOutput, 0)
	put_pwm(ChargeEnable, 0)
	return
	
turn_on_discharge:
	put_pwm(ChargeEnable, 0x7fff)
	
	setup_delay(ContactorCloseDelay, 1000)
	while (ContactorCloseDelayOutput <> 0) {}
	
	put_pwm(Charger1, 0x3fff)
	call set_second_charger
	put_pwm(ChargeOutput, 0x3fff)

	
	BMSChargerConnected = OFF ; maybe these should be on but turning them on makes lots of debug messages happen
	BMSChargingEnabled = OFF
	return
	
turn_off_charge:
	put_pwm(Charger1, 0x0)
	put_pwm(Charger2, 0x0)
	put_pwm(ChargeOutput, 0)
	put_pwm(ChargeEnable, 0)
	
	BMSChargerConnected = OFF
	BMSChargingEnabled = OFF
	return
	
;----------------------
;- ISA Driver
;
;- Channels:
;   0. Current
;   1. U1 (Voltage)
;   2. U2
;   3. U3
;   4. Temperature
;   5. Watts
;   6. Amp-seconds
;   7. Watt-hours
;
;-----------------------
ISA_send_command:
	send_mailbox(ISAcommandMsg)
	setup_delay(ISAcommandDelay, 200)
	while (ISAcommandDelayOutput <> 0) {}
	; Could eventually check for response message
	; after send if better error checking is desired.
	return

ISA_reset_defaults:
	ISACommandID = 0x3D
	ISACommandData0 = 0x00
    ISACommandData1 = 0x00
    ISACommandData2 = 0x00
    ISACommandData3 = 0x00
    ISACommandData4 = 0x00
    ISACommandData5 = 0x00
    ISACommandData6 = 0x00
	call ISA_send_command
	
	setup_delay(ISAcommandDelay, 2000)
	while (ISAcommandDelayOutput <> 0) {}
	
	return
	
ISA_reset_amp_hours:
	call ISA_send_stop
	
	ISACommandID = 0x30
	ISACommandData0 = 0x02
    ISACommandData1 = 0x00
    ISACommandData2 = 0x00
    ISACommandData3 = 0x00
    ISACommandData4 = 0x00
    ISACommandData5 = 0x00
    ISACommandData6 = 0x00
	call ISA_send_command
	
	call ISA_send_start
	return
	
ISA_send_stop:
	ISACommandID = 0x34
	ISACommandData0 = 0x00
    ISACommandData1 = 0x01
    ISACommandData2 = 0x00
    ISACommandData3 = 0x00
    ISACommandData4 = 0x00
    ISACommandData5 = 0x00
    ISACommandData6 = 0x00
	call ISA_send_command
	return

ISA_send_start:
	ISACommandID = 0x34
	ISACommandData0 = 0x01
    ISACommandData1 = 0x01
    ISACommandData2 = 0x00
    ISACommandData3 = 0x00
    ISACommandData4 = 0x00
    ISACommandData5 = 0x00
    ISACommandData6 = 0x00
	call ISA_send_command
	return
	
ISA_configure_amps_seconds:
	ISACommandID = 0x26 ; 0x2n where n is the channel number
	ISACommandData0 = (0x2) + (0x0 << 4) ; (0 = Disabled, 1 = Triggered, 2 = Cyclic Running), (Bit6 = Endianness, Bit7 = Invert)
    ISACommandData1 = 0x00 ; Output Cycle Time MSB (ms)
    ISACommandData2 = 60 ; Output Cycle Time LSB (ms)
    ISACommandData3 = 0x00 ; Unused
    ISACommandData4 = 0x00 ; Unused
    ISACommandData5 = 0x00 ; Unused
    ISACommandData6 = 0x00 ; Unused
	call ISA_send_command
	return

ISA_configure_watt_hours:
	ISACommandID = 0x27 ; 0x2n where n is the channel number
	ISACommandData0 = (0x2) + (0x0 << 4) ; (0 = Disabled, 1 = Triggered, 2 = Cyclic Running), (Bit6 = Endianness, Bit7 = Invert)
    ISACommandData1 = 0x00 ; Output Cycle Time MSB (ms)
    ISACommandData2 = 60 ; Output Cycle Time LSB (ms)
    ISACommandData3 = 0x00 ; Unused
    ISACommandData4 = 0x00 ; Unused
    ISACommandData5 = 0x00 ; Unused
    ISACommandData6 = 0x00 ; Unused
	call ISA_send_command
	return
	
ISA_init:
	setup_delay(ISAcommandDelay, 2000)
	while (ISAcommandDelayOutput <> 0) {}

	call ISA_send_stop
	;call ISA_reset_defaults
	call ISA_configure_amps_seconds
	call ISA_configure_watt_hours
	call ISA_send_start
	
	return






























