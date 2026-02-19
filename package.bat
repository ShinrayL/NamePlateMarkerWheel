@echo off
chcp 65001 >nul
REM NamePlateMarkerWheel 打包脚本
REM 生成用于发布的 zip 文件

echo ========================================
echo NamePlateMarkerWheel 打包工具
echo ========================================

set VERSION=1.1.0
set FOLDER_NAME=NamePlateMarkerWheel
set ZIP_NAME=NamePlateMarkerWheel-v%VERSION%.zip

REM 创建临时目录
set TEMP_DIR=%TEMP%\%FOLDER_NAME%_package
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%\%FOLDER_NAME%"

echo.
echo [1/3] 复制插件文件...

REM 复制 src 文件夹内容到临时目录
xcopy /s /y "%~dp0src\*" "%TEMP_DIR%\%FOLDER_NAME%\" >nul

REM 复制 README
copy /y "%~dp0README.md" "%TEMP_DIR%\%FOLDER_NAME%\" >nul

echo [2/3] 打包为 zip...

REM 切换到临时目录并打包
cd /d "%TEMP_DIR%"
powershell -Command "Compress-Archive -Path '%FOLDER_NAME%' -DestinationPath '%~dp0%ZIP_NAME%' -Force"

if %ERRORLEVEL% neq 0 (
    echo [错误] 打包失败！
    pause
    exit /b 1
)

echo [3/3] 清理临时文件...
rmdir /s /q "%TEMP_DIR%"

echo.
echo ========================================
echo 打包完成！
echo 文件名: %ZIP_NAME%
echo 位置: %~dp0%ZIP_NAME%
echo ========================================

pause
