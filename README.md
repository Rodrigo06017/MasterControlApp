# 🎮 MasterControlApp

**MasterControlApp** es una aplicación móvil multiplataforma de código abierto creada en **Flutter** que convierte tu dispositivo móvil (Android / iOS) en un control universal para consolas y centros multimedia.

Diseñada especialmente para esos momentos en los que tu control físico se quedó sin batería, lo olvidaste o simplemente necesitas un mando rápido para ver películas, series o navegar por la interfaz de tu consola sin complicaciones.

---

## ✨ Características Principales

- 📡 **Conexión Directa por Wi-Fi:** Comunicación de ultra baja latencia con tu consola en la misma red local.
- 🎮 **Modo Control Xbox:**
  - **D-Pad digital táctil:** Navegación en 4 direcciones (Arriba, Abajo, Izquierda, Derecha).
  - **Botones de acción:** A, B, X, Y con retroalimentación háptica (vibración).
  - **Botón Xbox (Nexus/Home):** Acceso instantáneo a la guía de la consola.
  - **Botones de sistema:** Menú (Start / Hamburguesa) y Vista (Select / Ventanas).
- 🎬 **Modo Multimedia:**
  - Controles de reproducción: Reproducir, Pausar, Siguiente, Anterior, Adelantar y Regresar.
  - Controles de audio: Subir volumen, Bajar volumen y Silenciar (Mute).
- 🔍 **Detección Automática de Consola:** Búsqueda en la red local mediante paquetes de descubrimiento UDP en el puerto `5050` o conexión directa por dirección IP.
- 🎨 **Interfaz Gamer Moderna:** Tema oscuro estilizado inspirado en la estética de Xbox con animaciones fluidas a 60–120 FPS.

---

## 🛠️ Configuración Previa en tu Consola Xbox

Para permitir que **MasterControlApp** se enlace directamente a tu Xbox sin cables ni dongles adicionales:

1. Enciende tu Xbox y abre **Configuración**.
2. Dirígete a **Dispositivos y conexiones** > **Características remotas** (o *Opciones de conexión*).
3. Asegúrate de tener activada la casilla **"Habilitar características remotas"**.
4. En la sección de preferencias de la aplicación, selecciona **"Permitir conexiones desde cualquier dispositivo"**.
5. Conecta tu teléfono a la misma red Wi-Fi en la que está conectada tu Xbox.

---

## 🚀 Arquitectura y Tecnologías

- **Framework Móvil:** [Flutter](https://flutter.dev) (Dart)
- **Protocolo de Comunicación:** Xbox SmartGlass UDP Protocol (`puerto 5050`)
- **Gestión de Estado:** Provider / ChangeNotifier
- **Retroalimentación Háptica:** HapticFeedback nativo

---

## 📂 Estructura del Proyecto

```text
lib/
├── core/
│   ├── constants/       # Constantes de botones y comandos SmartGlass
│   ├── network/         # Cliente UDP y descubrimiento de red
│   └── theme/           # Paleta de colores Xbox Dark Theme y tipografía
├── models/              # Modelos de consola, paquetes de control y estado
├── services/            # Servicios de conexión y protocolo Xbox
├── viewmodels/          # Lógica de conexión y estado del mando
└── views/               # Pantallas (Scanner, Control Xbox, Modo Multimedia)
```

---

## 👨‍💻 Autor

Desarrollado con dedicación por [Rodrigo06017](https://github.com/Rodrigo06017) 🚀
