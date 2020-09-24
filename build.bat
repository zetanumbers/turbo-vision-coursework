@echo off
if "%~1"=="--release" goto release
if "%~1"=="--debug" goto debug
if "%~1"=="" goto debug
goto help

:help
echo "Usage: .\build [--debug|--release]"
exit

:release
cd mnist_predictor
cargo build --target i686-pc-windows-msvc --release
cd ..
mkdir build build\release
REM %FPC_BIN%\h2pas -D -c -S -l mnist_predictor.dll mnist_predictor.h
copy mnist_predictor\target\i686-pc-windows-msvc\release\mnist_predictor.dll build\release\mnist_predictor.dll
%FPC_BIN%\fpc mnist_predictor_app.pas -Pi386 -Twin32 -FEbuild\release -Mtp -Schij- -CX -O3 -XXs -B -v
exit

:debug
cd mnist_predictor
cargo build --target i686-pc-windows-msvc
cd ..
mkdir build build\debug
REM %FPC_BIN%\h2pas -D -c -S -l mnist_predictor.dll mnist_predictor.h
copy mnist_predictor\target\i686-pc-windows-msvc\debug\mnist_predictor.dll build\debug\mnist_predictor.dll
%FPC_BIN%\fpc mnist_predictor_app.pas -Pi386 -Twin32 -FEbuild\debug -Mtp -Scahij- -CroOti -O- -Xg -B -v -glpw2 -godwarfsets
exit