#SingleInstance force
;#Include OCR.ahk
#Include captureScreen.ahk

Gui, add, Text, x5 y15 w100 h42, 프리셋 사용 = F1
Gui, add, Text, x5 y35 w95 h20, 프리셋 저장 = F2

Gui, add, Text, x200 y15 w80 h20, 수동 좌표 입력
Gui, add, Text, x200 y33 w80 h20, 좌측 상단 = F5
Gui, add, Text, x200 y46 w80 h20, 우측 하단 = F6


Gui, add, Text, x5 y100 w100 h20, 작동 시작 = F3
Gui, add, Text, x5 y60 w100 h20, 작동 속도 :
Gui, add, Edit, x80 y58 w30 h20 vwanna_speed, 100


Gui, add, Button, x225 y110 w50 h20 gEnd, 종료
Gui, add, Text, x200 y80 w75 h20, 일시정지 = F4
Gui, add, Text, x5 y120 w120 h15, 작업 완료 사운드 사용     
GUI, add, Checkbox, x5 y135 w10 h20 vsound1,
Gui, add, Button, x25 y132 w100 h20 gDir, 파일위치
Gui, add, Text, x205 y135 w70 h20, made by JHS
Gui, show

IniRead, soundDir, preset.ini, preset, soundDir
return

GuiClose:
 ExitApp


f1:: ; 프리셋 사용.
IniRead, luX, preset.ini, preset, luX
IniRead, luY, preset.ini, preset, luY
IniRead, rdX, preset.ini, preset, rdX
IniRead, rdY, preset.ini, preset, rdY

if ((luX = "ERROR")
    |(luY = "ERROR")
    |(rdX = "ERROR")
    |(rdY = "ERROR")) {
 MsgBox, 프리셋 파일 및 내용이 부적합합니다. 새로 좌표를 서칭해주세요.
}
else {
 MsgBox, 프리셋 읽기 성공
}

return


f2::

 if ((luX = "")
    |(luY = "")
    |(rdX = "")
    |(rdY = "")) {
 MsgBox, 좌표 지정을 전부 하지 않았습니다.
}
else {
 MsgBox, 프리셋 저장 성공
}

 IniWrite, %luX%, preset.ini, preset, luX
 IniWrite, %luY%, preset.ini, preset, luY
 IniWrite, %rdX%, preset.ini, preset, rdX
 IniWrite, %rdY%, preset.ini, preset, rdY

return

f3:: ; 시작

Gui, Submit, NoHide
CoordMode, Pixel, Screen

if (wanna_speed > 10000)
 wanna_speed:=100

FileCreateDir, %A_ScriptDir%\captured\

sFileTo=%A_ScriptDir%\captured\tmp.png
CaptureScreen(luX "," luY "," rdX "," rdY , 0, sFileTo, "100") 

cnt_num = 0
Sleep 100
while(1)
    {
        ImageSearch,vx,vy, luX-10, luY-5, rdX+10, rdY+10, *100 %sFileTo%
        ;ImageSearch,vx,vy, 0, 0, 500, 500, *100 %sFileTo%
        IF ErrorLevel = 1 ; 찾으면 0, 못찾으면 1.
        {
          ;MsgBox % cnt_num
          break
        }
        ;sFileTo=%A_ScriptDir%\captured\tmp2.png
        ;CaptureScreen(luX "," luY "," rdX "," rdY , 0, sFileTo, "100") 
        
        sleep wanna_speed
        Sleep 100
        ;cnt_num++
        ;MsgBox % cnt_num
    }

lux_c := luX + 10
luy_c := luY + 10

sFileTo=%A_ScriptDir%\captured\tmp2.png
CaptureScreen(luX "," luY "," rdX "," rdY , 0, sFileTo, "100") 

CoordMode, Mouse, Screen
MouseClick, Left, %luX%, %luY%, 5

if (sound1) {
 ;MsgBox %soundDir%
 SoundPlay, %soundDir%
}

else
 SoundBeep, 2000, 1000

return

f4::Pause

return

f5::
CoordMode, Mouse, Screen
MouseGetPos, luX, luY
;MsgBox %luX%, %luY%
;luX:=luX - 10
;luY:=luY - 10
return

f6::
CoordMode, Mouse, Screen
MouseGetPos, rdX, rdY
;rdY:=rdY - 10
;rdX:=rdX - 10
return

Shift::
 ExitApp
  
Dir:
 fileselectfile, soundDir
 IniWrite, %soundDir%, preset.ini, preset, soundDir
 
 return
End:
 ExitApp