---
name: uber-flutter-ui
description: Design and implement elite, high-polish mobile interfaces in Flutter following Uber Base UI, Apple HIG, and modern design systems.
---

# Uber Base UI & Flutter UX Design Skill

Use this skill whenever creating, refactoring, or polishing Flutter UI/UX components and screens.

## Design Tenets

### 1. Palette & High Contrast (Alerta Mesh DNA)
- **Obsidian Dark**: `Color(0xFF0B132B)` — used for dominant dark mode surfaces, high contrast headers, and crisp text.
- **Electric Mesh Blue**: `Color(0xFF2B70C9)` / `Color(0xFF2563EB)` — brand primary accent for actions, links, and selected states.
- **Surface Light**: `Color(0xFFFFFFFF)` with background `Color(0xFFF8FAFC)`.
- **Subtle Borders**: `Border.all(color: Color(0xFFE2E8F0), width: 1.0)`.
- **Status Accents**:
  - Green (Active/BLE connected): `Color(0xFF10B981)`
  - Red (Emergency SOS): `Color(0xFFEF4444)`
  - Amber (Warning/Low Battery): `Color(0xFFF59E0B)`

### 2. Typography
- Use `GoogleFonts.plusJakartaSansTextTheme()`.
- Headers: Semibold/Bold with negative letter spacing (`-0.5`).
- Subtitles: Medium weight with muted slate color (`Color(0xFF64748B)`).

### 3. Tactile & Micro-Interactions
- Add `HapticFeedback.lightImpact()` on tap actions.
- Use `flutter_animate` with `.fadeIn(duration: 200.ms).slideY(begin: 0.05, end: 0)`.
- Use `gap` for predictable 8pt-based whitespace.
