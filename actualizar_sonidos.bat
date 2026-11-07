@echo off
setlocal
chcp 65001 >nul

cd /d "%~dp0"

if not exist "sounds" (
    echo [ERROR] No se encontro la carpeta "sounds".
    pause
    exit /b 1
)

echo Generando Sounds.lua desde los archivos de la carpeta sounds...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$soundsDir = Join-Path (Get-Location) 'sounds';" ^
    "$outputFile = Join-Path (Get-Location) 'Sounds.lua';" ^
    "$files = Get-ChildItem -Path $soundsDir -File | Where-Object { $_.Extension -match '^\.(mp3|ogg|wav)$' } | Sort-Object Name;" ^
    "$lines = New-Object System.Collections.Generic.List[string];" ^
    "$lines.Add('--[[');" ^
    "$lines.Add('    ForeverBoard - Catalogo generado automaticamente');" ^
    "$lines.Add('    Generado por actualizar_sonidos.bat');" ^
    "$lines.Add('--]]');" ^
    "$lines.Add('');" ^
    "$lines.Add('ForeverBoard_Sounds = {');" ^
    "foreach ($f in $files) {" ^
    "    $rawName = [System.IO.Path]::GetFileNameWithoutExtension($f.Name);" ^
    "    $cleanId = ($rawName.ToLower() -replace '[^a-z0-9_]', '_') -replace '_+', '_';" ^
    "    $cleanId = $cleanId.Trim('_');" ^
    "    if ([string]::IsNullOrWhiteSpace($cleanId)) { $cleanId = 'audio_' + (Get-Random -Minimum 1000 -Maximum 9999) };" ^
    "    $prettyName = ($rawName -replace '[_-]', ' ').Trim();" ^
    "    $prettyName = (Get-Culture).TextInfo.ToTitleCase($prettyName);" ^
    "    $escapedFile = $f.Name.Replace('\', '\\').Replace('\"', '\"');" ^
    "    $escapedName = $prettyName.Replace('\', '\\').Replace('\"', '\"');" ^
    "    $lines.Add('    {');" ^
    "    $lines.Add('        id = \"' + $cleanId + '\",');" ^
    "    $lines.Add('        name = \"' + $escapedName + '\",');" ^
    "    $lines.Add('        file = \"' + $escapedFile + '\",');" ^
    "    $lines.Add('        desc = \"Audio: ' + $escapedFile + '\",');" ^
    "    $lines.Add('    },');" ^
    "};" ^
    "$lines.Add('}');" ^
    "$utf8NoBom = New-Object System.Text.UTF8Encoding($false);" ^
    "[System.IO.File]::WriteAllLines($outputFile, $lines, $utf8NoBom);"

if %ERRORLEVEL% equ 0 (
    echo [OK] Sounds.lua actualizado correctamente.
) else (
    echo [ERROR] Ocurrio un error al generar Sounds.lua.
)

echo.
pause
