:: Extracter
:: 1.0.0
:: Vasyl Lukianenko 
:: 3DGROUND
:: https://3dground.net

echo off
cls

set input=%1
set arg1=
set arg2=
set fmt=
set ext=

for /f "tokens=1,2,3 delims=;" %%I in (%input%) do (
	set arg1=%%I
	set arg2=%%J
	set fmt=%%K
)

for %%f in ("%arg1%") do (
    set ext=%%~xf
)

mkdir "%arg2%"
echo %ext%
if /i %ext%==.zip (
	7za.exe x "%arg1%" -o"%arg2%" -y -r %fmt% -xr!resources -xr!PIX -xr!render -xr!renders -xr!rendersoutput -xr!renderoutput
)
 
if /i %ext%==.7z (
	7za.exe x "%arg1%" -o"%arg2%" -y -r %fmt% -xr!resources -xr!PIX -xr!render -xr!renders -xr!rendersoutput -xr!renderoutput
)

if /i %ext%==.rar (
	"C:\Program Files\WinRAR\WinRAR.exe" x -y -ibck -x*resources* -x*PIX* -x*render* -x*renders* -x*rendersoutput* -x*renderoutput* "%arg1%" "%arg2%" %fmt%
)



:: del "%arg1%" /f /q

exit 0
