@echo off
chcp 65001 > nul

reg query HKCU\Console | findstr VirtualTerminalLevel >nul 2>&1
if errorlevel 1 (
    reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul
)

setlocal EnableDelayedExpansion

if "%1"=="admin" (
    echo Запущено с правами администратора
    goto main_menu
) else (
    echo Запрос прав администратора для диагностики...
    powershell -Command "Start-Process 'cmd.exe' -ArgumentList '/c \"\"%~f0\" admin\"' -Verb RunAs"
    exit /b
)

:main_menu
chcp 65001 > nul
cls

echo =================================
echo Утилиты для obhod
echo =================================
echo.
echo 1. Автозапуск
echo 2. Диагностика
echo 3. Проверка конфигов
echo 4. Очистить кэш Discord
echo 5. Проверка обновлений
echo 0. Выход
echo.
echo =================================
set /p choice=Введите номер варианта (0-5): 

if "%choice%"=="0" goto exit
if "%choice%"=="1" goto autostart_menu
if "%choice%"=="2" goto service_diagnostics
if "%choice%"=="3" goto config_check
if "%choice%"=="4" goto clear_discord_cache
if "%choice%"=="5" goto check_updates

echo Неверный выбор!
pause
goto main_menu

:exit
exit /b

:autostart_menu
cls
echo =================================
echo Управление автозапуском
echo =================================
echo.
echo 1. Добавить в автозапуск
echo 2. Удалить автозапуск
echo 0. Назад
echo.
echo =================================
set /p autostart_choice=Выберите действие: 

if "%autostart_choice%"=="0" goto main_menu
if "%autostart_choice%"=="1" goto autostart_setup
if "%autostart_choice%"=="2" goto autostart_remove

echo Неверный выбор!
pause
goto autostart_menu

:autostart_setup
cls
echo =================================
echo Настройка автозапуска:
echo =================================
echo.

set "SCRIPT_DIR=%~dp0"
set "CONFIGS_DIR=%SCRIPT_DIR%configs"

if not exist "%CONFIGS_DIR%" (
    call :PrintRed "[X] Папка configs не найдена!"
    echo Попробуйте заного скачать сборку, в которой есть папка configs
    echo.
    pause
    goto autostart_menu
)

echo 1.  general
echo 2.  general (ALT)
echo 3.  general (ALT2)
echo 4.  general (ALT3)
echo 5.  general (ALT4)
echo 6.  general (ALT5) - НЕ РЕКОМЕНДУЕТСЯ
echo 7.  general (ALT6)
echo 8.  general (ALT7)
echo 9.  general (FAKE TLS)
echo 10. general (FAKE TLS ALT)
echo 11. general (FAKE TLS AUTO)
echo 12. general (FAKE TLS AUTO ALT)
echo 13. general (FAKE TLS AUTO ALT2)
echo 14. general (МГТС)
echo 15. general (МГТС2)
echo.
echo =================================
set /p config_choice=Выберите конфиг для автозапуска (1-15): 

if "%config_choice%"=="" (
    echo Неверный выбор!
    pause
    goto autostart_setup
)

set "config_file="
if "%config_choice%"=="1" set "config_file=general.bat"
if "%config_choice%"=="2" set "config_file=general_alt.bat"
if "%config_choice%"=="3" set "config_file=general_alt2.bat"
if "%config_choice%"=="4" set "config_file=general_alt3.bat"
if "%config_choice%"=="5" set "config_file=general_alt4.bat"
if "%config_choice%"=="6" set "config_file=general_alt5.bat"
if "%config_choice%"=="7" set "config_file=general_alt6.bat"
if "%config_choice%"=="8" set "config_file=general_alt7.bat"
if "%config_choice%"=="9" set "config_file=general_fake_tls.bat"
if "%config_choice%"=="10" set "config_file=general_fake_tls_alt.bat"
if "%config_choice%"=="11" set "config_file=general_fake_tls_auto.bat"
if "%config_choice%"=="12" set "config_file=general_fake_tls_auto_alt.bat"
if "%config_choice%"=="13" set "config_file=general_fake_tls_auto_alt2.bat"
if "%config_choice%"=="14" set "config_file=general_mgts.bat"
if "%config_choice%"=="15" set "config_file=general_mgts2.bat"

if "%config_file%"=="" (
    echo Неверный выбор!
    pause
    goto autostart_setup
)

