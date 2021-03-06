

; Unsigned:
; a.b = -64 
; Debug a & 255  ; ergibt 192

#IOCTL_IDE_PASS_THROUGH = $04D028
#HDIO_DRIVE_CMD       = $03F1 ; Taken from /usr/include/linux/hdreg.h
#WIN_SETFEATURES      = $EF
#SETFEATURES_EN_AAM   = $42
#SETFEATURES_DIS_AAM  = $C2
#SETFEATURES_EN_APM   = $05
#SETFEATURES_DIS_APM  = $85

; hdparm.exe --debug -b 255 /dev/hda
; \\.\PhysicalDrive0: successfully opened
; 
; /dev/hda:
; setting Advanced Power Management level To disabled
; IOCTL_ATA_PASS_THROUGH succeeded, Bytes returned: 40
; In : cmd=0xef, FR=0x85, SC=0x00, SN=0x00, CL=0x00, ch=0x00, SEL=0x00
; Out: STS=0x50,ERR=0x00, SC=0x00, SN=0x00, CL=0x00, ch=0x00, SEL=0xa0
;RSet(Hex(12), 4, "0") 

Macro ZHex(val,digits=2)
  RSet(Hex(val), digits, "0")
EndMacro

Structure IDEREGS
  bFeaturesReg.c      ;0
  bSectorCountReg.c   ;1 
  bSectorNumberReg.c  ;2
  bCylLowReg.c        ;3
  bCylHighReg.c       ;4
  bDriveHeadReg.c     ;5
  bCommandReg.c       ;6
  bReserved.c         ;7
  DataBufferSize.l    ;8
  DataBuffer.c[1]     ;9, 10
EndStructure

; Structure ATA_PASS_THROUGH Extends IDEREGS
  ; ;IdeReg.IDEREGS
  ; DataBufferSize.l    ;8
  ; DataBuffer.c[1]     ;9
; EndStructure

