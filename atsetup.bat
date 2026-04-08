@echo off
cd /D "%~dp0"
setlocal enabledelayedexpansion
@set "PATH=%PATH%;%SystemRoot%\system32"

:: Generate the ESC character
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"

:: Standard Colors
set "BLACK=%ESC%[30m"
set "RED=%ESC%[31m"
set "GREEN=%ESC%[32m"
set "YELLOW=%ESC%[33m"
set "BLUE=%ESC%[34m"
set "MAGENTA=%ESC%[35m"
set "CYAN=%ESC%[36m"
set "WHITE=%ESC%[37m"
set "L_BLACK=%ESC%[90m"
set "L_RED=%ESC%[91m"
set "L_GREEN=%ESC%[92m"
set "L_YELLOW=%ESC%[93m"
set "L_BLUE=%ESC%[94m"
set "L_MAGENTA=%ESC%[95m"
set "L_CYAN=%ESC%[96m"
set "L_WHITE=%ESC%[97m"
set "RESET=%ESC%[0m"

echo "%CD%"| findstr /C:" " >nul &&  echo. && echo    %L_BLUE%ALLTALK WINDOWS SETUP UTILITY%RESET% && echo. &&  echo. &&  echo    You are trying to install AllTalk in a folder that has a space in the folder path e.g. && echo. && echo       C:\%L_RED%program files%RESET%\alltalk_tts && echo.	&& echo    This causes errors with Conda and Python scripts. Please follow this link for reference: &&  echo. && echo      %L_CYAN%https://docs.anaconda.com/free/working-with-conda/reference/faq/#installing-anaconda%RESET% && echo. && echo    Please use a folder path that has no spaces in it e.g. && echo. && echo       C:\myfiles\alltalk_tts\ && echo. && echo. && pause && goto :end

@rem Check for special characters in installation path
set "SPCHARMESSAGE="WARNING: Special characters were detected in the installation path!" "         This can cause the installation to fail!""
echo "%CD%"| findstr /R /C:"[!#\$%&()\*+,;<=>?@\[\]\^`{|}~]" >nul && (
	call :PrintBigMessage %SPCHARMESSAGE%
)
set SPCHARMESSAGE=

@rem Check if curl is available
curl --version >nul 2>&1
if "%ERRORLEVEL%" NEQ "0" (
    echo curl is not available on this system. Please install curl then re-run the script https://curl.se/ 
	echo or perform a manual installation of a Conda Python environment.
    goto end
)

:: Check for "-silent" install command-line argument
if "%1"=="-silent" goto SilentAutoDetect

:MainMenu
cls
echo.
echo    %L_BLUE%ALLTALK WINDOWS SETUP UTILITY%RESET%
echo.
echo    INSTALLATION TYPE
echo    1) I am using AllTalk as part of %L_GREEN%Text-generation-webui%RESET%
echo    2) I am using AllTalk as a %L_BLUE%Standalone Application%RESET%
echo.
echo    9) %L_RED%Exit/Quit%RESET%
echo.
echo.
set /p UserOption="    Enter your choice: "

if "%UserOption%"=="1" goto WebUIMenu
if "%UserOption%"=="2" goto StandaloneMenu
if "%UserOption%"=="9" goto End
goto MainMenu

:WebUIMenu
cls
echo.
echo    %L_BLUE%TEXT-GENERATION-WEBUI SETUP%RESET%
echo.
echo    Please ensure you have started your Text-generation-webui Python 
echo    environment. If you have NOT done this, please run %L_GREEN%cmd_windows.bat%RESET% 
echo    in the %L_GREEN%text-generation-webui%RESET% folder and then re-run this script.
echo.
echo    BASE REQUIREMENTS
echo    1) Apply/Re-Apply the requirements for %L_GREEN%Text-generation-webui%RESET%.
echo.
echo    OPTIONAL
echo    2) Git Pull the latest AllTalk updates from Github
echo.
echo    DEEPSPEED FOR %L_YELLOW=%PyTorch 2.1.x%RESET%
echo    4) Install DeepSpeed v11.2 for CUDA %L_GREEN%11.8%RESET% and Python-3.11.x and %L_YELLOW%PyTorch 2.1.x%RESET%.
echo    5) Install DeepSpeed v11.2 for CUDA %L_GREEN%12.1%RESET% and Python-3.11.x and %L_YELLOW%PyTorch 2.1.x%RESET%.
echo.
echo    DEEPSPEED FOR %L_YELLOW=%PyTorch 2.2.x%RESET% (March 2024 builds of Text-gen-webui and later)
echo    6) Install DeepSpeed v14.0 for CUDA %L_GREEN%12.1%RESET% and Python-3.11.x and %L_YELLOW%PyTorch 2.2.x%RESET%.
echo    7) Install DeepSpeed v14.0 for CUDA %L_GREEN%11.8%RESET% and Python-3.11.x and %L_YELLOW%PyTorch 2.2.x%RESET%.
echo.
echo    U) Uninstall DeepSpeed.
echo.
echo.   OTHER
echo    8) Generate a diagnostics file.
echo.
echo    9) %L_RED%Exit/Quit%RESET%
echo.
set /p WebUIOption="Enter your choice: "
if "%WebUIOption%"=="1" goto InstallNvidiaTextGen
if "%WebUIOption%"=="2" goto TGGitpull
if "%WebUIOption%"=="4" goto InstallDeepSpeed118TextGen
if "%WebUIOption%"=="5" goto InstallDeepSpeed121TextGen
if "%WebUIOption%"=="6" goto InstallDeepSpeed121TextGenPytorch221
if "%WebUIOption%"=="7" goto InstallDeepSpeed118TextGenPytorch221
if "%WebUIOption%"=="U" goto UnInstallDeepSpeed
if "%WebUIOption%"=="u" goto UnInstallDeepSpeed
if "%WebUIOption%"=="8" goto GenerateDiagsTextGen
if "%WebUIOption%"=="9" goto End
goto WebUIMenu

