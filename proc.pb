﻿Procedure ForceGadgetZOrder(gadget)
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    SetWindowLong_(GadgetID(gadget),#GWL_STYLE,GetWindowLong_(GadgetID(gadget),#GWL_STYLE)|#WS_CLIPSIBLINGS)
    SetWindowPos_(GadgetID(gadget),#HWND_TOP,0,0,0,0,#SWP_NOSIZE|#SWP_NOMOVE)
  CompilerEndIf
EndProcedure

Procedure getGamePaths()
  Shared gamePaths.s()
  Protected NewList paths.s()
  CompilerSelect #PB_Compiler_OS
    CompilerCase #PB_OS_Windows
      Protected steamPath.s = ReplaceString(Reg_GetValue("HKEY_CURRENT_USER\Software\Valve\Steam","SteamPath"),"/","\")
      If Len(steamPath)
        AddElement(paths())
        paths() = steamPath + "\steamapps\common\Open Sewer"
        If ReadFile(0,steamPath + "\steamapps\libraryfolders.vdf",#PB_File_SharedRead)
          CreateRegularExpression(0,~"\"[0-9]\"[ \t]*\"([a-zA-Z:\\\\]+)\"",#PB_RegularExpression_AnyNewLine|#PB_RegularExpression_NoCase)
          While Not Eof(0)
            Protected line.s = ReadString(0)
            ;Debug line
            If ExamineRegularExpression(0,line)
              While NextRegularExpressionMatch(0)
                AddElement(paths())
                paths() = RegularExpressionGroup(0,1) + "\steamapps\common\Open Sewer"
              Wend
            EndIf
          Wend
          CloseFile(0)
        EndIf
      EndIf
      AddElement(paths())
      paths() = "C:\games\Open Sewer"
      AddElement(paths())
      paths() = "D:\games\Open Sewer"
      AddElement(paths())
      paths() = "E:\games\Open Sewer"
      AddElement(paths())
      paths() = "Y:\osse\Open Sewer"
    CompilerCase #PB_OS_MacOS
      AddElement(paths())
      paths() = GetEnvironmentVariable("HOME") + "/Library/Application Support/Steam/SteamApps/common/Open Sewer"
    CompilerCase #PB_OS_Linux
      AddElement(paths())
      paths() = GetEnvironmentVariable("HOME") + "/.steam/steam/SteamApps/common/Open Sewer"
      AddElement(paths())
      paths() = GetEnvironmentVariable("HOME") + "/.local/share/Steam/SteamApps/common/Open Sewer"
      AddElement(paths())
      paths() = GetEnvironmentVariable("HOME") + "/Steam/SteamApps/common/Open Sewer"
      AddElement(paths())
      paths() = GetEnvironmentVariable("HOME") + "/.steam/common/Open Sewer"
  CompilerEndSelect
  ForEach paths()
    ;Debug "trying " + paths()
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      If FileSize(paths() + "\Open Sewer.exe") > 0
        AddElement(gamePaths())
        gamePaths() = paths()
      EndIf
    CompilerElse
      If FileSize(paths() + "/Open Sewer") > 0
        AddElement(gamePaths())
        gamePaths() = paths()
      EndIf
    CompilerEndIf
  Next
EndProcedure

Procedure checkSavesPath(path.s)
  Protected saveFound.b
  Shared saveFiles.s()
  If FileSize(path) = -2
    If ExamineDirectory(0,path,"*.sav")
      While NextDirectoryEntry(0)
        If DirectoryEntryType(0) = #PB_DirectoryEntry_File
          ;Debug "found " + DirectoryEntryName(0)
          AddElement(saveFiles())
          CompilerIf #PB_Compiler_OS = #PB_OS_Windows
            saveFiles() = path + "\" + DirectoryEntryName(0)
          CompilerElse
            saveFiles() = path + "/" + DirectoryEntryName(0)
          CompilerEndIf
          saveFound = #True
        EndIf
      Wend
      FinishDirectory(0)
      SortList(saveFiles(),#PB_Sort_Ascending|#PB_Sort_NoCase)
      ForEach(saveFiles())
        If LCase(GetFilePart(saveFiles())) = "slot10_save.sav"
          MoveElement(saveFiles(),#PB_List_Last)
          Break
        EndIf
      Next
      If saveFound : ProcedureReturn #True : EndIf
    EndIf
  EndIf
EndProcedure

Procedure loadLang(code.s)
  Shared strings.lang
  Select code
    Case "en"
      CatchJSON(0,?langEN,?LangEND-?langEN,#PB_JSON_NoCase)
  EndSelect
  If IsJSON(0)
    ExtractJSONStructure(JSONValue(0),@strings.lang,lang)
    FreeJSON(0)
    If strings\langCode = code
      ProcedureReturn #True
    EndIf
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure langPathSelect()
  Shared lang.s
  Shared strings.lang
  Shared savesPath.s
  Shared gamePaths.s()
  Shared savesPaths.s()
  OpenWindow(#wndSelect,#PB_Ignore,#PB_Ignore,400,135,#myName + " [settings]",#PB_Window_Tool|#PB_Window_ScreenCentered)
  StickyWindow(#wndSelect,#True)
  TextGadget(0,10,12,150,20,strings\options("langSelect"),#PB_Text_Right)
  ComboBoxGadget(1,170,10,220,20)
  AddGadgetItem(1,-1,"English")
  ;Select lang
  ;  Default
      lang = "en"
      SetGadgetState(1,0)
  ;EndSelect
  TextGadget(2,10,42,150,20,strings\options("savesPath"),#PB_Text_Right)
  ComboBoxGadget(3,170,40,220,20)
  AddElement(savesPaths())
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    savesPaths() = "/Volumes/Data/work/osse/saves"
  CompilerElse
    savesPaths() = GetEnvironmentVariable("USERPROFILE") + "\AppData\LocalLow\Loiste Interactive\Open Sewer"
  CompilerEndIf
  ForEach savesPaths()
    If LCase(savesPaths()) <> LCase(savesPath)
      AddGadgetItem(3,-1,savesPaths())
    EndIf
  Next
  If Len(savesPath) And FileSize(savesPath) = -2
    AddGadgetItem(3,-1,savesPath)
    SetGadgetState(3,CountGadgetItems(3)-1)
  Else
    If CountGadgetItems(3) > 1
      SetGadgetState(3,-1)
    Else
      SetGadgetState(3,0)
    EndIf
  EndIf
  AddGadgetItem(3,-1,"...")
  ButtonGadget(4,270,100,120,25,strings\options("apply"),#PB_Button_Default)
  Protected ev.i
  CompilerIf #PB_Compiler_OS = #PB_OS_Linux
    SetGadgetFont(0,FontID(#font))
    SetGadgetFont(1,FontID(#font))
    SetGadgetFont(2,FontID(#font))
    SetGadgetFont(3,FontID(#font))
    Protected maxWidth.i = GadgetWidth(1)
    If GadgetWidth(3) > maxWidth
      maxWidth = GadgetWidth(3)
    EndIf
    If maxWidth > 220
      ResizeWindow(#wndSelect,#PB_Ignore,#PB_Ignore,WindowWidth(#wndSelect)+maxWidth-220,#PB_Ignore)
    EndIf
    ResizeGadget(4,WindowWidth(#wndSelect)-GadgetWidth(4)-10,#PB_Ignore,#PB_Ignore,#PB_Ignore)
    ResizeGadget(0,#PB_Ignore,GadgetY(0)+6,#PB_Ignore,#PB_Ignore)
    ResizeGadget(2,#PB_Ignore,GadgetY(2)+6,#PB_Ignore,#PB_Ignore)
  CompilerEndIf
  Repeat
    ev = WaitWindowEvent()
    If ev = #PB_Event_Gadget
      Select EventGadget()
        Case 1
          ;Select GetGadgetText(1)
          ;  Default
              lang = "en"
          ;EndSelect
          loadLang(lang)
          SetGadgetText(0,strings\options("langSelect"))
          SetGadgetText(2,strings\options("savesPath"))
          SetGadgetText(4,strings\options("apply"))
        Case 4
          ;Select GetGadgetText(1)
          ;  Default
              lang = "en"
          ;EndSelect
          savesPath = GetGadgetText(3)
          Break
        Case 3
          If EventType() = #PB_EventType_Change And GetGadgetState(3) = CountGadgetItems(3)-1
            SetActiveGadget(2)
            savesPath = PathRequester(strings\options("savesPath"),GetGadgetText(3))
            If Len(savesPath)
              AddGadgetItem(3,0,savesPath)
            EndIf
            If CountGadgetItems(3) = 1
              SetGadgetState(3,-1)
            Else
              SetGadgetState(3,0)
            EndIf
          EndIf
      EndSelect
    EndIf
  Until ev = #PB_Event_CloseWindow
  CompilerIf #PB_Compiler_OS = #PB_OS_Linux
    ;gtk_window_close(WindowID(#wndSelect))
    ;CloseWindow(#wndSelect)
    gtk_widget_destroy(WindowID(#wndSelect))
  CompilerElse
    CloseWindow(#wndSelect)
  CompilerEndIf
EndProcedure

Procedure message(message.s,type.b = #mInfo)
  Protected wndID.i
  If IsWindow(#wnd) : wndID = WindowID(#wnd) : EndIf
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    Select type
      Case #mError
        MessageBox_(wndID,message,"PERKELE!",#MB_OK|#MB_ICONERROR)
      Case #mQuestion
        If MessageBox_(wndID,message,#myNameShort,#MB_YESNO|#MB_ICONQUESTION) = #IDYES
          ProcedureReturn #True
        Else
          ProcedureReturn #False
        EndIf
      Default
        MessageBox_(wndID,message,#myNameShort,#MB_OK|#MB_ICONINFORMATION)
    EndSelect
  CompilerElse
    Select type
      Case #mQuestion
        If MessageRequester(#myNameShort,message,#PB_MessageRequester_YesNo) = #PB_MessageRequester_Yes
          ProcedureReturn #True
        Else
          ProcedureReturn #False
        EndIf
      Case #mError
        MessageRequester("PERKELE!",message)
      Default
        MessageRequester(#myNameShort,message)
    EndSelect
  CompilerEndIf
  ProcedureReturn #True
EndProcedure

Procedure loadSave(path.s)
  Shared values.value()
  Shared strings.lang
  If FileSize(path) < 1
    ProcedureReturn #False
  EndIf
  If Not OpenFile(0,path,#PB_File_SharedRead)
    ProcedureReturn #False
  EndIf
  ;Debug "loading " + path
  ;While Not Eof(0)
  Protected line.s = ReadString(0,#PB_Unicode|#PB_File_IgnoreEOL)
  ;Debug line
  ;line = Trim(line)
  ForEach values()
    If CreateRegularExpression(0,values()\pcre,#PB_RegularExpression_AnyNewLine|#PB_RegularExpression_NoCase)
      ;Debug "searching " + values()\pcre
      If ExamineRegularExpression(0,line)
        While NextRegularExpressionMatch(0)
          ;Debug "found"
          values()\value = RegularExpressionGroup(0,1)
        Wend
      EndIf
      FreeRegularExpression(0)
    EndIf
  Next
  ;Wend
  CloseFile(0)
  line = ""
  Protected missingValues.i = 0
  ForEach values()
    If Not Len(values()\value)
      Debug "missing " + values()\pcre
      missingValues + 1
    EndIf
  Next
  If missingValues
    message(strings\messages("missingValues"),#mError)
  EndIf
  ProcedureReturn #True
EndProcedure

Procedure saveSave(path.s) ; no pun intended
  Shared values.value()
  ;Protected NewList lines.s()
  If FileSize(path) < 1
    ProcedureReturn #False
  EndIf
  If Not OpenFile(0,path,#PB_File_SharedRead)
    ProcedureReturn #False
  EndIf
  ;While Not Eof(0)
    ;AddElement(lines())
    Protected line.s = ReadString(0,#PB_Unicode|#PB_File_IgnoreEOL)
    ;Protected lineTrimmed.s = Trim(line)
    ;lines() = line
    ;If Left(lineTrimmed,2) <> "--"
      ForEach values()
        If CreateRegularExpression(0,values()\pcre,#PB_RegularExpression_AnyNewLine|#PB_RegularExpression_NoCase)
          If ExamineRegularExpression(0,line)
            While NextRegularExpressionMatch(0)
              Protected newLine.s = Left(line,RegularExpressionGroupPosition(0,1)-1) + values()\value + Right(line,Len(line) - RegularExpressionGroupPosition(0,1) - RegularExpressionGroupLength(0,1) + 1)
              If line <> newLine
                line = newLine
              EndIf
            Wend
          EndIf
          FreeRegularExpression(0)
        EndIf
      Next
    ;EndIf
  ;Wend
  CloseFile(0)
  If Not CreateFile(0,path,#PB_File_SharedWrite)
    ProcedureReturn #False
  EndIf
  WriteString(0,line,#PB_Unicode)
  CloseFile(0)
  ProcedureReturn #True
EndProcedure

Procedure updateInternal()
  Shared values.value()
  values("name")\value = GetGadgetText(#name)
  values("surname")\value = GetGadgetText(#surname)
  values("OC")\value = Str(GetGadgetState(#oc))
  values("RM")\value = Str(GetGadgetState(#rm))
  values("location")\value = GetGadgetText(#location)
EndProcedure

Procedure updateUI()
  Shared values.value()
  SetGadgetText(#name,values("name")\value)
  SetGadgetText(#surname,values("surname")\value)
  SetGadgetState(#oc,Val(values("OC")\value))
  SetGadgetState(#rm,Val(values("RM")\value))
  SetGadgetText(#location,values("location")\value)
  
  ; sending events to update captions
  Protected i
  For i = #controlsBegin To #controlsEnd
    PostEvent(#PB_Event_Gadget,#wnd,i,0,1)
  Next
EndProcedure

Procedure revertSave()

EndProcedure
; IDE Options = PureBasic 5.62 (Windows - x86)
; CursorPosition = 337
; FirstLine = 320
; Folding = ----
; EnableXP