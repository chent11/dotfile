/***
 *
 * Emacs Style Key Bindings
 *
 */
#+$::Send("#+S")

#UseHook
^n::
{
    if WinActive("ahk_exe WindowsTerminal.exe") && !WinActive("Windows PowerShell") {
		Send("^n")
		return
	}
    Send("{Down}")
}
^p::
{
    if WinActive("ahk_exe WindowsTerminal.exe") && !WinActive("Windows PowerShell") {
		Send("^p")
		return
	}
    Send("{Up}")
}
^b::
{
    if WinActive("ahk_exe WindowsTerminal.exe") && !WinActive("Windows PowerShell") {
		Send("^b")
		return
	}
    Send("{Left}")
}
^f::
{
    if WinActive("ahk_exe WindowsTerminal.exe") && !WinActive("Windows PowerShell") {
		Send("^f")
		return
	}
    Send("{Right}")
}
^h::
{
    if WinActive("ahk_exe WindowsTerminal.exe") && !WinActive("Windows PowerShell") {
		Send("^h")
		return
	}
    Send("{Backspace}")
}
^a::
{
    if WinActive("ahk_exe WindowsTerminal.exe") && !WinActive("Windows PowerShell") {
		Send("^a")
		return
	}
    Send("{Home}")
}
^e::
{
    if WinActive("ahk_exe WindowsTerminal.exe") && !WinActive("Windows PowerShell") {
		Send("^e")
		return
	}
    Send("{End}")
}
!b::
{
    if WinActive("ahk_exe WindowsTerminal.exe") && !WinActive("Windows PowerShell") {
		Send("!b")
		return
	}
    Send("^{Left}")
}
!f::
{
    if WinActive("ahk_exe WindowsTerminal.exe") && !WinActive("Windows PowerShell") {
		Send("!f")
		return
	}
    Send("^{Right}")
}
^w:: ;;Delete a word
{
    if WinActive("ahk_exe WindowsTerminal.exe") && !WinActive("Windows PowerShell") {
		Send("^w")
		return
	}
    Send("^{Backspace}")
}
!d:: ;;Delete previous word
{
	if WinActive("ahk_exe WindowsTerminal.exe") && !WinActive("Windows PowerShell") {
		Send("!d")
		return
	}
	Send("^+{Right}{Del}")
}
^;:: ;;Tmux leader key for mapping M-e
{
	if WinActive("ahk_exe WindowsTerminal.exe") && !WinActive("Windows PowerShell") {
		Send("!e")
		return
	}
	Send("^;")
}
#UseHook False

/***
 *
 * MacOS Style Key Bindings
 *
 */
~LWin::Send "{Blind}{vkE8}"
#w::
{
    if WinActive("ahk_exe WindowsTerminal.exe") {
		Send("^+w")
		return
	}
    Send("^w")
}
#a::
{
    if WinActive("ahk_exe WindowsTerminal.exe") {
		Send("^+a")
		return
	}
    Send("^a")
}
#f::
{
    if WinActive("ahk_exe WindowsTerminal.exe") {
		Send("+^f")
		return
	}
    Send("^f")
}
#h::
{
    if WinActive("ahk_exe WindowsTerminal.exe") {
		return
	}
    Send("^h")
}
#b::
{
    if WinActive("ahk_exe WindowsTerminal.exe") {
		return
	}
    Send("^b")
}
#c::
{
    if WinActive("ahk_exe WindowsTerminal.exe") {
		Send("^+C")
		return
	}
    Send("^c")
}
#x::
{
    Send("^x")
}
#v::
{
    if WinActive("ahk_exe WindowsTerminal.exe") {
		Send("^+V")
		return
	}
    Send("^v")
}
#s::
{
    Send("^s")
}
#z::
{
    if WinActive("ahk_exe WindowsTerminal.exe") {
		return
	}
    Send("^z")
}
#+Z::
{
    if WinActive("ahk_exe WindowsTerminal.exe") {
		return
	}
    Send("^y")
}

/***
 *
 * Desktop Switching
 *
 */
#^l::
{
	Send("{Blind}^#{Right}")
	KeyWait "l"
}
#^h::
{
	Send("{Blind}^#{Left}")
	KeyWait "h"
}
; global DesktopSwithcingDisabled := False
; #^l::desktopSwitch("^#{Right}", "l", "^#{Left}", "h")
; #^h::desktopSwitch("^#{Left}", "h", "^#{Right}", "l")

; desktopSwitch(direction, key, oppositeDirection, oppositeKey) {
; 	global DesktopSwithcingDisabled

; 	if DesktopSwithcingDisabled
; 		return
; 	DesktopSwithcingDisabled := True
; 	Send(direction)
; 	KeyWait key
; 	While GetKeyState("LCtrl") {
; 		Sleep 100
; 		if GetKeyState(key) {
; 			Send(direction)
; 			DesktopSwithcingDisabled := False
; 			return
; 		} Else if GetKeyState(oppositeKey) {
; 			Send(oppositeDirection)
; 			DesktopSwithcingDisabled := False
; 		}
; 	}
; 	DesktopSwithcingDisabled := False
; 	MouseClick "left"
; }
