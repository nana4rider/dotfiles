#InstallKeybdHook
#useHook On

; 日英切り替えを無効
#Space::return
; Win+Ctrl+Shift+Rで再読み込み
#+^r::Reload
; 仮想デスクトップ使わない
#^d::return

; Ctrl+Alt+Wで定型文グループ2
^!w::
    Run, "%ComSpec%" /c start Clibor.exe /vt 2, , Hide
return

; ChromeでWebページにフォーカスを移動
#IfWinActive, ahk_exe chrome.exe
!d::
    Send, {F10}
    Sleep 50
    Send, +{F6}
return
#IfWinActive

; like bash
#if WinGetProcessName() = "WindowsTerminal.exe" && InStr(WinGetTitle(), "PowerShell")
^a::Send, {Home}
^e::Send, {End}
^u::Send, ^{Home}
^k::Send, ^{End}
^f::Send, {Right}
^b::Send, {Left}
^n::Send, {Down}
^p::Send, {Up}
#If

#if WinGetProcessName() = "WindowsTerminal.exe" && InStr(WinGetTitle(), "@")
^+Left::
    Send, {Esc}
    Sleep 50
    Send, ^]
    Sleep 50
    Send, {Space}
return
^+Right::
    Send, ^]
    Sleep 50
    Send, {Space}
return
#If

; Win+Ctrl+i IN clause
#i::
    tmpclip := clipboard
    if (InStr(tmpclip, "IN(") != 0) {
        exit
    }
    if (InStr(tmpclip, "`r`n") != 0) {
        tmpArray := StrSplit(tmpclip, "`r`n")
    } else {
        tmpArray := StrSplit(tmpclip, "`n")
    }
    clipString := ""
    exists := Object()
    loop, % tmpArray.Length() {
        entry := Trim(tmpArray[A_Index])
        if (!entry) {
            Continue
        }
        if (!exists[entry]) {
            exists[entry] := 1
            clipString .= "'" . entry . "'" . Chr(44)
        }
    }
    if (clipString) {
        clipboard := " IN(" . SubStr(clipString, 1, -1) . ") "
    }
return

; Win+Ctrl+Rを、クリップボードの内容を元に関連付けで開くコマンドに変更
#^r::
    tmpclip := clipboard
    if (InStr(tmpclip, "`r`n") != 0) {
        tmpArray := StrSplit(tmpclip, "`r`n")
    } else {
        tmpArray := StrSplit(tmpclip, "`n")
    }
    tmpArray := uniqueArray(tmpArray)
    
    openCount := 0
    loop, % tmpArray.Length() {
        filePath := Trim(tmpArray[A_Index])
        if (RegExMatch(filePath, "^""(.+)""$", $)) {
            filePath := $1
        }
        
        ; クリップボードの中身がURIの場合は関連付けで開く
        if (RegExMatch(filePath, "^\w+://")) {
            RunWait, PowerShell.exe -Command start \"%filePath%\", , Hide
            openCount++
            continue
        }
        
        ; WSLパスの場合はWindowsパスに変換する
        if (RegExMatch(filePath, "^/")) {
            filePath := ToggleFilePath(filePath)
        }
        
        ; ショートカットの場合は実体を開く
        if (RegExMatch(filePath, ".lnk$")) {
            FileGetShortcut, %filePath%, filePath
        }

        fileAttr := FileExist(filePath)
        if (RegExMatch(fileAttr, "D")) {
            ; ディレクトリの場合はExplorerで開く
            Run, "explorer" "%filePath%"
            openCount++
        } else if (fileAttr) {
            Run, "%filePath%"
            openCount++
        }
    }
return