:StandaloneMenu
cls
echo.
echo    %L_BLUE%ALLTALK STANDALONE APPLICATION SETUP%RESET%
echo.
echo    BASE REQUIREMENTS
echo    1) Install AllTalk as a Standalone Application
echo.
echo    OPTIONAL
echo    2) Git Pull the latest AllTalk updates from Github
echo    3) Re-Apply/Update the requirements file
echo    4) Delete AllTalk's custom Python environment
echo    5) Purge the PIP cache
echo.
echo.   OTHER
echo    8) Generate a diagnostics file
echo.
echo    9) %L_RED%Exit/Quit%RESET%
echo.
set /p StandaloneOption="Enter your choice: "
if "%StandaloneOption%"=="1" goto StandaloneBackendMenu
if "%StandaloneOption%"=="2" goto STGitpull
if "%StandaloneOption%"=="3" goto STReapplyrequirements
if "%StandaloneOption%"=="4" goto STDeleteCustomStandalone
if "%StandaloneOption%"=="5" goto STPurgepipcache
if "%StandaloneOption%"=="8" goto GenerateDiagsStandalone
if "%StandaloneOption%"=="9" goto EndStandalone
goto StandaloneMenu

:InstallNvidiaTextGen
pip install -r system\requirements\requirements_textgen.txt
pip install -r system\requirements\requirements_textgen2.txt
pip install -r system\requirements\requirements_parler.txt
echo ** Faiss **
call "%CONDA_ROOT_PREFIX%\Scripts\conda.exe" install -y pytorch::faiss-cpu
echo ** FFmpeg **
call "%CONDA_ROOT_PREFIX%\Scripts\conda.exe" install -y -c conda-forge "ffmpeg=*=*gpl*"
call "%CONDA_ROOT_PREFIX%\Scripts\conda.exe" install -y -c conda-forge "ffmpeg=*=h*_*" --no-deps
if %ERRORLEVEL% neq 0 (
    echo.
    echo    There was an error installing the requirements.
    echo    Have you started your Text-gen-webui Python environment
    echo    with cmd_{yourOS} before running atsetup.bat?
    echo    Press any key to return to the menu.
    echo.
    pause
    goto WebUIMenu
)
Echo.
echo.
Echo    Requirements installed successfully.
Echo. 
pause
goto WebUIMenu

:TGGitpull
git pull
if %ERRORLEVEL% neq 0 (
    echo.
    echo    There was an error pulling from Github.
    echo    Press any key to return to the menu.
    echo.
    pause
    goto WebUIMenu
)
Echo.
echo     AllTalk Updated from Github. Please re-apply
echo     the latest requirements file. Option 1
Echo. 
pause
goto WebUIMenu

:InstallDeepSpeed118TextGen
echo Downloading DeepSpeed...
curl -LO https://github.com/erew123/alltalk_tts/releases/download/deepspeed/deepspeed-0.11.2+cuda118-cp311-cp311-win_amd64.whl
if %ERRORLEVEL% neq 0 (
    echo.
    echo    Failed to download DeepSpeed wheel file.
    echo    Please check your internet connection or try again later.
    echo    Press any key to return to the menu.
    echo.
    pause
    goto WebUIMenu
)
echo DeepSpeed wheel file downloaded successfully.
echo Installing DeepSpeed...
pip install deepspeed-0.11.2+cuda118-cp311-cp311-win_amd64.whl
if %ERRORLEVEL% neq 0 (
    echo. 
    echo    Failed to install DeepSpeed.
    echo    Please check if the wheel file is compatible with your system.
    echo    Press any key to return to the menu.
    echo.
    pause
    goto WebUIMenu
)
Echo.
echo.
Echo    DeepSpeed installed successfully.
Echo. 
del deepspeed-0.11.2+cuda118-cp311-cp311-win_amd64.whl
pause
goto WebUIMenu

:InstallDeepSpeed121TextGen
echo Downloading DeepSpeed...
curl -LO https://github.com/erew123/alltalk_tts/releases/download/deepspeed/deepspeed-0.11.2+cuda121-cp311-cp311-win_amd64.whl
if %ERRORLEVEL% neq 0 (
    echo.
    echo    Failed to download DeepSpeed wheel file.
    echo    Please check your internet connection or try again later.
    echo    Press any key to return to the menu.
    echo.
    pause
    goto WebUIMenu
)
echo    DeepSpeed wheel file downloaded successfully.
echo    Installing DeepSpeed...
pip install deepspeed-0.11.2+cuda121-cp311-cp311-win_amd64.whl
if %ERRORLEVEL% neq 0 (
    echo. 
    echo    Failed to install DeepSpeed.
    echo    Please check if the wheel file is compatible with your system.
    echo    Press any key to return to the menu.
    echo.
    pause
    goto WebUIMenu
)
Echo.
echo.
Echo    DeepSpeed installed successfully.
Echo. 
del deepspeed-0.11.2+cuda121-cp311-cp311-win_amd64.whl
pause
goto WebUIMenu

:InstallDeepSpeed121TextGenPytorch221
echo Downloading DeepSpeed...
curl -LO https://github.com/erew123/alltalk_tts/releases/download/DeepSpeed-14.0/deepspeed-0.14.0+ce78a63-cp311-cp311-win_amd64.whl
if %ERRORLEVEL% neq 0 (
    echo.
    echo    Failed to download DeepSpeed wheel file.
    echo    Please check your internet connection or try again later.
    echo    Press any key to return to the menu.
    echo.
    pause
    goto WebUIMenu
)
echo    DeepSpeed wheel file downloaded successfully.
echo    Installing DeepSpeed...
pip install deepspeed-0.14.0+ce78a63-cp311-cp311-win_amd64.whl
if %ERRORLEVEL% neq 0 (
    echo. 
    echo    Failed to install DeepSpeed.
    echo    Please check if the wheel file is compatible with your system.
    echo    Press any key to return to the menu.
    echo.
    pause
    goto WebUIMenu
)
Echo.
echo.
Echo    DeepSpeed installed successfully.
Echo. 
del deepspeed-0.14.0+ce78a63-cp311-cp311-win_amd64.whl
pause
goto WebUIMenu

