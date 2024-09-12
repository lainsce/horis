<img align="left" style="vertical-align: middle" width="120" height="120" alt="Template Screenshot" src="data/icons/app.svg">

# Horis

Habit tracking made fast.

###

[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

## 🛠️ Dependencies

Please make sure you have these dependencies first before building.

```bash
gtk4
libhelium-1
meson
vala
blueprint-compiler
libportal
libportal-gtk4
json-glib
```

## 🏗️ Building

Simply clone this repo, then:

```bash
meson setup _build --prefix=/usr && cd _build
sudo ninja install
```