; Win+Eを、クリップボードの内容を元にExplorerで開くコマンドに変更
#e::
    tmpclip := clipboard
    if (InStr(tmpclip, "`r`n") != 0) {
        tmpArray := StrSplit(tmpclip, "`r`n")
    } else {
        tmpArray := StrSplit(tmpclip, "`n")
    }
    tmpArray := uniqueArray(tmpArray)
    
    openCount := 0
    loop, % tmpArray.Length() {
        filePath := Trim(tmpArray[A_Index])
        if (filePath = "") {
            continue
        }

        if (RegExMatch(filePath, "^""(.+)""$", $)) {
            filePath := $1
        }
        
        if (RegExMatch(filePath, "^file:(?:///)?(.+)", $)) {
            ; file://
            filePath := RegExReplace($1, "/", "\")
        } else if (RegExMatch(filePath, "^/")) {
            ; WSLパスの場合はWindowsパスに変換する
            filePath := ToggleFilePath(filePath)
        }
        
        fileAttr := FileExist(filePath)
        if (RegExMatch(fileAttr, "D")) {
            ; ディレクトリの場合はそのまま開く
            Run, "explorer" "%filePath%"
            openCount++
        } else if (fileAttr) {
            ; ファイルの場合はフォーカスを当てた状態で開く
            select := "/select" . Chr(44)
            Run, "explorer" %select%"%filePath%"
            openCount++
        } else {
            if (openCount = 0) {
                ; ファイルが存在しない場合はホームディレクトリを開く
                EnvGet, userProfile, USER_PROFILE
                Run, "explorer" "%userProfile%"
            }
            exit
        }
    }
return

; クリップボードのWindowsとWLSのパスを相互変換
; パスにスペースが含まれる場合はダブルクォートで囲みます。
#p::
    tmpClip := Trim(Clipboard)
    if (RegExMatch(tmpClip, "^""(.+)""$", $)) {
        ; unwrap double quote
        tmpClip := $1
    }
    
    tmpClip := ToggleFilePath(tmpClip)
    
    if (RegExMatch(tmpClip, " ")) {
        ; wrap double quote
        tmpClip := """" . tmpClip . """"
    }
    
    Clipboard := tmpClip
return

; WindowsとWLSのパスを相互変換
; Example:
;   C:\Users\user  -> /mnt/c/Users/user
;   /mnt/c/Users/user       -> C:\Users\user
;   \\wsl$\Ubuntu\home\user -> /home/user
;   /tmp                    -> \\wsl$\Ubuntu\tmp
ToggleFilePath(filePath)
{
    ; /mnt/[A-Z] 以外のWSLパスをUNCに変換する場合のディストリビューション名
    distroName := "Ubuntu"
    
    if (RegExMatch(filePath, "^/")) {
        ; unescape single/back quote
        filePath := RegExReplace(filePath, "\\(?=[``'])", "")
    }
    
    if (RegExMatch(filePath, "^([a-zA-Z]):(.+)", $)) {
        ; Win -> WSL
        StringLower, letter, $1
        filePath := "/mnt/" . letter . RegExReplace($2, "\\", "/")
    } else if (RegExMatch(filePath, "^/mnt/([a-z])(.+)", $)) {
        ; WSL -> Win
        StringUpper, letter, $1
        filePath := letter . ":" . RegExReplace($2, "/", "\")
    } else if (RegExMatch(filePath, "^\\\\wsl\$\\[^\\]+\\?(.+)", $)) {
        ; UNC(WSL) -> WSL
        filePath := "/" . RegExReplace($1, "\\", "/")
    } else if (RegExMatch(filePath, "^(/.+)", $)) {
        ; WSL -> UNC(WSL)
        filePath := "\\wsl$\" . distroName . RegExReplace($1, "/", "\")
    }
    
    if (RegExMatch(filePath, "^/")) {
        ; escape single/back quote
        filePath := RegExReplace(filePath, "(?=[``'])", "\")
    }
    
    return filePath
}

; 全ての文字列が半角の場合は日本語に、そうでない場合は英語に翻訳します
F24::
    tmpclip := clipboard
    lang := getTranslateLanguage(tmpclip)
    transText := executeTranslate(tmpclip, lang)
    if (RegExMatch(transText, "^https?://")) {
        ; URLの場合はクリップボードに入れずに関連付けで開く
        RunWait, PowerShell.exe -Command start \"%transText%\", , Hide
    } else {
        clipboard := transText
        Sleep 100
        Send, ^v
    }
return

; ダイアログに指定した言語で翻訳します
+F24::
    tmpclip := clipboard
    lang := getTranslateLanguage(tmpclip)
    InputBox, lang, Please specify the translation language, %tmpclip%, , , , , , , , %lang%
    if (ErrorLevel == 0) {
        transText := executeTranslate(tmpclip, lang)
        clipboard := transText
        Sleep 100
        Send, ^v
    }
return

; 翻訳言語の判断
getTranslateLanguage(text)
{
    if (RegExMatch(text, "^[\x21-\x7e\s]+$") || RegExMatch(text, "^https?://")) {
        return "ja"
    } else {
        return "en"
    }
}

; 翻訳実行
executeTranslate(text, lang)
{
    ; translate-shell(https://github.com/soimort/translate-shell)をインストールしているディストリビューション名
    ; sudo apt install translate-shell
    distroName := "Ubuntu"
    
    srcFile := A_Temp . "\translate.src.txt"
    srcFileWsl := ToggleFilePath(srcFile)
    dstFile := A_Temp . "\translate.dst.txt"
    
    fh := FileOpen(srcFile, "w", "UTF-8-RAW")
    fh.Write(text)
    fh.Close()
    RunWait, %ComSpec% /c wsl -d %distroName% trans :%lang% "file://%srcFileWsl%" > "%dstFile%", , Hide
    
    fh := FileOpen(dstFile, "r", "UTF-8-RAW")
    content := fh.Read()
    fh.Close()
    content := RegExReplace(content, "\s+$", "")
    
    return content
}

WinGetClass(WinTitle = "A")
{
    WinGetClass, OutputVar, %WinTitle%
    Return, OutputVar
}

WinGetProcessName(WinTitle = "A")
{
    WinGet, OutputVar, ProcessName, %WinTitle%
    return, OutputVar
}

WinGetTitle(WinTitle = "A")
{
    WinGetTitle, OutputVar, %WinTitle%
    Return, OutputVar
}

ControlGetFocus(WinTitle = "A")
{
    ControlGetFocus, OutputVar, %WinTitle%
    return, OutputVar
}

uniqueArray(nameArray)
{
    hash := {}
    for i, name in nameArray {
        hash[name] := null
    }
    
    trimmedArray := []
    for name, dummy in hash {
        trimmedArray.Insert(name)
    }
    
    return trimmedArray
}