:InstallDeepSpeed118TextGenPytorch221
echo Downloading DeepSpeed...
curl -LO https://github.com/erew123/alltalk_tts/releases/download/DeepSpeed-14.0/deepspeed-0.14.0+cu118-cp311-cp311-win_amd64.whl
if %ERRORLEVEL% neq 0 (
    echo.
    echo    Failed to download DeepSpeed wheel file.
    echo    Please check your internet connection or try again later.
    echo    Press any key to return to the menu.
    echo.
    pause
    goto WebUIMenu
)
echo    DeepSpeed wheel file downloaded successfully.
echo    Installing DeepSpeed...
pip install deepspeed-0.14.0+cu118-cp311-cp311-win_amd64.whl
if %ERRORLEVEL% neq 0 (
    echo. 
    echo    Failed to install DeepSpeed.
    echo    Please check if the wheel file is compatible with your system.
    echo    Press any key to return to the menu.
    echo.
    pause
    goto WebUIMenu
)
Echo.
echo.
Echo    DeepSpeed installed successfully.
Echo. 
del deepspeed-0.14.0+cu118-cp311-cp311-win_amd64.whl
pause
goto WebUIMenu

:UnInstallDeepSpeed
pip uninstall deepspeed
if %ERRORLEVEL% neq 0 (
    echo. 
    echo    There was an error uninstalling DeepSpeed.
    echo    Press any key to return to the menu.
    echo.
    pause
    goto WebUIMenu
)
echo.
Echo    DeepSpeed uninstalled successfully.
Echo. 
pause
goto WebUIMenu

:GenerateDiagsTextGen
Python diagnostics.py
if %ERRORLEVEL% neq 0 (
    echo.
    echo    There was an error running diagnostics. Have you correctly started your 
    echo    Text-generation-webui Python environment with %L_GREEN%cmd_windows.bat%RESET%?
    echo.
    pause
    goto WebUIMenu
)
Echo.
echo.
Echo    Diagnostics.log generated. Please scroll up to look over the log.
Echo. 
pause
goto WebUIMenu

:DetectGpu
@rem Sets DETECTED_GPU_NAME, DETECTED_GPU_CC, DETECTED_GPU_CC_MAJOR.
@rem When multiple GPUs are present, picks the highest compute capability.
set "DETECTED_GPU_NAME="
set "DETECTED_GPU_CC="
set "DETECTED_GPU_CC_MAJOR=0"
nvidia-smi --query-gpu=name,compute_cap --format=csv,noheader >nul 2>&1
if errorlevel 1 goto :eof
for /f "tokens=1,2 delims=," %%a in ('nvidia-smi --query-gpu=name^,compute_cap --format^=csv^,noheader 2^>nul') do (
    set "_n=%%a"
    set "_c=%%b"
    call :TrimSpaces _n
    call :TrimSpaces _c
    for /f "tokens=1 delims=." %%m in ("!_c!") do set "_m=%%m"
    if !_m! GEQ !DETECTED_GPU_CC_MAJOR! (
        set "DETECTED_GPU_NAME=!_n!"
        set "DETECTED_GPU_CC=!_c!"
        set "DETECTED_GPU_CC_MAJOR=!_m!"
    )
)
goto :eof

:TrimSpaces
@rem Trims leading spaces from the variable whose name is passed as %1.
for /f "tokens=* delims= " %%t in ("!%1!") do set "%1=%%t"
goto :eof

:StandaloneBackendMenu
cls
echo.
echo    %L_BLUE%ALLTALK STANDALONE - SELECT COMPUTE BACKEND%RESET%
echo.
call :DetectGpu
if defined DETECTED_GPU_NAME (
    echo    Detected: %L_GREEN%!DETECTED_GPU_NAME!%RESET% ^(compute capability !DETECTED_GPU_CC!^)
) else (
    echo    Detected: %L_YELLOW%no NVIDIA GPU found%RESET%
)
echo.
echo    1) %L_GREEN%Auto-detect%RESET% NVIDIA GPU and pick the right CUDA version  [recommended]
echo    2) NVIDIA GPU - force CUDA %L_GREEN%12.1%RESET% ^(RTX 30/40 series, PyTorch 2.2.1^)
echo    3) NVIDIA GPU - force CUDA %L_GREEN%12.8%RESET% ^(RTX 50 series / Blackwell, PyTorch 2.7.1^)
echo    4) %L_YELLOW%CPU only%RESET% ^(no GPU acceleration - significantly slower^)
echo.
echo    9) Back
echo.
set /p BackendOption="    Enter your choice: "
if "%BackendOption%"=="1" (
    if !DETECTED_GPU_CC_MAJOR! GEQ 12 (
        set "PYTORCH_VARIANT=cu128"
    ) else if !DETECTED_GPU_CC_MAJOR! GEQ 1 (
        set "PYTORCH_VARIANT=cu121"
    ) else (
        echo.
        echo    %L_YELLOW%No NVIDIA GPU detected.%RESET% Falling back to CPU-only install.
        echo    Press any key to continue, or close this window to abort.
        pause >nul
        set "PYTORCH_VARIANT=cpu"
    )
    goto InstallCustomStandalone
)
if "%BackendOption%"=="2" set "PYTORCH_VARIANT=cu121" & goto InstallCustomStandalone
if "%BackendOption%"=="3" set "PYTORCH_VARIANT=cu128" & goto InstallCustomStandalone
if "%BackendOption%"=="4" set "PYTORCH_VARIANT=cpu"   & goto InstallCustomStandalone
if "%BackendOption%"=="9" goto StandaloneMenu
goto StandaloneBackendMenu

