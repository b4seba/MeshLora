# 📻 Radio-Mesh (Meshemergencia-Maule)

Aplicación móvil nativa en **Flutter** para comunicación descentralizada de emergencia en redes de malla (**LoRa 915 MHz / BLE**), basada en el diseño de alta fidelidad **Radio-Mesh** y orientada a pruebas con antenas **WisBlock RAK4630 / RAK4631**.

---

## 🚀 Características Principales

1. **Diseño de Alto Contraste y Cero Fricción:**
   - **Paleta de Colores Oficial:** Azul Marino Profesional (`#0A1F44`), Verde Lima/Seguridad (`#4CD137`), Naranja Vibrante (`#FF6B00`), Blanco Puro (`#FFFFFF`) y Alerta Roja (`#E53E3E`).
   - Botones grandes, táctiles y pensados para situaciones de estrés y personas no técnicas.
   - Sin tecnicismos en pantalla (interfaz simplificada estilo mensajería instantánea).

2. **Flujo de Pantallas:**
   - **Splash / Onboarding:** Identidad visual con logotipo vectorial Mesh y botón *"COMENZAR"*.
   - **Vinculación (Pairing):** Animación visual Celular $\leftrightarrow$ Antena de Radio RAK4630, checklist de conexión, escaneo BLE real y pantalla de confirmación verde *"¡CONECTADO!"*.
   - **Ingreso de Nombre:** Configuración de nombre corto de usuario (máximo 20 caracteres).
   - **Mensajería (Chat):** Indicador de señal de red activa, mensajes con avatares de colores, distintivo **URGENTE / SOS** con halo pulsante, barra de **Mensajes Rápidos** de un toque (*¡ESTOY BIEN!*, *NECESITO AYUDA*, *¿DÓNDE ESTÁN?*, *PUNTO DE ENCUENTRO*, *HAY AGUA DISPONIBLE*) y transmisión de paquetes por radio LoRa.
   - **Vecinos Cercanos (Lista & Mapa):** Pestaña segmentada para ver nodos en lista o sobre un **mapa vectorial interactivo** con cuadrícula urbana, zonas seguras/parques, radar pulsante de posición y controles de zoom (+/-).
   - **Estado del Dispositivo:** Indicador de batería de la radio con cálculo de horas restantes, estado de señal LoRa (915 MHz, RSSI dBm, nodos, mensajes), ficha técnica del hardware y botón desplegable de **GUÍA DE EMERGENCIA** (protocolos para Terremoto, Incendio, Tsunami, Primeros Auxilios y teléfonos de auxilio 131, 132, 133).

---

## 📡 Protocolo y Pruebas con las 2 Antenas RAK4630

### Formato de Paquete LoRa:
Los mensajes transmitidos entre los dos nodos RAK4630 utilizan un formato ultracompacto optimizado para bajo tiempo de aire:
```
[TIPO]|[REMITENTE]|[MENSAJE]
Ejemplo: MSG|Carlos R.|Todo en orden en la plaza
Ejemplo: SOS|Laura M.|NECESITO AYUDA. Quedamos atrapados en el piso 2
```

### Configuración de los Nodos RAK4630:
- **Banda LoRa:** 915 MHz (Banda ISM libre para Chile / SUBTEL).
- **Servicio BLE:** Nordic UART Service (NUS)
  - Service UUID: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
  - RX Characteristic (Teléfono $\rightarrow$ Radio): `6E400002-B5A3-F393-E0A9-E50E24DCCA9E`
  - TX Characteristic (Radio $\rightarrow$ Teléfono Notify): `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`
- **Compatibilidad adicional:** Soporta payloads y servicio BLE de Meshtastic / MeshCore.
- **Modo Simulado / Fallback:** Si se ejecuta en emulador o sin antena física encendida, la app entra automáticamente en modo simulado para pruebas de interfaz completas. Desde la pantalla de chat, el botón superior de antena permite simular la recepción en tiempo real de mensajes de la segunda antena RAK4630.

---

## 🛠️ Ejecución del Proyecto

### Requisitos:
- Flutter SDK 3.13+ o superior
- Dispositivo Android / iOS o emulador

### Comandos:
```bash
# Entrar al directorio
cd radio_mesh

# Obtener dependencias
flutter pub get

# Ejecutar análisis de código
flutter analyze

# Ejecutar pruebas unitarias / smoke tests
flutter test

# Ejecutar en tu celular o emulador
flutter run
```
