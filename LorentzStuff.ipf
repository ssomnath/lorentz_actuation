#pragma rtGlobals=1		// Use modern global access method.

Menu "UIUC"
	Submenu "Lorentz"
		"Master Panel", LorentzMasterDriver()
		"Voltage Sweep", LorentzSweepDriver()
	End
End

Function LorentzSweepDriver()
	
	// If the panel is already created, just bring it to the front.
	DoWindow/F LorentzRampPanel
	if (V_Flag != 0)
		return 0
	endif
	
	String dfSave = GetDataFolder(1)
	
	// Create a data folder in Packages to store globals.
	NewDataFolder/O/S root:packages:Lorentz
	
	Variable Vstart = NumVarOrDefault(":gVstart",-1)
	Variable/G gVstart= Vstart
	
	Variable Vend = NumVarOrDefault(":gVend",1)
	Variable/G gVend= Vend
	
	Variable dVolts = NumVarOrDefault(":gVStep",0.5)
	Variable/G gVStep= dVolts
	
	Variable delay = NumVarOrDefault(":gDelay",1)
	Variable/G gDelay= delay
	
	Variable/G gProgress= 0
	
	Variable numSteps = NumVarOrDefault(":gNumSteps",1)
	Variable/G gNumSteps= numSteps
	
	Variable showTable = NumVarOrDefault(":gshowTable",1)
	Variable/G gshowTable= showTable
	
	Variable rampMode = NumVarOrDefault(":gRampMode",1)
	Variable/G gRampMode= rampMode
	
	Variable/G gAbortIV = 0
	
	String/G gRampModeNames = "DC; AC"
	
	//String/G gLockinString = "";
	//if(rampMode == 1)
	//	gLockinString = "lockin.DCOffset";
	//else
	//	gLockinString = "lockin.Amp";
	//endif
	
	Make/O/N=0 VoutWave, SumWave, DefWave, AmpWave, PhaseWave
		
	// Create the control panel.
	Execute "LorentzRampPanel()"
	//Reset the datafolder to the root / previous folder
	SetDataFolder dfSave

End

