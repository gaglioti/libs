VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CryptoHelper"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'    CopyRight (c) 2006 Kelly Ethridge
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
'    Module: CryptoHelper
'

''
' Provides some helper routines.
'
Option Explicit

Private mRNG As New RNGCryptoServiceProvider


''
' Returns an array of random bytes.
'
' @remarks Zeros may be included.
'
Friend Function GetRandomBytes(ByVal Size As Long) As Byte()
    Dim Ret() As Byte
    ReDim Ret(0 To Size - 1)
    Call FillRandomBytes(Ret)
    GetRandomBytes = Ret
End Function

''
' Returns an array of random bytes not containing zeros.
'
Friend Function GetNonZeroRandomBytes(ByVal Size As Long) As Byte()
    Dim Ret() As Byte
    ReDim Ret(0 To Size - 1)
    Call mRNG.GetNonZeroBytes(Ret)
    GetNonZeroRandomBytes = Ret
End Function

''
' Fill an array of bytes with random values.
' This method fills an already allocated array. A new array is not created.
'
' @remarks Zeros may be included.
'
Friend Sub FillRandomBytes(ByRef RgbKey() As Byte)
    Call mRNG.GetBytes(RgbKey)
End Sub

''
' Fills the end of an array in with padded bytes, returning how many bytes were actually padded.
' The array must already be allocated to receive the padded byte values. The array is not resize locally.
'
Friend Function PadBlock(ByRef Bytes() As Byte, ByVal Index As Long, ByVal Padding As PaddingMode, ByVal PadLength As Long, ByVal OutputBlockSize As Long) As Long
    Dim i As Long

    Select Case Padding
        ' In this mode we fill in the padding bytes with the
        ' value equal to the number of padding bytes to fill.
        ' If there are 5 bytes of padding, then all 5 bytes
        ' are set to the value of 5.
        '
        ' FFFFFFFFFFF => FFFFFFFFFFF55555
        '
        Case PaddingMode.PKCS7
            For i = 0 To PadLength - 1
                Bytes(Index + i) = PadLength
            Next i

        ' In this mode we fill in all padding bytes except the
        ' last byte with the value of zero. The last padding
        ' byte is set the value equal to the number of padding bytes.
        ' 5 bytes of padding will be set to 4 zero filled bytes
        ' and 1 byte set to the value 5.
        '
        ' FFFFFFFFFFF => FFFFFFFFFFF00005
        '
        Case PaddingMode.ANSIX923
            For i = 0 To PadLength - 2
                Bytes(Index + i) = 0
            Next i
            Bytes(Index + PadLength - 1) = PadLength

        ' This mode fills all the padding bytes except the last byte
        ' with random values. The last byte is then set equal to the
        ' value of the number of padding bytes.
        '
        ' FFFFFFFFFFF => FFFFFFFFFFF1A8B5   ' not necessarily the same random bytes.
        '
        Case PaddingMode.ISO10126
            Dim RandomBytes() As Byte
            RandomBytes = CryptoHelper.GetRandomBytes(OutputBlockSize)

            For i = 0 To PadLength - 2
                Bytes(Index + i) = RandomBytes(i)
            Next i
            Bytes(Index + PadLength - 1) = PadLength

        ' This mode will fill in any padding bytes with zeros. Generally the
        ' block to be padded will need to be a partial block. A complete block
        ' won't have padding added.
        '
        ' FFFFFFFFF => FFFFFFFFF0000000
        ' FFFFFFFF => FFFFFFFF
        '
        Case PaddingMode.Zeros
            If PadLength = OutputBlockSize Then
                PadBlock = OutputBlockSize
                Exit Function
            End If

            For i = 0 To PadLength - 1
                Bytes(Index + i) = 0
            Next i

        ' No padding is provided
        Case PaddingMode.None
            PadBlock = OutputBlockSize

    End Select
End Function

''
' Removes the padding from the plain text and returns how many bytes of padding was removed.
'
Friend Function DepadBlock(ByRef Data() As Byte, ByVal Padding As PaddingMode, ByVal InputBlockSize As Long) As Long
    ' With no padding there is nothing to remove, so return 0.
    ' With Zero as padding, it is up to the client to remove them since
    ' we can't tell when the padding ends. So don't remove them either.
    If (Padding = PaddingMode.None) Or (Padding = PaddingMode.Zeros) Then
        DepadBlock = 0
        Exit Function
    End If

    Dim ub As Long
    ub = UBound(Data)

    ' The last byte holds the number of padding bytes there are.
    Dim PadLength As Long
    PadLength = Data(ub)

    ' Padding can't be longer than a single block in length,
    ' since that would make no sense.
    If PadLength > InputBlockSize Then _
        Throw Cor.NewCryptographicException("Invalid padding.")

    ' Since padding type ISO10126 is a random values for the padding,
    ' there is no wrong padding value for each byte of padding, so
    ' there is nothing to check. Just return the padding length removed.
    If Padding = PaddingMode.ISO10126 Then
        DepadBlock = PadLength
        Exit Function
    End If

    ' The remaining padding types have a specific pattern to be followed, so
    ' we define a byte value that is expected for each byte of padding, excluding the last.
    Dim ReqByteValue As Long

    ' This kind of padding means all padding bytes must contain the number of padding bytes.
    ' Otherwise, the remaining padding bytes must have a value of zero.
    If Padding = PaddingMode.PKCS7 Then ReqByteValue = PadLength

    ' Make sure the padding bytes (except the last) is of the specified value.
    Dim i As Long
    For i = ub - PadLength + 1 To ub - 1
        If Data(i) <> ReqByteValue Then Throw Cor.NewCryptographicException("Invalid padding.")
    Next i

    ' Return how many padding bytes there were.
    DepadBlock = PadLength
End Function



