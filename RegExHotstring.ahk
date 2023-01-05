#Requires AutoHotkey v2.0

RegHook := RegExHs("VI")
RegHook.NotifyNonText := true
RegHook.KeyOpt("{Space}{Tab}{Enter}", "+SN")
; RegHook.KeyOpt("{BS}", "-N")
RegHook.Start()

/**
 * Create a RegEx Hotstring or replace already existing one
 * @param {String} Str RegEx string
 * @param {Func or String} CallBack calls function with RegEx match info or replace string
 */
RegExHotstring(Str, CallBack) {
	RegHook.Append(Str, CallBack)
}

Class RegExHs extends InputHook {
	; stores hotstrings and CallBacks
	Hs := Map()

	; append new RegExHotstring
	Append(Str, CallBack) {
		this.Hs[Str "$"] := CallBack
	}

	OnKeyDown := this.KeyDown
	KeyDown(vk, sc) {
		if (vk = 8)
			return

		if (vk != 32 && vk != 9 && vk != 13) {
			this.Stop()
			this.Start()
			return
		}

		; find the last pattern without \s
		if (!RegExMatch(this.Input, "(\S+)(?![\s\S]*(\S+))", &match)) {
			this.Stop()
			Send("{Blind}{vk" Format("{:02x}", vk) " down}")
			this.Start()
			return
		}
		input := match[1]
		this.Stop()
		; loop through each strings and find the first match
		for str, call in this.Hs {
			start := RegExMatch(input, str, &match)
			if (start) {
				; delete matched string
				Send("{BS " match.Len[0] "}")
				if (call is String) {
					Send(RegExReplace(SubStr(input, start), str, call))
				} else if (call is Func) {
					call(match)
				} else
					throw Error('CallBack type error `nCallBack should be "Func" or "String"')
				this.Start()
				return
			}
		}
		Send("{Blind}{vk" Format("{:02x}", vk) " down}")
		this.Start()
	}

	OnKeyUp := this.KeyUp
	KeyUp(vk, sc) {
		if (vk = 8)
			return
		if (vk = 32 || vk = 9 || vk = 13)
			Send("{Blind}{vk" Format("{:02x}", vk) " up}")
	}
}