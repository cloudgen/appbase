#!/bin/sh
# -*- coding: utf-8 -*-
##! 0<0# : ^
##! """
##! @echo off
##! SET F="C:\\Users\\%USERNAME%\\AppData\\Local\\Microsoft\\WindowsApps\\python.exe"
##! if exist %F% ( del /s %F% >nul 2>&1 )
##! SET G="C:\\Users\\%USERNAME%\\AppData\\Local\\Microsoft\\WindowsApps\\python3.exe"
##! if exist %G% ( del /s %G% >nul 2>&1 )
##! FOR /F "tokens=*" %%g IN ('where python.exe') do (SET VAR=%%g)
##! if exist %VAR% (
##!     python "%~f0" %*
##!     exit /b 0
##! )
##! FOR /F "tokens=*" %%g IN ('where python3.exe') do (SET VAR=%%g)
##! if exist %VAR% ( python3 "%~f0" %* )
##! exit /b 0
##! """
""":"
if [ -f /usr/bin/sw_vers ]; then WHICH='which';elif [ -f /usr/bin/which ]; then WHICH='/usr/bin/which';elif [ -f /bin/which ]; then WHICH='/bin/which';elif [ -f "C:\\Windows\\System32\\where.exe" ]; then WHICH="C:\\Windows\\System32\\where.exe";fi; if [ ! -z $WHICH ]; then _PY_=$($WHICH python3);if [ -z $_PY_ ]; then _PY_=$($WHICH python2); if [ -z $_PY_ ]; then _PY_=$($WHICH pypy3); if [ -z $_PY_ ]; then _PY_=$($WHICH pypy); if [ -z $_PY_ ]; then _PY_=$($WHICH python); if [ -z $_PY_ ]; then echo 'No Python Found'; fi; fi; fi; fi; fi; if [ ! -z "$_PY_" ]; then WINPTY=$($WHICH winpty.exe 2>/dev/null);if [ ! -z "$WINPTY" ]; then PY_EXE=$($WHICH python.exe 2>/dev/null);if [ ! -z "$PY_EXE" ]; then exec "$WINPTY" "$PY_EXE" "$0" "$@";exit 0;fi;else exec $_PY_ "$0" "$@";exit 0;fi;fi;fi;if [  -f /usr/bin/python3 ]; then exec /usr/bin/python3 "$0" "$@";exit 0;fi;if [  -f /usr/bin/python2 ]; then exec /usr/bin/python2 "$0" "$@";exit 0;fi;if [  -f /usr/bin/python ]; then exec /usr/bin/python "$0" "$@";exit 0;fi;if [  -f /usr/bin/pypy3 ]; then exec /usr/bin/pypy3 "$0" "$@";exit 0;fi ;if [  -f /usr/bin/pypy ]; then exec /usr/bin/pypy "$0" "$@";exit 0;fi
# This is code from online-installer, homepage: https://github.com/cloudgen2/online-installer
exit 0
":"""
from lib.appbase import Sh
from lib.appbase import Which
from lib.appbase import AppData
from lib.appbase import MsgBase
from lib.appbase import CmdHistory
from lib.appbase import Shell
from lib.appbase import AppHistory
from lib.appbase import OS
from lib.appbase import AppMsg
from lib.appbase import Installer
from lib.appbase import AppPara
from lib.appbase import FromPipe
from lib.appbase import Ask
from lib.appbase import ShellProfile
from lib.appbase import Curl
from lib.appbase import Temp
from lib.appbase import AppBase

class AppBaseTest(AppBase):
    def start(self):
        self.allowInstallLocal(False).allowDisplayInfo(True).allowSelfInstall(False)
        if not self.parseArgs(self.usage()):
            self.msg_info()
        m = MsgBase()
        m.safeMsg("Thank you for using AppBase", "APPBASE")

if __name__ == "__main__":
    app = AppBaseTest(__file__)
    app.setInstallation(appName='appbasetest',author='Cloudgen Wong',homepage="https://github.com/cloudgen/appbase",downloadUrl="https://dl.leolio.page/appbasetest",lastUpdate='2024-1-26',majorVersion=1,minorVersion=26)
    app.start()