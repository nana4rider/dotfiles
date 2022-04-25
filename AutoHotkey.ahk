#InstallKeybdHook
#useHook On
#include *i Work.ahk

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

; A5M2
#IfWinActive, ahk_exe A5M2.exe
; F13でツリーにフォーカス
F13::Send, {F7}
; F19でエディタにフォーカス
F19::Send, {F8}
^s::Send, ^+r
^o::
    Send, !e
    Sleep 50
    Send, 0
return
#IfWinActive

; Slackのコードブロック
#IfWinActive, ahk_exe Slack.exe
F16::Send, ^!+c
#IfWinActive

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

; Win+Ctrl+Rを、オリジナルのWin+Rと同じ動作に変更
#^r::Run, "%ComSpec%" /c start "" explorer Shell:::{2559a1f3-21d7-11d4-bdaf-00c04f60b9f0}, , Hide

; Win+Rを、クリップボードの内容を元に関連付けで開くコマンドに変更
#r::
    EnvGet, fileExplorer, FILE_EXPLORER
    
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
        
        fileAttr := FileExist(filePath)
        if (RegExMatch(fileAttr, "D")) {
            ; ディレクトリの場合はTablacus Explorerで開く
            Run, "%fileExplorer%" "%filePath%"
            openCount++
        } else if (fileAttr) {
            Run, "%filePath%"
            openCount++
        }
    }
    
    ; クリップボードの内容で何も実行できなかった場合、ファイル名を指定して実行を開く
    if (openCount = 0) {
        Run, "%ComSpec%" /c start "" explorer Shell:::{2559a1f3-21d7-11d4-bdaf-00c04f60b9f0}, , Hide
    }
return

; Win+Eを、クリップボードの内容を元にTablacus Explorerで開くコマンドに変更
; 環境変数 FILE_EXPLORER にTablacus Explorerのパスを設定しておく
#e::
    EnvGet, fileExplorer, FILE_EXPLORER
    
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
            Run, "%fileExplorer%" "%filePath%"
            openCount++
        } else if (fileAttr) {
            ; ファイルの場合はフォーカスを当てた状態で開く
            select := "/select" . Chr(44)
            Run, "%fileExplorer%" %select%"%filePath%"
            openCount++
        } else {
            if (openCount = 0) {
                ; ファイルが存在しない場合はホームディレクトリを開く
                EnvGet, userProfile, USER_PROFILE
                Run, "%fileExplorer%" "%userProfile%"
            }
            exit
        }
    }
return

; Tablacus Explorerにおいて、アドレスバーやツリービューにフォーカス時
; 一部ショートカットが効かない問題を解消する
#if WinGetProcessName() = "TE64.exe" && (ControlGetFocus() = "SysTreeView321" || ControlGetFocus() = "Chrome_WidgetWin_11") ;
^t::Send, {Tab}{Down}^t
^w::Send, {Tab}{Down}^w
F13::Send, {Tab}{Down}{F13}
F19::Send, {Tab}{Down}
#if
    
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
