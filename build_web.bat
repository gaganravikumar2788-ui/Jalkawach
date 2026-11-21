@echo off
echo ================================================
echo   Building JalKawach Flutter Web to public/
echo ================================================
cd frontend
call flutter build web --release --no-wasm-dry-run
if %errorlevel% neq 0 (
    echo Flutter build failed!
    pause
    exit /b %errorlevel%
)
cd ..
if exist public (
    rmdir /s /q public
)
xcopy /E /I /Y frontend\build\web public
echo ================================================
echo   Web bundle successfully updated in public/!
echo   Ready to git commit and push to Vercel!
echo ================================================