Window LorentzRampPanel(): Panel
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(485,145, 1300,700) as "Lorentz Sweep Panel"
	SetDrawLayer UserBack
		
	
	SetVariable sv_StartV,pos={200,20},size={112,18},title="V initial (V)", limits={-10,10,1}
	SetVariable sv_StartV,value= root:packages:Lorentz:gVstart,live= 1
	
	SetVariable sv_VdcStep,pos={336,57},size={105,18},title="V step (V)", limits={-10,10,.01}
	SetVariable sv_VdcStep,value= root:packages:Lorentz:gVStep,live= 1
	
	SetVariable sv_EndV,pos={332,20},size={109,20},title="V Final (V)", limits={-10,10,1}
	SetVariable sv_EndV, value=root:Packages:Lorentz:gVend
	
	SetVariable sv_delay,pos={192,57},size={120,18},title="Delay (sec)", limits={0,inf,1}
	SetVariable sv_delay, value=root:Packages:Lorentz:gDelay
	
	ValDisplay sv_steps,pos={52,57},size={115,18},title="Num steps"
	ValDisplay sv_steps,value= root:packages:Lorentz:gNumSteps,live= 1
	
	Popupmenu pp_rampmode,pos={33,20},size={152,18},title="Ramp Mode",live= 1, proc=RampModeProc
	Popupmenu pp_rampmode, mode=root:packages:Lorentz:gRampMode, value= root:packages:Lorentz:gRampModeNames
		
	Button but_StartRamp,pos={465,18},size={67,25},title="Start", proc=StartVRamp	
	
	Button but_stop,pos={465,50},size={67,25},title="Stop", proc=StopRamp
	
	
	ValDisplay vd_Progress,pos={554,23},size={236,20},title="Progress", mode=0, live=1
	ValDisplay vd_Progress,limits={0,100,0},barmisc={0,40},highColor= (0,43520,65280)
	ValDisplay vd_Progress, fsize=14, value=root:Packages:Lorentz:GProgress
	
	Checkbox chk_ShowData, pos = {708, 51}, size={10,10}, title="Show Data", proc=ShowDataChkFun2
	Checkbox chk_ShowData, live=1, value=root:Packages:Lorentz:gshowTable
	
	String dfSave= GetDataFolder(1)
	SetDataFolder root:packages:Lorentz
	
	Display/W=(21,85,397,292) /HOST=# SumWave, vs VoutWave
	ModifyGraph frameStyle=5, mode=4, msize=3,marker=19, lStyle=7; // marker: kind of point, mode:=3display only points, 0 = lines between points
	Label bottom "\Z13 Ramp V (V)"
	Label left "\Z13 Sum (V)"
	RenameWindow #,G0
	SetActiveSubwindow ##
	
	Display/W=(410,85,790,292) /HOST=# DefWave, vs VoutWave
	ModifyGraph frameStyle=5, mode=4, msize=3,marker=19, lStyle=7;
	Label bottom "\Z13 Ramp V (V)"
	Label left "\Z13 Deflection (V)"
	RenameWindow #,G1
	SetActiveSubwindow ##
	
	Display/W=(21,305,397,505) /HOST=# PhaseWave, vs VoutWave
	ModifyGraph frameStyle=5, mode=4, msize=3,marker=19, lStyle=7;
	Label bottom "\Z13 Ramp V (V)"
	Label left "\Z13 Phase (deg)"
	RenameWindow #,G2
	SetActiveSubwindow ##
	
	Display/W=(410,305,790,505) /HOST=# AmpWave, vs VoutWave
	ModifyGraph frameStyle=5, mode=4, msize=3,marker=19, lStyle=7;
	Label bottom "\Z13 Ramp V (V)"
	Label left "\Z13 Amplitude (V)"
	RenameWindow #,G3
	SetActiveSubwindow ##
	
	SetDataFolder dfSave		
	SetDrawEnv fstyle= 1 
	SetDrawEnv textrgb= (0,0,65280)
	DrawText 624,535, "\Z13Suhas Somnath, UIUC 2013"
End	

Function StopRamp(ctrlname) : ButtonControl
	String ctrlname
	
	String dfSave = GetDataFolder(1)
		
	SetDataFolder root:Packages:Lorentz
	NVAR gAbortIV
	
	// stop background function here.
	gAbortIV = 1

	ModifyControl but_StartRamp, disable=0, title="Start"
	
	SetDataFolder dfSave
	
End

