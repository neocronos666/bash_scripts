# Terminal User Interface (TUI) Tools Guide

Una colección de herramientas CLI/TUI para gestión de sistema, redes, desarrollo y más, con instrucciones de instalación y ejemplos.

---

## Categorías

### 🖴 Disk Managers
| Tool    | Install (Linux)                  | Example Usage                     | Description                          |
|---------|----------------------------------|-----------------------------------|--------------------------------------|
| **ncdu** | `sudo apt install ncdu`          | `ncdu /path/to/dir`              | Analiza uso de disco interactivo.    |
| **dua-cli** | `cargo install dua-cli`        | `dua-cli analyze ~/Downloads`    | Visualiza y libera espacio.          |
| **gdu**  | `curl -L https://git.io/gdu | sh` | `gdu ~`                            | Alternativa rápida a `ncdu`.        |

### 📊 System Monitors
| Tool      | Install                          | Example Usage             | Description                          |
|-----------|----------------------------------|---------------------------|--------------------------------------|
| **htop**  | `sudo apt install htop`          | `htop`                    | Monitor de procesos interactivo.     |
| **btop++**| `sudo apt install btop`          | `btop`                    | Monitor con gráficos avanzados.      |
| **glances**| `pip install glances`           | `glances`                 | Monitor multiplataforma.             |

### 🌐 Web Browsers
| Tool       | Install                          | Example Usage                     |
|------------|----------------------------------|-----------------------------------|
| **lynx**   | `sudo apt install lynx`          | `lynx https://example.com`        |
| **w3m**    | `sudo apt install w3m`           | `w3m example.com`                 |

### 📶 Network Tools
| Tool         | Install                          | Example Usage                     |
|--------------|----------------------------------|-----------------------------------|
| **nmtui**    | `sudo apt install network-manager` | `nmtui` (interactive)            |
| **iftop**    | `sudo apt install iftop`          | `sudo iftop -i eth0`              |
| **gping**    | `cargo install gping`             | `gping google.com`                |

### 🎵 Multimedia
| Tool        | Install                          | Example Usage                     |
|-------------|----------------------------------|-----------------------------------|
| **cmus**    | `sudo apt install cmus`          | `cmus`, luego `:add ~/Music`      |
| **cava**    | `sudo apt install cava`          | `cava` (visualizador de audio)    |

### 💾 Git Clients
| Tool       | Install                          | Example Usage                     |
|------------|----------------------------------|-----------------------------------|
| **lazygit**| `sudo apt install lazygit`       | `lazygit` (interactive)           |
| **tig**    | `sudo apt install tig`           | `tig` (explorador de commits)     |

### 📁 File Managers
| Tool      | Install                          | Example Usage                     |
|-----------|----------------------------------|-----------------------------------|
| **ranger**| `sudo apt install ranger`        | `ranger` (navegación con preview) |
| **vifm**  | `sudo apt install vifm`          | `vifm` (modo Vim-like)            |

### 💬 Messaging
| Tool        | Install                          | Example Usage                     |
|-------------|----------------------------------|-----------------------------------|
| **mutt**    | `sudo apt install mutt`          | `mutt -f imap://user@server`      |
| **weechat** | `sudo apt install weechat`       | `/connect irc.libera.chat`        |

---

## Instalación General
- **Debian/Ubuntu**: `sudo apt install [tool]`
- **Arch**: `sudo pacman -S [tool]`
- **Fedora**: `sudo dnf install [tool]`
- **Via Cargo (Rust)**: `cargo install [tool]`
- **Via Pip (Python)**: `pip install [tool]`

## Ejemplo de Uso Avanzado
```bash
# Analizar disco y borrar archivos grandes con ncdu
ncdu /home
(Seleccionar archivos con ↑/↓ y borrar con 'd')

# Monitorizar red en tiempo real
sudo iftop -i wlp2s0 -t -s 10