Procedure setapm(APMValue.l)
  ; \\.\PhysicalDrive0
  hDevice = CreateFile_( "\\.\PhysicalDrive0", #GENERIC_READ | #GENERIC_WRITE, #FILE_SHARE_READ | #FILE_SHARE_WRITE, 0, #OPEN_EXISTING, 0, 0)
  If hDevice = #INVALID_HANDLE_VALUE
    PrintN( "CreateFile failed. hDevice="+Hex(hDevice))
    ProcedureReturn
  Else
    PrintN( "CreateFile success.")
  EndIf
  
  ;Initialize buffers...
  ; INPUT Commandbuffer
  regBuf_IN.IDEREGS
  regBuf_IN\bFeaturesReg	= 0  ;0
  regBuf_IN\bSectorCountReg	= 0  ;1 
  regBuf_IN\bSectorNumberReg	= 0  ;2
  regBuf_IN\bCylLowReg		= 0  ;3
  regBuf_IN\bCylHighReg		= 0  ;4
  regBuf_IN\bDriveHeadReg	= 0  ;5
  regBuf_IN\bCommandReg		= 0  ;6
  regBuf_IN\bReserved		= 0  ; reg[7] is reserved for future use. Must be zero.
  regBuf_IN\DataBufferSize	= 0  ;8
  ; OUTPUT Commandbuffer
  regBuf_OUT.IDEREGS
  regBuf_OUT\bFeaturesReg	= 0  ;0
  regBuf_OUT\bSectorCountReg	= 0  ;1 
  regBuf_OUT\bSectorNumberReg	= 0  ;2
  regBuf_OUT\bCylLowReg		= 0  ;3
  regBuf_OUT\bCylHighReg	= 0  ;4
  regBuf_OUT\bDriveHeadReg	= 0  ;5
  regBuf_OUT\bCommandReg	= 0  ;6
  regBuf_OUT\bReserved		= 0  ; reg[7] is reserved for future use. Must be zero.
  regBuf_OUT\DataBufferSize	= 0  ;8
  
  bSize = SizeOf(regBuf_IN) ; Size of regBuf_IN - 8 for reg, 4 for DataBufferSize, 512 for Data
  
  ; Prepare the ATA Command
  regBuf_IN\bCommandReg  = #WIN_SETFEATURES
  regBuf_IN\bFeaturesReg = #SETFEATURES_EN_APM
  If APMValue<1
    APMValue=1
  EndIf
  If APMValue>254
    APMValue = 255
    regBuf_IN\bFeaturesReg = #SETFEATURES_DIS_APM
    regBuf_IN\bSectorCountReg = 0
    PrintN("Disable APM.")
  Else
    regBuf_IN\bSectorCountReg = APMValue
    PrintN("Setting APM to "+ Str(APMValue)+".")
  EndIf
  
  bytesRet.l = 0
  retval = DeviceIoControl_( hDevice, #IOCTL_IDE_PASS_THROUGH, @regBuf_IN, bSize, @regBuf_OUT, bSize, @bytesRet, #Null) 
  If retval=0
    PrintN( "IOCTL_IDE_PASS_THROUGH failed. Error="+Str(GetLastError_()))
    PrintN("  In : CMD=0x"+ZHex(regBuf_IN\bCommandReg)+" FR=0x"+ZHex(regBuf_IN\bFeaturesReg)+" SC=0x"+ZHex(regBuf_IN\bSectorCountReg)+" SN=0x"+ZHex(regBuf_IN\bSectorNumberReg)+" CL=0x"+ZHex(regBuf_IN\bCylLowReg)+" CH=0x"+ZHex(regBuf_IN\bCylHighReg)+" SEL=0x"+ZHex(regBuf_IN\bDriveHeadReg))
    PrintN(" Out : CMD=0x"+ZHex(regBuf_OUT\bCommandReg)+" FR=0x"+ZHex(regBuf_OUT\bFeaturesReg)+" SC=0x"+ZHex(regBuf_OUT\bSectorCountReg)+" SN=0x"+ZHex(regBuf_OUT\bSectorNumberReg)+" CL=0x"+ZHex(regBuf_OUT\bCylLowReg)+" CH=0x"+ZHex(regBuf_OUT\bCylHighReg)+" SEL=0x"+ZHex(regBuf_OUT\bDriveHeadReg))
    ;DebugReg(regBuf_OUT, regBuf_OUT)
  EndIf
  PrintN( "bytesret: "+Str( bytesRet))
  PrintN("  In : CMD=0x"+ZHex(regBuf_IN\bCommandReg)+" FR=0x"+ZHex(regBuf_IN\bFeaturesReg)+" SC=0x"+ZHex(regBuf_IN\bSectorCountReg)+" SN=0x"+ZHex(regBuf_IN\bSectorNumberReg)+" CL=0x"+ZHex(regBuf_IN\bCylLowReg)+" CH=0x"+ZHex(regBuf_IN\bCylHighReg)+" SEL=0x"+ZHex(regBuf_IN\bDriveHeadReg))
  PrintN(" Out : CMD=0x"+ZHex(regBuf_OUT\bCommandReg)+" FR=0x"+ZHex(regBuf_OUT\bFeaturesReg)+" SC=0x"+ZHex(regBuf_OUT\bSectorCountReg)+" SN=0x"+ZHex(regBuf_OUT\bSectorNumberReg)+" CL=0x"+ZHex(regBuf_OUT\bCylLowReg)+" CH=0x"+ZHex(regBuf_OUT\bCylHighReg)+" SEL=0x"+ZHex(regBuf_OUT\bDriveHeadReg))
  
  If hDevice
    CloseHandle_( hDevice )
  EndIf
EndProcedure

OpenConsole()
Value = Val(ProgramParameter(0))
PrintN("Param: "+Str(Value))

setapm(Value)
 
; jaPBe Version=3.8.9.728
; Build=27
; Language=0x0000 Language Neutral
; FirstLine=12
; CursorPosition=22
; EnableUSER
; ExecutableFormat=Console
; Executable=C:\Dokumente und Einstellungen\injk\Eigene Dateien\PMEvent\setaam.exe
; DontSaveDeclare
; EOF 
; jaPBe Version=3.8.9.728
; Build=50
; Language=0x0000 Language Neutral
; FirstLine=36
; CursorPosition=51
; EnableUSER
; ExecutableFormat=Console
; Executable=C:\Users\Admin\Desktop\PMEvent\setapm.exe
; DontSaveDeclare
; EOF