Function ShowDataChkFun2(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			String dfSave = GetDataFolder(1)
			SetDataFolder root:Packages:Lorentz
			NVAR gShowTable
			gShowTable = cba.checked
			SetDataFolder dfSave
			break
	endswitch

	return 0
End

Function RampModeProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:Lorentz
	NVAR gRampMode
	SVAR gLockinString
	
	switch( pa.eventCode )
		case 2: // mouse up
			gRampMode = pa.popNum
			//if(gRampMode == 1)//DC
				//gLockinString = "lockin.DCOffset"
			//else // AC
				//gLockinString = "lockin.Amp"
			//endif
			break
	endswitch
	
	SetDataFolder dfSave
	
End //RampModeProc


Function StartVRamp(ctrlname) : ButtonControl
	String ctrlName;
	
	StartMeter("StartAndStopButton")
	ReWireXPT(3)
	
	String dfSave = GetDataFolder(1)
	
	SetDataFolder root:packages:Lorentz
	
	NVAR gVstart, gVStep, gDelay,gVend, gRampMode, gProgress, gAbortIV;
	Variable/G gIteration = 0
	Variable/G gIterStartTick = 0
	Variable/G gSumTotal = 0
	Variable/G gDefTotal = 0
	Variable/G gAmpTotal = 0
	Variable/G gPhaseTotal = 0
	Variable/G gNumMeasurements = 0
	Variable/G gNumSteps = 0;
	gProgress = 0;
	gAbortIV = 0;
	
	if((gVend < gVStart && gVStep > 0) || (gVend > gVStart && gVStep < 0))
		gVStep = gVStep *-1;
	endif
	
	if(gRampMode == 1) // DC
		Variable/G gNumSteps = 1;
		if(gVstart * gVend > 0) // both on same side
			gNumSteps = 1 + floor((gVend - gVstart)/gVstep);		
			//gVend = gVstart + gVStep * gNumSteps
		elseif(gVstart*gVend < 0) // opposite sides of 0
			gNumSteps = floor(1 + abs(gVstart/gVstep) + abs(gVend/gVstep));		
			//gVend = gVstart + gVStep * gNumSteps
		else // 0 is one of the points
			gNumSteps = 1+ floor(max(abs(gVend), abs(gVstart))/gVstep);	
		endif
	else
		//print "1 + floor(((" + num2str(gVend) + " - " + num2str(gVstart) + ")/" + num2str(gVstep) + "))"
		gVend = max(0,gVend);
		gVstart = max(0,gVstart);
		gNumSteps =  1 + floor(((gVend - gVstart)/gVstep));		
		//gVend = gVstart + gVStep * gNumSteps
	endif
	 
	//print "numsteps = " + num2str(gNumSteps)
	
	NVAR gNumSteps

	Make/O/N=0 VoutWave, SumWave, DefWave, AmpWave, PhaseWave
	Redimension/N=(gNumSteps) VoutWave, SumWave, DefWave, AmpWave, PhaseWave
	
	ModifyControl pp_rampmode, disable=2
	ModifyControl but_startRamp, disable=2, title="Running.."
	
	// Starting background process here:
	ARBackground("bgLorentzRamp",100,"")
	
	SetDataFolder dfSave

End

Function setDriveAmpVolts(amp)
	Variable amp
	TuneSetVarFunc("DriveAmplitudeSetVar_3",amp,num2str(amp) + " V", "MasterVariablesWave[%DriveAmplitude][%Value]")
End

Function returnToSafeValue(mode)
	Variable mode
	
	if(mode == 1) // DC
		td_wv("lockin.DCOffset",0)
	else // AC
		setDriveAmpVolts(0.1) // MUST be in VOLTS not mV
	endif
	
End

Function bgLorentzRamp()

	String dfSave = GetDataFolder(1)
	
	SetDataFolder root:packages:Lorentz
	NVAR gVstart, gVStep, gVend, gIteration, gIterStartTick, gSumTotal, gDefTotal, gAmpTotal, gPhaseTotal, gNumMeasurements, gNumSteps
	Wave VoutWave, SumWave, DefWave, AmpWave, PhaseWave
	NVAR gShowTable, gAbortIV, gRampMode
	
	if(gAbortIV)
		returnToSafeValue(gRampMode)
		
		SetDataFolder root:packages:Lorentz
		ModifyControl but_startRamp, disable=0, title="Start"
		gAbortIV = 0;
		SetDataFolder dfSave
		return 1;
	endif
	
	// Case 1: Very first run of IV
	if(gIterStartTick == 0)
		
		VoutWave[0] = gVstart + 0*gVStep
		
		
		if(gRampMode == 1) // DC
			td_wv("lockin.DCOffset",gVstart + 0*gVStep)
			//print "td_wv(" + gLockinString + ", " + num2str(gVstart + 0*gVStep) + ")"
		else // AC
			setDriveAmpVolts(gVstart + 0*gVStep) // MUST be in VOLTS not mV
		endif
		
		gIterStartTick = ticks
		SetDataFolder dfSave
		//print("very first")
		return 0;
	endif
	
	if(gIterStartTick > 0)
	
		NVAR gIteration, gVsenseTotal, gNumMeasurements, gDelay, gVtotTotal
		//print "Time till next iteration: " + num2str(gIterStartTick+(gDelay* 60) - ticks)
		if(ticks < (gIterStartTick+(gDelay* 60)))
		
			// Case 2: Same iteration 
			// take another measurement
			
			SetDataFolder Root:Packages:MFP3D:Meter
			NVAR Sum
			Wave ReadMeterRead
			
			gSumTotal += Sum;
			gDefTotal += ReadMeterRead[%Deflection][0];
			gAmpTotal += ReadMeterRead[%Amplitude][0];
			gPhaseTotal += ReadMeterRead[%Phase][0]
			gNumMeasurements += 1
			SetDataFolder dfSave
			//print("Grabbing more data")
			return 0;
		else
	
			// Case 3: Completed iteration 
			
			// a. calculate & store necessary vals for previous iter	
			SetDataFolder root:Packages:Lorentz
			NVAR gProgress

			//print "Took " + num2str(gNumMeasurements) + " measurements"
			VoutWave[gIteration] = gVstart + gIteration*gVStep
			SumWave[gIteration] = gSumTotal / gNumMeasurements
			DefWave[gIteration] = gDefTotal / gNumMeasurements
			AmpWave[gIteration] = gAmpTotal / gNumMeasurements
			PhaseWave[gIteration] = gPhaseTotal / gNumMeasurements
			
			if(AmpWave[gIteration] > 10)
				AmpWave[gIteration] = AmpWave[gIteration]/1000;
			endif

			
			//print "VoutWave["+num2str(gIteration)+"] = "+num2str(gVstart)+ "+ " +num2str(gIteration)+"*"+num2str(gVStep)
			
			
			

			// b. advance iteration & progress		
			gNumMeasurements = 0;
			gSumTotal = 0;
			gDefTotal = 0;
			gAmpTotal = 0;
			gPhaseTotal = 0;
			gIteration = gIteration+1
			gProgress = min(100,floor((gIteration/gNumSteps)*100))
			//print "iteration #" + num2str(gIteration) + " now complete"
			
			// c. Start next iteration OR stop
			
			if(gIteration < gNumsteps)
			
				// start next iteration
				
				if(gRampMode == 1) // DC
					td_wv("lockin.DCOffset",gVstart + gIteration*gVStep)
					//print "td_wv(" + gLockinString + ", " + num2str(gVstart + gIteration*gVStep) + ")"
				else // AC
					setDriveAmpVolts(gVstart + gIteration*gVStep) // MUST be in VOLTS not mV
				endif
				
				//VoutWave[gIteration] = gVstart + gIteration*gVStep;
				//print "Outputting: " + num2str(gVstart + gIteration*gVStep)
				gIterStartTick = ticks
				SetDataFolder dfSave
				//print("moving to next iteration")
				return 0;
				
			else
			
				// Safety cut off
				returnToSafeValue(gRampMode)
			
				ModifyControl but_startRamp, disable=0, title="Start"
				ModifyControl pp_rampmode, disable=0
				
				SetDataFolder dfSave
				
				if(gShowTable)
					Edit/K=1 VoutWave, SumWave, DefWave, AmpWave, PhaseWave
				endif
				return 1;
				
			endif
		endif
	endif
	
	print "IV calib should not be coming here. Aborting"
	return 1; // DONT keep background function alive

End


Function ReWireXPT(scanmode)
	Variable Scanmode


	if (ScanMode == 3) // Lorentz:
		XPTPopupFunc("LoadXPTPopup",2,"ACScan")
		WireXpt3("BNCOut0Popup","DDS")
		XPTBoxFunc("XPTLock10Box_0",1)
		
		WireXpt3("ShakePopup","Off")
		XPTBoxFunc("XPTLock15Box_0",1)
	
	else
		XPTBoxFunc("XPTLock10Box_0",0)	
		XPTBoxFunc("XPTLock15Box_0",0)	
		XPTButtonFunc("ResetCrosspoint")
		
		if (ScanMode == 1) // Contact mode:
			XPTPopupFunc("LoadXPTPopup",4,"DCScan")
			
		elseif(ScanMode == 2) // Piezo AC mode:
			XPTPopupFunc("LoadXPTPopup",2,"ACScan")
		
		endif
			
	endif
		
	
	XptButtonFunc("WriteXPT")
	XPTButtonFunc("ResetCrosspoint")
	 // seems to annul all the changes made so far if I used td_WS

End

Function WireXpt3(whichpopup,channel)
	String whichpopup, channel
	
	execute("XPTPopupFunc(\"" + whichpopup + "\",WhichListItem(\""+ channel +"\",Root:Packages:MFP3D:XPT:XPTInputList,\";\",0,0)+1,\""+ channel +"\")")

End

Function LorentzMasterDriver()
	
	// If the panel is already created, just bring it to the front.
	DoWindow/F LorentzMasterPanel
	if (V_Flag != 0)
		return 0
	endif
	
	String dfSave = GetDataFolder(1)
	
	// Create a data folder in Packages to store globals.
	NewDataFolder/O/S root:packages:Lorentz
	
	Variable/G gVdc= 0
	
	Variable Vac = NumVarOrDefault(":gVac",0.05)
	Variable/G gVac= Vac
		
	// Create the control panel.
	Execute "LorentzMasterPanel()"
	//Reset the datafolder to the root / previous folder
	SetDataFolder dfSave

End



Window LorentzMasterPanel(): Panel
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(485,145, 700,255) as "Lorentz Imaging Panel"
	SetDrawLayer UserBack
	
	SetVariable sv_Vdc,pos={16,16},size={180,18},title="V dc (V)", limits={0,10,.01}
	SetVariable sv_Vdc,value= root:packages:Lorentz:gVdc,live= 1, proc=changeLorentzDrive
	
	SetVariable sv_Vac,pos={16,49},size={180,20},title="V ac (V)", limits={0,10,1}
	SetVariable sv_Vac, value=root:Packages:Lorentz:gVac, proc=changeLorentzDrive
		
	SetDrawEnv fstyle= 1 
	SetDrawEnv fsize= 14
	SetDrawEnv textrgb= (0,0,65280)
	DrawText 16,98, "Suhas Somnath, UIUC 2013"
		
End	

Function changeLorentzDrive(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			updateLorentzDrive();			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function updateLorentzDrive()

	String dfSave = GetDataFolder(1)
	
	SetDataFolder root:packages:Lorentz
	NVAR gVac, gVdc
	
	if((gVac + gVdc) < 10)
		td_wv("lockin.DCOffset",gVdc)
		//setDriveAmpVolts(gVac)
	endif
	
	SetDataFolder dfSave


End



Function printDetails(Vdc)
	Variable Vdc
	
	SetDataFolder Root:Packages:MFP3D:Meter
	NVAR Sum
	Wave ReadMeterRead
	
	Variable s = 0;
	Variable d = 0;
	Variable a = 0;
	Variable n = 0;

	td_wv("lockin.DCOffset",Vdc)
	Variable t0 = ticks
	do
		s = s + Sum;
		d = d + ReadMeterRead[%Deflection][0];
		a = a + ReadMeterRead[%Amplitude][0];
		n = n +1;
	while ((ticks - t0)/60 < 1)
	print "Vdc = " + num2str(Vdc) + ", Sum = " + num2str(s/n) + ", Defl = " + num2str(d/n) + ", Amp = " + num2str(a/n);
	
	SetDataFolder Root:Packages:
End

//SetDataFolder root:Packages:MFP3D:Main:Variables
	//Wave MasterVariablesWave
		
	//SetVariable sv_StartV,pos={16,20},size={180,18},title="Amp (V)", limits={0,10,1}
	//SetVariable sv_StartV,value= MasterVariablesWave[%DriveAmplitude][%Value],live= 1
	//TuneSetVarFunc(ctrlName,varNum,varStr,varName)
	//DriveAmplitudeSetVar_3
	//SetDataFolder root:Packages:MFP3D:Main:Variables
	//Wave MasterVariablesWave[%DriveAmplitude][%Value]
	//
  	//0.2
  	//0.2 V
  	//MasterVariablesWave[%DriveAmplitude][%Value]
  	
 