:SilentAutoDetect
call :DetectGpu
if !DETECTED_GPU_CC_MAJOR! GEQ 12 (
    set "PYTORCH_VARIANT=cu128"
    echo Silent mode: detected !DETECTED_GPU_NAME! ^(cc !DETECTED_GPU_CC!^) - using cu128
) else if !DETECTED_GPU_CC_MAJOR! GEQ 1 (
    set "PYTORCH_VARIANT=cu121"
    echo Silent mode: detected !DETECTED_GPU_NAME! ^(cc !DETECTED_GPU_CC!^) - using cu121
) else (
    set "PYTORCH_VARIANT=cpu"
    echo Silent mode: no NVIDIA GPU detected - using CPU-only install
)
goto InstallCustomStandalone

:InstallCustomStandalone
@rem Fallback variant if nothing picked one.
if not defined PYTORCH_VARIANT set "PYTORCH_VARIANT=cu121"
set PATH=%PATH%;%SystemRoot%\system32

@rem Check if curl is available
curl --version >nul 2>&1
if "%ERRORLEVEL%" NEQ "0" (
    echo curl is not available on this system. Please install curl then re-run the script https://curl.se/ 
	echo or perform a manual installation of a Conda Python environment.
    goto end
)
echo "%CD%"| findstr /C:" " >nul && echo This script relies on Miniconda which can not be silently installed under a path with spaces. Please correct your folder names and re-try installation. && goto exit

@rem Check for special characters in installation path
set "SPCHARMESSAGE=WARNING: Special characters were detected in the installation path! This can cause the installation to fail!"
echo "%CD%"| findstr /R /C:"[!#\$%&()\*+,;<=>?@\[\]\^`{|}~]" >nul && (
    call :PrintBigMessage %SPCHARMESSAGE%
)
set SPCHARMESSAGE=

@rem fix failed install when installing to a separate drive
set TMP=%cd%\alltalk_environment
set TEMP=%cd%\alltalk_environment

@rem deactivate existing conda envs as needed to avoid conflicts
(call conda deactivate && call conda deactivate && call conda deactivate) 2>nul

@rem config
set INSTALL_DIR=%cd%\alltalk_environment
set CONDA_ROOT_PREFIX=%cd%\alltalk_environment\conda
set INSTALL_ENV_DIR=%cd%\alltalk_environment\env
set MINICONDA_DOWNLOAD_URL=https://repo.anaconda.com/miniconda/Miniconda3-py311_24.4.0-0-Windows-x86_64.exe
set conda_exists=F

@rem figure out whether git and conda need to be installed
call "%CONDA_ROOT_PREFIX%\_conda.exe" --version >nul 2>&1
if "%ERRORLEVEL%" EQU "0" (
    set conda_exists=T
    call "%CONDA_ROOT_PREFIX%\condabin\conda.bat" activate "%INSTALL_ENV_DIR%"
    goto RunScript
)

@rem download and install conda if not installed
echo Downloading Miniconda from %MINICONDA_DOWNLOAD_URL% to %INSTALL_DIR%\miniconda_installer.exe
mkdir "%INSTALL_DIR%"
call curl -Lk "%MINICONDA_DOWNLOAD_URL%" > "%INSTALL_DIR%\miniconda_installer.exe" || ( echo. && echo Miniconda failed to download. && goto end )
echo Installing Miniconda to %CONDA_ROOT_PREFIX%
start /wait "" "%INSTALL_DIR%\miniconda_installer.exe" /InstallationType=JustMe /NoShortcuts=1 /AddToPath=0 /RegisterPython=0 /NoRegistry=1 /S /D=%CONDA_ROOT_PREFIX%
echo Miniconda version:
call "%CONDA_ROOT_PREFIX%\_conda.exe" --version || ( echo. && echo Miniconda not found. && goto end )

@rem create the installer env
echo Packages to install: %PACKAGES_TO_INSTALL%
call "%CONDA_ROOT_PREFIX%\_conda.exe" create --no-shortcuts -y -k --prefix "%INSTALL_ENV_DIR%" python=3.11.9 || ( echo. && echo Conda environment creation failed. && goto end )

@rem check if conda environment was actually created
if not exist "%INSTALL_ENV_DIR%\python.exe" ( echo. && echo Conda environment is empty. && goto end )

@rem activate installer env
call "%CONDA_ROOT_PREFIX%\condabin\conda.bat" activate "%INSTALL_ENV_DIR%" || ( echo. && echo Miniconda hook not found. && goto end )
rem Install required packages

@rem Pre-seed `libglib` from conda-forge BEFORE FFmpeg's conda-forge install runs.
@rem Without this, the conda solver happily picks `libglib` from `pkgs/main`
@rem (defaults channel) while it picks `gdk-pixbuf` and `libintl 0.22.5` from
@rem conda-forge. The `pkgs/main` libglib was linked against an older gettext that
@rem exports `bind_textdomain_codeset` without the `libintl_` prefix, while
@rem conda-forge `gdk_pixbuf-2.0-0.dll` imports `libintl_bind_textdomain_codeset` -
@rem the postlink script `gdk-pixbuf-query-loaders.exe` then crashes mid-install
@rem with "Einsprungpunkt nicht gefunden". Forcing libglib to conda-forge keeps
@rem the whole glib/pixbuf/intl chain on the new ABI.
echo ** Pre-seeding libglib from conda-forge (libintl ABI fix) **
call "%CONDA_ROOT_PREFIX%\Scripts\conda.exe" install -y -c conda-forge --strict-channel-priority libglib libintl
echo.

:install_pytorch
@rem Dispatcher: branch on PYTORCH_VARIANT chosen in StandaloneBackendMenu.
echo ** Selected PyTorch variant: %PYTORCH_VARIANT% **
if /I "%PYTORCH_VARIANT%"=="cu128" goto install_pytorch_cu128
if /I "%PYTORCH_VARIANT%"=="cpu"   goto install_pytorch_cpu
goto install_pytorch_cu121

