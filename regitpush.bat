@echo off
setlocal

set remote=origin
set branch=master
set retry_interval=300

:retry
git push

if %errorlevel% neq 0 (
    echo Push failed. Retrying in %retry_interval% seconds...
    timeout /t %retry_interval%
    goto retry
)

echo Push successful.

endlocal
