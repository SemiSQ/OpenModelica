@echo off
REM Clear all environment variables that may interfere during compile and link phases.
set GCC_EXEC_PREFIX=
set CPLUS_INCLUDE_PATH=
set C_INCLUDE_PATH=D
set LIBRARY_PATH=
set OLD_PATH=%PATH%
pushd "%OPENMODELICAHOME%\MinGW\bin" >%1.log 2<&1
set PATH=%CD%;%PATH%
popd
mingw32-make -f %1.makefile >%1.log 2<&1
set RESULT=%ERRORLEVEL%
set PATH=%OLD_PATH%
set OLD_PATH=
exit /B %RESULT%
