# KittyBoard

A fully customizable **Qt 6.11 + QML-based virtual keyboard engine** built for modern Wayland compositors. It features a theme-driven UI, modular key components, a JSON-based styling system, and system-wide keystroke injection without stealing window focus.

## Overview

KittyBoard is a lightweight virtual keyboard built using **Qt Quick (QML)** and a **C++ backend**. Designed specifically for Wayland environments, it utilizes the `wlr-layer-shell` protocol to render as an overlay that never takes focus away from your target application. Keystrokes are injected directly into the kernel's input layer using `ydotool`.

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
