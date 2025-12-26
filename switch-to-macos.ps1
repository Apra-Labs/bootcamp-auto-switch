# switch-to-macos.ps1 - Run on Windows to reboot into macOS
# Requires: winget install AutoHotkey.AutoHotkey

$ErrorActionPreference = "Stop"

$ahkPath = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"

if (-not (Test-Path $ahkPath)) {
    Write-Error "AutoHotkey not found. Install with: winget install AutoHotkey.AutoHotkey"
    exit 1
}

$ahkScript = @'
#Requires AutoHotkey v2.0
#SingleInstance Force

GetFocusedExeName() {
    static IUIAutomation := ComObject("{ff48dba4-60ef-4201-aa87-54103eef594e}", "{30cbe57d-d9d0-452a-ab13-7ac5ac4825ee}")
    try {
        ComCall(8, IUIAutomation, "Ptr*", &element := 0)
        if !element
            return ""
        ComCall(20, element, "Int*", &pid := 0)
        ObjRelease(element)
        if pid {
            for proc in ComObjGet("winmgmts:").ExecQuery("SELECT Name FROM Win32_Process WHERE ProcessId=" pid)
                return proc.Name
        }
    }
    return ""
}

; Open system tray
Send "#b"
Sleep 300
Send "{Space}"
Sleep 500

; Jump to Boot Camp (keyboard shortcut 'b')
Send "{Up}"
Sleep 150
Send "b"
Sleep 300

; Open context menu
Send "{AppsKey}"
Sleep 600

; Check menu exists and validate
menuHwnd := WinExist("ahk_class #32768")
if menuHwnd {
    Send "{Up}"
    Sleep 300
    exeName := GetFocusedExeName()
    if InStr(exeName, "Bootcamp") or InStr(exeName, "Apple") {
        Send "{Enter}"
        Sleep 500
        Send "{Enter}"
        ExitApp 0
    }
}

; Cleanup on failure
Send "{Escape}"
Sleep 200
Send "{Escape}"
ExitApp 1
'@

Write-Host "Switching to macOS..."

$tempFile = [System.IO.Path]::Combine($env:TEMP, "switch-to-macos.ahk")

# Write file with UTF8 encoding
Set-Content -Path $tempFile -Value $ahkScript -Encoding UTF8

if (-not (Test-Path $tempFile)) {
    Write-Error "Failed to create temp file: $tempFile"
    exit 1
}

Write-Host "Created: $tempFile"

try {
    $process = Start-Process -FilePath $ahkPath -ArgumentList $tempFile -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        Write-Error "Boot Camp not found"
        exit 1
    }
} finally {
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
}