:install_pytorch_cu121
echo ** Installing PyTorch 2.2.1 (CUDA 12.1) **
call "%CONDA_ROOT_PREFIX%\Scripts\conda.exe" install -y pytorch==2.2.1 torchvision==0.17.1 torchaudio==2.2.1 pytorch-cuda=12.1 -c pytorch -c nvidia
echo.
if errorlevel 1 (
    echo PyTorch installation failed, errorlevel was %errorlevel%.
    echo See the AllTalk Github Wiki ^> Error Messages Help/Support for known errors.
    echo.
    choice /C YN /M "Do you want to retry the Pytorch installation?"
    if errorlevel 2 goto End
    if errorlevel 1 goto install_pytorch_cu121
) else (
    echo PyTorch installation was successful.
    echo.
)
goto install_pytorch_done

:install_pytorch_cu128
echo ** Installing PyTorch 2.7.1 (CUDA 12.8 - Blackwell / RTX 50 series) **
@rem Use pip wheels from PyTorch's cu128 index. Conda has no pytorch-cuda=12.8 build,
@rem and only torch >= 2.7 ships sm_120 kernels required by Blackwell GPUs.
pip install torch==2.7.1 torchvision==0.22.1 torchaudio==2.7.1 --index-url https://download.pytorch.org/whl/cu128
echo.
if errorlevel 1 (
    echo PyTorch installation failed, errorlevel was %errorlevel%.
    echo.
    choice /C YN /M "Do you want to retry the Pytorch installation?"
    if errorlevel 2 goto End
    if errorlevel 1 goto install_pytorch_cu128
) else (
    echo PyTorch installation was successful.
    echo.
)
goto install_pytorch_done

:install_pytorch_cpu
echo ** Installing PyTorch 2.7.1 (CPU only) **
pip install torch==2.7.1 torchvision==0.22.1 torchaudio==2.7.1 --index-url https://download.pytorch.org/whl/cpu
echo.
if errorlevel 1 (
    echo PyTorch installation failed, errorlevel was %errorlevel%.
    echo.
    choice /C YN /M "Do you want to retry the Pytorch installation?"
    if errorlevel 2 goto End
    if errorlevel 1 goto install_pytorch_cpu
) else (
    echo PyTorch installation was successful.
    echo.
)
goto install_pytorch_done

:install_pytorch_done

:install_faiss
echo ** Installing Faiss **
call "%CONDA_ROOT_PREFIX%\Scripts\conda.exe" install -y pytorch::faiss-cpu
echo.
if errorlevel 1 (
    echo Faiss installation failed, errorlevel was %errorlevel%. There should be a Conda
    echo error message above with a code and/or text explanation of the issue. Please note 
    echo the error code to help with diagnotics. 
    echo.
    echo Generally speaking though, errors could be caused by:
    echo.
    echo      1. Internet connection issues/unable to download Faiss from Conda's website.
    echo      2. Disk space related issues - Check your disk space on this drive.
    echo      3. Incorrect or missing Conda environment - Restart installation.
    echo      4. Permissions issues - Check you have enough rights on this system.
    echo      5. Firewall or proxy settings blocking access to Conda's servers.
    echo      6. Antivirus or security software interference.
    echo      7. Your Conda policy is set to Strict see the Github Wiki for help with this.
    echo      8. Other issues not mentioned above.
    echo.
    echo      Known errors are in the AllTalk Github Wiki > Error Messages Help/Support
    echo.
    choice /C YN /M "Do you want to retry the Faiss installation?"
    if errorlevel 2 goto End
    if errorlevel 1 goto install_faiss
) else (
    echo Faiss installation was successful.
    echo.
)

:install_ffmpeg
echo ** Installing FFmpeg **
@rem --strict-channel-priority ensures conda-forge wins for the entire ffmpeg
@rem dependency closure (libglib, gdk-pixbuf, libintl, etc.). Without this, the
@rem solver mixes pkgs/main and conda-forge for glib and triggers the
@rem `libintl_bind_textdomain_codeset` postlink crash described above.
call "%CONDA_ROOT_PREFIX%\Scripts\conda.exe" install -y -c conda-forge --strict-channel-priority "ffmpeg=*=*gpl*"
call "%CONDA_ROOT_PREFIX%\Scripts\conda.exe" install -y -c conda-forge --strict-channel-priority "ffmpeg=*=h*_*" --no-deps
echo.
if errorlevel 1 (
    echo FFmpeg installation failed, errorlevel was %errorlevel%. There should be a Conda
    echo error message above with a code and/or text explanation of the issue. Please note 
    echo the error code to help with diagnotics. 
    echo.
    echo Generally speaking though, errors could be caused by:
    echo.
    echo      1. Internet connection issues/unable to download FFmpeg from Conda's website.
    echo      2. Disk space related issues - Check your disk space on this drive.
    echo      3. Incorrect or missing Conda environment - Restart installation.
    echo      4. Permissions issues - Check you have enough rights on this system.
    echo      5. Firewall or proxy settings blocking access to Conda's servers.
    echo      6. Antivirus or security software interference.
    echo      7. Your Conda policy is set to Strict see the Github Wiki for help with this.
    echo      8. Other issues not mentioned above.
    echo.
    echo      Known errors are in the AllTalk Github Wiki > Error Messages Help/Support
    echo.
    choice /C YN /M "Do you want to retry the FFmpeg installation?"
    if errorlevel 2 goto End
    if errorlevel 1 goto install_ffmpeg
) else (
    echo FFmpeg installation was successful.
    echo.
)


