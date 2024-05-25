#Requires AutoHotkey v2.0

RegHook := RegExHk("VI")
RegHook.NotifyNonText := true
RegHook.KeyOpt("{Space}{Tab}{Enter}{NumpadEnter}{BackSpace}", "+SN")
RegHook.Start()

/**
 * Create a RegEx Hotstring or replace already existing one
 * @param {String} String [RegEx string](https://www.autohotkey.com/docs/v2/misc/RegEx-QuickRef.htm)
 * @param {Func or String} CallBack calls function with [RegExMatchInfo](https://www.autohotkey.com/docs/v2/lib/RegExMatch.htm#MatchObject)
 * and array of additional params or replace string like [RegExReplace](https://www.autohotkey.com/docs/v2/lib/RegExReplace.htm)
 * @param {String} Options A string of zero or more of the following options (in any order, with optional spaces in between)
 * 
 * Use the following options follow by a zero to turn them off:
 * 
 * `*` (asterisk): An ending character (e.g. Space, Tab, or Enter) is not required to trigger the hotstring.
 * 
 * `?` (question mark): The hotstring will be triggered even when it is inside another word;
 * that is, when the character typed immediately before it is alphanumeric.
 * 
 * `B0` (B followed by a zero): Automatic backspacing is not done to erase the abbreviation you type.
 * Use a plain B to turn backspacing back on after it was previously turned off.
 * 
 * `C`: Case sensitive: When you type an abbreviation, it must exactly match the case defined in the script.
 * 
 * `O`: Omit the ending character of auto-replace hotstrings when the replacement is produced.
 * 
 * `T`: Use SendText instead of SendInput to send the replacement string.
 * Only works when CallBack is a string.
 * 
 * @param {Params} Params additional params pass to CallBack, check [Variadic functions](https://www.autohotkey.com/docs/v2/Functions.htm#Variadic)
 * and [Variadic function calls](https://www.autohotkey.com/docs/v2/Functions.htm#VariadicCall), only works when CallBack is a function.
 */
RegExHotstring(String, CallBack, Options := "", OnOffToggle := "On", Params*) {
	RegHook.Add(String, CallBack, Options, OnOffToggle, Params*)
}

class RegExHk extends InputHook {
	; stores with RegEx string as key and obj as value

	; "*0" option
	a0 := Map()
	; "*" option
	a := Map()

	/**
	 * Object for storing all the information
	 */
	class obj {
		__New(string, call, options, on, params*) {
			this.call := call
			this.str := string
			this.params := params

			this.opt := Map("*", false, "?", false, "B", true, "C", false, "O", false, "T", false)
			loop parse (options) {
				switch A_LoopField {
					case "*", "?", "B", "C", "O", "T":
						this.opt[A_LoopField] := true
					case "0":
						try
							this.opt[temp] := false
						catch
							throw ValueError("Unknown Option: " A_LoopField)
					case " ":
						continue
					default:
						throw ValueError("Unknown Option: " A_LoopField)
				}
				temp := A_LoopField
			}
			this.str := this.opt["?"] ? this.str "$" : "^" this.str "$"
			this.str := this.opt["C"] ? this.str : "i)" this.str

			switch on {
				case "On", 1, true:
					this.on := true
				case "Off", 0, false:
					this.on := false
				case "Toggle", -1:
					; toggle depands on the previous state, it's unreachable here, so defaults to true.
					this.on := true
				default:
					throw ValueError("Unknown OnOffToggle: " on)
			}
		}
	}

	Add(String, CallBack, Options, OnOffToggle, Params*) {
		toggle := false
		switch OnOffToggle {
			case "Toggle", -1:
				toggle := true
		}

		info := RegExHk.obj(String, CallBack, Options, OnOffToggle, Params*)
		if (info.opt["*"]) {
			try
				this.a0.Delete(String)
			; end key is always omitted
			info.opt["O"] := true
			if (toggle) {
				try
					info.on := !this.a[String].on
			}
			this.a[String] := info
		} else {
			try
				this.a.Delete(String)
			if (toggle) {
				try
					info.on := !this.a0[String].on
			}
			this.a0[String] := info
		}
	}

	OnKeyDown := this.keyDown
	keyDown(vk, sc) {
		switch vk {
			case 8:
				Send("{Blind}{vk08 down}")
			case 9, 13, 32:
				; clear input if not match
				if (!this.match(this.a0,
					SubStr(this.Input, 1, StrLen(this.Input) - 1),
					(*) => Send("{Blind}{vk" Format("{:02x}", vk) " down}"))) {
					this.Stop()
					this.Start()
				}
			case 160, 161:
				; do nothing on shift key
			default:
				; clear input when press non-text key
				this.Stop()
				this.Start()
		}
	}

	OnKeyUp := this.keyUp
	keyUp(vk, sc) {
		switch vk {
			case 8, 9, 13, 32:
				Send("{Blind}{vk" Format("{:02x}", vk) " up}")
		}
	}

	OnChar := this.char
	char(c) {
		blind := StrLen(c) > 1 ? "" : "{Blind}"
		loop parse c {
			c := A_LoopField
			vk := GetKeyVK(GetKeyName(c))
			switch vk {
				case 9, 13, 32:
					return
			}
			; if capslock is on, convert to lower case
			GetKeyState("CapsLock", "T") ? c := StrLower(c) : 0
			this.match(this.a)
		}
	}

	/**
	 * Function for matching and executing
	 * @param map Map to search for RegEx string
	 * @param {String} input Input string
	 * @param {(*) => void} defer What to do if no match or `O` is `false`
	 * @returns {Boolean} If match found
	 */
	match(map, input := this.Input, defer := (*) => 0) {
		; debug use
		; ToolTip(this.Input)
		if (!map.Count) {
			defer()
			return false
		}
		; loop through each strings and find the first match
		for , obj in map {
			if (!obj.on)
				continue
			str := obj.str
			call := obj.call
			opt := obj.opt
			params := obj.params
			start := RegExMatch(input, str, &match)
			; if match, send replace or call function
			if (start) {
				; ToolTip(match[1])
				Sleep(1)
				if (opt["B"]) {
					loop match.Len[0] {
						Send("{BS down}")
					}
					Send("{BS up}")
				}
				else
					defer()
				; workaround for Send sometimes not working
				Sleep(1)
				if (call is String) {
					; ToolTip(RegExReplace(SubStr(input, start), str, call))
					this.Stop()
					if (opt["T"]) {
						SendText(RegExReplace(SubStr(input, start), str, call))
					} else {
						Send(RegExReplace(SubStr(input, start), str, call))
					}
					if (!opt["O"])
						defer()
					this.Start()
				} else if (call is Func) {
					this.Stop()
					call(match, params*)
					this.Start()
				} else
					throw TypeError('CallBack should be "Func" or "String"')
				return true
			}
		}
		defer()
		return false
	}
}