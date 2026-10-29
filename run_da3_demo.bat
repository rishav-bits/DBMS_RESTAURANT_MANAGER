@echo off
title SurrealDB DA3 Showcase - Restaurant DBMS
color 0A

echo ==============================================================================
echo       LA CARTE - SURREALDB MULTI-MODEL DATABASE SHOWCASE (DA3)
echo       Course: BACSE202 (Database Management Systems) - VIT Chennai
echo ==============================================================================
echo.

REM 1. Verify Python
python --version >nul 2>&1
if errorlevel 1 (
    color 0C
    echo [ERROR] Python is not found in PATH. Please install Python 3.10+.
    pause
    exit /b 1
)

echo [1/3] Running Automated SurrealDB Unit Test Suite...
python -m unittest tests/test_surreal_graph.py
if errorlevel 1 (
    color 0C
    echo [ERROR] Unit tests failed! Please check error output above.
    pause
    exit /b 1
)
echo [PASS] All 10 SurrealDB graph tests passed successfully!
echo.

echo [2/3] Starting Flask Application with SurrealDB Extension...
start "" http://127.0.0.1:5000/surreal

echo [3/3] Opening Interactive Showcase Dashboard in Default Browser...
echo Access URLs:
echo   - Interactive Showcase:  http://127.0.0.1:5000/surreal
echo   - Graph Canvas (Tab 3):  http://127.0.0.1:5000/surreal?tab=graph
echo   - Benchmarks (Tab 4):    http://127.0.0.1:5000/surreal?tab=benchmarks
echo   - Main Relational App:   http://127.0.0.1:5000/
echo.
echo Press Ctrl+C in this terminal when you wish to stop the server.
echo.

cd /d "%~dp0app"
python app.py