@rem On the cu128/cpu branches, torch 2.7 was installed via pip and pulled numpy 2.x,
@rem but the subsequent `conda install faiss-cpu` from the `pytorch` channel drags in
@rem `numpy 1.26` from `pkgs/main` and downgrades numpy in place. Pip-installed pandas
@rem (in requirements_standalone.txt) is built against the numpy 2.x ABI and crashes
@rem at import time with "numpy._core.multiarray failed to import". Force numpy back
@rem to 2.x before installing the pip requirements. The cu121 branch keeps numpy 1.x
@rem because torch 2.2 expects it.
if /I "%PYTORCH_VARIANT%"=="cu128" goto force_numpy2
if /I "%PYTORCH_VARIANT%"=="cpu"   goto force_numpy2
goto skip_force_numpy2
:force_numpy2
echo ** Reasserting numpy^>=2 (faiss-cpu downgrade fix) **
pip install --upgrade --force-reinstall "numpy>=2.0,<3"
echo.
:skip_force_numpy2

echo ** Requirements file **
pip install -r system\requirements\requirements_standalone.txt
echo.

@rem Remove the deprecated `pynvml` package if a transitive dependency pulled it in.
@rem `nvidia-ml-py` (installed via requirements_standalone.txt) is the official replacement
@rem and provides the same `pynvml` module name, so `import pynvml` still works and the
@rem FutureWarning emitted from torch/cuda/__init__.py goes away.
echo ** Removing deprecated pynvml package (replaced by nvidia-ml-py) **
pip uninstall -y pynvml
echo.

@rem Persist the chosen backend variant so subsequent runs of atsetup.bat
@rem (e.g. DeepSpeed install) can react to it without re-prompting.
> "%INSTALL_DIR%\variant.txt" echo %PYTORCH_VARIANT%

@rem DeepSpeed has no Blackwell-capable Windows wheel and is irrelevant on CPU.
@rem For cu128 / cpu installs, disable it in every model_settings.json so xtts
@rem doesn't try to load deepspeed on first run.
if /I "%PYTORCH_VARIANT%"=="cu128" goto disable_deepspeed
if /I "%PYTORCH_VARIANT%"=="cpu"   goto disable_deepspeed
goto skip_disable_deepspeed
:disable_deepspeed
echo ** Disabling DeepSpeed in model_settings.json files (not supported on %PYTORCH_VARIANT%) **
@rem Read each settings file fully, THEN write. The previous one-liner used
@rem `open(p,'w').write(json.dumps({**json.load(open(p)), ...}))` which truncated
@rem the file before reading because Python evaluates the call receiver before its
@rem arguments. The lambda form below evaluates `json.load(open(p))` as a function
@rem argument first, so the read completes before `open(p,'w')` truncates.
python -c "import json,glob; [(lambda d,p: open(p,'w').write(json.dumps({**d,'deepspeed_enabled':False},indent=4)))(json.load(open(p)),p) for p in glob.glob('system/tts_engines/**/model_settings.json',recursive=True)]"
echo.
:skip_disable_deepspeed

:update_gradio
echo ** Updating Gradio **
pip install --upgrade gradio==4.44.1
echo.
if errorlevel 1 (
    echo Gradio update failed, errorlevel was %errorlevel%. There should be an error
    echo message above with a code and/or text explanation of the issue. Please note 
    echo the error code to help with diagnotics. 
    echo.
    echo Generally speaking though, errors could be caused by:
    echo.
    echo      1. Internet connection issues/unable to download Gradio from PyPI.
    echo      2. Disk space related issues - Check your disk space on this drive.
    echo      3. Incorrect or missing Python environment - Restart installation.
    echo      4. Permissions issues - Check you have enough rights on this system.
    echo      5. Firewall or proxy settings blocking access to PyPI servers.
    echo      6. Antivirus or security software interference.
    echo      7. Other issues not mentioned above.
    echo.
    echo      Known errors are in the AllTalk Github Wiki > Error Messages Help/Support
    echo.
    choice /C YN /M "Do you want to retry the Gradio update?"
    if errorlevel 2 goto End
    if errorlevel 1 goto update_gradio
) else (
    echo Gradio update was successful.
    echo.
)

:install_deepspeed
echo ** Downloading DeepSpeed **
curl -LO https://github.com/erew123/alltalk_tts/releases/download/DeepSpeed-14.0/deepspeed-0.14.0+ce78a63-cp311-cp311-win_amd64.whl
echo.
if errorlevel 1 (
    echo DeepSpeed download failed, errorlevel was %errorlevel%. There should be an error
    echo message above with a code and/or text explanation of the issue. Please note 
    echo the error code to help with diagnotics. 
    echo.
    echo Generally speaking though, errors could be caused by:
    echo.
    echo      1. Internet connection issues/unable to reach GitHub.
    echo      2. Disk space related issues - Check your disk space on this drive.
    echo      3. Permissions issues - Check you have enough rights on this system.
    echo      4. Firewall or proxy settings blocking access to GitHub.
    echo      5. Antivirus or security software interference.
    echo      6. The file may have been moved or deleted from the GitHub repository.
    echo      7. Other issues not mentioned above.
    echo.
    echo      Known errors are in the AllTalk Github Wiki > Error Messages Help/Support
    echo.
    choice /C YN /M "Do you want to retry the DeepSpeed download?"
    if errorlevel 2 goto End
    if errorlevel 1 goto install_deepspeed
) else (
    echo DeepSpeed download was successful.
    echo.
)

echo ** Installing DeepSpeed **
pip install deepspeed-0.14.0+ce78a63-cp311-cp311-win_amd64.whl
echo.
if errorlevel 1 (
    echo DeepSpeed installation failed, errorlevel was %errorlevel%. There should be an error
    echo message above with a code and/or text explanation of the issue. Please note 
    echo the error code to help with diagnotics. General issues may be:
    echo.
    echo Generally speaking though, errors could be caused by:
    echo.
    echo      1. The DeepSpeed wheel file was not downloaded successfully in the previous step.
    echo      2. Microsoft C++ development tools for Python are not installed correctly.
    echo      3. Disk space related issues - Check your disk space on this drive.
    echo      4. Incorrect or missing Python environment - Restart installation.
    echo      5. Permissions issues - Check you have enough rights on this system.
    echo      6. Antivirus or security software interference.
    echo      7. Other issues not mentioned above.
    echo.
    echo      Known errors are in the AllTalk Github Wiki > Error Messages Help/Support
    echo.
    echo Please ensure you have followed the instructions to install the Microsoft C++ development
    echo tools for Python, which is detailed on the AllTalk GitHub page.
    echo.
    choice /C YN /M "Do you want to retry the DeepSpeed installation?"
    if errorlevel 2 goto End
    if errorlevel 1 goto install_deepspeed
) else (
    echo DeepSpeed installation was successful.
    del deepspeed-0.14.0+ce78a63-cp311-cp311-win_amd64.whl
    echo.
)

