@echo off
setlocal
chcp 65001 >nul

cd /d "%~dp0"

if not exist "sounds" (
    echo [ERROR] No se encontro la carpeta "sounds".
    pause
    exit /b 1
)

echo ======================================================
echo    ForeverBoard - Gestor y Actualizador de Sonidos
echo ======================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$soundsDir = Join-Path (Get-Location) 'sounds';" ^
    "$outputFile = Join-Path (Get-Location) 'Sounds.lua';" ^
    "$allFiles = Get-ChildItem -Path $soundsDir -File;" ^
    "$validExts = @('.mp3', '.ogg', '.wav');" ^
    "$audioFiles = $allFiles | Where-Object { $validExts -contains $_.Extension.ToLower() } | Sort-Object Name;" ^
    "$otherFiles = $allFiles | Where-Object { $validExts -notcontains $_.Extension.ToLower() };" ^
    "if ($otherFiles) {" ^
    "    Write-Host '[AVISO] Se han detectado archivos con formatos no directos para WoW:' -ForegroundColor Yellow;" ^
    "    foreach ($of in $otherFiles) {" ^
    "        Write-Host ('   - ' + $of.Name + ' (se recomienda convertir a .mp3)') -ForegroundColor Yellow;" ^
    "    };" ^
    "    Write-Host '';" ^
    "};" ^
    "Write-Host ('Indexando ' + $audioFiles.Count + ' archivo(s) de audio compatibles...') -ForegroundColor Cyan;" ^
    "$lines = New-Object System.Collections.Generic.List[string];" ^
    "$lines.Add('--[[');" ^
    "$lines.Add('    ForeverBoard - Catalogo generado automaticamente');" ^
    "$lines.Add('    Generado por actualizar_sonidos.bat');" ^
    "$lines.Add('');" ^
    "$lines.Add('    COMO DISTRIBUIDOR:');" ^
    "$lines.Add('    Configura los sonidos por defecto para los eventos en esta tabla:');" ^
    "$lines.Add('--]]');" ^
    "$lines.Add('');" ^
    "$levelDef = if ($audioFiles.Count -gt 1) { '\"' + [System.IO.Path]::GetFileNameWithoutExtension($audioFiles[1].Name).ToLower().Replace(' ', '_') + '\"' } elseif ($audioFiles.Count -gt 0) { '\"' + [System.IO.Path]::GetFileNameWithoutExtension($audioFiles[0].Name).ToLower().Replace(' ', '_') + '\"' } else { '\"\"' };" ^
    "$bossDef = if ($audioFiles.Count -gt 0) { '\"' + [System.IO.Path]::GetFileNameWithoutExtension($audioFiles[0].Name).ToLower().Replace(' ', '_') + '\"' } else { '\"\"' };" ^
    "$deadDef = $bossDef;" ^
    "$lines.Add('ForeverBoard_DefaultTriggers = {');" ^
    "$lines.Add('    levelUp  = \"ff_fanfare\", -- ID del sonido por defecto para Subida de nivel (Ding!)');" ^
    "$lines.Add('    bossKill = \"faaah\", -- ID del sonido por defecto para Victoria en Boss');" ^
    "$lines.Add('    death    = \"gemido_anime\", -- ID del sonido por defecto para Muerte/Wipe');" ^
    "$lines.Add('    loot     = \"\", -- ID del sonido por defecto para Botin (vacio = sin sonido por defecto)');" ^
    "$lines.Add('}');" ^
    "$lines.Add('');" ^
    "$lines.Add('ForeverBoard_Sounds = {');" ^
    "foreach ($f in $audioFiles) {" ^
    "    $rawName = [System.IO.Path]::GetFileNameWithoutExtension($f.Name);" ^
    "    $cleanId = ($rawName.ToLower() -replace '[^a-z0-9_]', '_') -replace '_+', '_';" ^
    "    $cleanId = $cleanId.Trim('_');" ^
    "    if ([string]::IsNullOrWhiteSpace($cleanId)) { $cleanId = 'audio_' + (Get-Random -Minimum 1000 -Maximum 9999) };" ^
    "    $prettyName = ($rawName -replace '[_-]', ' ').Trim();" ^
    "    $prettyName = (Get-Culture).TextInfo.ToTitleCase($prettyName);" ^
    "    $escapedFile = $f.Name.Replace('\', '\\').Replace('\"', '\"');" ^
    "    $escapedName = $prettyName.Replace('\', '\\').Replace('\"', '\"');" ^
    "    if ($f.Extension.ToLower() -eq '.ogg') {" ^
    "        try {" ^
    "            $bytes = [System.IO.File]::ReadAllBytes($f.FullName);" ^
    "            $header = [System.Text.Encoding]::ASCII.GetString($bytes[28..35]);" ^
    "            if ($header -eq 'OpusHead') {" ^
    "                Write-Host ('   [!] ALERTA: ' + $f.Name + ' es Ogg Opus. WoW solo admite Ogg Vorbis o MP3. Convertir a MP3 si no suena.') -ForegroundColor Red;" ^
    "            }" ^
    "        } catch {}" ^
    "    };" ^
    "    $lines.Add('    {');" ^
    "    $lines.Add('        id = \"' + $cleanId + '\",');" ^
    "    $lines.Add('        name = \"' + $escapedName + '\",');" ^
    "    $lines.Add('        file = \"' + $escapedFile + '\",');" ^
    "    $lines.Add('        desc = \"Audio: ' + $escapedFile + '\",');" ^
    "    $lines.Add('    },');" ^
    "    Write-Host ('   [+] ' + $escapedName + ' -> ' + $escapedFile) -ForegroundColor Green;" ^
    "};" ^
    "$lines.Add('}');" ^
    "$utf8NoBom = New-Object System.Text.UTF8Encoding($false);" ^
    "[System.IO.File]::WriteAllLines($outputFile, $lines, $utf8NoBom);"

if %ERRORLEVEL% equ 0 (
    echo.
    echo [OK] Sounds.lua generado y actualizado con exito.
    echo Recuerda: si anadiste archivos de audio nuevos en disco, reinicia el juego WoW una vez.
) else (
    echo.
    echo [ERROR] Ocurrio un error al generar Sounds.lua.
)

echo.
pause
