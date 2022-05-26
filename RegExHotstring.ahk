#SingleInstance Force

Esc:: ExitApp()

SacHook := InputHook("V")
SacHook.KeyOpt("{Tab}{Space}{Enter}", "+N")
SacHook.OnKeyDown := SacChar
SacHook.Start()
Hs := RegExHs()

SacChar(ih, vk, sc) {
    ; match when pressed
    if (vk = 0x09 || vk = 0x0d || vk = 0x20) {
        ; loop through
        input := ih.Input
        ih.Stop()
        loop Hs.Len() {
            str := Hs.str_arr[A_Index]
            call := Hs.call_arr[A_Index]
            if (RegExMatch(input, str, &match)) {
                ; delete matched string
                Send("{BS " match.Len[0] + 1 "}")
                if (call is String) {
                    Send(RegExReplace(input, str, call))
                } else if (call is Func) {
                    call(match)
                } else
                    throw 'callback type error:`ninput should be "Func" or "String"'
                ih.Start()
                return
            }
        }
        ih.Start()
    }
}

RegExHotstring(str, Callback) {
    Hs.Append(str, Callback)
}

Class RegExHs {

    str_arr := Array()
    call_arr := Array()

    ; append new RegExHotstring
    Append(str, callback) {
        this.str_arr.Push(str)
        this.call_arr.Push(callback)
    }

    Len() {
        return this.str_arr.Length
    }
}

; ###################### test #########################

RegExHotstring("(\w)abc", call)
RegExHotstring("(\w)dbc", "dbc$1")
::asdf::qwer
RegExHotstring("!@(\d+)s", rand)

call(match) {
    Send("call" match[1])
}

arr := Array()
i := 0x30
While i < 0x40 {
    arr.Push(chr(i))
    i++
}
i := 0x41
While i <= 0x5a {
    arr.Push(Chr(i))
    i++
}
i := 0x61
While i <= 0x7a {
    arr.Push(Chr(i))
    i++
}
rand(match) {
    str := ""
    loop match[1] {
        r := Random(1, arr.Length)
        str .= arr[r]
    }
    Send(str)
}