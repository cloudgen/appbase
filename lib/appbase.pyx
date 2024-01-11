from __future__ import print_function
try:
    raw_input
except NameError:
    raw_input = input
try:
    basestring
except NameError:
    basestring = str
try: 
    __file__
except NameError: 
    __file__ = ''
try:
    import ConfigParser as configparser
except:
    import configparser
try:
    import pwd
except:
    pwd = None
try:
    get_ipython
    getIpythonExists = True
except:
    getIpythonExists = True
    get_ipython={}
from datetime import date, datetime
import getpass
from inspect import currentframe
import os
import platform
import re
import signal
from subprocess import Popen, PIPE
import subprocess
import shutil
import socket
import time
import sys

class AppBase(object):
    VERSION="1.1"
    BOLD='\033[1m'
    DARK_AMBER='\033[33m'
    DARK_BLUE='\033[34m'
    DARK_TURQUOISE='\033[36m'
    END='\033[0m'
    FLASHING='\033[5m'
    ITALICS='\033[3m'
    LIGHT_RED='\033[91m'
    LIGHT_AMBER='\033[93m'
    LIGHT_BLUE='\033[94m'
    LIGHT_GREEN='\033[92m'
    LIGHT_TURQUOISE='\033[96m'

    __here__ = __file__

    def __alpine_ask_install_sudo__(self):
        if self.ask_install_sudo():
            cmd="apk add sudo"
            self.cmd_history(cmd)
            result, stdout = self.shell(cmd, True)
            cmd="echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel"
            self.cmd_history(cmd)
            result, stdout = self.shell(cmd)

    def __ask_number__(self, ask):
        if not hasattr(self, '__regex_number__'):
            self.__regex_number__ = re.compile(r"[1-9][0-9]*|exit")
        ask_number = ''
        try:
            ask_number = raw_input(ask).strip().lower()
        except:
            ask_number = ""
        if self.signal()== 2:
            return None
        while ask_number == '' or self.__regex_number__.sub("",ask_number) != '':
            try:
                ask_number = raw_input(ask).strip()
            except:
                ask_number = ""
            if self.signal()== 2:
                return None
        if ask_number == "" or ask_number == "exit":
            return None
        if self.signal() == 2:
            self.signal(0)
            return None
        return int(ask_number)

    def __ask_yesno__(self, ask):
        if not hasattr(self, '__regex_yesno__'):
            self.__regex_yesno__ = re.compile(r"yes|no|exit")
        ask_yesno = ''
        try:
            ask_yesno = raw_input(ask).strip().lower()
        except:
            ask_yesno = ""
        if self.signal()== 2:
            return None
        while ask_yesno == '' or self.__regex_yesno__.sub("",ask_yesno) != '':
            try:
                ask_yesno = raw_input(ask).strip().lower()
            except:
                ask_yesno = ""
            if self.signal()== 2:
                return None
        return ask_yesno

    def __coloredMsg__(self,color=None):
        if color is None :
            if self.__message__() == '':
                return ''
            else:
                return "%s%s%s" % (self.__colorMsgColor__(),\
                    self.__message__(),self.__colorMsgTerm__())
        else:
            if color == '' or not self.useColor():
                self.__colorMsgColor__('')
                self.__colorMsgTerm__('')
            else:
                self.__colorMsgColor__(color)
                self.__colorMsgTerm__(AppBase.END)
            return self

    def __colorMsgColor__(self, color=None):
        if color is not None:
            self.__cmc__=color
            return self
        elif not hasattr(self,'__cmc__'):
            self.__cmc__=""
        return self.__cmc__

    def __colorMsgTerm__(self,term=None):
        if term is not None:
            self.__cmt__=term
            return self
        elif not hasattr(self,'__cmt__'):
            self.__cmt__=""
        return self.__cmt__

    def __formattedMsg__(self):
        return "%s %s %s\n  %s" % (self.__timeMsg__(),self.__header__(),\
            self.__tagMsg__(),self.__coloredMsg__())

    def __header__(self,color=None):
        if color is None:
            return "%s%s(v%s) %s" % (self.__headerColor__(),\
                self.appName(),self.version(),\
                self.__headerTerm__())
        else:
            if color == '' or not self.useColor():
                self.__headerColor__('')\
                    .__headerTerm__('')
            else:
                self.__headerColor__(color)\
                    .__headerTerm__(AppBase.END)
        return self

    def __headerColor__(self,color=None):
        if color is not None:
            self.__hc__=color
            return self
        elif not hasattr(self,'__hc__'):
            self.__hc__=""
        return self.__hc__

    def __headerTerm__(self,term=None):
        if term is not None:
            self.__ht__=term
            return self
        elif not hasattr(self,'__ht__'):
            self.__ht__=""
        return self.__ht__

    def __install_local__(self, this = None, verbal = True ):
        result = False
        if this is None:
            this = self.this()
        if self.isCmd() or self.isGitBash():
            file = 'C:\\Users\\%s\\AppData\\Local\\Microsoft\\WindowsApps\\%s.bat' % (self.username(),self.appName())
            result = self.translateScript(source=this, target=file, useSudo=False)
        else:
            folder=self.localInstallFolder()
            self.mkdir(folder)
            file=self.localInstallPath()
            result = self.translateScript(source=this, target=file, useSudo=False)
        self.check_env()
        if verbal:
            if self.targetApp() == '':
                self.msg_install_app_local()
            else:
                self.msg_install_target_local()
        return result

    def __message__(self,message=None):
        if message is not None:
            self.__m__=message
            return self
        elif not hasattr(self,'__m__'):
            self.__m__=""
        return self.__m__

    def __self_install__(self, this=None, verbal = True, sudo=False):
        if this is None:
            this = self.this()
        result = False
        try_global = True
        if self.username() != 'root':
            if self.allowInstallLocal():
                if self.fromPipe():
                    return False
                if self.ask_not_root():
                    if self.ask_choose():
                        try_global = False
                        result = self.__install_local__()
            elif sudo:
                try_global = True
                result = False
                if try_global:
                    if self.osVersion() == 'Alpine':
                        self.msg_alpine_detected()
                        self.msg_sudo_failed()
                        result = False
                    elif self.sudo_test():
                        self.msg_sudo()
                        self.removeGlobalInstaller()
                        result = self.translateScript(source=this, target=self.globalInstallPath(1),useSudo=True)
                    else:
                        self.msg_sudo_failed()
                        result = False
        else:
            self.removeGlobalInstaller()
            result = self.translateScript(source=this, target=self.globalInstallPath(1))
        if result:
            if try_global and verbal:
                self.msg_install_app_global()

        return result

    def __self_install_globally__(self, verbal = True):
        if self.username() == 'root':
            if self.thisFile().endswith(".so"):
                self.__self_install__(this=self.this(), verbal=verbal)
            else:
                self.__self_install__(this=self.thisFile(), verbal=verbal)
        elif self.ask_not_root():
            if self.sudo_test():
                self.msg_sudo()
                if self.thisFile().endswith(".so"):
                    return self.__self_install__(this=self.this(), verbal=verbal, sudo=True)
                else:
                    return self.__self_install__(this=self.thisFile(), verbal=verbal, sudo=True)
        elif self.username() != 'root':
            self.msg_root_continue()
            return False
        else:
            if self.thisFile().endswith(".so"):
                return self.__self_install__(this=self.thisFile(), verbal=verbal)
            else:
                return self.__self_install__(this=self.this(), verbal=verbal)

    def __tag__(self, tag=None):
        if tag is not None:
            self.__t__=tag
            return self
        elif not hasattr(self,'__t__'):
            self.__t__=''
        return self.__t__

    def __tagColor__(self, color=None):
        if color is not None:
            self.__tc__=color
            return self
        elif not hasattr(self,'__tc__'):
            self.__tc__=''
        return self.__tc__

    def __tagMsg__(self,color=None,outterColor=None):
        if color is None:
            if self.__tag__() == '' or not self.useColor():
                return '[%s]: ' % self.__tag__()
            else:
                return "%s[%s%s%s%s%s]:%s " % (self.__tagOutterColor__(),\
                    self.__tagTerm__(),self.__tagColor__(),\
                    self.__tag__(),self.__tagTerm__(),\
                    self.__tagOutterColor__(),self.__tagTerm__())
        else:
            if color == '':
                self.__tagColor__('')\
                    .__tagOutterColor__('')\
                    .__tagTerm__('')
            else:
                self.__tagColor__(color)\
                    .__tagOutterColor__(outterColor)\
                    .__tagTerm__(AppBase.END)
            return self

    def __tagOutterColor__(self, color=None):
        if color is not None:
            self.__toc__=color
            return self
        elif not hasattr(self,'__toc__'):
            self.__toc__=''
        return self.__toc__
    
    def __tagTerm__(self, term=None):
        if term is not None:
            self.__tt__=term
            return self
        elif not hasattr(self,'__tt__'):
            self.__tt__=''
        return self.__tt__

    def __timeColor__(self, color=None):
        if color is not None:
            self.__tcolor__=color
            return self
        elif not hasattr(self,'__tcolor__'):
            self.__tcolor__=''
        return self.__tcolor__

    def __timeMsg__(self, color=None):
        if color is None:
            return "%s%s%s" % (self.__timeColor__(),self.now(),\
                self.__timeTerm__())
        else:
            if color == '' or not self.useColor():
                self.__timeColor__('')\
                    .__timeTerm__('')
            else:
                self.__timeColor__(color)\
                    .__timeTerm__(AppBase.END)
            return self

    def __timeTerm__(self, term=None):
        if term is not None:
            self.__tterm__=term
            return self
        elif not hasattr(self,'__tterm__'):
            self.__tterm__=''
        return self.__tterm__

    def alpine_version(self):
        if not hasattr(self,'__alpine_version__'):
            if self.osVersion().startswith("Alpine"):
                version=self.osVersion().split(' ')
                length=len(version)
                if length>1:
                    self.__alpine_version__=version[length - 1]
            else:
                self.__alpine_version__=''
        return self.__alpine_version__

    def add_alpine_nginx_adm_sudoer(self, usr="nginx-adm"):
        self.history_check_copy_sudoers(currentframe().f_lineno)
        if self.sudo_cmd() != "":
            s_cmd = self.which_rc_service()
            n_cmd = self.which_nginx()
            lines = [
                self.nopw(usr, "%s nginx reload" % s_cmd),
                self.nopw(usr, "%s nginx restart" % s_cmd),
                self.nopw(usr, "%s nginx start" % s_cmd),
                self.nopw(usr, "%s nginx status" % s_cmd),
                self.nopw(usr, "%s nginx stop" % s_cmd),
                self.nopw(usr, n_cmd),
                ""
            ]
            self.add_sudoers("1700-%s" % usr,'\n'.join(lines))
        else:
            self.msg_sudo_not_installed()
        return False

    def add_apk_community(self):
        comm="https://dl-cdn.alpinelinux.org/alpine/%s/community" % self.alpine_version()
        hasCommunity=False
        self.history_check_repositories(currentframe().f_lineno)
        fin = self.open('/etc/apk/repositories', "rt", use_history=True)
        for line in fin:
            if 'https://dl-cdn.alpinelinux.org' in line and 'community' in line:
                if '#' not in line:
                    hasCommunity=True
        fin.close()
        if not hasCommunity:
            with self.open('/etc/apk/repositories', "a") as file:
                file.write("\n%s\n" % comm)
            file.close()
        return True

    def add_bashprofile_modification(self):
        # Append the modification lines to .bashrc file
        modification_lines = [
            "# modified to add ~/.local/bin to PATH",
            "PATH=$PATH:~/.local/bin\n"
        ]
        
        with self.open(self.bashprofile(), "a") as file:
            file.write("\n".join(modification_lines))
        self.chmod_x(self.bashprofile())

    def add_bashrc_modification(self):
        # Append the modification lines to .bashrc file
        modification_lines = [
            "# modified to add ~/.local/bin to PATH",
            "PATH=$PATH:~/.local/bin\n"
        ]
        
        with self.open(self.bashrc(), "a") as file:
            file.write("\n".join(modification_lines))
        self.chmod_x(self.bashrc())        

    def add_nginx_adm_sudoer(self, usr="nginx-adm"):
        self.history_check_copy_sudoers(currentframe().f_lineno)
        if self.sudo_cmd() != "":
            s_cmd = self.which_systemctl()
            j_cmd = self.which_journalctl()
            n_cmd = self.which_nginx()
            lines = [
                self.nopw(usr, "%s -f -u nginx" % j_cmd),
                self.nopw(usr, "%s -f -u nginx" %  j_cmd),
                self.nopw(usr, "%s -u nginx" % j_cmd),
                self.nopw(usr, "%s reload nginx" % s_cmd),
                self.nopw(usr, "%s restart nginx" % s_cmd),
                self.nopw(usr, "%s start nginx" % s_cmd),
                self.nopw(usr, "%s status nginx" % s_cmd),
                self.nopw(usr, "%s stop nginx" % s_cmd),
                self.nopw(usr, n_cmd),
                ""
            ]
            self.add_sudoers("1700-%s" % usr,'\n'.join(lines))
            return True
        else:
            self.msg_sudo_not_installed()
            return False

    def add_sudoers(self, fname, content):
        target_sudoers="/etc/sudoers.d/%s" % fname
        if not self.pathexists(target_sudoers):
            tempSudoer = "%s/%s-%s" % (self.tempFolder(),fname, self.timestamp())
            file = self.open(tempSudoer,'w')
            file.write(content)
            file.close()
            self.cp(tempSudoer, target_sudoers, useSudo=self.is_sudo())
            self.history_remove_temp(currentframe().f_lineno)
            self.removeFile(tempSudoer)
            return True
        return True

    def add_zshenv_modification(self):
        # Append the modification lines to .bashrc file
        modification_lines = [
            "\n# modified to add ~/.local/bin to PATH",
            "path+=('%s')" %  os.path.join(self.home(), ".local/bin"),
            "export PATH\n"
        ]
        with self.open(self.zshenv(), "a") as file:
            file.write("\n".join(modification_lines))

    def allowInstallLocal(self, installLocal=None):
        if installLocal is not None:
            self.__allow_install_local__=installLocal
            return self
        elif not hasattr(self,'__allow_install_local__'):
            self.__allow_install_local__=True
        return self.__allow_install_local__

    def allowDisplayInfo(self, state=None):
        if state is not None:
            self.__allow_display_info__=state
            return self
        elif not hasattr(self, '__allow_display_info__'):
            self.__allow_display_info__=True
        return  self.__allow_display_info__

    def allowLinuxOnly(self, state=None):
        if state is not None:
            self.__allow_linux_only__=state
            return self
        elif not hasattr(self,'__allow_linux_only__'):
            self.__allow_linux_only__=False
        return self.__allow_linux_only__

    def allowSelfInstall(self, state=None):
        if state is not None:
            self.__allow_self_install__=state
            return self
        elif not hasattr(self,'__allow_linux_only__'):
            self.__allow_self_install__=True
        return self.__allow_self_install__

    def appExec(self):
        if not hasattr(self, '__app_path__'):
            self.appPath()
        if not hasattr(self, '__app_exec__'):
            self.__app_exec__ = ''
            if self.is_local() or self.isGlobal():
                if self.isCmd() or self.isGitBash():
                    self.__app_exec__ = self.appName() + '.bat'
                else:
                    self.__app_exec__ = self.appName()
            elif self.appPath() != '' :
                if self.isCmd() or self.isGitBash():
                    self.__app_exec__ = self.appName() + '.bat'
                elif self.isLinuxShell():
                    self.__app_exec__='./' + self.appName()
                else:
                    self.__app_exec__='./' + self.appName()
        return self.__app_exec__

    def python2(self, path=None):
        if not hasattr(self,"__python_checked__"):
            self.check_python()
        if not hasattr(self, "__python2__"):
            self.__python2__=""
        if path is not None:
            self.__python2__=path
            return self
        else:
            return self.__python2__

    def python3(self, path=None):
        if not hasattr(self,"__python_checked__"):
            self.check_python()
        if not hasattr(self, "__python3__"):
            self.__python3__=""
        if path is not None:
            self.__python3__=path
            return self
        else:
            return self.__python3__

    def check_python(self):
        self.cmd_history("# ** Checking python version  **")
        python2 = self.which_cmd("python2")
        python3 = self.which_cmd("python3")
        arch = 'x86_64'
        if self.arch() == 'amd64':
            arch = 'x86_64'
        if python2 == '' or python3 == '':
            python = self.which_cmd("python")
            if python != "":
                result , stdout = self.shell(f"{python} --version")
                if result:
                    id_array = stdout.strip().split(' ')
                    if len(id_array) > 1:
                        version_array = id_array[1].split(".")
                        version = version_array[0]
                        if int(version) == 2:
                            python2 = python
                        elif int(version) == 3 and python3=='':
                            python3 = python
                        self.__cython_version__=f"cpython-{version_array[0]}{version_array[1]}-{arch}-linux-gnu"
        self.__python2__ = python2
        self.__python3__ = python3
        if not hasattr(self,"__cython_version__"):
            self.__cython_version__=""
            if self.__python3__ != "":
                result , stdout = self.shell(f"{self.__python3__} --version")
                if result:
                    id_array = stdout.strip().split(' ')
                    if len(id_array) > 1:
                        version_array = id_array[1].split(".")
                        self.__cython_version__=f"cpython-{version_array[0]}{version_array[1]}-{arch}-linux-gnu"
        self.__python_checked__ = True

    def cmd_history(self,cmd=None, line=None):
        if not hasattr(self, '__reg_end_stars__'):
            self.__reg_end_stars__ = re.compile(r"[\*]+\s*$")
        if hasattr(self, "__tick__"):
            self.__diff_time__ = (datetime.now() - self.__tick__).total_seconds()
        else:
            self.__start_time__= datetime.now()
            self.__diff_time__= 0
        self.__tick__=datetime.now()
        if not hasattr(self,'__cmd_history_id__'):
            self.__cmd_history_id__=1
        if not hasattr(self,'__cmd_history__'):
            self.__cmd_history__=["# ====== Command History starting at %s: ======" % self.__tick__]
        if cmd is None:
            return self.__cmd_history__
        else:
            if cmd.startswith("# **"):
                if line is not None:
                    line_at = "--line %d--" % line
                else:
                    line_at = ""
                cmd = self.__reg_end_stars__.sub("",cmd)
                if self.__cmd_history_id__ > 1:
                    self.__cmd_history__.append("  #    ...( %.3f second )" % self.__diff_time__)
                self.__cmd_history__.append("# ** %d. %s %s **" % (self.__cmd_history_id__, cmd[5:], line_at))
                self.__cmd_history_id__ = self.__cmd_history_id__ + 1
            else:
                self.__cmd_history__.append("  %s" % cmd)
        return self

    def cmd_history_print(self, line=None):
        if hasattr(self, "__tick__"):
            self.__diff_time__ = (datetime.now() - self.__tick__).total_seconds()
        else:
            self.__start_time__= datetime.now()
            self.__diff_time__= 0
        end_at = ""
        if line is not None:
            end_at = "--line %d--" % line
        if hasattr(self, '__cmd_history__'):
            self.__cmd_history__.append("  #    ...( %.3f second )" % self.__diff_time__)
        else:            
            self.__cmd_history__=['  #    ... History is empty']
        history = self.cmd_history()
        if hasattr(self, "__start_time__"):
            self.__diff_time__ = (datetime.now() - self.__start_time__).total_seconds()
        else:
            self.__diff_time__= 0
        if len(history) == 0:
            self.infoMsg("Command History: Not Available!", "COMMAND HISTORY")
        else:
            history_list = '\n  '.join(history)
            self.infoMsg("%s\n  # ====== End at %s ...( %.3f second ) %s ======\n" % ( history_list, str(self.__tick__),self.__diff_time__, end_at), "COMMAND HISTORY")

    def appPath(self, path=None):
        if path is not None:
            self.__app_path__=path
            return self
        elif not hasattr(self,'__app_path__'):
            self.__app_path__=''
            if not self.fromPipe() and self.this() != '':
                appPath = os.path.abspath(self.this())
                if not appPath.startswith(self.globalFolder(0)) and not appPath.startswith(self.globalFolder(0)) and not appPath.startswith(self.localInstallFolder()):
                    if self.comparePath(appPath, '%s/%s' % (os.getcwd(),appPath.split("/")[-1])):
                        self.__app_path__="./%s" % appPath.split("/")[-1]
                    elif self.comparePath(appPath, self.which()):
                        self.__app_path__=appPath.split("/")[-1]
                    else:
                        self.__app_path__=appPath
                else:
                    self.__app_path__=appPath.split("/")[-1]
        return self.__app_path__

    def arch(self):
        if not hasattr(self, '__arch__'):
            if self.isCmd():
                self.__arch__ = 'amd64'
            else:
                result2, stdout2 = self.uname_a()
                result, stdout = self.uname_m()
                if result:
                    self.__arch__ = stdout.strip()
                    # "aarch64" and "arm64" are the same thing. AArch64 is the official name for the 64-bit ARM architecture, 
                    # but some people prefer to call it "ARM64" as a continuation of 32-bit ARM.
                    if self.__arch__ == 'arm64':
                        self.__arch__ = 'aarch64'
                    elif 'ARM64' in stdout2:
                        self.__arch__ = 'aarch64'
                    # X86_64 and AMD64 are different names for the same thing
                    elif self.__arch__ == 'x86_64':
                        self.__arch__ = 'amd64'
                else:
                    self.__arch__=''
        return self.__arch__

    def author(self, author=None):
        if author is not None:
            self.__author__=author
            return self
        elif not hasattr(self,'__author__'):
            self.__author__=None
        return self.__author__

    def appName(self, appName=None):
        if appName is not None:
            self.__appName__=appName
            return self
        elif not hasattr(self,'__appName__'):
            self.__appName__=''
        return self.__appName__

    def bashprofile(self):
        return os.path.join(self.home(), ".profile")

    def bashrc(self):
        if self.shellCmd() == '/bin/ash':
            return os.path.join(self.home(), ".profile")
        return os.path.join(self.home(), ".bashrc")

    def binaryVersion(self, version=None):
        if version is not None:
            self.__binary_version__ = version
            return self 
        elif not hasattr(self,'__binary_version__'):
            self.__binary_version__ = ''
        return self.__binary_version__

    def check_env(self):
        if self.shellCmd() == '/bin/zsh':
            self.history_check_zsh(currentframe().f_lineno)
            self.check_and_modify_zshenv()
        elif self.shellCmd() == '/bin/bash':
            self.history_check_bash(currentframe().f_lineno)
            self.check_and_modify_bashrc()
        elif self.shellCmd() == '/bin/ash':
            self.history_check_ash(currentframe().f_lineno)
            self.check_and_modify_bashprofile()

    def check_and_modify_bashprofile(self):
        if not self.is_bashprofile_modified():
            self.add_bashprofile_modification()

    def check_and_modify_bashrc(self):
        if not self.is_bashrc_modified():
            self.add_bashrc_modification()

    def check_and_modify_zshenv(self):
        if not self.is_zshenv_modified():
            self.add_zshenv_modification()

    def check_system(self):
        if self.pythonVersion().split(".")[0] =="3":
            self.pythonName( "python3" )
            major = 3
        else:
            self.pythonName( "python2" )
            major = 2
        minor = int(self.pythonVersion().split(".")[0])
        gcc = sys.version
        self.arch()
        if '\n' in gcc:
            gcc = gcc.split('\n')[1]
        elif '[' in gcc and ']' in gcc:
            gcc = gcc.split('[')[1].split(']')[0]
        if gcc=='GCC':
            gcc= '[GCC]'
        if ' (Red Hat' in gcc:
            gcc = gcc.split(' (Red Hat')[0] + ']'
        if '[PyPy ' in gcc and 'with' in gcc:
            pythonVersion = gcc.split('with')[0].split('[')[1].strip()
            self.pythonVersion("%s (%s)" % (self.pythonVersion(), pythonVersion))
            gcc = '[' + gcc.split('with ')[1]
            if self.pythonName() == "python3":
                self.pythonName( "pypy3")
            else:
                self.pythonName( "pypy" )
        if platform.libc_ver()[0]!='':
                self.libcName( platform.libc_ver()[0] )
        if 'AMD64' in gcc:
            self.__arch__ = 'amd64'
            if 'MSC' in gcc:
                self.libcName('msc')
        elif 'AMD32' in gcc:
            self.libcName('msc')
            self.__arch__ = 'x86'
        if 'clang' in gcc:
            self.libcName('clang')
        self.libcVersion(gcc)
        self.osVersion()
        self.shellCmd()
        self.this()
        self.linuxDistro()
        if self.libcName()  == '' and self.shellCmd() == '/bin/ash':
            self.libcName('muslc')
        if self.arch() != '':
            if self.libcName() == '':
                self.binaryVersion('%s-' % (self.arch()))
            else:
                self.binaryVersion('%s-%s' % (self.arch(), self.libcName()))

    def check_system_and_user(self):
        # is_linux() Check if not windows and not macOS
        if self.allowLinuxOnly() and not self.is_linux():
            self.msg_linux_only()
            return False
        else:
            # root_or_sudo() Check user is root or has sudo privilege
            return self.root_or_sudo()

    def check_update(self):
        if self.need_update():
            self.msg_latest_available()
        elif self.latest_version() != '0.0':
            self.msg_latest()

    def chmod(self, filePath="", switch="", use_history=True, useSudo=False):
        if self.isCmd() or self.isGitBash():
            filePath=self.path_to_dos(filePath)
        if self.pathexists(filePath):
            chmod_cmd = self.which_cmd('chmod')
            cmd=""
            if useSudo:
                if self.sudo_cmd()!="":
                    cmd = '%s %s %s %s' % (self.sudo_cmd(), chmod_cmd,switch,filePath)
            else:                
                cmd = '%s %s %s' % (chmod_cmd,switch,filePath)
            if cmd=="":
                return False                
            if use_history:
                self.cmd_history(cmd)
            result, stdout = self.shell(cmd)
            return result
        return False

    def chown(self, filePath="", owner="", use_history=True, useSudo=False):
        if self.isCmd() or self.isGitBash():
            filePath=self.path_to_dos(filePath)
        if self.pathexists(filePath):
            chown = self.which_cmd('chown')
            cmd=""
            if useSudo:
                if self.sudo_cmd()!="":
                    cmd = '%s %s -R %s %s' % (self.sudo_cmd(), chown,owner,filePath)
            else:                
                cmd = '%s -R %s %s' % (chown,owner,filePath)    
            if cmd=="":
                return False            
            if use_history:
                self.cmd_history(cmd)
            result, stdout = self.shell(cmd)
            return result
        return False
    
    def chmod_x(self, filePath="", use_history=True, useSudo=False):
        return self.chmod(filePath=filePath, switch="+x", use_history=use_history, useSudo=useSudo)

    def cmd(self, cmd=None):
        if cmd is not None:
            self.__cmd__=cmd
            return self
        elif not hasattr(self, '__cmd__'):
            self.__cmd__=False
        return self.__cmd__

    def cmd_list(self, x=None, rstrip=False):
        if not hasattr(self,'__cmdList__'):
            self.__cmdList__=[]
        if x is not None:
            if isinstance(x,list):
                for l in x:
                    if isinstance(l,basestring) and rstrip:
                        self.__cmdList__.append(l.rstrip())
                    else:
                        self.__cmdList__.append(l)
            else:
                self.__cmdList__.append(x)
            return self
        return self.__cmdList__

    def comparePath(self, p1, p2):
        return os.path.abspath(p1)==os.path.abspath(p2)

    def cp(self, filePath1="", filePath2="", use_history=True, useSudo=False):
        cmd = ""
        if self.isCmd() or self.isGitBash():
            filePath1=self.path_to_dos(filePath1)
            filePath2=self.path_to_dos(filePath2)
            cmd = 'copy %s %s' % (filePath1,filePath2)
        else:
            cp = self.which_cmd('cp')
            if useSudo:
                if self.sudo_cmd!="":
                    cmd = 'sudo %s %s %s' % (cp,filePath1,filePath2)
            else:
                cmd = '%s %s %s' % (cp,filePath1,filePath2)
        if cmd=="":
            return False 
        if useSudo:
            self.shell(cmd, ignoreErr=True)
        else:
            shutil.copy(filePath1,filePath2) 
        if self.pathexists(filePath1):
            if use_history:
                self.cmd_history(cmd)
            result, stdout = self.shell(cmd)
            return result
        return False

    def create_user(self, username=None, user_id=None, group_id=None, home=None):
        self.create_group(username, user_id=user_id, group_id=group_id)
        cmd= "id %s" % username
        self.history_check_user_exists(currentframe().f_lineno)
        self.cmd_history(cmd)
        result, stdout = self.shell(cmd, ignoreErr=True)
        if stdout=="":
            cmd = ""
            if home is None:                    
                if self.is_alpine():
                    if self.is_sudo():
                        cmd = "sudo adduser -D -G %s %s" % (group_id, username)
                    else:
                        cmd = "adduser -D -G %s %s" % (group_id, username)
                elif self.is_debian() or self.osVersion().startswith('CentOS') or self.osVersion().startswith('Amazon Linux'):
                    if self.is_sudo():
                        cmd = "sudo useradd -g %d -u %d -m -s /bin/bash %s" % (group_id, user_id, username)
                    else:
                        cmd = "useradd -g %d -u %d -m -s /bin/bash %s" % (group_id, user_id, username)
            else:
                if self.is_alpine():
                    if self.is_sudo():
                        cmd = "sudo adduser -D -G %s -h %s %s" % (username, home, username)
                    else:
                        cmd = "adduser -D -G %s -h %s %s" % (username, home, username)
                elif self.is_debian() or self.osVersion().startswith('CentOS') or self.osVersion().startswith('Amazon Linux'):
                    if self.is_sudo():
                        cmd = "sudo useradd -g %d -u %d -m -d %s -s /bin/bash %s" % (group_id, user_id, home, username)
                    else:
                        cmd = "useradd -g %d -u %d -m -d %s -s /bin/bash %s" % (group_id, user_id, home, username)
            if cmd != "":
                self.history_add_user(username, currentframe().f_lineno)
                self.cmd_history(cmd)
                self.shell(cmd, ignoreErr=True)
        else:
            self.history_user_exists(username, currentframe().f_lineno)
            self.msg_user_found(username)

    def criticalMsg(self,msg,tag=''):
        self.__tag__(tag).__message__(msg) \
            .__timeMsg__(AppBase.BOLD + AppBase.ITALICS + \
            AppBase.DARK_AMBER) \
            .__header__(AppBase.BOLD + AppBase.DARK_AMBER) \
            .__coloredMsg__(AppBase.ITALICS + AppBase.LIGHT_AMBER) \
            .__tagMsg__(AppBase.FLASHING + AppBase.LIGHT_RED,\
            AppBase.LIGHT_AMBER)
        self.prn("%s" % (self.__formattedMsg__()))
        return self

    def curl_cmd(self, url='', file='', switches='-fsSL',  ignoreErr=True):
        stderr = 'Unknown Error'
        stdout = ''
        if self.isLinuxShell():
            curl = self.which_cmd('curl')
            if url!='' and file!='':
                cmd = ' '.join([curl,switches,'-o',file, url])
                self.cmd_history(cmd)
                stdout,stderr = Popen([curl,switches,'-o',file, url],stdin=PIPE,stdout=PIPE,\
                    stderr=PIPE,universal_newlines=True).communicate('\n')
            elif url!='':
                cmd = ' '.join([curl,switches,url])
                self.cmd_history(cmd)
                stdout,stderr = Popen([curl,switches,url],stdin=PIPE,stdout=PIPE,\
                    stderr=PIPE,universal_newlines=True).communicate('\n')
        elif self.isGitBash():
            winpty = self.where_cmd('winpty.exe')
            curl = self.where_cmd('curl.exe')
            if url!='' and file!='':
                file=self.path_to_dos(file)
                cmd = ' '.join([winpty,curl,switches,'-o',file, url])
                self.cmd_history(cmd)
                stdout,stderr = Popen([winpty,curl,switches,'-o',file, url],stdin=PIPE,stdout=PIPE,\
                    stderr=PIPE,universal_newlines=True).communicate('\n')
                if stderr.strip().lower() == 'stdin is not a tty':
                    cmd = ' '.join([curl,switches,'-o',file, url])
                    self.cmd_history(cmd)
                    stdout,stderr = Popen([curl,switches,'-o',file, url],stdin=PIPE,stdout=PIPE,\
                        stderr=PIPE,universal_newlines=True).communicate('\n')
            elif url!='':
                cmd = ' '.join([winpty,curl,switches, url])
                self.cmd_history(cmd)
                stdout,stderr = Popen([winpty,curl,switches,url],stdin=PIPE,stdout=PIPE,\
                    stderr=PIPE,universal_newlines=True).communicate('\n')
                if stderr.strip().lower() == 'stdin is not a tty':
                    cmd = ' '.join([curl,switches, url])
                    self.cmd_history(cmd)
                    stdout,stderr = Popen([curl,switches,url],stdin=PIPE,stdout=PIPE,\
                        stderr=PIPE,universal_newlines=True).communicate('\n')
        elif self.isCmd():
            curl = self.where_cmd('curl.exe')
            if url!='' and file!='':
                cmd = ' '.join([curl,switches,'-o',file, url])
                self.cmd_history(cmd)
                stdout,stderr = Popen([curl,switches,'-o',file, url],stdin=PIPE,stdout=PIPE,\
                    stderr=PIPE,universal_newlines=True).communicate('\n')
            elif url!='':
                cmd = ' '.join([curl,switches,url])
                self.cmd_history(cmd)
                stdout,stderr = Popen([curl,switches,url],stdin=PIPE,stdout=PIPE,\
                    stderr=PIPE,universal_newlines=True).communicate('\n')
        elif url!='':
            # Assume /bin/sh as default shell
            curl = self.which_cmd('curl')
            if url!='' and file!='':
                cmd = ' '.join([curl,switches,'-o',file, url])
                self.cmd_history(cmd)
                stdout,stderr = Popen([curl,switches,'-o',file, url],stdin=PIPE,stdout=PIPE,\
                    stderr=PIPE,universal_newlines=True).communicate('\n')
            elif url!='':
                cmd = ' '.join([curl,switches,url])
                self.cmd_history(cmd)
                stdout,stderr = Popen([curl,switches,url],stdin=PIPE,stdout=PIPE,\
                    stderr=PIPE,universal_newlines=True).communicate('\n')
        if stderr != "" and not ignoreErr:
            self.msg_error(cmd, stderr)
            return False, stderr
        return True, stdout

    def curl_download(self, url='', file='', ignoreErr=True):
        self.history_curl_check(currentframe().f_lineno)
        if self.curl_is_200(url):
            self.history_curl_download(currentframe().f_lineno)
            self.curl_cmd(url=url, file=file, ignoreErr=ignoreErr)
            if file == '':
                return True
            if file !='' and not self.pathexists(file):
                count=20
                # In gitbash, downloading time may be longer
                self.msg_downloading(file)
                while count>0 and  not self.pathexists(file):
                    count = count - 1
                    time.sleep(1) # wait for curl download the file
            if file !='' and self.pathexists(file):
                return True
            elif ignoreErr:
                return True
            else:
                self.msg_timeout(file)
                return False
        return False

    def curl_is_200(self, url):
        result, stdout = self.curl_cmd(url=url, switches='-fsSLI', ignoreErr=True)
        if result:
            result = False
            for rawline in stdout.splitlines():
                line = rawline.strip()
                if 'HTTP' in line.strip():
                    line_split=line.split(' ')
                    if len(line_split) > 1:
                        if  '200' == line_split[1] or '301' == line_split[1] or '302' == line_split[1]:
                            return True
                        else:
                            self.msg_download_url_error(url, line_split[1])
                            return False
        return result

    def curPath(self, curPath=None):
        if curPath is not None:
            self.__curPath__=curPath
            return self
        elif not hasattr(self, '__curPath__'):
            pw='%s' % os.getcwd()
            if self.isGitBash() and ':' in pw:
                pw=pw.split(':')
                self.__curPath__='/'+pw[0]+'/'.join(pw[1].split('\\'))
            else:
                self.__curPath__=pw
        return self.__curPath__

    def download_to_temp(self, url=None, file=None,verbal = False):
        # msg_system_check(), this message only shown when downloading files
        if self.tempFolder() == "":
            return False
        self.msg_system_check()
        if url is None:
            url=self.downloadUrl()
        if file is None:
            file=self.tempFile()
        result = self.curl_download(url=url, file=file)
        if not self.pathexists(file):
            result = False
            self.msg_download_error(file)
        elif verbal:
            self.msg_downloaded(file)
        return result

    def download_and_install(self, verbal = False):
        if self.tempFolder() == "":
            return False
        if self.targetApp() != '':
            if self.username() == 'root' or  not self.isGlobal():
                result = self.download_and_install_target()
            else:
                self.msg_global_already()
                return False                
        else:
            result=True
        if result:
            fname = self.tempFile()
            self.download_to_temp(verbal=False)
            if self.pathexists(fname):
                if not self.install(this=fname, verbal=False):
                    return False
                if verbal:
                    self.cmd_history_print(currentframe().f_lineno)
                if result and verbal:
                    if self.targetApp() != '':
                        if self.username() == 'root':
                            self.msg_install_target_global()
                        else:
                            self.msg_install_target_local()
                    else:
                        if self.username() == 'root':
                            self.msg_install_app_global()
                        else:
                            self.msg_install_app_local()
                return result
            else:
                self.msg_download_not_found(fname)
        return False

    def chdir(self, path, line_num=None):
        if self.isCmd() or self.isGitBash():
            self.history_cd(self.path_to_dos(path), line_num)
            os.chdir(self.path_to_dos(path))
        else:
            self.history_cd(path, line_num)
            os.chdir(path)

    def download_and_install_target(self):
        tempFolder = self.tempFolder()
        if self.targetApp() == '' or tempFolder=="":
            return False
        fname = self.tempTargetGzip()
        self.download_to_temp(url=self.tempAppUrl(), file=fname, verbal=False)
        if self.pathexists(fname):
            self.history_cd_decompress(currentframe().f_lineno)
            self.chdir(tempFolder, currentframe().f_lineno)
            if self.isCmd() or self.isGitBash():
                self.tar_extract( self.path_to_dos(fname).split('\\')[-1] )
            else:
                self.tar_extract(fname.split('/')[-1])
            self.history_remove_downloaded(currentframe().f_lineno)
            self.removeFile(fname)
            if self.isCmd() or self.isGitBash():
                this = "%s.exe" % self.tempAttachDecomp()
            else:
                this = self.tempAttachDecomp()
            if self.pathexists(this):
                self.this(this)
                if self.username() == 'root':
                    self.install_target_global(this, useSudo=False)
                else:
                    self.install_target_local(this)
                return True
            else:
                self.cmd_history_print(currentframe().f_lineno)
                self.msg_extraction_error(this)
                return False
        else:
            self.msg_download_error(self.tempTargetGzip())
            return False

    def downloadHost(self):
        if self.downloadUrl() == '':
            return ''
        x = re.search("https:..([^/]+)", self.downloadUrl())
        if x:
            return x.group(1)
        else:
            ''

    def downloadUrl(self, downloadUrl=None):
        if downloadUrl is not None:
            self.__downloadUrl__=downloadUrl
            return self
        elif not hasattr(self,'__downloadUrl__'):
            self.__downloadUrl__=None
        return self.__downloadUrl__

    def duplication_warning(self):
        if self.installedLocal() and self.installedGlobal():
            self.msg_both_local_global()

    def executable(self):
        if hasattr(self, '__executable__'): 
            return self.__executable__
        if '/' in sys.executable:
            self.__executable__  = sys.executable.split('/')[-1]
        elif '\\'  in sys.executable:
            self.__executable__  = sys.executable.split('\\')[-1]
        else:
            self.__executable__ = ''
        return self.__executable__ 

    def findConfig(self, ini_name='cy-master.ini'):
        pathToken = os.path.abspath(".").split('/')
        path = "/".join(pathToken)
        self.configFile( "" )
        while len(pathToken) > 0:
            path = "/".join(pathToken)
            pathToken.pop()
            if path == '' :
                configFile = f'/{ini_name}'
            else :
                configFile = f"{path}/{ini_name}" 
            if self.pathexists( configFile ) :
                self.infoMsg("Configuation file: '%s' !" % configFile, "CONFIG FOUND")
                self.configFile( configFile )
                self.projectPath( path )
                return True
        return False

    def fromPipe(self):
        return self.thisFile() == '<stdin>'

    def globalFolder(self, id=1):
        path = ['/usr/bin','/usr/local/bin']
        if id>=0 and id<2:
            return path[id]
        return ''

    def globalInstallPath(self, id=1):
        folder = self.globalFolder(id)
        if folder[-1] == '/':
            return '%s%s' % (folder, self.appName())
        else:
            return '%s/%s' % (folder, self.appName())

    def globalInstallTargetPath(self, id=1):
        if self.targetApp() == '':
            return ''
        folder = self.globalFolder(id)
        if folder[-1] == '/':
            return '%s%s' % (folder, self.targetApp())
        else:
            return '%s/%s' % (folder, self.targetApp())

    def hasGlobalInstallation(self):
        return  self.pathexists(self.globalInstallPath(0)) or self.pathexists(self.globalInstallPath(1)) 

    def home(self):
        return os.path.expanduser("~")

    def homepage(self, homepage=None):
        if homepage is not None:
            self.__homepage__=homepage
            return self
        elif not hasattr(self,'__homepage__'):
            self.__homepage__=None
        return self.__homepage__

    def infoMsg(self,msg,tag=''):
        self.__tag__(tag).__message__(msg) \
            .__timeMsg__(AppBase.BOLD+AppBase.ITALICS+AppBase.DARK_BLUE) \
            .__header__(AppBase.BOLD+AppBase.DARK_BLUE) \
            .__coloredMsg__(AppBase.ITALICS + AppBase.LIGHT_BLUE) \
            .__tagMsg__(AppBase.LIGHT_AMBER,AppBase.LIGHT_BLUE)
        self.prn("%s" % (self.__formattedMsg__()))
        return self

    def install(self, this, verbal=False):
        if self.username() == 'root':
            return self.__self_install__(this=this, verbal=verbal)
        elif not self.isGlobal():
            return self.__install_local__(this=this, verbal=verbal)
        else:
            self.msg_global_already()
            return False

    def install_libcrypto(self):
        if self.osVersion().startswith('Alpine'):
            result = self.install_package('libcrypto1.1', ['/usr/lib/libcrypto.so'])
        else:
            result = self.install_package('libssl-dev', ['/usr/lib/x86_64-linux-gnu/libcrypto.so'])
        return result

    def install_libinih(self):
        if self.is_alpine():
            result = self.install_package('inih-dev', ['/usr/lib/libinih.so'])
        else:
            result = self.install_package('libinih-dev', ['/usr/lib/x86_64-linux-gnu/libinih.so'])
        return result

    def install_libpcre2(self):
        if self.is_alpine():
            result = self.install_package('pcre2-dev', ['/usr/lib/libpcre2-8.so.0'])
        else:
            result = self.install_package('libpcre2-dev', ['/usr/lib/x86_64-linux-gnu/libpcre2-32.so'])
        return result

    def install_libsqlite3_dev(self):
        if self.is_alpine():
            result = self.install_package('sqlite-dev', ['/usr/lib/libsqlite3.so'])
        else:
            result = self.install_package('libsqlite3-dev', ['/usr/lib/x86_64-linux-gnu/libsqlite3.so'])
        return result

    def install_libsqlite3(self):
        result = self.install_package('sqlite3', ['/usr/bin/sqlite3'])
        return result

    def install_local(self, verbal = True):
        if self.thisFile().endswith(".so"):
            return self.__install_local__(self.this(), verbal)
        else:
            return self.__install_local__(self.thisFile(), verbal)

    def install_package(self, package=None, path=None):
        # root_or_sudo() Check user is root or has sudo privilege and assuming linux
        if not self.root_or_sudo():
            return False
        installed = False
        if path is not None and package is not None:
            self.history_check_exists(package, currentframe().f_lineno)
            if isinstance(path,basestring):
                if self.pathexists(path, use_history=True):
                    self.history_package_exists(package, currentframe().f_lineno)
                    return True
            elif isinstance(path,list):
                for l in path:
                    if self.pathexists(l, use_history=True):
                        self.history_package_exists(package, currentframe().f_lineno)
                        return True
        if self.update_repository():
            if self.is_debian():
                self.history_install_package(package, currentframe().f_lineno)
                if self.is_sudo():
                    cmd = "sudo apt install -y %s" % package
                else:
                    cmd = "apt install -y %s" % package
                self.cmd_history(cmd)
                self.shell(cmd, ignoreErr=True)
                installed = True
            elif self.is_alpine():
                self.history_install_package(package, currentframe().f_lineno)
                if self.is_sudo():
                    cmd = "sudo apk add %s" % package
                else:
                    cmd = "apk add %s" % package
                self.cmd_history(cmd)
                self.shell(cmd, ignoreErr=True)
                installed = True
            elif self.is_redhat():
                if self.is_sudo():
                    cmd = "sudo yum install -y %s" % package
                else:
                    cmd = "yum install -y %s" % package
                self.cmd_history(cmd)
                self.shell(cmd, ignoreErr=True)
                installed = True
            elif self.is_fedora():
                if self.is_sudo():
                    cmd = "sudo dnf install -y %s" % package
                else:
                    cmd = "dnf install -y %s" % package
                self.cmd_history(cmd)
                self.shell(cmd, ignoreErr=True)
                installed = True
            elif self.is_opensuse():
                if self.is_sudo():
                    cmd = "sudo zypper install -y %s" % package
                else:
                    cmd = "zypper install -y %s" % package
                self.cmd_history(cmd)
                self.shell(cmd, ignoreErr=True)
                installed = True
            else:
                self.cmd_history("  # Not compatible OS")
                self.msg_not_compatible_os()
            if installed:
                if path is not None and package is not None:
                    if isinstance(path,basestring):
                        if self.pathexists(path):
                            installed = True
                    elif isinstance(path,list):
                        for l in path:
                            if self.pathexists(l):
                                installed = True
                else:
                    installed = False
        return installed

    def install_python_dev(self):
        if self.python2() != '':
            self.cmd_history("  # python2 found! ")
            if self.is_alpine():
                self.install_package('python2-dev')
            elif self.is_debian():
                self.install_package('python-dev')
            elif self.is_fedora():
                self.install_package('python2-devel')
            elif self.is_redhat():
                self.install_package('python-devel')    
            elif self.is_opensuse():
                self.install_package('python-devel')
            else:
                self.install_package('python-devel')
        if self.python3() != '':
            self.cmd_history("  # python3 found")
            if self.is_alpine():
                self.install_package('python3-dev')
            elif self.is_debian():
                self.install_package('python3-dev')
            elif self.is_fedora():
                self.install_package('python3-devel')
            elif self.is_redhat():
                self.install_package('python3-devel')
            elif self.is_opensuse():
                self.install_package('python3-devel')
            else:
                self.install_package('pytho3-devel')
        if self.python3() == '' and self.python2() == '':
            self.cmd_history("  # Both python2 and python3 not found! ")


    def install_python_package(self, package=None):
        self.history_install_package('jupyter', currentframe().f_lineno)
        if self.is_ubuntu() and self.os_major_version()>22:
            cmd = 'pip3 install --upgrade --break-system-packages %s' % package
        elif self.osVersion().startswith('Debian') and self.os_major_version()>11:
            cmd = 'pip3 install --upgrade --break-system-packages %s' % package
        else:
            cmd = 'pip3 install --upgrade %s' % package
        self.cmd_history(cmd)
        self.shell(cmd,ignoreErr=True)

    def installedGlobal(self):
        return self.pathexists(self.globalInstallPath(0)) or self.pathexists(self.globalInstallPath(1)) 

    def installedLocal(self):
        which = self.which()
        if which == '':    
            return False
        if self.isCmd() or self.isGitBash():
            return self.path_to_dos(which) == self.path_to_dos(self.localInstallPath())
        return which == self.localInstallPath()

    def install_jupyter(self):
        result = self.install_package('gcc', ['/usr/bin/gcc'])
        result = self.install_package('python3-dev',['/usr/include/python3.8/Python.h','/usr/include/python3.9/Python.h','/usr/include/python3.10/Python.h','/usr/include/python3.11/Python.h','/usr/include/python3.12/Python.h'])
        if self.is_alpine():
            result = self.install_package('musl-dev',['/usr/include/stdio.h'])
            result = self.install_package('py3-pip', ['/usr/bin/pip3'])
        else:
            result = self.install_package('python3-pip', ['/usr/bin/pip3'])
        if result:
            self.install_python_package('jupyter')
            self.install_python_package('jupyterhub')
        if result:
            result = self.install_package('nginx', ['/usr/sbin/nginx','/usr/bin/nginx'])
        if result:
            if self.is_alpine():
                self.rc_update('nginx')
        return result

    def install_nginx_admin(self):
        # root_or_sudo() Check user is root or has sudo privilege and assuming linux
        if not self.root_or_sudo():
            return False
        if self.install_package('nginx', ['/usr/sbin/nginx','/usr/bin/nginx']):
            if self.is_alpine():
                self.add_apk_community()
                self.install_package('sudo')
            self.create_user(username="nginx-adm", user_id=1700, group_id=1700, home="/opt/nginx-adm")
            self.history_change_ownership_of_folder(currentframe().f_lineno)
            self.chown("/etc/nginx", "nginx-adm:nginx-adm", useSudo=self.is_sudo())
            self.history_create_soft_link(currentframe().f_lineno)
            if self.is_alpine():
                self.ln("/etc/nginx/http.d", "/opt/nginx-adm/", useSudo=self.is_sudo())
                result = self.add_alpine_nginx_adm_sudoer()
            else:
                if self.is_debian():
                    self.ln("/etc/nginx/sites-available", "/opt/nginx-adm/", useSudo=self.is_sudo())
                    self.ln("/etc/nginx/sites-enabled", "/opt/nginx-adm/", useSudo=self.is_sudo())
                else:
                    self.ln("/etc/nginx/conf.d", "/opt/nginx-adm/", useSudo=self.is_sudo())                    
                result = self.add_nginx_adm_sudoer()
            return result
        return True

    def install_target_global(self, this, useSudo=False):
        if self.targetApp() != '':
            file1 = self.globalInstallTargetPath(0)
            file2 = self.globalInstallTargetPath(1)
            self.history_remove_previous_global(currentframe().f_lineno)
            self.sudoRemoveFile( file1 )
            self.sudoRemoveFile( file2 )
        if self.pathexists(self.globalFolder(0)):
            self.history_copy_uncompressed(currentframe().f_lineno)
            self.cp(this,file1,useSudo=useSudo)
            if not self.isCmd() and not self.isGitBash():
                self.history_change_target_mode(currentframe().f_lineno)
                self.chmod_x(file1, useSudo=useSudo)
        elif self.pathexists(self.globalFolder(1)):
            self.history_copy_uncompressed(currentframe().f_lineno)
            self.cp(this,file2,useSudo=useSudo)
            if not self.isCmd() and not self.isGitBash():
                self.history_change_target_mode(currentframe().f_lineno)
                self.chmod_x(file2, useSudo=useSudo)
        if this.startswith('/tmp') or self.isGitBash() or self.isCmd():
            self.history_remove_uncompressed(currentframe().f_lineno)
            self.removeFile(this)

    def install_target_local(self, this):
        self.mkdir( self.localInstallFolder() )
        if self.targetApp() != '':
            self.history_remove_previous_local(currentframe().f_lineno)
            self.removeFile(self.localTargetInstallPath())
        self.history_copy_uncompressed(currentframe().f_lineno)
        self.cp(this, self.localInstallFolder())
        if not self.isCmd() and not self.isGitBash():
            self.history_change_target_mode(currentframe().f_lineno)
            result = self.chmod_x(self.localTargetInstallPath())
        if this.startswith('/tmp') or self.isCmd() or self.isGitBash():
            self.history_remove_downloaded(currentframe().f_lineno)
            self.removeFile(this)
        self.check_env()

    def create_group(self, groupname=None, user_id=None, group_id=None):
        cmd= "getent group %s" %  groupname
        self.history_check_group_exists(currentframe().f_lineno)
        self.cmd_history(cmd)
        result, stdout = self.shell(cmd)
        if group_id is None and not (user_id is None):
            group_id = user_id
        if stdout=="":
            cmd = ""
            if self.is_alpine():
                if self.is_sudo():
                    cmd = "sudo addgroup -g %d %s" % (group_id, groupname)
                else:
                    cmd = "addgroup -g %d %s" % (group_id, groupname)
            elif self.is_debian() or self.osVersion().startswith('CentOS') or self.osVersion().startswith('Amazon Linux'):
                if self.is_sudo():
                    cmd = "sudo groupadd -g %d %s" % (group_id, groupname)
                else:
                    cmd = "groupadd -g %d %s" % (group_id, groupname)
            if cmd != "":
                self.history_add_group(groupname, currentframe().f_lineno)
                self.cmd_history(cmd)
                self.shell(cmd, ignoreErr=True)
        else:
            self.history_group_exists(groupname, currentframe().f_lineno)
            self.msg_user_group_found(groupname)

    def is_alpine(self):
        return self.osVersion().startswith('Alpine')

    def is_bashprofile_modified(self):
        # Check if .bashrc file exists and if it contains the modification lines
        if not os.path.isfile(self.bashrc()):
            return False
        with self.open(self.bashrc(), "r") as file:
            contents = file.read()
        
        return "# modified to add ~/.local/bin to PATH" in contents

    def is_bashrc_modified(self):
        # Check if .bashrc file exists and if it contains the modification lines
        if not os.path.isfile(self.bashrc()):
            return False
        
        with self.open(self.bashrc(), "r") as file:
            contents = file.read()
        
        return "# modified to add ~/.local/bin to PATH" in contents

    def is_debian(self):
        return self.osVersion().startswith('Ubuntu') or self.osVersion().startswith('Debian') or self.osVersion().startswith('Raspbian')

    def is_docker_container(self):
        if not hasattr(self, '__is_container__'):
            self.__is_container__=self.pathexists('/.dockerenv')
        return self.__is_container__

    def is_fedora(self):
        return self.osVersion().startswith('Amazon') or self.osVersion().startswith('Fedora')

    def is_linux(self):
        return not (self.osVersion()=='windows' or self.osVersion()=='macOS' or self.osVersion().startswith('macOS'))

    def is_mac(self):
        return self.osVersion()=='macOS'

    def is_ubuntu(self):
        return self.osVersion().startswith('Ubuntu')

    def is_zshenv_modified(self):
        # Check if .zshenv file exists and if it contains the modification lines
        if not os.path.isfile(self.zshenv()):
            return False
        
        with self.open(self.zshenv(), "r") as file:
            contents = file.read()
        
        return "# modified to add ~/.local/bin to PATH" in contents

    def isCmd(self):
        if not hasattr(self, '__is_cmd__'):
            if not hasattr(self, '__shell_cmd__'):
                self.shellCmd()
            self.__is_cmd__ = self.__shell_cmd__.split('\\')[-1] == 'cmd.exe' 
        return self.__is_cmd__

    def isGitBash(self):
        if not hasattr(self, '__is_gitbash__'):
            if not hasattr(self, '__shell_cmd__'):
                self.shellCmd()
            self.__is_gitbash__ = self.__shell_cmd__.split('\\')[-1] == 'bash.exe' 
        return self.__is_gitbash__

    def isGlobal(self):
        if not hasattr(self,'__is_global__'):
            if self.thisFile().endswith(".so"):
                this=self.this() 
            else:
                this=self.thisFile() 
            if this=='' or this=='<stdin>':
                if self.pathexists(self.globalInstallPath(0)) or self.pathexists(self.globalInstallPath(1)):
                    return True 
                else:
                    return False
            else:
                self.__is_global__ = this== self.globalInstallPath(0) or this == self.globalInstallPath(1)
        return self.__is_global__

    def isLinuxShell(self):
        return self.shellCmd() == '/bin/bash' or self.shellCmd() == '/bin/zsh' or \
            self.shellCmd() == '/bin/sh' or self.shellCmd() == '/bin/ash' or \
            self.shellCmd() == '/usr/bin/fish'

    def is_local(self):
        if not hasattr(self, '__is_local__'):
            if self.thisFile().endswith(".so"):
                self.__is_local__=self.this() == self.localInstallPath()
            else:
                self.__is_local__=self.thisFile() == self.localInstallPath()
        return self.__is_local__

    def is_opensuse(self):
        return self.osVersion().startswith('openSUSE')

    def is_redhat(self):
        return self.osVersion().startswith('CentOS') or self.osVersion().startswith('Red Hat')

    def is_sudo(self, sudo=None):
        if sudo is not None:
            self.__isSudo__=sudo
            return self
        elif not hasattr(self, '__isSudo__'):
            self.__isSudo__=False
        return self.__isSudo__

    def is_latest(self, major1, major2, minor1, minor2, patch1=0, patch2=0):
        # check 1 is latest, 2 as reference
        return major1>major2 or (major1==major2 and minor1>minor2) or (major1==major2 and minor1==minor2 and patch1>patch2)

    def latest_version(self):
        useRequest = False
        try:
            if not hasattr(self,'__latest_version__'):
                majorVersion = 0
                minorVersion = 0
                lines = []
                result, stdout = self.curl_cmd( url=self.downloadUrl())
                if result:
                    lines = stdout.splitlines()
                for line in lines:
                    if 'setInstallation' in line and self.appName() in line:
                        for token in line.split(')')[0].split(','):
                            if 'majorVersion' in token:
                                majorVersion = int(token.split('=')[1])
                            if 'minorVersion' in token:
                                minorVersion = int(token.split('=')[1])
                self.__latest_version__="%d.%d" % (majorVersion,minorVersion)
                self.__need_update__=self.is_latest(majorVersion, self.majorVersion(), minorVersion, self.minorVersion())
        except:
            self.msg_no_server()
        if not hasattr(self,'__latest_version__'):
            self.__latest_version__='0.0'
        return self.__latest_version__

    def lastUpdate(self, lastUpdate=None):
        if lastUpdate is not None:
            self.__lastUpdate__=lastUpdate
            return self
        elif not hasattr(self,'__lastUpdate__'):
            self.__lastUpdate__=None
        return self.__lastUpdate__

    def libcName(self, name=None):
        if name is not None:
            self.__libc_name__ = name
            return self
        elif not hasattr(self, '__libc_name__'):
            self.__libc_name__ = ''
        return self.__libc_name__

    def libcVersion(self, version=None):
        if version is not None:
            self.__libc_version__ = version
            return self
        elif not hasattr(self, '__libc_version__'):
            self.__libc_version__ = ''
        return self.__libc_version__

    def linuxDistro(self):
        if not hasattr(self, '__distro__'):
            self.__distro__=''
            self.__os_major__=0
            self.__os_minor__=0
            if os.path.isfile("/etc/os-release"):
                fin = self.open("/etc/os-release", "rt", use_history=False)
                self.__distro__ = ''
                for line in fin:
                    line = line.strip()
                    if line.startswith('PRETTY_NAME='):
                        if '"' in line:
                            self.__distro__ = line.split('"')[1]
                        else:
                            self.__distro__ = line.split('=')[1]
                    if line.startswith('VERSION_ID='):
                        if '"' in line:
                            version_id = line.split('"')[1]
                        else:
                            version_id = line.split('=')[1]
                        if "." in version_id:
                            major = version_id.split(".")[0]
                            minor = version_id.split(".")[1]
                            if major.isdigit():
                                self.__os_major__=int(major)
                            if minor.isdigit():
                                self.__os_minor__=int(minor)
                        elif version_id.isdigit():
                            self.__os_major__=int(version_id)
                if 'Alpine' in self.__distro__:
                    self.shellCmd("/bin/ash")
        return self.__distro__

    def ln(self, source="", target="", use_history=True, useSudo=False):
        if self.isCmd():
            self.msg_wrong_shell('ln')
            return False
        if self.isGitBash():  
            filePath=self.path_to_dos(source)
        if self.pathexists(source, use_history=True):
            source_split = source.split('/')
            if len(source_split) > 0:
                last_part=source_split[len(source_split) - 1]
                if target[-1] == '/':
                    test_path = '%s%s' % (target,last_part)
                else:
                    test_path = '%s/%s' % (target,last_part)
                if self.pathexists(test_path, use_history=True):
                    self.history_link_exists(test_path, currentframe().f_lineno)
                else:
                    cmd = ""
                    ln_cmd = self.which_cmd('ln')
                    if useSudo:
                        if self.sudo_cmd() != "":
                            cmd = '%s %s -s %s %s' % (self.sudo_cmd(),ln_cmd,source,target)
                    else:                
                        cmd = '%s -s %s %s' % (ln_cmd,source,target)
                    if cmd=="":
                        return False
                    if use_history:
                        self.cmd_history(cmd)
                    result, stdout = self.shell(cmd)
                    return result
        return False

    def local(self):
        return socket.gethostname()

    def localInstallFolder(self):
        if self.isCmd() or self.isGitBash():
            return 'C:\\Users\\%s\\AppData\\Local\\Microsoft\\WindowsApps' % self.username()
        else:  
            return os.path.abspath('%s/.local/bin' % self.home())

    def localInstallPath(self):
        if self.isCmd() or self.isGitBash():
            return '%s\\%s.bat' % (self.localInstallFolder(), self.appName())
        else:
            return os.path.abspath('%s/%s' % (self.localInstallFolder(), self.appName()))

    def localTargetInstallPath(self):
        if self.isCmd() or self.isGitBash():
            return '%s\\%s.exe' % (self.localInstallFolder(), self.targetApp())
        else:
            return os.path.abspath('%s/%s' % (self.localInstallFolder(), self.targetApp()))

    def majorVersion(self, majorVersion=None):
        if majorVersion is not None:
            self.__majorVersion__=majorVersion
            return self
        elif not hasattr(self,'__majorVersion__'):
            self.__majorVersion__=0
        return self.__majorVersion__

    def minorVersion(self, minorVersion=None):
        if minorVersion is not None:
            self.__minorVersion__=minorVersion
            return self
        elif not hasattr(self,'__minorVersion__'):
            self.__minorVersion__=0
        return self.__minorVersion__

    def mkdir(self, path):
        if not self.pathexists( path ):
            if self.osVersion() == 'windows':
                dir_split = path.split('\\')
                dirloc = dir_split[0]
                for dirlet in dir_split[1:]:
                    self.cmd_history("md %s" % path)
                    if dirlet != '':
                        dirloc = dirloc + '\\' + dirlet
                        if not self.pathexists(dirloc):
                            os.mkdir( dirloc )
            else:
                self.cmd_history("mkdir -p %s" % path)
                dir_split = path.split('/')
                dirloc = ''
                for dirlet in dir_split:
                    if dirlet != '':
                        dirloc = dirloc + '/' + dirlet
                        if not self.pathexists(dirloc):
                            try:
                                os.mkdir( dirloc )
                            except:
                                self.msg_permission_denied(dirloc)
                                return False
            return True
        return True

    def need_update(self):
        if not hasattr(self,'__need_update__'):
            self.__need_update__=False
            self.latest_version()
        return self.__need_update__

    def nopw(self, user, cmd):
        return "%s ALL=(ALL) NOPASSWD: %s" % (user, cmd)

    def now(self):
        return str(datetime.now())

    def open(self, fname="", sw="", use_history=True):
        if self.isGitBash() or self.isCmd():
            fname = self.path_to_dos(fname)
        if use_history:
            cmd='# python> open("%s", "%s")' % (fname,sw)
            self.cmd_history(cmd)
        return open(fname, sw)

    def osVersion(self):
        if self.pathexists("/etc/os-release"):
            self.linuxDistro()
        if hasattr(self,'__distro__'):
            return self.__distro__
        self.__distro__  = ''
        if os.name == 'nt':
            self.__distro__='windows'
        elif self.shellCmd() != '':
            result, stdout = self.shell(command=["sw_vers","-productName"],ignoreShell=True)
            if result:
                self.__distro__ = stdout.strip()
        return self.__distro__

    def os_major_version(self):
        if not hasattr(self, '__os_major__'):
            self.__os_major__=0
            self.linuxDistro()
        return self.__os_major__

    def os_minor_version(self):
        if not hasattr(self, '__os_minor__'):
            self.__os_minor__=0
            self.linuxDistro()
        return self.__os_minor__

    def path_to_dos(self, path):
        # Avoid doing any os.path.realpath conversion
        split_path=path.split('/')
        count=0
        result=''
        for pathlet in split_path:
            # Avoid repeatively adding c:, it should not been there
            if pathlet!= '' and pathlet[-1] != ':':
                count = count + 1
                if count == 1:
                    if len(pathlet) == 1:
                        result = pathlet + ':'
                    else:
                        result = pathlet
                else:
                    result = result + '\\' + pathlet
        return result

    def parseArgs(self, usage=None):
        if usage is None:
            usage = self.usage()
        if self.appPath() != '' :
            if len(sys.argv) > 1:
                self.cmd(sys.argv[1])
                if self.cmd()== "help": 
                    self.help()
                    return True
                elif self.cmd() == "self-install" or self.cmd() == "install" or self.cmd() == "update":
                    self.start_install()
                    return True
                elif self.cmd() == "cython-string":
                    self.prn(self.cythonVersion()) 
                    return True
                elif self.cmd() == "check-system":
                    self.msg_system_check()
                    return True
                elif self.cmd() == "this":
                    self.prn(self.this()) 
                    return True
                elif self.cmd() == "this-file":
                    self.prn(self.thisFile())
                    return True
                elif self.cmd() == "download":
                    self.download_to_temp(verbal=True)
                    return True
                elif self.cmd() == "download-app" or self.cmd() == "download-target-app":
                    self.download_to_temp(url=self.tempAppUrl(), file=self.tempTargetGzip(), verbal=True)
                    return True
                elif self.cmd() == "global-installation-path":
                    self.prn(self.globalInstallPath(0))
                    self.prn(self.globalInstallPath(1))
                    return True
                elif self.cmd() == "local-installation-path":
                    self.prn(self.localInstallPath())
                    return True
                elif self.cmd() == "os-major-version":
                    self.prn(self.os_major_version())
                    return True
                elif self.cmd() == "timestamp":
                    self.prn(self.timestamp())
                    return True
                elif self.cmd() == "today":
                    self.prn(self.today())
                    return True
                elif self.cmd() == "uninstall":
                    self.selfUninstall(verbal=True)
                    return True
                elif self.cmd() == "check-update" or self.cmd() == "check-version"  or self.cmd() == "check":
                    self.check_update()
                    return True
                elif self.allowDisplayInfo():
                    self.msg_info(usage)
                    return True
            elif self.allowDisplayInfo():
                self.msg_info(usage)
                return True
        elif self.allowSelfInstall():
            if self.fromPipe():
                result = self.download_and_install(verbal=False)
                if hasattr(self,"requisite") and callable(self.requisite):
                    self.requisite()
                self.cmd_history_print(currentframe().f_lineno)
                if not result:
                    self.msg_installation_failed()
                return True
        return False

    def pathexists(self, path, use_history=False):
        if self.isGitBash():
            path=self.path_to_dos(path)
        if use_history:
            if self.isCmd():
                self.history_dir(path)
            else:
                self.history_ls(path)
        return os.path.exists(path)

    def pid(self):
        return os.getpid()

    def prn(self, msg):
        print("%s" % msg)
        return self

    def pythonMajor(self, major=None):
        if major is not None:
            self.__python_major__ = major
            return self
        elif not hasattr(self, '__python_major__'):
            self.__python_major__ = 0
        return self.__python_major__

    def pythonMinor(self, minor=None):
        if minor is not None:
            self.__python_minor__ = minor
            return self
        elif not hasattr(self, '__python_minor__'):
            self.__python_minor__ = 0
        return self.__python_minor__

    def pythonName(self, name=None):
        if name is not None:
            self.__python_name__ = name
            return self
        elif not hasattr(self, '__python_name__'):
            self.__python_name__ = 0
        return self.__python_name__

    def cythonVersion(self):
        if not hasattr(self, "__cython_version__"):
            self.check_python()
        return self.__cython_version__

    def pythonVersion(self, version=None):
        if version is not None:
            self.__python_version__ = version.strip()
            return self
        elif  hasattr(self, '__python_version__'):
            return self.__python_version__ 
        self.__python_version__ = sys.version
        if len(self.__python_version__.split('\n'))>1:
            self.__python_version__ =  self.__python_version__.split('\n')[0].strip()
        if len( self.__python_version__.split('['))>1:
            self.__python_version__ =  self.__python_version__.split('[')[0].strip()
        if len( self.__python_version__.split('('))>1:
            self.__python_version__ =  self.__python_version__.split('(')[0].strip()
        return self.__python_version__

    def rc_update(self, package):
        self.history_check_rc_update(currentframe().f_lineno)
        if self.root_or_sudo():
            rc_cmd = self.which_cmd("rc-update")
            if rc_cmd != "":
                if self.sudo_cmd!="":
                    cmd = 'sudo %s add %s default' % (rc_cmd, package)
                else:
                    cmd = '%s add %s default' % (rc_cmd, package)

    def real_path(self, x, curr_path=None):
        if curr_path is None:
            curr_path = self.curPath()
        if self.isCmd():
            if x[:1].startswith(':\\'):
                result=x
            elif x.startswith('..\\'):
                curr_path= '\\'.join(curr_path.split('\\')[:-1])
                if curr_path=='':
                    curr_path=self.curPath()
            result=self.path_to_dos('%s\\%s'% (os.getcwd(),x))
        else:
            if x.startswith('/'):
                result=x
            elif x.startswith('../../'):
                x=x[6:]
                curr_path = '/'.join(curr_path.split('/')[:-2])
            elif x.startswith('../'):
                x=x[3:]
                curr_path = '/'.join(curr_path.split('/')[:-1])
            result='%s/%s' % (curr_path,x)
        return result

    def removeFile(self, filePath="", use_history=True):
        if self.isCmd() or self.isGitBash():
            filePath=self.path_to_dos(filePath)
        if self.pathexists(filePath):
            if use_history:
                if self.isCmd():
                    cmd = 'del %s' % filePath
                else:
                    rm = self.which_cmd('rm')
                    cmd = '%s %s' % (rm,filePath)                
                self.cmd_history(cmd)
            os.remove(filePath)

    def removeGlobalInstaller(self):
        file1 = self.globalInstallPath(0)
        file2 = self.globalInstallPath(1)
        display_once = False
        if os.path.exists(file1):
            self.history_remove_previous_global(currentframe().f_lineno)
            display_once = True
            self.sudoRemoveFile(file1)
        if os.path.exists(file2):
            if not display_once:
                self.history_remove_previous_global(currentframe().f_lineno)
                display_once = True
            self.sudoRemoveFile(file2)

    def removeFilePattern(self, dirPath, pattern):
        if self.pathexists(dirPath) and os.path.isdir(dirPath):
            for file in os.listdir(dirPath):
                if file.endswith(pattern):
                    self.removeFile("%s/%s" % (dirPath,file))

    def removeFolder(self, dirPath):
        if self.isCmd() or self.isGitBash():
            dirPath=self.path_to_dos(dirPath)
        if self.pathexists(dirPath) and os.path.isdir(dirPath):
            shutil.rmtree(dirPath)

    def remove_user(self, username=None):
        cmd= "id %s" % username
        self.history_check_user_exists(currentframe().f_lineno)
        self.cmd_history(cmd)
        result, stdout = self.shell(cmd, ignoreErr=True)
        if stdout!="":
            cmd = ""
            if self.is_alpine():
                if self.is_sudo():
                    cmd = "sudo deluser --remove-home %s" % username
                else:
                    cmd = "deluser --remove-home %s" % username
            elif self.is_debian() or self.osVersion().startswith('CentOS'):
                if self.is_sudo():
                    cmd = "sudo userdel -r %s" % username
                else:
                    cmd = "userdel -r %s" % username
            self.history_remove_user(username,currentframe().f_lineno)
            self.cmd_history(cmd)
            self.shell(cmd, ignoreErr=True)

    def remove_nginx_adm_sudoer(self, usr="nginx-adm"):
        self.history_remove_sudoer(currentframe().f_lineno)
        target_sudoers="/etc/sudoers.d/1700-%s" % usr
        self.cmd_history("ls %s" % target_sudoers)
        if self.pathexists(target_sudoers):
            self.sudoRemoveFile(target_sudoers)

    def run_shell(self, command='', ignoreErr=False, ignoreShell=False, ignoreAll=False):
        stderr = ''
        stdout = ''
        useWinpty = False
        if ignoreAll:
            pipe_array=[]
        elif ignoreShell:
            if self.isGitBash():
                winpty = self.where_cmd('winpty.exe')
                if winpty == "":
                    pipe_array=[]
                else:
                    useWinpty = True
                    pipe_array=[winpty]
            else:
                pipe_array=[]
        elif self.isLinuxShell():   
            pipe_array=[self.shellCmd(),'-c']
        elif self.isGitBash():
            winpty = self.where_cmd('winpty.exe')
            if winpty == "":
                pipe_array=[self.shellCmd(),'-c']
            else:
                useWinpty = True
                pipe_array=[winpty, self.shellCmd(),'-c']
        elif self.isCmd():
            pipe_array=[self.shellCmd(),'/c']
        else:
            # Assume /bin/sh as default shell
            pipe_array=['/bin/sh','-c']
        if isinstance(command, basestring):
            pipe_array.append(command)
        elif isinstance(command, list):
            for cmdlet in command:
                pipe_array.append(cmdlet)
        else:
            if ignoreErr:
                return True, ""
            else:
                return False, "Wrong command data type."
        try:
            p = Popen(pipe_array)
            while p.poll() is None:
                time.sleep(0.5)
        except:
            if ignoreErr:
                return True
            else:
                return False

    def root_or_sudo(self):
        # root_or_sudo() Check user is root or has sudo privilege and assuming linux
        if not self.is_linux():
            return False
        if self.username()=='root':
            return True
        if not hasattr(self, '__asked_sudo__'):
            self.__asked_sudo__=True
            if self.ask_not_root():
                self.sudo_test()
        return self.is_sudo()

    def safeMsg(self,msg,tag=''):
        self.__tag__(tag).__message__(msg).__timeMsg__(AppBase.BOLD + AppBase.ITALICS + \
            AppBase.DARK_TURQUOISE) \
            .__header__(AppBase.BOLD + AppBase.DARK_TURQUOISE) \
            .__coloredMsg__(AppBase.ITALICS + AppBase.LIGHT_TURQUOISE) \
            .__tagMsg__(AppBase.LIGHT_GREEN,AppBase.LIGHT_TURQUOISE)
        self.prn("%s" % (self.__formattedMsg__()))
        return self

    def selfInstall(self, verbal = True):
        if self.isGlobal():
            if self.need_update():
                self.msg_old_global()
                if self.ask_update():
                    return self.download_and_install(verbal=verbal)
            else:
                self.msg_latest_global()
                return False
        elif self.is_local():
            if self.need_update():
                self.msg_old_local()
                if self.ask_update():
                    return self.download_and_install(verbal=verbal)
            else:
                self.msg_latest_local()
                return False
        elif self.installedGlobal():
            self.msg_global_already()
            if self.ask_overwrite_global():
                if self.thisFile().endswith(".so"):
                    return self.__self_install__(this=self.this(), verbal=verbal)
                else:
                    return self.__self_install__(this=self.thisFile(), verbal=verbal)
        elif self.installedLocal():
            self.msg_local_already()
            if self.ask_overwrite_local():  
                return self.install_local(verbal)
        elif self.username() != 'root' and self.allowInstallLocal():
            if self.ask_local():
                return self.install_local(verbal)
        else:
            return self.__self_install_globally__(verbal)

    def selfLocation(self):
        if self.this() != '':
            return self.this()
        if getIpythonExists:
            try:
                shell = get_ipython().__class__.__name__
                if shell == 'ZMQInteractiveShell':
                    return "Jupyter"
                elif shell == 'TerminalInteractiveShell':
                    return "IPython"
                else:
                    return "Unknown location"
            except NameError:
                return "Unknown location" 
        return "Unknown location" 
        
    def selfUninstallGlobal(self, verbal = True):
        if self.installedGlobal():
            result = False
            display_once = False
            if self.username() != 'root':
                if self.sudo_test():
                    self.msg_sudo()
                    if self.targetApp() != '':
                        file1 = "%s/%s" % (self.globalFolder(0), self.targetApp())
                        file2 = "%s/%s" % (self.globalFolder(1), self.targetApp())
                        if os.path.exists(file1):
                            self.history_remove_previous_global(currentframe().f_lineno)
                            display_once = True
                            self.sudoRemoveFile(file1)
                        if os.path.exists(file1):
                            if not display_once:
                                self.history_remove_previous_global(currentframe().f_lineno)
                                display_once = True
                            self.sudoRemoveFile(file2)
                    if os.path.exists(self.globalInstallPath(0)):
                        if not display_once:
                            self.history_remove_previous_global(currentframe().f_lineno)
                            display_once = True
                        self.sudoRemoveFile(self.globalInstallPath(0))
                        result = True
                    if os.path.exists(self.globalInstallPath(1)):
                        if not display_once:
                            self.history_remove_previous_global(currentframe().f_lineno)
                            display_once = True
                        self.sudoRemoveFile(self.globalInstallPath(1))
                        result = True
                else:
                    if verbal:
                        self.msg_unintall_need_root()
                    return False
            else:
                if self.targetApp() != '':
                    file1 = "%s/%s" % (self.globalFolder(0), self.targetApp())
                    file2 = "%s/%s" % (self.globalFolder(1), self.targetApp())
                    if os.path.exists(file1):
                        self.history_remove_previous_global(currentframe().f_lineno)
                        display_once = True
                        self.sudoRemoveFile(file1)
                    if os.path.exists(file1):
                        if not display_once:
                            self.history_remove_previous_global(currentframe().f_lineno)
                            display_once = True
                        self.sudoRemoveFile(file2)
                if os.path.exists(self.globalInstallPath(0)):
                    if not display_once:
                        self.history_remove_previous_global(currentframe().f_lineno)
                        display_once = True
                    self.sudoRemoveFile(self.globalInstallPath(0))
                    result = True
                if os.path.exists(self.globalInstallPath(1)):
                    if not display_once:
                        self.history_remove_previous_global(currentframe().f_lineno)
                        display_once = True
                    self.sudoRemoveFile(self.globalInstallPath(1))
                    result = True
            if result:
                if verbal:
                    self.cmd_history_print(currentframe().f_lineno)
                    self.msg_unintall_global()
            else:
                self.msg_global_failed()
            return result
        else:
            self.msg_no_global()
        return False

    def selfUninstall(self, verbal=False):
        once =False
        if self.installedLocal():
            self.selfUninstallLocal(verbal)
            once = True
        if self.installedGlobal():
            if once:
                self.selfUninstallGlobal(verbal=False)
            else:
                self.selfUninstallGlobal(verbal)
            once = True
        if not once:
            self.msg_no_installation()    

    def selfUninstallLocal(self, verbal = True):
        if self.installedLocal():
            self.history_remove_previous_local(currentframe().f_lineno)
            self.removeFile(self.localInstallPath())
            if not os.path.exists(self.localInstallPath()):
                if self.targetApp() != '':
                    self.removeFile(self.localTargetInstallPath())
                if verbal:
                    self.cmd_history_print(currentframe().f_lineno)
                    self.msg_uninstall_local()
                return True
            else:
                self.msg_uninstall_local_failed()
                return False
        else:
            self.msg_no_local()
            return False

    def setInstallation(self,appName='',author='',lastUpdate='',homepage='',downloadUrl="",majorVersion=0,minorVersion=0):
        signal.signal(signal.SIGINT, self.signal_handler)
        self.check_system()
        self.author( author )
        self.appName( appName )
        self.downloadUrl( downloadUrl )
        self.homepage( homepage )
        self.lastUpdate( lastUpdate )
        self.majorVersion( majorVersion )
        self.minorVersion( minorVersion )

    def shell(self, command='', ignoreErr=False, ignoreShell=False, ignoreAll=False):
        stderr = ''
        stdout = ''
        useWinpty = False
        if ignoreAll:
            pipe_array=[]
        elif ignoreShell:
            if self.isGitBash():
                winpty = self.where_cmd('winpty.exe')
                if winpty == "":
                    pipe_array=[]
                else:
                    useWinpty = True
                    pipe_array=[winpty]
            else:
                pipe_array=[]
        elif self.isLinuxShell():   
            pipe_array=[self.shellCmd(),'-c']
        elif self.isGitBash():
            winpty = self.where_cmd('winpty.exe')
            if winpty == "":
                pipe_array=[self.shellCmd(),'-c']
            else:
                useWinpty = True
                pipe_array=[winpty, self.shellCmd(),'-c']
        elif self.isCmd():
            pipe_array=[self.shellCmd(),'/c']
        else:
            # Assume /bin/sh as default shell
            pipe_array=['/bin/sh','-c']
        if isinstance(command, basestring):
            pipe_array.append(command)
        elif isinstance(command, list):
            for cmdlet in command:
                pipe_array.append(cmdlet)
        else:
            if ignoreErr:
                return True, ""
            else:
                return False, "Wrong command data type."
        try:
            stdout,stderr = Popen(pipe_array,stdin=PIPE,stdout=PIPE,\
                stderr=PIPE,universal_newlines=True).communicate('\n')
        except:
            if ignoreErr:
                return True
            else:
                return False
        if stderr.strip().lower() == 'stdin is not a tty' and useWinpty:
            stdout,stderr = Popen(pipe_array[1:],stdin=PIPE,stdout=PIPE,\
                stderr=PIPE,universal_newlines=True).communicate('\n')
        if stderr != "" and not ignoreErr:
            self.msg_error(command, stderr)
            return False, stderr
        else:
            return True, stdout

    def shellCmd(self, cmd=None):
        if cmd is not None:
            self.__shell_cmd__=cmd
            return self
        elif not hasattr(self,'__shell_cmd__'):
            if 'SHELL' in os.environ:
                self.__shell_cmd__ = os.environ['SHELL']
                # cannot use self.pathexists to avoid recursive call
            elif os.path.exists('/usr/bin/fish'):
                self.__shell_cmd__ = '/usr/bin/fish'
            elif os.path.exists('/bin/bash'):
                self.__shell_cmd__ = '/bin/bash'
            elif os.path.exists('/bin/ash'):
                self.__shell_cmd__ = '/bin/ash'
            elif os.path.exists('/bin/zsh'):
                self.__shell_cmd__ = '/bin/zsh'
            elif os.path.exists('/bin/sh'):
                self.__shell_cmd__ = '/bin/sh'
            elif os.path.exists('C:\\Windows\\System32\\cmd.exe'):
                self.__shell_cmd__ = 'C:\\Windows\\System32\\cmd.exe'
            else:
                self.__shell_cmd__=''
        return self.__shell_cmd__

    def signal(self, signal=None):
        if signal is not None:
            self.__signal__=signal
            return self
        elif not hasattr(self, '__signal__'):
            self.__signal__=0
        return self.__signal__

    def signal_handler(self, sig, frame):
        if sig == 2:
            self.prn('\nYou pressed Ctrl+C!\nPress Enter to Leave!')
        if sig == 3:
            self.prn('\nYou pressed Ctrl+\!')
        self.signal(sig)

    def start_install(self):
        if hasattr(self,"requisite") and callable(self.requisite):
            self.requisite()
        if self.is_local() or self.isGlobal():
            if self.need_update():
                self.download_and_install()
                self.selfInstall()
            else:
                self.infoMsg("You are using the latest version.", "LATEST VERSION")
        elif self.selfLocation() != "Unknown location": 
            self.install(self.selfLocation(), verbal=True)
        else:
            self.download_and_install()
            self.selfInstall()

    def sudo_cmd(self):
        if not hasattr(self,'__sudo_cmd__'):
            if self.is_linux():
                self.__sudo_cmd__=self.which_cmd('sudo')
            else:
                self.__sudo_cmd__=""
        return self.__sudo_cmd__

    def sudo_test(self,msg='.'):
        if self.sudo_cmd() == "":
            return False
        distro = self.osVersion()
        if distro == 'windows':
            self.is_sudo(False)
            return False
        if self.is_sudo():
            return True
        if distro.startswith('Alpine'):
            stdout,stderr = Popen([ self.shellCmd(), '-c' , "which sudo" ],\
                stdin=PIPE,stdout=PIPE,stderr=PIPE,universal_newlines=True)\
                .communicate( '\n' )
            if stdout=='':
                return False
        stdout,stderr = Popen([ self.shellCmd(), '-c' , "sudo echo %s" % msg ],\
            stdin=PIPE,stdout=PIPE,stderr=PIPE,universal_newlines=True)\
            .communicate( '\n' )
        trial=0
        while stdout.strip() != msg.strip() and trial < 3:
            sudoPassword=getpass.getpass( 'Please input "sudo" password for %s: ' % self.username() )
            stdout, stderr = Popen([ self.shellCmd() , '-c',"sudo echo %s" % msg ] \
                ,stdin=PIPE,stdout=PIPE,stderr=PIPE,\
                universal_newlines=True ).communicate( "%s\n" % sudoPassword )
            trial=trial + 1
        if trial < 3:
            self.is_sudo( True )
        return self.is_sudo()

    def sudoRemoveFile(self, filePath, useSudo=False):
        if self.pathexists(filePath):
            cmd = ""
            rm_cmd = self.which_cmd('rm')
            if self.username() == 'root':
                cmd = '%s -rf %s' % (rm_cmd, filePath)
            elif useSudo or self.sudo_test():
                if self.sudo_cmd() != "":
                    cmd = '%s %s -rf %s' % (self.sudo_cmd(), rm_cmd, filePath)
            if cmd=="" :
                return False
            self.cmd_history(cmd)
            self.shell( cmd )
            return True

    def tag(self, tag=None):
        if tag is not None:
            self.__TAG__=tag
            return self
        elif not hasattr( self, '__TAG__' ):
            self.__TAG__=''
        return self.__TAG__

    def tar_compress(self,fname, path):
        if self.isCmd() or self.isGitBash():
            tar = self.where_cmd('tar.exe')
        else:
            tar = self.which_cmd('tar')
        cmd= [tar,"-cvf", fname, path]
        self.cmd_history(" ".join(cmd))
        result, stdout = self.shell(cmd,ignoreErr=True,ignoreAll=True)

    def tar_extract(self,fname):
        if self.isCmd() or self.isGitBash():
            tar = self.where_cmd('tar.exe')
        else:
            tar = self.which_cmd('tar')
        cmd= [tar,"-xvf", fname]
        self.cmd_history(" ".join(cmd))
        result, stdout = self.shell(cmd,ignoreErr=True,ignoreAll=True)

    def targetApp(self, app=None):
        if app is not None:
            self.__target_app__=app
            return self
        elif not hasattr( self, '__target_app__' ):
            self.__target_app__=''
        return self.__target_app__

    def tempAppUrl(self):
        if self.downloadUrl()[-1] == '/':
            return "%s%s/%d.%d/%s.tar.gz" % (self.downloadUrl(), self.binaryVersion(), self.majorVersion(),self.minorVersion(), self.targetApp())
        else:
            return "%s/%s/%d.%d/%s.tar.gz" % (self.downloadUrl(), self.binaryVersion(), self.majorVersion(),self.minorVersion(), self.targetApp())

    def tempTargetGzip(self):
        timestamp = self.timestamp()
        tempFolder = self.tempFolder()
        if tempFolder=="":
            return ""
        if self.isLinuxShell():
            return "%s/%s-%s.tar.gz" % (tempFolder, self.targetApp(), timestamp)
        elif self.isGitBash() or self.isCmd():
            return "%s\\%s-%s.tar.gz" % (tempFolder, self.targetApp(), timestamp)
        return "%s/%s-%s.tar.gz" % (tempFolder, self.targetApp(), timestamp)

    def tempAttachDecomp(self):
        tempFolder=self.tempFolder()
        if tempFolder=="":
            return ""
        if self.isCmd():
            fname="%s\\%s" % (tempFolder,self.targetApp())
        elif self.isGitBash():
            fname="%s/%s" % (tempFolder,self.targetApp())
        else:
            fname="%s/%s" % (tempFolder, self.targetApp())
        return fname

    def tempFile(self):
        tempFolder=self.tempFolder()
        if tempFolder=="":
            return ""
        if self.isCmd():
            fname="%s\\%s-%s.bat" % (tempFolder, self.appName(),self.timestamp())
        elif self.isGitBash():
            # GitBash download location should remain the same such that starting with /c/Users/user...
            fname="%s/%s-%s.bat" % (tempFolder, self.appName(),self.timestamp())
        else:
            fname="%s/%s-%s" % (tempFolder, self.appName(),self.timestamp())
        return fname

    def tempFolder(self):
        if not hasattr(self,'__temp_checked__'):
            self.__temp_checked__=0
            self.history_check_mkdir(currentframe().f_lineno)
        if self.isGitBash():
            folder="/C/Users/%s/AppData/Local/Temp" % self.username()
        elif self.isCmd():
            folder="C:\\Users\\%s\\AppData\\Local\\Temp" % self.username()
        elif 'TEMP' in os.environ:
            folder=os.environ['TEMP']
        elif self.username() == 'root':
            folder="/tmp" 
        elif self.osVersion() == 'macOS':
            folder = '/Users/%s/Library/Caches' % self.username()
        else:
            folder="/home/%s/.local/temp" % self.username()
        if self.__temp_checked__<1:
            if not self.mkdir(folder):
                return ""
        if self.__temp_checked__==0:
            use_history=True
        else:
            use_history=False
        self.__temp_checked__=self.__temp_checked__+1
        if self.pathexists(folder, use_history=use_history):
            return folder
        self.msg_temp_folder_failed(folder)
        return ""

    def this(self, this = None):
        if this is None :
            if not hasattr(self, '__this__'):
                self.__this__=self.appPath()
            return self.__this__
        else:
            self.__this__ = this
            return self

    @staticmethod
    def thisFile():
        return AppBase.__here__

    def today(self):
        return date.today()

    def timestamp(self):
        return "%s" % (int(time.time()))

    def translateScript(self, source="", target="", useSudo=False):
        tempFolder=self.tempFolder()
        if tempFolder=="":
            return False
        result = False
        if self.pathexists(source):
            tempScript = "%s.tmp" % self.tempFile()
            if tempScript!=source:
                self.history_open_as_source(source, currentframe().f_lineno)
                file1 = self.open(source, 'r')
                self.history_open_as_target(tempScript, currentframe().f_lineno)
                file2 = self.open(tempScript,'w')
                if self.isCmd() or self.isGitBash():
                    for line in file1:
                        if line.startswith('##! '):
                            file2.write(line[4:])
                        elif not (line.startswith('from __future__') or line.startswith('#!') or line.startswith('# -*-')):
                            file2.write(line)
                else:
                    for line in file1:
                        if line.startswith('#!/bin/sh'):
                            file2.write('#!%s\n' % sys.executable)
                        else:
                            file2.write(line)
                file1.close()
                file2.close()
                if source.startswith(tempFolder):
                    self.history_remove_source(currentframe().f_lineno)
                    self.removeFile(source)
                self.history_copy_temp(currentframe().f_lineno)
                self.cp(tempScript, target, useSudo=useSudo)
                self.history_remove_temp(currentframe().f_lineno)
                self.removeFile(tempScript)
                self.history_change_target_mode(currentframe().f_lineno)
                result=self.chmod_x(target, useSudo=useSudo)
        else:
            self.msg_download_not_found(target)
        return result

    def where_cmd(self, cmd, default=""):
        stdout = ''
        if self.isLinuxShell():
            return self.which_cmd(cmd)
        elif self.isCmd()  or self.isGitBash():
            path = "C:\\Users\\%s\\AppData\\Local\\Microsoft\\WindowsApps\\%s" % (self.username(), cmd)
            if os.path.exists('C:\\Windows\\system32\\%s' % cmd):
                return 'C:\\Windows\\system32\\%s' % cmd
            elif os.path.exists(path):
                return path
            elif 'PATH' in os.environ:
                split_path = os.environ['PATH'].split(';')
                for pathlet in split_path:
                    if os.path.exists('%s\\%s' % (pathlet, cmd)):
                        return '%s\\%s' % (pathlet, cmd)
        if default != "":
            cmd = default
        return cmd

    def which(self):
        if self.isCmd()  or self.isGitBash():
            if self.pathexists(self.localInstallPath()):
                return self.localInstallPath()
            elif self.pathexists(self.globalInstallPath(0)):
                return self.globalInstallPath(0)
            elif self.pathexists(self.globalInstallPath(1)):
                return self.globalInstallPath(1)
            elif self.pathexists('C:\\Windows\\System32\\where.exe'):
                return self.where_cmd( self.appName())
        else:
            if self.pathexists(self.localInstallPath()):
                return self.localInstallPath()
            elif self.pathexists(self.globalInstallPath(0)):
                return self.globalInstallPath(0)
            elif self.pathexists(self.globalInstallPath(1)):
                return self.globalInstallPath(1)
            if self.pathexists('/usr/bin/which'):
                return self.which_cmd( self.appName())

    def which_cmd(self, cmd, default=""):
        stdout = ''
        if self.isCmd() or self.isGitBash():
            return self.where_cmd(cmd)
        elif self.isLinuxShell():
            if os.path.exists('/bin/%s' % cmd):
                return '/bin/%s' % cmd
            elif os.path.exists('/sbin/%s' % cmd):
                return '/sbin/%s' % cmd
            elif os.path.exists('/usr/bin/%s' % cmd):
                return '/usr/bin/%s' % cmd
            elif os.path.exists('/usr/bin/local/%s' % cmd):
                return '/usr/bin/local/%s' % cmd
            elif os.path.exists('/usr/sbin/%s' % cmd):
                return '/usr/sbin/%s' % cmd
            elif os.path.exists('/home/%s/.local/bin/%s' % (self.username(), cmd)):
                return '/home/%s/.local/bin/%s' % (self.username(), cmd)
            elif os.path.exists('/usr/bin/which'):
                result, stdout = self.shell("/usr/bin/which %s" % cmd, ignoreErr=True)
                return stdout.strip()
            elif os.path.exists('/bin/which'):
                result, stdout = self.shell("/usr/bin/which %s" % cmd, ignoreErr=True)
                return stdout.strip()
            elif 'PATH' in os.environ:
                split_path = os.environ['PATH'].split(':')
                for pathlet in split_path:
                    if os.path.exists('%s/%s' % (pathlet, cmd)):
                        return '%s/%s' % (pathlet, cmd)
        if default!="":
            cmd=default
        return cmd

    def which_journalctl(self):
        return self.which_cmd('journalctl', '/usr/bin/journalctl')

    def which_nginx(self):
        return self.which_cmd('nginx', '/usr/sbin/nginx')

    def which_rc_service(self):
        return self.which_cmd('rc-service', '/sbin/rc-service')

    def which_systemctl(self):
        return self.which_cmd('systemctl','/usr/bin/systemctl')

    def which_uname(self):
        return self.which_cmd('uname', '/usr/bin/uname')

    def ubuntu_version(self):
        if not hasattr(self,'__ubuntu_version__'):
            if self.osVersion().startswith("Ubuntu"):
                version=self.osVersion().split(' ')
                length=len(version)
                if length>1:
                    self.__ubuntu_version__=version[length - 1]
            else:
                self.__ubuntu_version__=''
        return self.__ubuntu_version__

    def uname(self, switch, ignoreErr=True):
        stderr = ''
        stdout = ''
        command = 'uname %s' % switch
        if self.isLinuxShell():
            uname = self.which_cmd('uname')
            command = '%s %s' % (uname, switch)
            if uname != '':
                stdout,stderr = Popen([uname,switch],stdin=PIPE,stdout=PIPE,\
                    stderr=PIPE,universal_newlines=True).communicate('\n')
            else:
                return False, 'uname not found'
        if self.isGitBash():
            winpty = self.where_cmd('winpty.exe')
            uname = self.where_cmd('uname.exe')
            stdout,stderr = Popen([winpty, uname,switch],stdin=PIPE,stdout=PIPE,\
                stderr=PIPE,universal_newlines=True).communicate('\n')
            if stderr.strip().lower() == 'stdin is not a tty':
                stdout,stderr = Popen([uname,switch],stdin=PIPE,stdout=PIPE,\
                    stderr=PIPE,universal_newlines=True).communicate('\n')
        elif self.isCmd():
            stdout,stderr = Popen([self.shellCmd(),'/c',command],stdin=PIPE,stdout=PIPE,\
                stderr=PIPE,universal_newlines=True).communicate('\n')
        else:
            # Assume /bin/sh as default shell
            uname = self.which_cmd('uname')
            if uname != '':
                stdout,stderr = Popen([uname,switch],stdin=PIPE,stdout=PIPE,\
                    stderr=PIPE,universal_newlines=True).communicate('\n')
            else:
                return False, 'uname not found'
        if stderr != "" and not ignoreErr:
            self.msg_error(command, stderr)
            return False, stderr
        else:
            return True, stdout

    def uname_a(self, ignoreErr=True):
        return self.uname('-a')

    def uname_m(self, ignoreErr=True):
        return self.uname('-m')

    def update_repository(self):
        # root_or_sudo() Check user is root or has sudo privilege and assuming linux
        cmd = ""
        if not self.root_or_sudo():
            return False
        if not hasattr(self,'__has_repository_updated__'):
            self.__has_repository_updated__ = False
        if self.__has_repository_updated__:
            return True
        if self.is_debian():
            cmd = "apt update"
        elif self.is_alpine():
            cmd = "apk update"
        elif self.osVersion().startswith('CentOS'):
            cmd = "yum check-update"
        elif self.is_fedora():
            cmd = "dnf check-update"
        else:
            self.msg_not_compatible_os()
        if cmd != "":
            self.history_update_repository(currentframe().f_lineno)
            self.cmd_history(cmd)
            self.shell(cmd, ignoreErr=True)
            self.__has_repository_updated__=True
            return True
        return False

    def uninstall_jupyter(self):
        self.uninstall_python_package('jupyter')
        self.uninstall_python_package('jupyterhub')
        result = self.uninstall_package('gcc', ['/usr/bin/gcc'])
        result = self.uninstall_package('python3-dev',['/usr/include/python3.8/Python.h','/usr/include/python3.9/Python.h','/usr/include/python3.10/Python.h','/usr/include/python3.11/Python.h','/usr/include/python3.12/Python.h'])
        if self.is_alpine():
            result = self.uninstall_package('musl-dev',['/usr/include/stdio.h'])
            result = self.uninstall_package('linux-headers',['/usr/include/linux/version.h'])
            result = self.uninstall_package('py3-pip', ['/usr/bin/pip3'])
        else:
            result = self.uninstall_package('libc6-dev',['/usr/include/stdio.h'])
            result = self.uninstall_package('python3-pip', ['/usr/bin/pip3'])
        result = self.uninstall_nginx()
        self.remove_nginx_adm_sudoer()
        self.remove_user('nginx-adm')
        return True

    def uninstall_libcrypto(self):
        if self.osVersion().startswith('Alpine'):
            result = self.uninstall_package('libcrypto1.1', ['/usr/lib/libcrypto.so'])
        else:
            result = self.uninstall_package('libssl-dev', ['/usr/lib/x86_64-linux-gnu/libcrypto.so'])
        return result

    def uninstall_libinih(self):
        if self.is_alpine():
            result = self.uninstall_package('inih-dev', ['/usr/lib/libinih.so'])
        else:
            result = self.uninstall_package('libinih-dev', ['/usr/lib/x86_64-linux-gnu/libinih.so'])
        return result

    def uninstall_libpcre2(self):
        if self.is_alpine():
            result = self.uninstall_package('pcre2-dev', ['/usr/lib/libpcre2-8.so.0'])
        else:
            result = self.uninstall_package('libpcre2-dev', ['/usr/lib/x86_64-linux-gnu/libpcre2-32.so'])
        return result

    def uninstall_libsqlite3_dev(self):
        if self.is_alpine():
            result = self.uninstall_package('sqlite-dev', ['/usr/lib/libsqlite3.so'])
        else:
            result = self.uninstall_package('libsqlite3-dev', ['/usr/lib/x86_64-linux-gnu/libsqlite3.so'])
        return result

    def uninstall_libsqlite3(self):
        result = self.uninstall_package('sqlite3', ['/usr/bin/sqlite3'])
        return result

    def uninstall_nginx(self):
        self.history_backup_nginx_conf(currentframe().f_lineno)
        if self.is_alpine():
            if self.pathexists("/etc/nginx/http.d", use_history=True):
                backup_source="/etc/nginx/http.d"
        else:
            if self.pathexists("/etc/nginx/sites-available", use_history=True):
                backup_source="/etc/nginx/sites-available"        
        if backup_source != "":
            next_id = 0
            self.mkdir('/var/nginx-backup')
            for id in range(99):
                test_path='/var/nginx-backup/%s.%d' % (self.today(), id)
                if self.pathexists(test_path):
                    next_id = id + 1
            if next_id > 99:
                self.msg_too_many_backup()
                return False
            backup_destination='/var/nginx-backup/%s.%d' % (self.today(), next_id)
            shutil.copytree(backup_source, backup_destination)
        result = self.uninstall_package('nginx', ['/usr/sbin/nginx','/usr/bin/nginx'])
        return result

    def uninstall_package(self, package=None, path=None):
        # root_or_sudo() Check user is root or has sudo privilege and assuming linux
        if not self.root_or_sudo():
            return False
        installed = False
        location = ''
        if path is not None and package is not None:
            self.history_check_exists(package, currentframe().f_lineno)
            if isinstance(path,basestring):
                if self.pathexists(path, use_history=True):
                    location = path
                    installed=True
                    self.history_location_found(location, currentframe().f_lineno)
            elif isinstance(path,list):
                for l in path:
                    if self.pathexists(l, use_history=True):
                        location = l
                        installed=True
                        self.history_location_found(location, currentframe().f_lineno)
        if installed:
            if self.is_debian():
                self.history_uninstall_package(package, currentframe().f_lineno)
                if self.is_sudo():
                    cmd = "sudo apt purge --auto-remove -y %s" % package
                else:
                    cmd = "apt purge --auto-remove -y %s" % package
                self.cmd_history(cmd)
                self.shell(cmd, ignoreErr=True)
                installed = True
            elif self.is_alpine():
                self.history_uninstall_package(package, currentframe().f_lineno)
                if self.is_sudo():
                    cmd = "sudo apk del %s" % package
                else:
                    cmd = "apk del %s" % package
                self.cmd_history(cmd)
                self.shell(cmd, ignoreErr=True)
                installed = True
            elif self.osVersion().startswith('CentOS'):
                if self.is_sudo():
                    cmd = "sudo yum remove -y %s" % package
                else:
                    cmd = "yum remove -y %s" % package
                self.cmd_history(cmd)
                self.shell(cmd, ignoreErr=True)
                installed = True
            elif self.is_fedora():
                if self.is_sudo():
                    cmd = "sudo dnf remove -y %s" % package
                else:
                    cmd = "dnf remove -y %s" % package
                self.cmd_history(cmd)
                self.shell(cmd, ignoreErr=True)
                installed = True
            else:
                self.msg_not_compatible_os()
                return False
            if self.pathexists(location):
                self.msg_unintall_global()
                return False
        return installed

    def uninstall_python_package(self, package=None):
        self.history_uninstall_package('jupyter', currentframe().f_lineno)
        cmd = 'pip3 uninstall --break-system-packages %s' % package
        self.cmd_history(cmd)
        self.shell(cmd,ignoreErr=True)

    def help(self):
        cmd_list=list(self.__sub_command__.keys())
        cmd_list.sort()
        self.prn("%s [%s]" % (self.appExec(), "|".join(cmd_list)))

    def usage(self, para=None):
        if not hasattr(self,'__para__'):
            self.__para__=''
        if not hasattr(self,''):
            self.__sub_command__={}
            self.__sub_command__["install"] = True
            self.__sub_command__["update"] = True
            self.__sub_command__["check-system"] = True
            self.__sub_command__["cython-string"]=True
            self.__sub_command__["this"] = True
            self.__sub_command__["this-file"] = True
            self.__sub_command__["download"] = True
            self.__sub_command__["download-app"] = True
            self.__sub_command__["download-target-app"] = True
            self.__sub_command__["global-installation-path"] = True
            self.__sub_command__["local-installation-path"] = True
            self.__sub_command__["timestamp"] = True
            self.__sub_command__["today"] = True
            self.__sub_command__["help"] = True
            self.__sub_command__["check-update"] = True
            self.__sub_command__["check-version"] = True

            if para is not None:
                for subcmd in para.split(","):
                    if subcmd !="":
                        self.__sub_command__[subcmd]=True                
        if para is not None:
            self.__para__=para
            return self
        return "%s [%s]" % (self.appExec(),self.__para__)

    def useColor(self, color=None):
        if color is not None:
            self.__useColor__=color
            return self
        elif not hasattr(self, '__useColor__'):
            if self.isGitBash():
                # Gitbash cannot show color
                self.__useColor__=False
            else:
                self.__useColor__=True
        return self.__useColor__

    def userID(self):
        return os.getuid()

    def username(self):
        if pwd is None:
            return os.getlogin()
        return pwd.getpwuid(self.userID())[0]

    def version(self):
        return "%s.%s" % (self.majorVersion(),self.minorVersion())

    def zshenv(self):
        return os.path.join(self.home(), ".zshenv")
        
    def ask_choose(self):
        # fromPipe() usually involve from curl and don't have stdin
        if self.fromPipe():
            return False
        return self.__ask_yesno__('Install globally (yes) or locally(no)? (yes/no) ') == 'no'

    def ask_choose_profile_number(self):
        # fromPipe() usually involve from curl and don't have stdin
        if self.fromPipe():
            return None
        return self.__ask_number__('Choose the profile number? ')

    def ask_create_ini(self):
        # fromPipe() usually involve from curl and don't have stdin
        if self.fromPipe():
            return None
        return 'yes' == self.__ask_yesno__('Do you wanted to create ini file (type "exit" to exit)? ') 

    def ask_install_sudo(self):
        # fromPipe() usually involve from curl and don't have stdin
        if self.fromPipe():
            return None
        return 'yes' == self.__ask_yesno__('Do you want to install sudo? (yes/no) ')

    def ask_local(self):
        # fromPipe() usually involve from curl and don't have stdin
        if self.fromPipe():
            return None
        return 'yes' == self.__ask_yesno__('Do you want to install locally? (yes/no) ')

    def ask_not_root(self):
        # fromPipe() usually involve from curl and don't have stdin
        if self.fromPipe():
            return None
        return self.__ask_yesno__('You are not using root account. Do you want to continue? (yes/no) ') == 'yes'

    def ask_overwrite_global(self):
        # fromPipe() usually involve from curl and don't have stdin
        if self.fromPipe():
            return None
        return 'yes' == self.__ask_yesno__('Do you want to overwrite the global installation? (yes/no) ')

    def ask_overwrite_local(self):
        # fromPipe() usually involve from curl and don't have stdin
        if self.fromPipe():
            return None
        return 'yes' == self.__ask_yesno__('Do you want to overwrite the local installation? (yes/no) ')

    def ask_update(self):
        # fromPipe() usually involve from curl and don't have stdin
        if self.fromPipe():
            return None
        return 'yes' == self.__ask_yesno__('Do you want to update the latest (%s) from internet? (yes/no) ' % self.latest_version())

    def history_add_group(self, groupname, line_num=None):
        self.cmd_history("# ** Adding user group: %s **" % groupname, line_num)

    def history_add_user(self, username, line_num=None):
        self.cmd_history("# ** Adding user: %s **" % username, line_num)

    def history_backup_nginx_conf(self, line_num=None):
        self.cmd_history("# ** Try to backup nginx config **", line_num)

    def history_cd(self, path="", line_num=None):
        self.cmd_history("cd %s" % path, line_num)

    def history_cd_decompress(self, line_num=None):
        self.cmd_history("# ** Change to temp folder to uncompress **", line_num)

    def history_change_target_mode(self, line_num=None):
        self.cmd_history("# ** Change target to executable **", line_num)

    def history_check_ash(self, line_num=None):
        self.cmd_history("# ** Try to check and modify ~/.profile **", line_num)

    def history_check_bash(self, line_num=None):
        self.cmd_history("# ** Try to check and modify ~/.bashrc **", line_num)

    def history_check_copy_sudoers(self, line_num=None):
        self.cmd_history("# ** Try to check existence or copy from temp to /etc/sudoers.d/ **" , line_num)

    def history_check_mkdir(self, line_num=None):
        self.cmd_history("# ** Check and create directory **", line_num)

    def history_check_exists(self, name="", line_num=None):
        self.cmd_history("# ** Check existence of %s **" % name, line_num)

    def history_check_group_exists(self, line_num=None):
        self.cmd_history("# ** Try to check if the user group exists  **", line_num)

    def history_check_rc_update(self, line_num=None):
        self.cmd_history("# ** Try to check sudo and add rc-update **" , line_num)

    def history_check_repositories(self, line_num=None):
        self.cmd_history("# ** Check and update apk repositories **", line_num)

    def history_check_user_exists(self, line_num=None):
        self.cmd_history("# ** Try to check if the user exists  **", line_num)

    def history_copy_temp(self, line_num=None):
        self.cmd_history("# ** Try to copy from temp to target **" , line_num)

    def history_copy_uncompressed(self, line_num=None):
        self.cmd_history("# ** Copy uncompressed file to target **", line_num)

    def history_change_ownership_of_folder(self, line_num=None):
        self.cmd_history("# ** Try to change ownership of folder **", line_num)

    def history_check_zsh(self, line_num=None):
        self.cmd_history("# ** Try to check and modify ~/.zshenv **", line_num)

    def history_create_soft_link(self, line_num=None):
        self.cmd_history("# ** Try to create soft link **", line_num)

    def history_curl_check(self, line_num=None):
        self.cmd_history("# ** Using curl to check if url is ok **", line_num)

    def history_curl_download(self, line_num=None):
        self.cmd_history("# ** Using curl for downloading file **", line_num)

    def history_dir(self, path, line_num=None):
        self.cmd_history("dir %s" % path, line_num)

    def history_group_exists(self, groupname, line_num=None):
        self.cmd_history("# ** User group: %s exists and no adding for it **" % groupname, line_num)

    def history_install_package(self, package, line_num):
        self.cmd_history("# ** Install package: %s **" % package, line_num)

    def history_ls(self, path, line_num=None):
        self.cmd_history("ls %s" % path, line_num)

    def history_link_exists(self, path, line_num=None):
        self.cmd_history("# link exists: %s, no need to create short link" % path, line_num)

    def history_location_found(self, location, line_num=None):
        self.cmd_history("# found: %s" % location, line_num)

    def history_open_as_source(self, f, line_num=None):
        self.cmd_history("# ** Open %s as source file **" % f, line_num)

    def history_open_as_target(self, f, line_num=None):
        self.cmd_history("# ** Open %s as the location for writing **" % f, line_num)

    def history_package_exists(self, package, line_num=None):
        self.cmd_history("# ** Package: %s exists and no installation for it **" % package, line_num)

    def history_remove_downloaded(self, line_num=None):
        self.cmd_history("# ** Try to remove downloaded file **", line_num)

    def history_remove_previous_global(self, line_num=None):
        self.cmd_history("# ** Try to remove previous installed global version **", line_num)

    def history_remove_previous_local(self, line_num=None):
        self.cmd_history("# ** Try to remove previous installed local version **", line_num)

    def history_remove_sudoer(self, line_num=None):
        self.cmd_history("# ** Try to check and remove sudoer file **", line_num)

    def history_remove_source(self, line_num=None):
        self.cmd_history("# ** Try to remove source file **", line_num)

    def history_remove_temp(self, line_num=None):
        self.cmd_history("# ** Try to remove temp file **", line_num)

    def history_remove_uncompressed(self, line_num=None):
        self.cmd_history("# ** Try to remove uncompressed file **", line_num)

    def history_remove_user(self, username, line_num=None):
        self.cmd_history("# ** Removing user: %s **" % username, line_num)

    def history_update_repository(self, line_num=None):
        self.cmd_history("# ** Try to update repository first **", line_num)

    def history_uninstall_package(self, package, line_num=None):
        self.cmd_history("# ** Uninstall package: %s **" % package, line_num)

    def history_user_exists(self, username, line_num=None):
        self.cmd_history("# ** User: %s exists and no adding for it **" % username, line_num)

    def msg_alpine_detected(self, title="OPERATION SYSTEM"):
        self.infoMsg("Alpine Detected!", title)

    def msg_both_local_global(self, title="INSTALLED TWICE"):
        self.criticalMsg("It may causes error if you have installed both local version and Global Version!\n  Please uninstall local version by,\n    %s uninstall" % self.appPath(), title)

    def msg_download_error(self, file):
        if not hasattr(self,'__msgshown_download_error__'):
            self.criticalMsg("Download file error: %s" % file, "DOWNLOAD ERROR")
            self.__msgshown_download_error__=True

    def msg_download_url_error(self, url, code):
        if not hasattr(self,'__msgshown_download_error__'):
            self.criticalMsg("Url: %s\n  HTTP code: %s" % (url, code), "DOWNLOAD ERROR")
            self.__msgshown_download_error__=True

    def msg_download_not_found(self, file):
        self.criticalMsg("Downloaded File: %s" % file, "NOT FOUND")

    def msg_downloaded(self, fname="", title="DOWNLOADED"):
        self.safeMsg("File downloaded to: %s" % fname, title)

    def msg_downloading(self, url="", title="DOWNLOAD FILES"):
        self.infoMsg("Downloading: %s ..." % url, title)

    def msg_error(self, command="", stderr="", title="ERROR"):
        self.criticalMsg("Error in %s: %s" % (command, stderr), title)

    def msg_extraction_error(self, file="", title="DOWNLOAD ERROR"):
        self.criticalMsg("File Extraction error: %s not found" % file, title)

    def msg_installation_failed(self, title="INSTALLATION"):
        self.criticalMsg("Installation failed!", title)

    def msg_global_already(self, title="SELF INSTALL"):
        self.infoMsg("Global Installation installed already!", title)

    def msg_global_failed(self, title="SELF UNINSTALL"):
        self.criticalMsg("Global uninstall failed!", title)

    def msg_info(self, usage=None):
        if usage is None:
            usage=self.usage()
        if self.isCmd():
            msg1="%s.bat (%s.%s) by %s on %s" % (self.appName(),self.majorVersion(),\
                self.minorVersion(),self.author(),self.lastUpdate())
        else:
            msg1="%s (%s.%s) by %s on %s" % (self.appName(),self.majorVersion(),\
                self.minorVersion(),self.author(),self.lastUpdate())
        if self.isGlobal():
            app = "You are using the GLOBAL INSTALLED version, location:"
        elif self.is_local():
            app = "You are using the LOCAL INSTALLED version, location:"
        else :
            app = "You are using an UNINSTALLED version, location:" 
        python_exe = self.executable()
        if python_exe == '':
            python_exe = self.pythonName()
        msg = [
            msg1, 
            '',
            '%s' % app,
            '    %s' % self.selfLocation(),
            '', 
            "Basic Usage:",
            "    %s" % usage,
            '',
            'Please visit our homepage: ',
            '    "%s"' % self.homepage(),
            '',
            'Installation command:',
            '    curl -fsSL %s|%s' % (self.downloadUrl(), python_exe),
            ''
        ]
        starLine=[]
        space=[]
        spaces=[[],[],[],[],[],[],[],[],[],[],[],[],[],[]]
        if self.targetApp() != '':
            spaces.append([])
            spaces.append([])
            msg.append('Target Application:')
            if self.isCmd() or self.isGitBash():
                file3 = self.localTargetInstallPath()
                if self.pathexists(file3):
                    msg.append('    %s' % file3)
                    spaces.append([])
            else:
                file1 = "%s/%s" % (self.globalFolder(0), self.targetApp())
                file2 = "%s/%s" % (self.globalFolder(1), self.targetApp())
                file3 = self.localTargetInstallPath()
                if self.pathexists(file1):
                    msg.append('    %s' % file1)
                    spaces.append([])
                if self.pathexists(file2):
                    msg.append('    %s' % file2)
                    spaces.append([])
                if self.pathexists(file3):
                    msg.append('    %s' % file3)
                    spaces.append([])
            msg.append('')
        maxLen=len(msg[0])
        if self.downloadUrl() == '':
            if self.homepage() == '':
                max_line = len(spaces) - 3
            else:
                max_line = len(spaces) - 2
        else:
            max_line = len(spaces) - 1
        for n in range(1, max_line):
            if len(msg[n]) > maxLen :
                maxLen=len(msg[n])
        for n in range(0, max_line):
            for i in range(1,maxLen - len(msg[n]) + 1):
                spaces[n].append(' ')
            msg[n]=msg[n] + ''.join(spaces[n])
        for i in range(1,maxLen + 5):
            starLine.append("*")
        for i in range(1,maxLen + 1):
            space.append(" ")
        self.prn(''.join(starLine))
        self.prn('* %s *' % ''.join(space))
        for n in range(0, max_line):
            self.prn('* %s *' % msg[n])
        self.prn('* %s *' % ''.join(space))
        self.prn(''.join(starLine))

    def msg_install_app_global(self, title="INSTALL"):
        if self.isCmd() or self.isGitBash():
            self.msg_install(location='Globally', app="%s.bat" % self.appName(), title=title)
        else:
            self.msg_install(location='Globally', app=self.appName(), title=title)

    def msg_install_app_local(self, title="INSTALL"):
        if self.isCmd() or self.isGitBash():
            self.msg_install(location='Locally', app="%s.bat" % self.appName(), title=title)
        else:
            self.msg_install(location='Locally', app=self.appName(), title=title)

    def msg_install(self, location="", app="", title="INSTALL"):
        startSh =  ""   # for ash, cmd, gitbash
        if location == 'Locally':
            if self.osVersion() == 'macOS':
                startSh = "  Please type 'hash -r' and 'source ~/.zshenv' to refresh zsh shell hash!\n  Then, you can "
            elif self.shellCmd() != '/bin/ash' and self.isLinuxShell():
                startSh =  "  Please type 'hash -r' and 'source ~/.bashrc' to refresh bash shell hash!\n  Then, you can "
            self.safeMsg("Installed %s! \n%s  type '%s' to run!" % (location, startSh, app), title)
        else:
            self.safeMsg("Installed %s! \n    type '%s' to run!" % (location, app), title)

    def msg_install_target_global(self, title="INSTALL"):
        if self.isCmd() or self.isGitBash():
            self.msg_install(location='Globally', app="%s.exe" % self.targetApp(), title=title)
        else:
            self.msg_install(location='Globally', app=self.targetApp(), title=title)

    def msg_install_target_local(self, title="INSTALL"):
        if self.isCmd() or self.isGitBash():
            self.msg_install(location='Locally', app="%s.exe" % self.targetApp(), title=title)
        else:
            self.msg_install(location='Locally', app=self.targetApp(), title=title)

    def msg_latest(self, title="CHECK VERSION"):
        if self.is_local():
            self.msg_latest_global(title)
        elif self.is_local():
            self.msg_latest_local(title)
        else:
            self.infoMsg("You are using latest (%s.%s) already!" % (self.majorVersion(),self.minorVersion()), title)

    def msg_latest_global(self, title="CHECK VERSION"):
        self.infoMsg("You are using latest (%s.%s) Global Installation's copy already!" % (self.majorVersion(),self.minorVersion()), title)

    def msg_latest_local(self, title="CHECK VERSION"):
        self.infoMsg("You are using latest (%s.%s) Local Installation's copy already!" % (self.majorVersion(),self.minorVersion()), title)

    def msg_latest_available(self, title="CHECK UPDATE"):
        self.infoMsg("Latest Version = %s\n  Update is available" % self.latest_version(), title)

    def msg_linux_only(self):
        self.criticalMsg("This programs required linux only.", "LINUX ONLY")

    def msg_local_already(self, title="SELF INSTALL"):
        self.infoMsg("Local Installation installed already!", title)

    def msg_no_global(self, title="GLOBAL UNINSTALL"):
        self.infoMsg("You don't have any local installation.", title)

    def msg_no_local(self, title="LOCAL UNINSTALL"):
        self.infoMsg("You don't have any local installation.", title)

    def msg_no_server(self, title="CONNECTION FAILED"):
        self.criticalMsg("Cannot communicate with server", title)

    def msg_no_installation(self, title="UNINSTALL"):
        self.infoMsg("You don't have any global or local installation.", title)

    def msg_not_compatible_os(self, title="INSTALL"):
        self.infoMsg("Your OS is not compatible: %s" % self.osVersion(), title)

    def msg_not_working_docker(self, title="SYSTEM DAEMON"):
        self.criticalMsg("systemctl or journalctl cannot work properly in docker container.", title)

    def msg_root_continue(self, title="SELF INSTALL"):
        self.infoMsg("You must be root or sudo to continue installation!", title)

    def msg_old_global(self, title="SELF INSTALL"):
        self.infoMsg("You are using an old (%s.%s) Global Installation's copy already!" % (self.majorVersion(),self.minorVersion()), title)

    def msg_old_local(self, title="SELF INSTALL"):
        self.infoMsg("You are using an old (%s.%s) Local Installation's copy already!" % (self.majorVersion(),self.minorVersion()), title)

    def msg_permission_denied(self, path="", title=""):
        self.criticalMsg("Permission denied: %s" % path, title)

    def msg_sudo(self, title="SUDO TEST"):
        if not hasattr(self,'__msg_sudo_verified__'):
            self.__msg_sudo_verified__ = True
            self.infoMsg("Your sudo privilege has been verified.", title)

    def msg_sudo_not_installed(self, title="SUDO TEST"):
        if not hasattr(self,'__msg_sudo_not_installed__'):
            self.__msg_sudo_not_installed__ = True
            self.infoMsg("'SUDO' has not installed in your system.", title)
            if self.osVersion().startswith("Alpine"):
                self.safeMsg("Please use the following command to install sudo:\n    apk add sudo", title)

    def msg_sudo_failed(self, title="SUDO FAILED"):
        self.criticalMsg("You should be root or sudo to install globally.", title)

    def msg_system_check(self, title="START"):
        # msg_system_check(), this message only shown when downloading files
        if not hasattr(self,'__system_msg_shown__'):
            self.safeMsg("Now checking your operation system!", title)
            self.prn("    Python: %s" % self.pythonVersion())
            self.prn("    C Library: %s" % self.libcVersion())
            self.prn("    Operation System: %s" % self.osVersion())
            self.prn("    Architecture: %s" % self.arch())
            self.prn("    Current User: %s" % self.username())
            self.prn("    Shell: %s" % self.shellCmd())
            self.prn("    Python Executable: %s" % self.executable())
            self.prn("    Inside docker container: %s" % self.is_docker_container())
            self.prn("    AppBase Version: %s" % AppBase.VERSION)
            self.prn("    Cython String: %s" % self.cythonVersion())
            self.prn("    Binary Type: %s" % self.binaryVersion() )
            self.prn("")
            self.__system_msg_shown__ = True

    def msg_temp_folder_failed(self, folder="", title=""):
        if not hasattr(self,'__msg_temp_error__'):
            self.__msg_temp_error__=True
            self.criticalMsg("Cannot access or create temp folder" % folder, title)

    def msg_timeout(self, file="", title="ERROR"):
        self.criticalMsg("Time out in downloading %s" % (file), title)

    def msg_too_many_backup(self):
        self.criticalMsg("Too many backup created.", "BACKUP CREATION FAILED")

    def msg_unintall_global(self, title="GLOBAL UNINSTALL"):
        self.safeMsg("You have uninstalled successfully.", title)

    def msg_uninstall_global_failed(self, title="UNINSTALL FAILED"):
        self.criticalMsg("Failed to uninstall globally", title)

    def msg_uninstall_local(self, title="LOCAL UNINSTALL"):
        self.safeMsg("You have uninstalled successfully.", title)

    def msg_uninstall_local_failed(self, title="UNINSTALL FAILED"):
        self.criticalMsg("Failed to uninstall locally", title)

    def msg_unintall_need_root(self, title="GLOBAL UNINSTALL"):
        self.criticalMsg("You should be root or sudo to uninstall globally.", title)

    def msg_unknown_parameter(self, title="UNKNOWN PARAMETER"):
        self.criticalMsg("Unknown parameter '%s'" % self.cmd(), title)

    def msg_user_found(self, username="", title="CREATING USER"):
        self.infoMsg("Existing user group: %s found." % username, title)

    def msg_user_group_found(self, usergroup="", title="CREATING GROUP"):
        self.infoMsg("Existing user: %s found." % usergroup, title)

    def msg_wrong_shell(self, cmd="", title=""):
        self.infoMsg("You are using wrong shell to execute: '%s'" % cmd)

    def __init__(self, this = None):
        if this is not None:
            self.this(this)