echo ** Installing Parler **
pip install -r system\requirements\requirements_parler.txt
echo Clean Environment
call "%CONDA_ROOT_PREFIX%\Scripts\conda.exe" clean --all --force-pkgs-dirs -y
echo.

echo.
echo Installation process completed.
if /I "%PYTORCH_VARIANT%"=="cpu" (
    echo.
    echo    %L_YELLOW%CPU-only install selected.%RESET% xtts generation will be significantly
    echo    slower than on a GPU. To switch to a GPU backend later, re-run atsetup.bat
    echo    and choose option 1 ^(Install AllTalk as a Standalone Application^).
)
if /I "%PYTORCH_VARIANT%"=="cu128" (
    echo.
    echo    %L_YELLOW%DeepSpeed has been disabled%RESET% - no Blackwell-capable Windows wheel
    echo    is currently available for PyTorch 2.7 / CUDA 12.8. xtts will run without it.
)

@rem Create start_environment.bat to run AllTalk environment
echo @echo off > start_environment.bat
echo cd /D "%~dp0" >> start_environment.bat
echo set CONDA_ROOT_PREFIX=%cd%\alltalk_environment\conda >> start_environment.bat
echo set INSTALL_ENV_DIR=%cd%\alltalk_environment\env >> start_environment.bat
echo call "%CONDA_ROOT_PREFIX%\condabin\conda.bat" activate "%INSTALL_ENV_DIR%" >> start_environment.bat
@rem Create start_alltalk.bat to run AllTalk
echo @echo off > start_alltalk.bat
echo cd /D "%~dp0" >> start_alltalk.bat
echo set CONDA_ROOT_PREFIX=%cd%\alltalk_environment\conda >> start_alltalk.bat
echo set INSTALL_ENV_DIR=%cd%\alltalk_environment\env >> start_alltalk.bat
echo call "%CONDA_ROOT_PREFIX%\condabin\conda.bat" activate "%INSTALL_ENV_DIR%" >> start_alltalk.bat
echo call python script.py >> start_alltalk.bat
@rem Create start_finetune.bat to run AllTalk
echo @echo off > start_finetune.bat
echo cd /D "%~dp0" >> start_finetune.bat
echo set CONDA_ROOT_PREFIX=%cd%\alltalk_environment\conda >> start_finetune.bat
echo set INSTALL_ENV_DIR=%cd%\alltalk_environment\env >> start_finetune.bat
echo call "%CONDA_ROOT_PREFIX%\condabin\conda.bat" activate "%INSTALL_ENV_DIR%" >> start_finetune.bat
echo call python finetune.py >> start_finetune.bat
echo @echo off > start_diagnostics.bat
echo cd /D "%~dp0" >> start_diagnostics.bat
echo set CONDA_ROOT_PREFIX=%cd%\alltalk_environment\conda >> start_diagnostics.bat
echo set INSTALL_ENV_DIR=%cd%\alltalk_environment\env >> start_diagnostics.bat
echo call "%CONDA_ROOT_PREFIX%\condabin\conda.bat" activate "%INSTALL_ENV_DIR%" >> start_diagnostics.bat
echo call python diagnostics.py >> start_diagnostics.bat
Echo.
Echo    Run %L_YELLOW%start_alltalk.bat%RESET% to start AllTalk.
Echo    Run %L_YELLOW%start_diagnostics.bat%RESET% to start the diagnostics.
Echo    Run %L_YELLOW%start_finetune.bat%RESET% to start Finetuning.
Echo    Run %L_YELLOW%start_environment.bat%RESET% to start the AllTalk Python environment.
Echo. 
Echo    Documentation is built into the Gradio interface. Please explore the documentation for
Echo    tips, troubleshooing and explanations as most common questions are answered there.
Echo.
if "%1"=="-silent" goto End
pause
goto StandaloneMenu

:STDeleteCustomStandalone
@rem Check if the alltalk_environment directory exists
if not exist "%cd%\alltalk_environment\" (
    echo.
    echo    %L_GREEN%alltalk_environment%RESET% directory does not exist. No need to delete.
    echo.
    pause
    goto StandaloneMenu
)
@rem Check if a Conda environment is active
if not defined CONDA_PREFIX goto NoCondaEnvDeleteCustomStandalone
@rem Deactivate Conda environment if it's active
Echo    Exiting the Conda Environment. Please run %L_GREEN%atsetup.bat%RESET% again and delete the environment.
call conda deactivate
:NoCondaEnvDeleteCustomStandalone
echo Deleting "alltalk_environment". Please wait.
rd /s /q "alltalk_environment"
del start_alltalk.bat
del start_environment.bat
if %ERRORLEVEL% neq 0 (
    echo.
    echo    Failed to delete alltalk_environment folder.
    echo    Please make sure it is not in use and try again.
    echo    Worst case, manually delete the folder called 'alltalk_environment'
    echo.
    pause
    goto StandaloneMenu
)
echo.
Echo.
echo    Environment %L_GREEN%alltalk_environment%RESET% deleted. Please set up the environment again.
Echo.
pause
goto StandaloneMenu