set "selected_file=%CONFIGS_DIR%\%config_file%"

if not exist "%selected_file%" (
    call :PrintRed "[X] Конфиг не найден: %config_file%"
    echo Убедитесь что файл существует в папке configs
    echo.
    pause
    goto autostart_menu
)

echo Проверка текущего автозапуска...
reg query "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "obhod_Auto" >nul 2>&1
if !errorlevel!==0 (
    for /f "tokens=3*" %%a in ('reg query "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "obhod_Auto" 2^>nul') do (
        if "%%a"=="%selected_file%" (
            call :PrintYellow "[!] Этот конфиг уже установлен в автозапуск"
            echo.
            pause
            goto autostart_menu
        )
    )
)

echo Удаление предыдущего автозапуска...
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "obhod_Auto" /f >nul 2>&1

echo Добавление в автозагрузку...
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "obhod_Auto" /t REG_SZ /d "%selected_file%" /f >nul 2>&1

if errorlevel 1 (
    call :PrintRed "[X] Ошибка добавления в автозагрузку"
    echo Попробуйте запустить service.bat от имени администратора
) else (
    call :PrintGreen "[V] Автозапуск успешно настроен"
    call :PrintGreen "[V] Конфиг: %config_file%"
)

echo.
pause
goto autostart_menu

:autostart_remove
cls
echo Удаление автозапуска...

echo Удаление из реестра...
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "obhod_Auto" /f >nul 2>&1

echo Удаление всех записей obhod из автозагрузки...
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "obhod" /f >nul 2>&1
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "obhod_low" /f >nul 2>&1
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "obhod_winws" /f >nul 2>&1

call :PrintGreen "[V] Автозапуск полностью удален"
echo.
pause
goto autostart_menu

:service_diagnostics
chcp 65001 > nul
cls

echo =================================
echo Диагностика системы и сети
echo =================================
echo.
echo Проверка основных сайтов...
for %%s in (https://youtube.com https://discord.com) do (
    curl -s -I --connect-timeout 5 %%s >nul 2>&1
    if !errorlevel!==0 (
        call :PrintGreen "  [V] %%s - доступен"
    ) else (
        call :PrintRed "  [X] %%s - НЕ доступен"
    )
)

echo.
echo Проверка DNS...
nslookup google.com >nul 2>&1
if !errorlevel!==0 (
    call :PrintGreen "  [V] DNS работает"
) else (
    call :PrintRed "  [X] Проблемы с DNS"
)

echo.
echo Проверка маршрутизации...
ping -n 1 -w 3000 8.8.8.8 >nul 2>&1
if !errorlevel!==0 (
    call :PrintGreen "  [V] Маршрутизация в порядке"
) else (
    call :PrintRed "  [X] Проблемы с маршрутизацией"
)

echo.
echo =================================
echo Проверка конфликтующих служб
echo =================================
echo.

tasklist /FI "IMAGENAME eq AdguardSvc.exe" | find /I "AdguardSvc.exe" > nul
if !errorlevel!==0 (
    call :PrintRed "[X] Найден процесс Adguard. Adguard может вызывать проблемы с Discord"
) else (
    call :PrintGreen "[V] Проверка Adguard пройдена"
)
echo.

sc query | findstr /I "Killer" > nul
if !errorlevel!==0 (
    call :PrintRed "[X] Найдены службы Killer. Killer конфликтует с obhod"
) else (
    call :PrintGreen "[V] Проверка Killer пройдена"
)
echo.

sc query | findstr /I "Intel" | findstr /I "Connectivity" | findstr /I "Network" > nul
if !errorlevel!==0 (
    call :PrintRed "[X] Найдена служба Intel Connectivity Network Service. Она конфликтует с obhod"
) else (
    call :PrintGreen "[V] Проверка Intel Connectivity пройдена"
)
echo.

set "checkpointFound=0"
sc query | findstr /I "TracSrvWrapper" > nul
if !errorlevel!==0 (
    set "checkpointFound=1"
)

sc query | findstr /I "EPWD" > nul
if !errorlevel!==0 (
    set "checkpointFound=1"
)

if !checkpointFound!==1 (
    call :PrintRed "[X] Найдены службы Check Point. Check Point конфликтует с obhod"
    call :PrintRed "Попробуйте удалить Check Point"
) else (
    call :PrintGreen "[V] Проверка Check Point пройдена"
)
echo.

