# Linux Setup Script

A comprehensive automated setup script for Ubuntu/Debian-based Linux distributions that installs and configures essential development tools, applications, and fonts.

## Features

- **System Tools**: Essential utilities and development packages
- **Containerization**: Docker and Docker Compose
- **Programming Languages**: Python, Rust, C/C++, Go, Java
- **Package Managers**: Snap, Flatpak
- **Applications**: Browsers, editors, media players, and productivity tools
- **Fonts**: Automatic font installation with type detection
- **AI Models**: Ollama with pre-configured language models

## Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd linux_setup_script

# Make the script executable
chmod +x setup.sh

# Run the setup
./setup.sh
```

## Configuration

The script uses boolean variables to control what gets installed. Edit the configuration section in `setup.sh`:

```bash
# System Components
INSTALL_SYSTEM_TOOLS=true
INSTALL_CONTAINERIZATION=true
INSTALL_PROGRAMMING_LANGUAGES=true

# Applications
INSTALL_BRAVE=true
INSTALL_VSCODE=true
INSTALL_SPOTIFY=true
# ... and many more
```

## Supported Applications

### Development Tools

- Visual Studio Code / VSCodium
- Docker (includes Docker Compose)
- Programming language toolchains (Python, Rust, Go, Java, C/C++)
- Node.js, Hugo

### Browsers & Communication

- Brave Browser
- Mullvad VPN

### Productivity

- Bitwarden password manager
- ONLYOFFICE Desktop Editors
- Filezilla FTP client
- Texmaker LaTeX editor

### Media & Entertainment

- Spotify
- VLC Media Player
- MultiMC (Minecraft launcher)

### Security & Privacy

- VeraCrypt (file & disk encryption)
- Mullvad VPN

### File Sharing & Downloading

- LocalSend
- JDownloader

## Font Installation

The script supports automatic font installation from Google Fonts and direct zip downloads. Fonts are configured in the `FONTS` array:

```bash
FONTS=(
    "Lato|https://fonts.google.com/download?family=Lato"
    "Myriad Pro|https://font.download/dl/font/myriad-pro.zip"
)
```

Supported font formats:

- TTF files → `/usr/share/fonts/truetype/{font-name}/`
- OTF/TTC files → `/usr/share/fonts/opentype/{font-name}/`

## AI Models

Pre-configured Ollama models for local AI development:

```bash
AI_MODELS=(
    "gemma3:1b"
    "gemma3:4b"
    "llama3.1:8b"
)
```

## Package Managers

The script installs and configures multiple package managers:

- **APT**: System packages and repositories
- **Snap**: Universal Linux packages
- **Flatpak**: Sandboxed applications

## System Requirements

- Ubuntu 20.04+ or Debian-based distribution
- Internet connection for downloads
- Sudo privileges
- At least 5GB free disk space

## Installation Methods

The script uses different installation methods based on the application:

- **APT repositories**: System packages and officially supported apps
- **GitHub releases**: Latest versions of applications like Obsidian, LocalSend
- **Snap packages**: Universal Linux applications
- **Flatpak**: Sandboxed applications like JDownloader
- **Direct downloads**: Specialized installers and fonts

## Logging

All installation activities are logged with colored output:

- Green: Success messages
- Yellow: Warnings and skipped items
- Red: Errors
- Blue: Information

## Customization

To add new applications:

1. Add a configuration variable in the appropriate section
2. Create an installation function following the existing patterns
3. Add the function call to the relevant installation section

For fonts, simply add entries to the `FONTS` array using the format:

```bash
"Font Display Name|Download URL"
```

## Contributing

Contributions are welcome! Please ensure new applications follow the existing patterns and include proper error handling.

## License

This project is open source. Please check the license file for details.
