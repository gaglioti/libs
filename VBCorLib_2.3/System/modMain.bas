Attribute VB_Name = "modMain"
'    CopyRight (c) 2004 Kelly Ethridge
'
'    This file is part of VBCorLib.
'
'    VBCorLib is free software; you can redistribute it and/or modify
'    it under the terms of the GNU Library General Public License as published by
'    the Free Software Foundation; either version 2.1 of the License, or
'    (at your option) any later version.
'
'    VBCorLib is distributed in the hope that it will be useful,
'    but WITHOUT ANY WARRANTY; without even the implied warranty of
'    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
'    GNU Library General Public License for more details.
'
'    You should have received a copy of the GNU Library General Public License
'    along with Foobar; if not, write to the Free Software
'    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
'
'    Module: modMain
'
Option Explicit

Public InIDE        As Boolean
Public InDebugger   As Boolean


Private Sub Main()
    Debug.Assert SetInIDE
    
    Call SetInDebugger
    Call InitWin32Api
    Call InitHelper
    Call InitPublicFunctions
    Call InitcDateTimeHelpers
    Call InitEncodingHelpers
End Sub

Private Sub SetInDebugger()
    Dim result As String
    result = String$(1024, 0)
    
    Call GetModuleFileName(vbNullPtr, result, Len(result))
    
    Dim i As Long
    i = InStr(result, vbNullChar)
    
    result = Left$(result, i - 1)
    
    InDebugger = (UCase$(Right$(result, 8)) = "\VB6.EXE")
End Sub

Private Function SetInIDE() As Boolean
    InIDE = True
    SetInIDE = True
End Function
