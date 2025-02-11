@set LOCAL_DIR=%~dp0%
@powershell -NoLogo -ExecutionPolicy Unrestricted -File "%LOCAL_DIR%..\script\main.ps1" %LOCAL_DIR% main.sh XX AAA
@pause
