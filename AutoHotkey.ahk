#InstallKeybdHook
#useHook On

#space::return

#^r::Reload

; like bash
#if WinGetProcessName() = "WindowsTerminal.exe" && WinGetTitle() = "pwsh"
^a::Send, {Home}
^e::Send, {End}
^u::Send, ^{Home}
^k::Send, ^{End}
^f::Send, {Right}
^b::Send, {Left}
^n::Send, {Down}
^p::Send, {Up}
#If

; #if WinGetProcessName() = "RLogin.exe"
; ^Left::Send, {ESC}{b}
; ^Right::Send, {ESC}{f}
; #If

WinGetProcessName(WinTitle = "A")
{
    WinGet, OutputVar, ProcessName, %WinTitle%
    Return, OutputVar
}

WinGetTitle(WinTitle = "A")
{
    WinGetTitle, OutputVar, %WinTitle%
    Return, OutputVar
}
