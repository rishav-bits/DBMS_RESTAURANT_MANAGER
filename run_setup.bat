@echo off
REM ============================================================================
REM DA2: Restaurant Table Reservation & Food Ordering System
REM Automated Database Setup Script for Oracle 21c XE
REM ============================================================================

echo ========================================================
echo SETTING UP ORACLE RESTAURANT MANAGEMENT DATABASE
echo ========================================================

REM Run SQL scripts in order using local sqlplus
"C:\Anu\21c\dbhomeXE\bin\sqlplus.exe" -s restaurant_app/restaurant_pass@localhost:1521/XEPDB1 @database_scripts/01_schema.sql
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to execute 01_schema.sql
    pause
    exit /b %ERRORLEVEL%
)

"C:\Anu\21c\dbhomeXE\bin\sqlplus.exe" -s restaurant_app/restaurant_pass@localhost:1521/XEPDB1 @database_scripts/03_plsql.sql
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to compile 03_plsql.sql
    pause
    exit /b %ERRORLEVEL%
)

"C:\Anu\21c\dbhomeXE\bin\sqlplus.exe" -s restaurant_app/restaurant_pass@localhost:1521/XEPDB1 @database_scripts/02_data.sql
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to execute 02_data.sql
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ========================================================
echo SEEDING AUTHENTICATION & MULTI-ROLE USERS
echo ========================================================
python setup_auth.py

echo.
echo ========================================================
echo RUNNING AUTOMATED PL/SQL TEST SUITE
echo ========================================================
"C:\Anu\21c\dbhomeXE\bin\sqlplus.exe" -s restaurant_app/restaurant_pass@localhost:1521/XEPDB1 @database_scripts/05_tests.sql

echo.
echo ========================================================
echo SETUP COMPLETE! Database is ready for the Web Application.
echo ========================================================
pause
