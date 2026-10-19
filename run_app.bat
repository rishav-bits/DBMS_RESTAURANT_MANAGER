@echo off
REM ============================================================================
REM DA2: Restaurant Table Reservation & Food Ordering System
REM Web Application Launcher Script
REM ============================================================================

echo ========================================================
echo STARTING RESTAURANT TABLE RESERVATION & FOOD ORDERING SYSTEM (DA2)
echo Connecting to Oracle 21c XE at localhost:1521/XEPDB1...
echo Web Interface URL: http://localhost:5000
echo ========================================================

python app/app.py
pause
