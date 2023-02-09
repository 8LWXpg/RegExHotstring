#Requires AutoHotkey v2.0

RegHook := RegExHs("VI")
RegHook.NotifyNonText := true
RegHook.KeyOpt("{Space}{Tab}{Enter}", "+SN")
RegHook.Start()

/**
 * Create a RegEx Hotstring or replace already existing one
 * @param {String} Str RegEx string
 * @param {Func or String} CallBack calls function with RegEx match info or replace string
 * @param {String} Options
 *
 * ? (question mark): The hotstring will be triggered even when it is inside another word;
 * that is, when the character typed immediately before it is alphanumeric.
 * Use ?0 to turn this option back off.
 *
 * B0 (B followed by a zero): Automatic backspacing is not done to erase the abbreviation you type.
 * Use a plain B to turn backspacing back on after it was previously turned off.
 *
 * C: Case sensitive: When you type an abbreviation, it must exactly match the case defined in the script.
 * Use C0 to turn case sensitivity back off.
 *
 * O: Omit the ending character of auto-replace hotstrings when the replacement is produced.
 * Use O0 (the letter O followed by a zero) to turn this option back off.
 */
RegExHotstring(Str, CallBack, Options := "") {
	RegHook.Add(Str, CallBack, Options)
}

class RegExHs extends InputHook {
	; stores with RegEx string as key and obj as value
	hs := Map()

	class obj {
		__New(string, call, options) {
			this.call := call
			this.str := string
			this.opt := Map("?", false, "B", true, "C", false, "O", false)
			loop parse (options) {
				switch A_LoopField {
					case "?", "B", "C", "O":
						this.opt[A_LoopField] := true
					case "0":
						try
							this.opt[temp] := false
						catch
							throw ValueError("Unknown option: " A_LoopField)
					default:
						throw ValueError("Unknown option: " A_LoopField)
				}
				temp := A_LoopField
			}
			this.str := this.opt["?"] ? this.str "$" : "^" this.str "$"
			this.str := this.opt["C"] ? this.str : "i)" this.str
		}
	}

	; append new RegExHotstring
	Add(Str, CallBack, Options) {
		this.hs[Str] := RegExHs.obj(Str, CallBack, Options)
	}

	OnKeyDown := this.keyDown
	keyDown(vk, sc) {
		if (vk = 8 || vk = 160 || vk = 161)
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
		for , obj in this.hs {
			str := obj.str
			call := obj.call
			opt := obj.opt
			start := RegExMatch(input, str, &match)
			if (start) {
				if (opt["B"])
					Send("{BS " match.Len[0] "}")
				if (call is String) {
					Send(RegExReplace(SubStr(input, start), str, call))
					if (!opt["O"])
						Send("{Blind}{vk" Format("{:02x}", vk) " down}")
				} else if (call is Func) {
					call(match)
				} else
					throw TypeError('CallBack type error `nCallBack should be "Func" or "String"')
				this.Start()
				return
			}
		}
		Send("{Blind}{vk" Format("{:02x}", vk) " down}")
		this.Start()
	}

	OnKeyUp := this.keyUp
	keyUp(vk, sc) {
		if (vk = 32 || vk = 9 || vk = 13)
			Send("{Blind}{vk" Format("{:02x}", vk) " up}")
	}

	; debug use
	/* OnChar := this.Char
	Char(c) {
		ToolTip(this.Input)
	} */
}