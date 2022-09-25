#SingleInstance Force

RegHook := InputHook("VI")
; match when pressed
RegHook.KeyOpt("{Space}", "+N")
RegHook.OnKeyDown := RegExHs.KeyDown
RegHook.Start()
RegHook.Hs := RegExHs()

RegExHotstring(Str, Callback) {
	RegHook.Hs.Append(Str " ", Callback)
}

Class RegExHs {
	; stores hotstrings and callbacks
	str_arr := Array()
	call_arr := Array()

	; append new RegExHotstring
	Append(Str, CallBack) {
		this.str_arr.Push(Str)
		this.call_arr.Push(CallBack)
	}

	Len() {
		return this.str_arr.Length
	}

	static KeyDown(vk, sc) {
		; return when triggered by Hotstrings
		if RegExHs.HotstringIsQueued() {
			this.Stop()
			Critical false	; Enable immediate thread interruption.
			Sleep -1	; Process any pending messages.
			this.Start()
			return
		}

		; loop through ench strings and find the first match
		input := this.Input
		this.Stop()
		loop this.Hs.Len() {
			str := this.Hs.str_arr[A_Index]
			call := this.Hs.call_arr[A_Index]
			start := RegExMatch(input, str, &match)
			if (start) {
				Send("{BS " (match.Len[0]) "}")
				if (call is String) {
					; delete matched string
					Send(RegExReplace(SubStr(input, start), str, call))
				} else if (call is Func) {
					call(match)
				} else
					throw Error('callback type error `ncallback should be "Func" or "String"')
				this.Start()
				return
			}
		}
		this.Start()
	}

	; thanks lexikos - https://www.autohotkey.com/boards/viewtopic.php?f=82&t=104538#p464744
	; detect if hotstring is triggered
	static HotstringIsQueued() {
		static AHK_HOTSTRING := 1025
		msg := Buffer(4 * A_PtrSize + 16)
		return DllCall("PeekMessage", "ptr", msg, "ptr", A_ScriptHwnd
			, "uint", AHK_HOTSTRING, "uint", AHK_HOTSTRING, "uint", 0)
	}
}