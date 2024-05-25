#SingleInstance Force
#Include ../RegExHotstring.ahk

::btw::by the way

RegHook.MinSendLevel := 2
SendLevel(1)
RegExHotstring("b([Tt])([Ww])", "by $1he $2ay", "C")