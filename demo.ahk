#Requires AutoHotkey v2.0
#Include RegExHotstring.ahk
#SingleInstance Force

; the upmost function will be triggered first

; replace with regex string
RegExHotstring("(\w+)a", "b$1", "C")
RegExHotstring("(\w)a(\w)", "$2a$1", "*")
RegExHotstring("(\d+)(\w+)", "$2$1", "OB0")
RegExHotstring("a(\w)c", (match) => MsgBox("you just typed a" match[1] "c!"), "*?B0")

; use anonymous function
RegExHotstring("(\w+)b", (match) => MsgBox("matched: " match[1]))

; modify callback and options
^!a:: RegExHotstring("(\w+)a", (match) => MsgBox("matched: " match[1]), "*")

; call with function name
RegExHotstring("(\w*)c", call)
RegExHotstring("r(\d+)", rand)

; receives RegExMatchInfo
call(match) {
	MsgBox("matched: " match[1])
}

rand(match) {
	char := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	loop match[1] {
		r := Random(1, StrLen(char))
		str .= SubStr(char, r, 1)
	}
	Send(str)
}