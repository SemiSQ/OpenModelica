@echo off
set GCC_EXEC_PREFIX=
set OLDPATH=%PATH%
pushd "%OPENMODELICAHOME%\MinGW\bin" >%1.log 2<&1
set PATH=%CD%;%PATH%
popd
mingw32-make -f %1.makefile >%1.log 2<&1
set RESULT=%ERRORLEVEL%
set PATH=%OLDPATH%
exit /B %RESULT%