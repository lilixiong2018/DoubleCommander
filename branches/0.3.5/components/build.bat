rem Compiling components

rem This script run from _make.bat
rem If you run it direct, set up %lazpath% first

pushd components
%lazpath%\lazbuild.exe KASToolBar\kascomp.lpk
%lazpath%\lazbuild.exe viewer\viewerpackage.lpk
popd