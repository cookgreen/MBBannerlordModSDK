
setlocal EnableDelayedExpansion

FOR /F "tokens=1,2 delims==" %%A IN (mod.ini) DO (set %%A=%%B)
xcopy SubModule\* "%BANNERLORD_DIRECTORY%\Modules\%MOD_NAME%\*" /Y /R /E

cd "%BANNERLORD_DIRECTORY%\bin\Win64_Shipping_Client"

%BANNERLORD_ROOT_DRIVE%

"%BANNERLORD_DIRECTORY%\bin\Win64_Shipping_Client\Bannerlord.exe" /singleplayer _MODULES_*Native*SandBoxCore*CustomBattle*SandBox*StoryMode*%MOD_NAME%*_MODULES_