sc query | findstr /I "SmartByte" > nul
if !errorlevel!==0 (
    call :PrintRed "[X] Найдены службы SmartByte. SmartByte конфликтует с obhod"
    call :PrintRed "Попробуйте удалить или отключить SmartByte через services.msc"
) else (
    call :PrintGreen "[V] Проверка SmartByte пройдена"
)
echo.

sc query | findstr /I "VPN" > nul
if !errorlevel!==0 (
    call :PrintYellow "[?] Найдены VPN службы. Некоторые VPN могут конфликтовать с obhod"
    call :PrintYellow "Убедитесь что все VPN отключены"
) else (
    call :PrintGreen "[V] Проверка VPN пройдена"
)
echo.

set "dnsfound=0"
for /f "skip=1 tokens=*" %%a in ('wmic nicconfig where "IPEnabled=true" get DNSServerSearchOrder /format:table 2^>nul') do (
    echo %%a | findstr /i "192.168." >nul
    if !errorlevel!==0 (
        set "dnsfound=1"
    )
)

if !dnsfound!==1 (
    call :PrintYellow "[?] DNS серверы вероятно не указаны."
    call :PrintYellow "Используются DNS провайдера, что может влиять на obhod. Рекомендуется установить известные DNS серверы и настроить DoH"
) else (
    call :PrintGreen "[V] Проверка DNS пройдена"
)
echo.
echo.
pause
goto main_menu

:config_check
cls
echo =================================
echo Тестирование конфигов
echo =================================
echo.
echo Закрытие всех запущенных конфигов obhod...
taskkill /f /im winws.exe >nul 2>&1
timeout /t 2 /nobreak >nul
echo.

set "SCRIPT_DIR=%~dp0"
set "CONFIGS_DIR=%SCRIPT_DIR%configs"

if not exist "%CONFIGS_DIR%" (
    call :PrintRed "[X] Папка configs не найдена!"
    echo Попробуйте заного скачать сборку, в которой есть папка configs
    echo.
    pause
    goto main_menu
)

set "config_list[1]=general.bat"
set "config_list[2]=general_alt.bat"
set "config_list[3]=general_alt2.bat"
set "config_list[4]=general_alt3.bat"
set "config_list[5]=general_alt4.bat"
set "config_list[6]=general_alt5.bat"
set "config_list[7]=general_alt6.bat"
set "config_list[8]=general_alt7.bat"
set "config_list[9]=general_fake_tls.bat"
set "config_list[10]=general_fake_tls_alt.bat"
set "config_list[11]=general_fake_tls_auto.bat"
set "config_list[12]=general_fake_tls_auto_alt.bat"
set "config_list[13]=general_fake_tls_auto_alt2.bat"
set "config_list[14]=general_mgts.bat"
set "config_list[15]=general_mgts2.bat"

set "config_display[1]=general"
set "config_display[2]=general (ALT)"
set "config_display[3]=general (ALT2)"
set "config_display[4]=general (ALT3)"
set "config_display[5]=general (ALT4)"
set "config_display[6]=general (ALT5)"
set "config_display[7]=general (ALT6)"
set "config_display[8]=general (ALT7)"
set "config_display[9]=general (FAKE TLS)"
set "config_display[10]=general (FAKE TLS ALT)"
set "config_display[11]=general (FAKE TLS AUTO)"
set "config_display[12]=general (FAKE TLS AUTO ALT)"
set "config_display[13]=general (FAKE TLS AUTO ALT2)"
set "config_display[14]=general (МГТС)"
set "config_display[15]=general (МГТС2)"

set "test_urls=https://youtube.com https://discord.com"

