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

; Win+Eを、クリップボードの内容を元に開くコマンドに変更
; 環境変数 FILE_EXPLORER にTablacus Explorerのパスを設定しておく
#e::
    EnvGet, fileExplorer, FILE_EXPLORER
    
    filePath := Trim(Clipboard)
    if (RegExMatch(filePath, "^""(.+)""$", $)) {
        filePath := $1
    }
    
    ; クリップボードの中身がURIの場合は関連付けで開く
    if (RegExMatch(filePath, "^\w+://")) {
        Run, "%ComSpec%" /c start %filePath%, , Hide
        exit
    }
    
    ; WSLパスの場合はWindowsパスに変換する
    if (RegExMatch(filePath, "^/")) {
        filePath := ToggleFilePath(filePath)
    }
    
    fileAttr := FileExist(filePath)
    if (RegExMatch(fileAttr, "D")) {
        ; ディレクトリの場合はそのまま開く
        Run, "%fileExplorer%" "%filePath%"
    } else if (fileAttr) {
        ; ファイルの場合はフォーカスを当てた状態で開く
        select := "/select" . Chr(44)
        Run, "%fileExplorer%" %select%"%filePath%"
    } else {
        ; ファイルが存在しない場合はホームディレクトリを開く
        EnvGet, userProfile, USER_PROFILE
        Run, "%fileExplorer%" "%userProfile%"
    }
return

; クリップボードのWindowsとWLSのパスを相互変換
; パスにスペースが含まれる場合はダブルクォートで囲みます。
^F19::
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
    distroName := "Ubuntu-20.04"
    
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
