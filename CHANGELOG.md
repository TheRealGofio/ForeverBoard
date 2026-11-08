# Changelog

Todas las novedades y cambios notables de **ForeverBoard** se documentan en este archivo.

El formato sigue las convenciones de [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/) y se rige por [SemVer](https://semver.org/lang/es/).

---

## [1.1.0] - 2026-11-08

### ✨ Novedades
- **Catálogo de sonidos ampliado**: 13 clips de audio incluidos por defecto (FF Fanfare, Faaah, Roblox Death, Sad Violin, Rizz, etc.).
- **Triggers automáticos configurables por distribuidor**: Valores predeterminados oficiales configurables en `Sounds.lua` (`levelUp`, `bossKill`, `death`).
- **Menú desplegable con scroll para eventos**: Asignación rápida de cualquier sonido a cada disparador sin necesidad de rotación manual.
- **Soporte bilingüe completo (i18n)**: Español e Inglés con detección automática según el idioma del cliente del juego.
- **Selector de canal de audio**: Alternar entre `Master`, `SFX` y `Ambience` directamente desde la interfaz.
- **Pestaña de Favoritos con estrellas de raid**: Marcar audios con la estrella dorada nativa de WoW y filtrarlos con un solo clic.
- **Control de Mute & Silenciar en combate**: Botón rápido en la cabecera, comando `/fb mute` y opción de auto-mute en combate.
- **Comprobación de versiones en grupo (`/fb version`)**: Saber al instante quién del grupo o banda tiene el addon instalado y qué versión lleva.

---

## [1.0.0] - 2026-11-07

### ✨ Novedades
- **Sincronización en tiempo real**: Reproducción simultánea invisible mediante canales de addon de grupo y banda (`PARTY` / `RAID`).
- **Botón circular en Minimapa**:
  - Icono accesible y estilizado al borde exterior del minimapa.
  - Clic izquierdo para abrir/cerrar el SoundBoard.
  - Clic derecho y arrastrar para mover libremente alrededor del minimapa (posición recordada entre sesiones).
- **Buscador interactivo**: Barra de búsqueda en tiempo real en la cabecera del panel para filtrar sonidos rápidamente por nombre, ID o descripción.
- **Ventana redimensionable y arrastrable**:
  - Asa de agarre visual (Resize Grip) en la esquina inferior derecha.
  - Tamaño mínimo y máximo adaptativo según la versión de API.
  - Guarda automáticamente posición y dimensiones en `ForeverBoardDB`.
- **Detección de autor en chat**: Mensaje unificado de notificación indicando exactamente qué jugador disparó el sonido (`<Personaje> ha reproducido: <Sonido>`).
- **Script automático `actualizar_sonidos.bat`**:
  - Escaneo automático con un solo clic de la carpeta `sounds/` para generar `Sounds.lua`.
  - Detección de audios `.mp3`, `.ogg` y `.wav` con nombres de botones limpios y formateados.
- **Compatibilidad con WowUp**:
  - Soporte de metadatos completos en `.toc` (`X-Category`, `X-Website`, `X-Curse-Project-ID`, `X-WoWI-ID`, etc.) para instalación y actualización directa por URL en WowUp.
- **Protección Anti-Spam**: Margen de cooldown de 1.5 segundos para evitar saturación del canal de audio.
