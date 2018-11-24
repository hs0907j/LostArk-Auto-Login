
CaptureScreen(aRect = 0, bCursor = False, sFile = "", nQuality = "")
{
 If !aRect
 {
  SysGet, nL, 76
  SysGet, nT, 77
  SysGet, nW, 78
  SysGet, nH, 79
 }
 Else If aRect = 1
  WinGetPos, nL, nT, nW, nH, A
 Else If aRect = 2
 {
  WinGet, hWnd, ID, A
  VarSetCapacity(rt, 16, 0)
  DllCall("GetClientRect" , UPTR,hWnd, UPTR,&rt)
  DllCall("ClientToScreen", UPTR,hWnd, UPTR,&rt)
  nL := NumGet(rt, 0, "int")
  nT := NumGet(rt, 4, "int")
  nW := NumGet(rt, 8)
  nH := NumGet(rt,12)
 }
 Else If aRect = 3
 {
  VarSetCapacity(mi, 40, 0)
  DllCall("GetCursorPos", "int64P", pt)
  DllCall("GetMonitorInfo", UPTR,DllCall("MonitorFromPoint", "int64", pt, "Uint", 2), UPTR,NumPut(40,mi)-4)
  nL := NumGet(mi, 4, "int")
  nT := NumGet(mi, 8, "int")
  nW := NumGet(mi,12, "int") - nL
  nH := NumGet(mi,16, "int") - nT
 }
 Else
 {
  StringSplit, rt, aRect, `,, %A_Space%%A_Tab%
  nL := rt1
  nT := rt2
  nW := rt3 - rt1
  nH := rt4 - rt2
  znW := rt5
  znH := rt6
 }
 
 mDC := DllCall("CreateCompatibleDC", UPTR,0)
 hBM := CreateDIBSection(mDC, nW, nH)
 oBM := DllCall("SelectObject", UPTR,mDC, UPTR,hBM)
 hDC := DllCall("GetDC", UPTR,0)
 DllCall("BitBlt", UPTR,mDC, "int",0, "int",0, "int",nW, "int",nH, UPTR,hDC, "int",nL, "int",nT, "Uint",0x40000000|0x00CC0020)
 DllCall("ReleaseDC", "Uint", 0, UPTR,hDC)
 If bCursor
  CaptureCursor(mDC, nL, nT)
 DllCall("SelectObject", UPTR,mDC, UPTR,oBM)
 DllCall("DeleteDC", UPTR,mDC)
 If znW && znH
  hBM := Zoomer(hBM, nW, nH, znW, znH)
 If sFile = 0
  SetClipboardData(hBM)
 Else Convert(hBM, sFile, nQuality), DllCall("DeleteObject", UPTR,hBM)
}
 
CaptureCursor(hDC, nL, nT)
{
 VarSetCapacity(CURSORINFO, sizeof:=A_PtrSize=8? 24:20, 0)
 NumPut(sizeof, CURSORINFO, 0, "UInt") ;cbSize
 DllCall("GetCursorInfo", UPTR,&CURSORINFO)
 bShow   := NumGet(CURSORINFO, 4, "UInt") ;flags
 hCursor := NumGet(CURSORINFO, 8, "UPtr") ;hCursor
 xCursor := NumGet(CURSORINFO, A_PtrSize=8? 16:12, "Int") ;ptScreenPos.x
 yCursor := NumGet(CURSORINFO, A_PtrSize=8? 20:16, "Int") ;ptScreenPos.y
 
 VarSetCapacity(ICONINFO, A_PtrSize=8? 32:20, 0)
 DllCall("GetIconInfo", UPTR,hCursor, UPTR,&ICONINFO)
 xHotspot := NumGet(ICONINFO, 4, "UInt") ;xHotspot
 yHotspot := NumGet(ICONINFO, 8, "UInt") ;yHotspot
 hbmMask := NumGet(ICONINFO, A_PtrSize=8? 16:12, "UPtr") ;hbmMask
 hbmColor := NumGet(ICONINFO, A_PtrSize=8? 24:16, "UPtr") ;hbmColor
 
 If bShow
  DllCall("DrawIcon", UPTR,hDC, "int",xCursor - xHotspot - nL, "int",yCursor - yHotspot - nT, UPTR,hCursor)
 If hBMMask
  DllCall("DeleteObject", UPTR,hBMMask)
 If hBMColor
  DllCall("DeleteObject", UPTR,hBMColor)
}
 
Zoomer(hBM, nW, nH, znW, znH)
{
 mDC1 := DllCall("CreateCompatibleDC", UPTR,0)
 mDC2 := DllCall("CreateCompatibleDC", UPTR,0)
 zhBM := CreateDIBSection(mDC2, znW, znH)
 oBM1 := DllCall("SelectObject", UPTR,mDC1, UPTR,hBM)
 oBM2 := DllCall("SelectObject", UPTR,mDC2, UPTR,zhBM)
 DllCall("SetStretchBltMode", UPTR,mDC2, "int", 4)
 DllCall("StretchBlt", UPTR,mDC2, "int",0, "int",0, "int",znW, "int",znH, UPTR,mDC1, "int",0, "int",0, "int",nW, "int",nH, "Uint",0x00CC0020)
 DllCall("SelectObject", UPTR,mDC1, UPTR,oBM1)
 DllCall("SelectObject", UPTR,mDC2, UPTR,oBM2)
 DllCall("DeleteDC", UPTR,mDC1)
 DllCall("DeleteDC", UPTR,mDC2)
 DllCall("DeleteObject", UPTR,hBM)
 Return zhBM
}
 
Convert(sFileFr = "", sFileTo = "", nQuality = "")
{
 If sFileTo  =
  sFileTo := A_scriptDir . "screen.bmp"
 SplitPath, sFileTo, , sDirTo, sExtTo, sNameTo
 
 If Not hGdiPlus := DllCall("LoadLibrary", "str", "gdiplus.dll")
  Return sFileFr+0 ? SaveHBITMAPToFile(sFileFr, sDirTo . "" . sNameTo . ".bmp") : ""
 VarSetCapacity(si, A_PtrSize=8? 24:16, 0), si := Chr(1)
 DllCall("gdiplus\GdiplusStartup", "UintP",pToken, UPTR,&si, "Uint", 0)
 If !sFileFr
 {
  DllCall("OpenClipboard", "Uint", 0)
  If  DllCall("IsClipboardFormatAvailable", "Uint", 2) && (hBM:=DllCall("GetClipboardData", "Uint", 2))
  DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", UPTR,hBM, "Uint",0, "UintP",pImage)
  DllCall("CloseClipboard")
 }
 Else If sFileFr Is Integer
  DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "UPTR",sFileFr, "Uint",0, "UintP",pImage)
 Else
 {
  str := sFileFr
  if !A_IsUnicode
   VarSetCapacity(sFileTo, StrPut(str, "UTF-16")*2), StrPut(str, &sFileFr, "UTF-16")
  DllCall("gdiplus\GdipLoadImageFromFile", UPTR,&sFileFr, "UintP",pImage)
 }
 
 DllCall("gdiplus\GdipGetImageEncodersSize", "UintP",nCount, "UintP",nSize)
 VarSetCapacity(ci,nSize,0)
 DllCall("gdiplus\GdipGetImageEncoders", "Uint",nCount, "Uint",nSize, UPTR,&ci)
 ci_part_size := A_PtrSize=8? 104:76
 ext_offset := A_PtrSize=8? 56:44 ;FilenameExtension offset
 Loop, % nCount
 {
  if InStr(StrGet(NumGet(ci,ci_part_size*(A_Index-1)+ext_offset,"UPTR"), "UTF-16"), "." . sExtTo)
  {
   pCodec := &ci+ci_part_size*(A_Index-1)
   Break
  }
 }
 If InStr(".JPG.JPEG.JPE.JFIF", "." . sExtTo) && nQuality<>"" && pImage && pCodec
 {
  DllCall("gdiplus\GdipGetEncoderParameterListSize", UPTR,pImage, UPTR,pCodec, "UintP",nSize)
  VarSetCapacity(pi,nSize,0)
  DllCall("gdiplus\GdipGetEncoderParameterList", UPTR,pImage, UPTR,pCodec, "Uint",nSize, UPTR,&pi)
  pi_part_size := A_PtrSize=8? 32:28
  Loop, % NumGet(pi,0,"Uint")
  {
   If NumGet(pi,pi_part_size*(A_Index-1)+A_PtrSize+16,"UInt")=1 && NumGet(pi,pi_part_size*(A_Index-1)+A_PtrSize+20,"UInt")=6
   {
    pParam := &pi+pi_part_size*(A_Index-1)
    NumPut(nQuality,NumGet(NumPut(4,NumPut(1,pParam+0,"Uint")+A_PtrSize+16,"Uint"),"UPTR"),"Uint")
    Break
   }
  }
 }
 If pImage
 {
  str := sFileTo
  if !A_IsUnicode
   VarSetCapacity(sFileTo, StrPut(str, "UTF-16")*2), StrPut(str, &sFileTo, "UTF-16")
  if pCodec
   DllCall("gdiplus\GdipSaveImageToFile", UPTR,pImage, UPTR,&sFileTo, UPTR,pCodec, UPTR,pParam)
  else
   DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", UPTR,pImage, "UintP",hBitmap, "Uint",0) . SetClipboardData(hBitmap), DllCall("gdiplus\GdipDisposeImage", UPTR,pImage)
 }
 DllCall("gdiplus\GdiplusShutdown", UPTR,pToken)
 DllCall("FreeLibrary", UPTR,hGdiPlus)
}
 
CreateDIBSection(hDC, nW, nH, bpp = 32, ByRef pBits = "")
{
 VarSetCapacity(BITMAPINFO, 44, 0)
 NumPut(44, BITMAPINFO, 0,"UInt")
 NumPut(nW, BITMAPINFO, 4,"Int")
 NumPut(nH, BITMAPINFO, 8,"Int")
 NumPut(1, BITMAPINFO, 12,"UShort")
 NumPut(bpp, BITMAPINFO, 14,"UShort")
 Return DllCall("gdi32\CreateDIBSection", "UPTR", hDC, "UPTR", &BITMAPINFO, "Uint", 0, "UPTR", pBits, "Uint", 0, "Uint", 0)
}
SaveHBITMAPToFile(hBitmap, sFile)
{
 VarSetCapacity(DIBSECTION, A_PtrSize=8? 104:84, 0)
 NumPut(40, DIBSECTION, A_PtrSize=8? 32:24,"UInt") ;dsBmih.biSize
 DllCall("GetObject", "UPTR", hBitmap, "int", A_PtrSize=8? 104:84, "UPTR", &DIBSECTION)
 hFile:= DllCall("CreateFile", "UPTR", &sFile, "Uint", 0x40000000, "Uint", 0, "Uint", 0, "Uint", 2, "Uint", 0, "Uint", 0)
 DllCall("WriteFile", "UPTR", hFile, "int64P", 0x4D42|14+40+(biSizeImage:=NumGet(DIBSECTION, A_PtrSize=8? 52:44, "UInt"))<<16, "Uint", 6, "UintP", 0, "Uint", 0)
 DllCall("WriteFile", "UPTR", hFile, "int64P", 54<<32, "Uint", 8, "UintP", 0, "Uint", 0)
 DllCall("WriteFile", "UPTR", hFile, "UPTR", &DIBSECTION + (A_PtrSize=8? 32:24), "Uint", 40, "UintP", 0, "Uint", 0)
 DllCall("WriteFile", "UPTR", hFile, "Uint", NumGet(DIBSECTION, A_PtrSize=8? 24:20, "UPtr"), "Uint", biSizeImage, "UintP", 0, "Uint", 0)
 DllCall("CloseHandle", "UPTR", hFile)
}
 
SetClipboardData(hBitmap)
{
 VarSetCapacity(DIBSECTION, A_PtrSize=8? 104:84, 0)
 NumPut(40, DIBSECTION, A_PtrSize=8? 32:24,"UInt") ;dsBmih.biSize
 DllCall("GetObject", "UPTR", hBitmap, "int", A_PtrSize=8? 104:84, "UPTR", &DIBSECTION)
 biSizeImage := NumGet(DIBSECTION, A_PtrSize=8? 52:44, "UInt")
 hDIB := DllCall("GlobalAlloc", "Uint", 2, "Uint", 40+biSizeImage)
 pDIB := DllCall("GlobalLock", "UPTR", hDIB)
 DllCall("RtlMoveMemory", "UPTR", pDIB, "UPTR", &DIBSECTION + (A_PtrSize=8? 32:24), "Uint", 40)
 DllCall("RtlMoveMemory", "UPTR", pDIB+40, "Uint", NumGet(DIBSECTION, A_PtrSize=8? 24:20, "UPtr"), "Uint", biSizeImage)
 DllCall("GlobalUnlock", "UPTR", hDIB)
 DllCall("DeleteObject", "UPTR", hBitmap)
 DllCall("OpenClipboard", "Uint", 0)
 DllCall("EmptyClipboard")
 DllCall("SetClipboardData", "Uint", 8, "UPTR", hDIB)
 DllCall("CloseClipboard")
}