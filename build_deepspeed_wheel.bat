@echo off
cd /D "%~dp0"
setlocal enabledelayedexpansion

:: ============================================================================
:: Build DeepSpeed wheel for Windows
:: Targets: Blackwell (RTX 5090/5080/5070) + older architectures
:: Requires: Visual Studio Build Tools 2022 with C++ workload, CUDA Toolkit 12.8+
:: ============================================================================

set "DEEPSPEED_VERSION=0.17.2"
set "BUILD_DIR=%cd%\deepspeed_build"

:: CUDA compute capabilities to compile for:
::   8.0  = Ampere data center (A100)
::   8.6  = Ampere consumer (RTX 3060/3070/3080/3090)
::   8.9  = Ada Lovelace (RTX 4060/4070/4080/4090)
::   12.0 = Blackwell consumer (RTX 5070/5080/5090)
:: Add/remove as needed. More targets = longer build time.
set "TORCH_CUDA_ARCH_LIST=8.0;8.6;8.9;12.0"

:: ============================================================================
:: Activate AllTalk conda environment
:: ============================================================================
set "CONDA_ROOT_PREFIX=%cd%\alltalk_environment\conda"
set "INSTALL_ENV_DIR=%cd%\alltalk_environment\env"

if not exist "%CONDA_ROOT_PREFIX%\_conda.exe" (
    echo ERROR: AllTalk conda environment not found at %CONDA_ROOT_PREFIX%
    echo        Run atsetup.bat first to install AllTalk.
    goto :error
)

call "%CONDA_ROOT_PREFIX%\condabin\conda.bat" activate "%INSTALL_ENV_DIR%"
if errorlevel 1 (
    echo ERROR: Failed to activate AllTalk conda environment.
    goto :error
)

:: ============================================================================
:: Check prerequisites
:: ============================================================================
echo.
echo ============================================================
echo  DeepSpeed %DEEPSPEED_VERSION% Wheel Builder for Windows
echo  CUDA architectures: %TORCH_CUDA_ARCH_LIST%
echo ============================================================
echo.

:: Check Python
python --version 2>nul
if errorlevel 1 (
    echo ERROR: Python not found in environment.
    goto :error
)

:: Check PyTorch + CUDA
python -c "import torch; print(f'PyTorch {torch.__version__}, CUDA {torch.version.cuda}')" 2>nul
if errorlevel 1 (
    echo ERROR: PyTorch not found. Install PyTorch first.
    goto :error
)

