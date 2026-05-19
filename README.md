# KittyBoard

A fully customizable **Qt 6.11 + QML-based virtual keyboard engine** built for modern Wayland compositors. It features a theme-driven UI, modular key components, a JSON-based styling system, and system-wide input injection via `ydotool`.

## Overview

KittyBoard is a lightweight virtual keyboard built using **Qt Quick (QML)** and a **C++ backend**. Designed specifically for Wayland environments, it utilizes the `wlr-layer-shell` protocol to render as a persistent overlay surface without stealing focus from your active application.

## Features

* **Wayland Native:** Uses `LayerShellQt` to run as an overlay surface.
* **No Focus Stealing:** `KeyboardInteractivityNone` ensures your target application always keeps focus.
* **System-Wide Input:** Injects keystrokes directly via `ydotool` (bypassing Wayland security restrictions on virtual inputs).
* **Draggable Interface:** Custom coordinate tracking allows the layer-shell window to be moved freely across the screen.
* **Caps Lock Support:** Fully functional Caps Lock state management affecting alphabet keys.
* **Dynamic Theming:** JSON-based styling system (colors, layout, sizing, animations).
* **Modular UI:** Clean QML architecture with reusable key components.

## Requirements

### System Dependencies
* **OS:** Linux (Wayland)
* **Compositor:** wlroots-based (Sway, Hyprland) or KDE Plasma Wayland (must support `wlr-layer-shell`)
* **Input Injection:** `ydotool` (must be installed and the daemon `ydotoold` must be running)

### Build Dependencies
* Qt 6.11 (with Quick and WaylandClient modules)
* LayerShellQt (`layer-shell-qt`)
* CMake 3.16+
* C++17 compatible compiler

## Building

### Prerequisites
Ensure all build dependencies are installed on your system:

```bash
# Ubuntu/Debian
sudo apt install qt6-base-dev qt6-declarative-dev layer-shell-qt cmake build-essential

# Arch
sudo pacman -S qt6-base qt6-declarative layer-shell-qt cmake gcc
```

### Build Instructions

The project uses **CMake** as its build system. Follow these steps to build KittyBoard:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/nirajandata/kittyBoard.git
   cd kittyBoard
   ```

2. **Create a build directory:**
   ```bash
   mkdir build
   cd build
   ```

3. **Configure the project with CMake:**
   ```bash
   cmake ..
   ```

4. **Build the project:**
   ```bash
   cmake --build .
   ```
   Or use the traditional `make`:
   ```bash
   make
   ```

5. **Install (optional):**
   ```bash
   cmake --install .
   ```
   Or with make:
   ```bash
   sudo make install
   ```

### CMakeLists.txt Overview

The `CMakeLists.txt` file defines the build configuration for KittyBoard:

- **Minimum CMake version:** 3.16
- **Qt 6 modules required:** Core, Gui, Quick, WaylandClient
- **External dependencies:** LayerShellQt
- **C++ standard:** C++17
- **Sources:** QML files and C++ backend implementation

For detailed configuration, refer to the `CMakeLists.txt` file in the project root.