:GenerateDiagsStandalone
cd /D "%~dp0"
set CONDA_ROOT_PREFIX=%cd%\alltalk_environment\conda
set INSTALL_ENV_DIR=%cd%\alltalk_environment\env
@rem Check if the Conda environment exists
if not exist "%INSTALL_ENV_DIR%\python.exe" (
    echo.
    echo    The Conda environment at "%INSTALL_ENV_DIR%" does not exist.
    echo    Please install the environment before proceeding.
    echo. 
    pause
    goto StandaloneMenu
)
@rem Attempt to activate the Conda environment
call "%CONDA_ROOT_PREFIX%\condabin\conda.bat" activate "%INSTALL_ENV_DIR%"
if errorlevel 1 (
    echo. 
    echo    Failed to activate the Conda environment.
    echo    Please check your installation and try again.
    echo.
    pause
    goto StandaloneMenu
)
@rem Run diagnostics
Python diagnostics.py
if %ERRORLEVEL% neq 0 (
    echo.
    echo    There was an error running diagnostics.
    echo    Press any key to return to the menu.
    echo.
    pause
    goto StandaloneMenu
)
Echo.
Echo.
Echo    Diagnostics.log generated. Please scroll up to look over the log.
Echo.
pause
goto StandaloneMenu

:STReapplyrequirements
cd /D "%~dp0"
set CONDA_ROOT_PREFIX=%cd%\alltalk_environment\conda
set INSTALL_ENV_DIR=%cd%\alltalk_environment\env
@rem Check if the Conda environment exists
if not exist "%INSTALL_ENV_DIR%\python.exe" (
    echo.
    echo    The Conda environment at "%INSTALL_ENV_DIR%" does not exist.
    echo    Please install the environment before proceeding.
    echo. 
    pause
    goto StandaloneMenu
)
@rem Attempt to activate the Conda environment
call "%CONDA_ROOT_PREFIX%\condabin\conda.bat" activate "%INSTALL_ENV_DIR%"
if errorlevel 1 (
    echo. 
    echo    Failed to activate the Conda environment.
    echo    Please check your installation and try again.
    echo.
    pause
    goto StandaloneMenu
)
@rem Run Reapply requirements
echo.
echo  Re-installing requirements. If you have problems after this, it may indicate 
echo  that the custom Python environment is damaged in some way. As such it may be
echo  best to delete the custom Python environment and re-run the entire setup
echo  routine again to rebuild AllTalk's Python environment. Please press a key
echo  to continue re-applying the Requirements for a standalone installation.
echo.
pause
goto install_faiss

:STPurgepipcache
cd /D "%~dp0"
set CONDA_ROOT_PREFIX=%cd%\alltalk_environment\conda
set INSTALL_ENV_DIR=%cd%\alltalk_environment\env
@rem Check if the Conda environment exists
if not exist "%INSTALL_ENV_DIR%\python.exe" (
    echo.
    echo    The Conda environment at "%INSTALL_ENV_DIR%" does not exist.
    echo    Please install the environment before proceeding.
    echo. 
    pause
    goto StandaloneMenu
)
@rem Attempt to activate the Conda environment
call "%CONDA_ROOT_PREFIX%\condabin\conda.bat" activate "%INSTALL_ENV_DIR%"
if errorlevel 1 (
    echo. 
    echo    Failed to activate the Conda environment.
    echo    Please check your installation and try again.
    echo.
    pause
    goto StandaloneMenu
)
@rem Clear the PIP cache
echo.
echo     Purging the PIP cache of downloaded files.
echo.
pip cache purge
if %ERRORLEVEL% neq 0 (
    echo.
    echo    There was an error.
    echo    Press any key to return to the menu.
    echo.
    pause
    goto StandaloneMenu
)
Echo.
Echo    The PIP cache has been purged.
Echo.
pause
goto StandaloneMenu

:STGitpull
cd /D "%~dp0"
set CONDA_ROOT_PREFIX=%cd%\alltalk_environment\conda
set INSTALL_ENV_DIR=%cd%\alltalk_environment\env
@rem Check if the Conda environment exists
if not exist "%INSTALL_ENV_DIR%\python.exe" (
    echo.
    echo    The Conda environment at "%INSTALL_ENV_DIR%" does not exist.
    echo    Please install the environment before proceeding.
    echo. 
    pause
    goto StandaloneMenu
)
@rem Attempt to activate the Conda environment
call "%CONDA_ROOT_PREFIX%\condabin\conda.bat" activate "%INSTALL_ENV_DIR%"
if errorlevel 1 (
    echo. 
    echo    Failed to activate the Conda environment.
    echo    Please check your installation and try again.
    echo.
    pause
    goto StandaloneMenu
)
@rem Pull from Github
echo.
echo     Pulling the latest updates. Please re-apply
echo     the latest requirements file. Option 3
echo.
git pull
if %ERRORLEVEL% neq 0 (
    echo.
    echo    There was an error pulling from Github.
    echo    Press any key to return to the menu.
    echo.
    pause
    goto StandaloneMenu
)
Echo.
echo     AllTalk Updated from Github. Please re-apply
echo     the latest requirements file. Option 3
Echo.
pause
goto StandaloneMenu

:EndStandalone
echo Exiting AllTalk Setup Utility...
echo.
Echo    Remember, after installation you can....
Echo.
Echo    Run %L_YELLOW%start_alltalk.bat%RESET% to start AllTalk.
Echo    Run %L_YELLOW%start_finetune.bat%RESET% to start Finetuning.
Echo    Run %L_YELLOW%start_environment.bat%RESET% to start the AllTalk Python environment.
Echo    Run %L_YELLOW%start_diagnostics.bat%RESET% to start generate a diagnostics file.
Echo.
Echo    Documentation is built into the Gradio interface. Please explore the documentation for
Echo    tips, troubleshooing and explanations as most common questions are answered there.
exit /b

:End
echo Exiting AllTalk Setup Utility...
Echo.
Echo    Documentation is built into the Gradio interface and the AllTalk Wiki page on Github.
Echo    Please explore the documentation for tips, troubleshooing and explanations on the most
Echo    common questions.
exit /b
