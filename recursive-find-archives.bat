@echo off
setlocal

set input=%1
set folder=
set arg2=

for /f "tokens=1,2 delims=;" %%I in (%input%) do (
	set folder=%%I
	set arg2=%%J
)

set ini=%folder%files.ini



echo Searching for .rar, .zip, and .7z files in %source_folder% and its subfolders...
echo. > "%ini%"
echo [FILES] >> "%ini%"

for /r "%folder%" %%f in (*.rar *.zip *.7z) do (   
    echo %%f= >> "%ini%"
)

exit 0