echo.
for /l %%i in (1,1,15) do (
    echo =================================
    echo Тест: !config_display[%%i]!
    echo =================================
    set "config_file=!config_list[%%i]!"
    set "selected_file=%CONFIGS_DIR%\!config_file!"

    if not exist "!selected_file!" (
        call :PrintRed "[X] Конфиг не найден: !config_file!"
        echo.
    ) else (
        for /f "tokens=2" %%p in ('tasklist /fi "imagename eq winws.exe" /fo table /nh') do (
            set "winws_pid=%%p"
        )
        
        start "" /B "!selected_file!" >nul 2>&1
        timeout /t 5 /nobreak >nul

        set "success_count=0"
        set "total_count=0"
        for %%s in (!test_urls!) do (
            set /a total_count+=1
            curl -s -I --connect-timeout 5 %%s >nul 2>&1
            if !errorlevel!==0 (
                call :PrintGreen "  [V] %%s - доступен"
                set /a success_count+=1
            ) else (
                call :PrintRed "  [X] %%s - НЕ доступен"
            )
        )
        
        for /f "tokens=2" %%p in ('tasklist /fi "imagename eq winws.exe" /fo table /nh 2^>nul') do (
            if not "%%p"=="!winws_pid!" (
                taskkill /pid %%p /f >nul 2>&1
            )
        )
        
        taskkill /f /im winws.exe >nul 2>&1
        taskkill /fi "WindowTitle eq DPI Test *" /f >nul 2>&1

        echo.
        if !success_count! geq !total_count! (
            call :PrintGreen "[V] Конфиг !config_display[%%i]! успешно прошел тест"
        ) else (
            call :PrintYellow "[?] Конфиг !config_display[%%i]! не прошел все тесты"
        )
        echo.
    )
)

echo =================================
echo Тестирование завершено
echo =================================
echo.
pause
goto main_menu

:clear_discord_cache
cls
echo =================================
echo Очистка кэша Discord
echo =================================
echo.

set "DISCORD_CACHE_PATH=%LocalAppData%\Discord"

if exist "%DISCORD_CACHE_PATH%" (
    echo Найден кэш Discord: %DISCORD_CACHE_PATH%
    echo.
    set /p "CONFIRM=Очистить кэш Discord? (Y/N): "
    if /i "!CONFIRM!"=="y" (
        echo.
        echo Удаление папок кэша...
        rd /s /q "%DISCORD_CACHE_PATH%\Cache" >nul 2>&1
        rd /s /q "%DISCORD_CACHE_PATH%\Code Cache" >nul 2>&1
        rd /s /q "%DISCORD_CACHE_PATH%\GPUCache" >nul 2>&1
        
        call :PrintGreen "[V] Кэш Discord успешно очищен"
    ) else (
        call :PrintYellow "[!] Очистка отменена пользователем"
    )
) else (
    call :PrintYellow "[?] Папка кэша Discord не найдена"
)

echo.
pause
goto main_menu

:check_updates
cls
echo =================================
echo Проверка обновлений
echo =================================
echo.

set "CURRENT_VERSION=1.0.1"

echo Ваша текущая версия: !CURRENT_VERSION!
echo.
echo Получение информации о последней версии с GitHub...

curl -s "https://api.github.com/repos/olegnekifir/obhod/releases/latest" > "%temp%\github_latest.json" 2>nul

if not exist "%temp%\github_latest.json" (
    call :PrintRed "[X] Не удалось получить информацию о версии"
    echo.
    pause
    goto main_menu
)

set "LATEST_VERSION="
for /f "usebackq tokens=*" %%a in ("%temp%\github_latest.json") do (
    set "line=%%a"
    echo !line! | findstr "\"tag_name\"" >nul
    if !errorlevel!==0 (
        for /f "tokens=2 delims=:," %%b in ("!line!") do (
            set "LATEST_VERSION=%%b"
            set "LATEST_VERSION=!LATEST_VERSION:"=!"
            set "LATEST_VERSION=!LATEST_VERSION: =!"
        )
        goto :version_found
    )
)

:version_found
if "!LATEST_VERSION!"=="" (
    call :PrintRed "[X] Не удалось получить информацию о версии"
    echo.
    pause
    goto main_menu
)

echo Последняя версия на GitHub: !LATEST_VERSION!

if "!CURRENT_VERSION!"=="!LATEST_VERSION!" (
    call :PrintGreen "[V] У вас актуальная версия!"
) else (
    call :PrintYellow "[!] Доступно обновление"
    echo.
    set /p "DOWNLOAD=Скачать последнюю версию? (Y/N): "
    if /i "!DOWNLOAD!"=="y" (
        start "" "https://github.com/olegnekifir/obhod/releases/latest"
        call :PrintGreen "[V] Открываю страницу загрузки..."
    ) else (
        echo.
    )
)

del "%temp%\github_latest.json" >nul 2>&1
echo.
pause
goto main_menu

:PrintGreen
echo [32m%~1[0m
exit /b

:PrintRed
echo [31m%~1[0m
exit /b

:PrintYellow
echo [33m%~1[0m
exit /b