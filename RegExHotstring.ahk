#Requires AutoHotkey v2.0

RegHook := RegExHs("VI")
; match when pressed
RegHook.KeyOpt("{Space}", "+N")
RegHook.NotifyNonText := true
RegHook.Start()

RegExHotstring(Str, Callback) {
	RegHook.Append(Str, Callback)
}

Class RegExHs extends InputHook {
	; stores hotstrings and callbacks
	str_arr := Array()
	call_arr := Array()

	; append new RegExHotstring
	Append(Str, CallBack) {
		this.str_arr.Push(Str "$")
		this.call_arr.Push(CallBack)
	}

	Len() {
		return this.str_arr.Length
	}

	OnKeyDown := this.KeyDown
	KeyDown(vk, sc) {
		if (vk != 32) {
			this.Stop()
			this.Start()
			return
		}

		; find the last pattern without \s
		if (!RegExMatch(this.Input, "(\S+)(?![\s\S]*(\S+))", &match)) {
			this.Stop()
			this.Start()
			return
		}
		input := match[1]
		this.Stop()
		; loop through each strings and find the first match
		loop this.Len() {
			str := this.str_arr[A_Index]
			call := this.call_arr[A_Index]
			start := RegExMatch(input, str, &match)
			if (start) {
				Send("{BS " (match.Len[0] + 1) "}")
				if (call is String) {
					; delete matched string
					Send(RegExReplace(SubStr(input, start), str, call))
				} else if (call is Func) {
					call(match)
				} else
					throw Error('callback type error `nCallBack should be "Func" or "String"')
				this.Start()
				return
			}
		}
		this.Start()
	}
}