:: Detect PyTorch's CUDA version and force the matching toolkit
:: (system PATH may have a different CUDA version, e.g. 13.2 vs PyTorch's 12.8)
for /f "delims=" %%V in ('python -c "import torch; v=torch.version.cuda; print(f'v{v.split(chr(46))[0]}.{v.split(chr(46))[1]}')"') do set "TORCH_CUDA_VER=%%V"
echo PyTorch expects CUDA toolkit: %TORCH_CUDA_VER%

set "CUDA_TOOLKIT_DIR=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\%TORCH_CUDA_VER%"
if exist "%CUDA_TOOLKIT_DIR%\bin\nvcc.exe" (
    echo Found matching CUDA toolkit at %CUDA_TOOLKIT_DIR%
    set "CUDA_HOME=%CUDA_TOOLKIT_DIR%"
    set "CUDA_PATH=%CUDA_TOOLKIT_DIR%"
    set "PATH=%CUDA_TOOLKIT_DIR%\bin;%CUDA_TOOLKIT_DIR%\lib\x64;%PATH%"
) else (
    echo ERROR: CUDA Toolkit %TORCH_CUDA_VER% not found at %CUDA_TOOLKIT_DIR%
    echo        Install it from https://developer.nvidia.com/cuda-toolkit-archive
    echo        Multiple CUDA toolkits can coexist side-by-side.
    goto :error
)

:: Check MSVC (cl.exe)
where cl >nul 2>&1
if errorlevel 1 (
    echo MSVC compiler not in PATH. Attempting to find Visual Studio...
    :: Try VS2022 first, then VS2019
    for %%V in (2022 2019) do (
        for %%E in (Enterprise Professional Community BuildTools) do (
            if exist "C:\Program Files\Microsoft Visual Studio\%%V\%%E\VC\Auxiliary\Build\vcvarsall.bat" (
                echo Found Visual Studio %%V %%E, loading environment...
                call "C:\Program Files\Microsoft Visual Studio\%%V\%%E\VC\Auxiliary\Build\vcvarsall.bat" x64
                goto :msvc_found
            )
            if exist "C:\Program Files (x86)\Microsoft Visual Studio\%%V\%%E\VC\Auxiliary\Build\vcvarsall.bat" (
                echo Found Visual Studio %%V %%E, loading environment...
                call "C:\Program Files (x86)\Microsoft Visual Studio\%%V\%%E\VC\Auxiliary\Build\vcvarsall.bat" x64
                goto :msvc_found
            )
        )
    )
    echo ERROR: Visual Studio Build Tools not found.
    echo        Install "Desktop development with C++" workload from:
    echo        https://visualstudio.microsoft.com/visual-cpp-build-tools/
    goto :error
)
:msvc_found

echo.
echo Prerequisites OK. Starting build...
echo.

:: ============================================================================
:: Clone and build DeepSpeed
:: ============================================================================
if exist "%BUILD_DIR%\DeepSpeed" (
    echo Cleaning previous DeepSpeed source...
    rmdir /S /Q "%BUILD_DIR%\DeepSpeed"
)
mkdir "%BUILD_DIR%" 2>nul

echo Cloning DeepSpeed v%DEEPSPEED_VERSION%...
git clone --depth 1 --branch "v%DEEPSPEED_VERSION%" https://github.com/microsoft/DeepSpeed.git "%BUILD_DIR%\DeepSpeed"
if errorlevel 1 (
    echo ERROR: Failed to clone DeepSpeed repository.
    goto :error
)

cd /D "%BUILD_DIR%\DeepSpeed"

:: Set build environment
:: DISTUTILS_USE_SDK tells PyTorch's cpp_extension that MSVC is already
:: activated, preventing "multiple activations of the VC env" errors.
set "DISTUTILS_USE_SDK=1"
:: Default all ops OFF, then enable only the ones needed for TTS inference.
:: Many ops are Linux-only (AIO, GDS, NCCL/DeepCompile, Triton/SparseAttn).
set "DS_BUILD_OPS=0"
set "DS_BUILD_TRANSFORMER_INFERENCE=1"
set "DS_BUILD_TRANSFORMER=1"
set "DS_BUILD_STOCHASTIC_TRANSFORMER=1"
set "DS_BUILD_QUANTIZER=1"
set "DS_BUILD_FUSED_ADAM=1"
set "DS_BUILD_CPU_ADAM=1"

echo.
echo Building DeepSpeed wheel...
echo   TORCH_CUDA_ARCH_LIST = %TORCH_CUDA_ARCH_LIST%
echo   DS_BUILD_OPS = %DS_BUILD_OPS%
echo   This will take 10-30 minutes depending on your system.
echo.

python setup.py bdist_wheel
if errorlevel 1 (
    echo.
    echo ERROR: DeepSpeed build failed. Check the output above for details.
    echo        Common issues:
    echo          - CUDA Toolkit version mismatch with PyTorch
    echo          - Missing Visual Studio C++ workload
    echo          - Insufficient disk space
    goto :error
)

:: ============================================================================
:: Copy wheel to output directory
:: ============================================================================
mkdir "%BUILD_DIR%\wheels" 2>nul
copy "%BUILD_DIR%\DeepSpeed\dist\*.whl" "%BUILD_DIR%\wheels\"
echo.
echo ============================================================
echo  BUILD SUCCESSFUL!
echo  Wheel location: %BUILD_DIR%\wheels\
echo ============================================================
dir "%BUILD_DIR%\wheels\*.whl"
echo.
echo To install this wheel into AllTalk:
echo   1. Activate the AllTalk environment
echo   2. pip install "%BUILD_DIR%\wheels\deepspeed-*.whl"
echo   3. Set deepspeed_enabled to true in model_settings.json
echo.
goto :end

:error
echo.
echo Build failed. See errors above.
cd /D "%~dp0"
pause
exit /b 1

:end
cd /D "%~dp0"
pause
exit /b 0
