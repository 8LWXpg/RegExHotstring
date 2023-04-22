#Requires AutoHotkey v2.0

SendLevel(1)
RegHook := RegExHs("VI2")
RegHook.NotifyNonText := true
RegHook.KeyOpt("{Space}{Tab}{Enter}", "+SN")
RegHook.Start()

/**
 * Create a RegEx Hotstring or replace already existing one
 * @param {String} String RegEx string
 * @param {Func or String} CallBack calls function with RegEx match info or replace string
 * @param {String} Options
 * 
 * \* (asterisk): An ending character (e.g. Space, Tab, or Enter) is not required to trigger the hotstring.
 * use *0 to turn this option back off.
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
RegExHotstring(String, CallBack, Options := "") {
	RegHook.Add(String, CallBack, Options)
}

class RegExHs extends InputHook {
	; stores with RegEx string as key and obj as value
	; "*0" option
	a0 := Map()
	; "*" option
	a := Map()

	; process RegEx string and options then store in obj
	class obj {
		__New(string, call, options) {
			this.call := call
			this.str := string
			this.opt := Map("*", false, "?", false, "B", true, "C", false, "O", false)
			loop parse (options) {
				switch A_LoopField {
					case "*", "?", "B", "C", "O":
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

	; add new RegExHotstring
	Add(String, CallBack, Options) {
		info := RegExHs.obj(String, CallBack, Options)
		if (info.opt["*"]) {
			try
				this.a0.Delete(String)
			; end key is always omitted
			info.opt["O"] := true
			this.a[String] := info
		} else {
			try
				this.a.Delete(String)
			this.a0[String] := info
		}
	}

	OnKeyDown := this.keyDown
	keyDown(vk, sc) {
		switch vk {
			case 9, 13, 32:
				; clear input if not match
				if (!this.match(this.a0, vk,
					SubStr(this.Input, 1, StrLen(this.Input) - 1),
					(*) => Send("{Blind}{vk" Format("{:02x}", vk) " down}"))) {
					this.Stop()
					this.Start()
				}
			case 8, 160, 161:
				; do nothing
			default:
				; clear input when press non-text key
				this.Stop()
				this.Start()
		}
	}

	OnKeyUp := this.keyUp
	keyUp(vk, sc) {
		switch vk {
			case 9, 13, 32:
				Send("{Blind}{vk" Format("{:02x}", vk) " up}")
		}
	}

	OnChar := this.char
	char(c) {
		vk := GetKeyVK(GetKeyName(c))
		switch vk {
			case 9, 13, 32:
				return
		}
		this.match(this.a, vk)
	}

	match(map, vk, input := this.Input, defer := (*) => 0) {
		; debug use
		; ToolTip(this.Input)
		if (!map.Count) {
			defer()
			return false
		}
		; loop through each strings and find the first match
		for , obj in map {
			str := obj.str
			call := obj.call
			opt := obj.opt
			start := RegExMatch(input, str, &match)
			; if match, replace or call function
			if (start) {
				if (opt["B"])
					Send("{BS " match.Len[0] "}")
				if (call is String) {
					this.Stop()
					Send(RegExReplace(SubStr(input, start), str, call))
					if (!opt["O"])
						defer()
					this.Start()
				} else if (call is Func) {
					this.Stop()
					call(match)
					this.Start()
				} else
					throw TypeError('CallBack type error `nCallBack should be "Func" or "String"')
				return true
			}
		}
		defer()
		return false
	}
}