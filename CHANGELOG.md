# Changelog

Todas las novedades y cambios notables de **ForeverBoard** se documentan en este archivo.

El formato sigue las convenciones de [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/) y se rige por [SemVer](https://semver.org/lang/es/).

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
