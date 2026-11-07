# ForeverBoard 🔊

Addon de **SoundBoard sincronizado** para World of Warcraft (Vanilla / Classic Era / Forever / Turtle / 1.12 - 1.15).

Cuando pulsas un sonido en el panel o lanzas un comando, el audio **se reproduce instantáneamente para ti y para todos los compañeros de tu grupo o banda (raid)** que tengan el addon instalado.

---

## 🚀 Características
- **Sincronización en tiempo real**: Envío invisible mediante el canal de addons de Blizzard (`RAID` / `PARTY`).
- **Botón en el Minimapa**: Icono circular arrastrable alrededor del minimapa con acceso de un clic.
- **Buscador integrado**: Barra de búsqueda interactiva en tiempo real para encontrar cualquier sonido al instante.
- **Ventana redimensionable (Resize)**: Panel ajustable en tamaño desde la esquina inferior derecha y posición guardada automáticamente.
- **Protección Anti-Spam**: Margen de cooldown para evitar saturar el canal de audio.
- **Comandos de Chat**: Posibilidad de crear macros de WoW (`/fb play butano`, etc.).
- **Fácilmente extensible**: Añade cualquier archivo `.mp3` u `.ogg` editando un único archivo `Sounds.lua`.

---

## 🛠️ Instalación
1. Descarga o clona este repositorio en tu carpeta de AddOns:
   `World of Warcraft\_classic_era_\Interface\AddOns\ForeverBoard`
2. Asegúrate de que los archivos de audio estén dentro de `ForeverBoard\sounds\`.
3. Inicia sesión en el juego y escribe `/fb`.

---

## ⌨️ Comandos
| Comando | Descripción |
| :--- | :--- |
| `/fb` o `/foreverboard` | Abre / Cierra el panel de control del SoundBoard |
| `/fb play <id>` | Reproduce y sincroniza un clip directamente (útil para macros) |
| `/fb list` | Muestra la lista de sonidos disponibles y sus identificadores |

---

## 🎵 ¿Cómo añadir nuevos sonidos?
1. Coloca tus archivos `.mp3` u `.ogg` dentro de la carpeta `ForeverBoard\sounds\`.
2. Haz doble clic en el archivo **`actualizar_sonidos.bat`**.
   - Escaneará automáticamente todos los audios y creará los botones con sus nombres limpios y formateados.
3. En el juego escribe `/reload` (o entra al juego) ¡y ya tendrás todos los botones listos!
