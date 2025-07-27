#!/bin/bash

# Mint Base Setup Script
# All-in-one bash script to install & configure a new installation of Linux Mint (Ubuntu based)

set -e  # Exit on any error

# =============================================================================
# GLOBAL CONFIGURATION VARIABLES
# =============================================================================

# System Components Toggle
INSTALL_SYSTEM_TOOLS=true
INSTALL_CONTAINERIZATION=true
INSTALL_PROGRAMMING_LANGUAGES=true

# Containerization Tools Toggle (used via install_with_toggle function)
INSTALL_DOCKER=true

# Programming Languages Toggle (used via install_with_toggle function)
INSTALL_PYTHON=true
INSTALL_RUST=true
INSTALL_C_CPP=true
INSTALL_GO=true
INSTALL_JAVA=true

# Package Managers Toggle (used via install_with_toggle function)
INSTALL_SNAP=true
INSTALL_FLATPAK=true

# Applications Toggle (used via install_with_toggle function)
INSTALL_BRAVE=true
INSTALL_LIBREWOLF=true
INSTALL_MULLVAD=true
INSTALL_BITWARDEN=true
INSTALL_VERACRYPT=true
INSTALL_VSCODE=true
INSTALL_VSCODIUM=true
INSTALL_OLLAMA=true
INSTALL_MULTIMC=true
INSTALL_SPOTIFY=true
INSTALL_ONLYOFFICE=true
INSTALL_OBSIDIAN=true
INSTALL_LOCALSEND=true
INSTALL_FILEZILLA=true
INSTALL_TEXMAKER=true
INSTALL_VLC=true

# Snap Applications Toggle (used via install_with_toggle function)
INSTALL_HUGO=true
INSTALL_NODE=true
INSTALL_ANDROID_STUDIO=true

# Flatpak Applications Toggle (used via install_with_toggle function)
INSTALL_JDOWNLOADER=true

# Font Installation Configuration
INSTALL_FONTS=true

# Array of fonts to install with their URLs and names
# Format: "Font Name|URL"
# The "Font Name" is used as the directory name and should be unique
# (the name will get processed into lowercase, spaces to hyphens)
#
# Supported: Google Fonts and direct links to font zip files
# Font types (TTF/OTF) are automatically detected and installed to appropriate directories
FONTS=(
    "Lato|https://fonts.google.com/download?family=Lato"
    "Myriad Pro|https://font.download/dl/font/myriad-pro.zip"
)

# AI Models Configuration
DOWNLOAD_AI_MODELS=true

# Array of AI models to download with Ollama
AI_MODELS=(
    "gemma3:1b"   # 32K Context
    "gemma3:4b"   # 128K Context
    "gemma3n:e2b" # 32K Context
    "gemma3n:e4b" # 32K Context
    "llama3.1:8b" # 128K Context
    "llama3.2:1b" # 128K Context
    "llama3.2:3b" # 128K Context
)

# =============================================================================
# CONSTANTS AND UTILITY FUNCTIONS
# =============================================================================

# Colors for output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
GRAY='\033[1;90m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_disabled() {
    echo -e "${GRAY}[DISABLED]${NC} $1"
}

# Utility functions
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

file_exists() {
    local file_path="$1"
    [ -f "$file_path" ]
}

# Get the correct installer directory for the actual user
get_installer_dir() {
    local actual_user="${SUDO_USER:-$USER}"
    local actual_home

    if [ "$actual_user" != "root" ]; then
        actual_home=$(eval echo "~$actual_user")
    else
        actual_home="$HOME"
    fi

    echo "$actual_home/Downloads/Installers"
}

# Generic installation helper for simple apt packages
install_apt_package() {
    local package_name="$1"
    local display_name="${2:-$package_name}"
    local command_check="${3:-$package_name}"

    log_info "Installing $display_name..."

    if command_exists "$command_check"; then
        log_warning "$display_name is already installed"
    else
        log_info "Installing $package_name..."
        sudo apt-get install -y "$package_name"
        log_success "$display_name installed successfully"
    fi
}

# Generic installation helper with toggle check
install_with_toggle() {
    local toggle_var="$1"
    local install_function="$2"
    local component_name="$3"

    if [ "${!toggle_var}" = "true" ]; then
        $install_function
    else
        log_disabled "$component_name installation is disabled"
    fi
}

# =============================================================================
# SYSTEM SETUP FUNCTIONS
# =============================================================================

# Create Downloads/Installers directory
create_installer_dir() {
    log_info "Creating Downloads/Installers directory..."

    # Get the actual user (not root when using sudo)
    local actual_user="${SUDO_USER:-$USER}"
    local actual_home

    if [ "$actual_user" != "root" ]; then
        actual_home=$(eval echo "~$actual_user")
    else
        actual_home="$HOME"
    fi

    local installer_dir="$actual_home/Downloads/Installers"

    # Create directory as the actual user to ensure proper ownership
    if [ "$actual_user" != "root" ] && [ -n "$SUDO_USER" ]; then
        sudo -u "$actual_user" mkdir -p "$installer_dir"
    else
        mkdir -p "$installer_dir"
    fi

    log_success "Downloads/Installers directory created at $installer_dir"
}

# Update system packages
update_system() {
    log_info "Updating package lists..."
    sudo apt-get update
    log_success "Package lists updated"

    log_info "Upgrading system packages..."
    sudo apt-get upgrade -y
    log_success "System packages upgraded"
}

# Final system upgrade
final_system_upgrade() {
    log_info "=== Performing Final System Upgrade ==="
    log_info "Running distribution upgrade to ensure all packages are up to date..."
    sudo apt-get dist-upgrade -y
    log_success "Distribution upgrade completed"
}

# =============================================================================
# SYSTEM TOOLS INSTALLATION
# =============================================================================

# Install essential system tools
install_system_tools() {
    log_info "Installing system tools..."

    local tools=("curl" "wget" "git" "htop")

    for tool in "${tools[@]}"; do
        install_apt_package "$tool"
    done
}

# =============================================================================
# REPOSITORY SETUP
# =============================================================================

# Add all required repositories
setup_repositories() {
    log_info "=== Setting up Application Repositories ==="
    local repositories_added=false

    # Add VSCodium repository if enabled
    if [ "$INSTALL_VSCODIUM" = "true" ]; then
        if ! file_exists "/etc/apt/sources.list.d/vscodium.list"; then
            log_info "Adding VSCodium repository..."
            # Add the GPG key of the repository
            wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
            | gpg --dearmor \
            | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
            # Add the repository
            echo 'deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg] https://download.vscodium.com/debs vscodium main' \
            | sudo tee /etc/apt/sources.list.d/vscodium.list
            repositories_added=true
        else
            log_info "VSCodium repository already exists"
        fi
    fi

    # Add Spotify repository if enabled
    if [ "$INSTALL_SPOTIFY" = "true" ]; then
        if ! file_exists "/etc/apt/sources.list.d/spotify.list"; then
            log_info "Adding Spotify repository..."
            # Add Spotify GPG key
            curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
            # Add Spotify repository
            echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
            repositories_added=true
        else
            log_info "Spotify repository already exists"
        fi
    fi

    # Add ONLYOFFICE repository if enabled
    if [ "$INSTALL_ONLYOFFICE" = "true" ]; then
        if ! file_exists "/etc/apt/sources.list.d/onlyoffice.list"; then
            log_info "Adding ONLYOFFICE repository..."
            # Create gnupg directory with proper permissions
            mkdir -p -m 700 ~/.gnupg
            # Add ONLYOFFICE GPG key
            gpg --no-default-keyring --keyring gnupg-ring:/tmp/onlyoffice.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys CB2DE8E5
            chmod 644 /tmp/onlyoffice.gpg
            sudo chown root:root /tmp/onlyoffice.gpg
            sudo mv /tmp/onlyoffice.gpg /usr/share/keyrings/onlyoffice.gpg
            # Add ONLYOFFICE repository
            echo 'deb [signed-by=/usr/share/keyrings/onlyoffice.gpg] https://download.onlyoffice.com/repo/debian squeeze main' | sudo tee /etc/apt/sources.list.d/onlyoffice.list
            repositories_added=true
        else
            log_info "ONLYOFFICE repository already exists"
        fi
    fi

    # Update package lists if any repositories were added
    if [ "$repositories_added" = true ]; then
        log_info "Updating package lists for newly added repositories..."
        sudo apt-get update
        log_success "Package lists updated for all repositories"
    else
        log_info "No new repositories to add"
    fi
}

# =============================================================================
# PACKAGE MANAGERS INSTALLATION
# =============================================================================

# Install Snap package manager
install_snap() {
    log_info "Installing Snap package manager..."

    if command_exists snap; then
        log_warning "Snap is already installed"
        return 0
    fi

    # Check if this is Linux Mint and handle nosnap.pref file
    if file_exists "/etc/apt/preferences.d/nosnap.pref"; then
        log_info "Linux Mint detected - backing up nosnap.pref file..."
        sudo mv /etc/apt/preferences.d/nosnap.pref /etc/apt/preferences.d/nosnap.backup
        log_info "nosnap.pref backed up to nosnap.backup"

        log_info "Updating package lists after removing snap restrictions..."
        sudo apt-get update
    fi

    log_info "Installing snapd..."
    sudo apt-get install -y snapd
    log_success "Snap package manager installed successfully"
}

# Install Flatpak package manager
install_flatpak() {
    log_info "Installing Flatpak package manager..."

    if command_exists flatpak; then
        log_warning "Flatpak is already installed"
        return 0
    fi

    log_info "Installing flatpak..."
    sudo apt-get install -y flatpak

    log_info "Adding Flathub repository..."
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

    log_success "Flatpak package manager installed successfully"
    log_info "Note: A system restart may be required for Flatpak applications to appear in the application menu"
}

# =============================================================================
# CONTAINERIZATION TOOLS
# =============================================================================

# Install Docker
install_docker() {
    log_info "Installing Docker..."

    if command_exists docker; then
        log_warning "Docker is already installed"
    else
        log_info "Downloading and installing Docker..."
        curl -sSL https://get.docker.com | sh

        # Add current user to docker group
        sudo usermod -aG docker "$USER"
        log_success "Docker installed successfully"
        log_warning "Please log out and log back in for Docker group changes to take effect"
    fi
}

# Install containerization tools
install_containerization() {
    if [ "$INSTALL_CONTAINERIZATION" != "true" ]; then
        log_disabled "Containerization tools installation is disabled"
        return 0
    fi

    log_info "=== Installing Containerization Tools ==="

    install_with_toggle "INSTALL_DOCKER" "install_docker" "Docker"
}

# =============================================================================
# PROGRAMMING LANGUAGES
# =============================================================================

# Install Python 3.12
install_python() {
    log_info "Installing Python 3.12..."

    if command_exists python3.12; then
        log_warning "Python 3.12 is already installed"
    else
        log_info "Installing python3.12-full..."
        sudo apt-get install -y python3.12-full python3.12-venv
        log_success "Python 3.12 installed successfully"
    fi
}

# Install Rust
install_rust() {
    log_info "Installing Rust..."

    # Get the actual user (not root when using sudo)
    local actual_user="${SUDO_USER:-$USER}"
    local actual_home

    if [ "$actual_user" != "root" ]; then
        actual_home=$(eval echo "~$actual_user")
    else
        actual_home="$HOME"
    fi

    local cargo_env="$actual_home/.cargo/env"
    local rustup_path="$actual_home/.cargo/bin/rustup"
    local rustc_path="$actual_home/.cargo/bin/rustc"

    # Check if Rust is installed in the user's cargo directory
    if [ -f "$rustc_path" ] && [ -f "$rustup_path" ]; then
        log_info "Rust is already installed, checking for updates..."

        # Check if updates are available before running rustup update
        local update_check
        if [ "$actual_user" != "root" ] && [ -n "$SUDO_USER" ]; then
            update_check=$(sudo -u "$actual_user" bash -c "source '$cargo_env' 2>/dev/null; rustup check 2>/dev/null || echo 'check-failed'")
        else
            source "$cargo_env" 2>/dev/null
            update_check=$(rustup check 2>/dev/null || echo 'check-failed')
        fi

        # Only run update if there are actually updates available
        if echo "$update_check" | grep -q "Update available"; then
            log_info "Updates available, updating Rust to the latest version..."
            if [ "$actual_user" != "root" ] && [ -n "$SUDO_USER" ]; then
                sudo -u "$actual_user" bash -c "source '$cargo_env' 2>/dev/null; rustup update"
            else
                rustup update
            fi

            if [ $? -eq 0 ]; then
                log_success "Rust updated successfully"
            else
                log_warning "Rust update completed with some issues"
            fi
        else
            log_success "Rust is already up to date"
        fi
    elif [ -f "$rustc_path" ]; then
        log_warning "Rust compiler found but rustup is missing - manual Rust installation detected"
        log_info "Skipping automatic update for manual Rust installation"
    else
        log_info "Downloading and installing Rust..."

        # Install Rust as the actual user, not root
        if [ "$actual_user" != "root" ] && [ -n "$SUDO_USER" ]; then
            sudo -u "$actual_user" bash -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
        else
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        fi

        log_success "Rust installed successfully"
    fi
}

# Install C & C++
install_c_cpp() {
    install_apt_package "build-essential" "C & C++ development tools" "gcc"
}

# Install Go
install_go() {
    install_apt_package "golang-go" "Go" "go"
}

# Install Java
install_java() {
    install_apt_package "default-jdk" "Java" "java"
}

# Install programming languages
install_programming_languages() {
    if [ "$INSTALL_PROGRAMMING_LANGUAGES" != "true" ]; then
        log_disabled "Programming languages installation is disabled"
        return 0
    fi

    log_info "=== Installing Programming Languages ==="

    install_with_toggle "INSTALL_PYTHON" "install_python" "Python"
    install_with_toggle "INSTALL_RUST" "install_rust" "Rust"
    install_with_toggle "INSTALL_C_CPP" "install_c_cpp" "C & C++"
    install_with_toggle "INSTALL_GO" "install_go" "Go"
    install_with_toggle "INSTALL_JAVA" "install_java" "Java"
}

# =============================================================================
# APPLICATIONS INSTALLATION
# =============================================================================

# Install Brave Browser
install_brave() {
    log_info "Installing Brave Browser..."

    if command_exists brave-browser; then
        log_warning "Brave Browser is already installed"
    else
        log_info "Installing Brave Browser using the official script..."
        curl -fsS https://dl.brave.com/install.sh | sh
        log_success "Brave Browser installed successfully"
    fi
}

# Install LibreWolf Browser
install_librewolf() {
    log_info "Installing LibreWolf Browser..."

    if command_exists librewolf; then
        log_warning "LibreWolf Browser is already installed"
        return 0
    fi

    log_info "Installing extrepo package manager..."
    sudo apt-get update
    sudo apt-get install -y extrepo

    log_info "Enabling LibreWolf repository..."
    sudo extrepo enable librewolf

    log_info "Installing LibreWolf Browser..."
    sudo apt-get update
    sudo apt-get install -y librewolf

    log_success "LibreWolf Browser installed successfully"
}

# Download and install Mullvad VPN
install_mullvad() {
    log_info "Downloading and installing Mullvad VPN..."

    local installer_dir=$(get_installer_dir)
    local mullvad_url="https://mullvad.net/de/download/app/deb/latest"

    cd "$installer_dir"

    # Get the original filename from the redirect URL
    log_info "Fetching Mullvad VPN download information..."
    local redirect_info=$(wget --spider --max-redirect=5 "$mullvad_url" 2>&1)
    local final_url=$(echo "$redirect_info" | grep -o "Location:.*\.deb" | tail -1 | sed 's/Location: //' | tr -d '\r')
    local filename=$(basename "$final_url")

    if [ -z "$filename" ]; then
        filename="MullvadVPN-latest_amd64.deb"  # Fallback to generic name
    fi

    log_info "Target filename: $filename"

    # Check if file already exists
    if [ -f "$filename" ]; then
        log_warning "Mullvad VPN already downloaded: $filename"
    else
        log_info "Downloading Mullvad VPN from $mullvad_url..."
        wget -O "$filename" "$mullvad_url"
    fi

    if [ -f "$filename" ]; then
        log_success "Mullvad VPN available at $installer_dir/$filename"
        log_info "Installing Mullvad VPN with dependencies..."
        sudo apt-get install -y "./$filename"
        log_success "Mullvad VPN installed successfully"
    else
        log_error "Failed to download Mullvad VPN"
    fi
}

# Download and install Bitwarden
install_bitwarden() {
    log_info "Downloading and installing Bitwarden..."

    local installer_dir=$(get_installer_dir)
    local bitwarden_url="https://vault.bitwarden.com/download/?app=desktop&platform=linux&variant=deb"

    cd "$installer_dir"

    # Get the actual filename by following redirects and checking headers
    log_info "Fetching Bitwarden download information..."

    # Use curl to get the final redirect URL and Content-Disposition header
    local redirect_response=$(curl -sI -L --max-redirs 5 "$bitwarden_url")

    # Try to extract filename from Content-Disposition header first
    local filename=$(echo "$redirect_response" | grep -i "content-disposition" | grep -o "filename=[^;]*" | sed 's/filename=//' | tr -d '"' | tr -d '\r' | tail -1)

    # If that fails, try to get it from the final URL
    if [ -z "$filename" ] || [[ ! "$filename" == *.deb ]]; then
        local final_url=$(echo "$redirect_response" | grep -i "^location:" | tail -1 | sed 's/location: //i' | tr -d '\r')
        if [ -n "$final_url" ]; then
            filename=$(basename "$final_url" | cut -d'?' -f1)
        fi
    fi

    # Final fallback
    if [ -z "$filename" ] || [[ ! "$filename" == *.deb ]]; then
        filename="Bitwarden-latest-amd64.deb"
    fi

    log_info "Target filename: $filename"

    # Check if the specific file already exists
    if [ -f "$filename" ]; then
        log_warning "Bitwarden already downloaded: $filename"
    else
        # Check if any Bitwarden file already exists (different version)
        local existing_file=$(ls -t Bitwarden-*-amd64.deb 2>/dev/null | head -1)

        if [ -n "$existing_file" ]; then
            log_info "Found existing Bitwarden file: $existing_file"
            log_info "But newer version available, downloading: $filename"
        fi

        # Download with content-disposition to get the proper filename
        wget --content-disposition --trust-server-names "$bitwarden_url"

        # Find the actual downloaded file
        local actual_file=$(ls -t Bitwarden-*-amd64.deb 2>/dev/null | head -1)
        if [ -n "$actual_file" ]; then
            filename="$actual_file"
            log_info "Downloaded filename: $filename"
        fi
    fi

    if [ -f "$filename" ]; then
        log_success "Bitwarden available at $installer_dir/$filename"
        log_info "Installing Bitwarden with dependencies..."
        sudo apt-get install -y "./$filename"
        log_success "Bitwarden installed successfully"
    else
        log_error "Failed to download Bitwarden"
    fi
}

# Download and install VeraCrypt
install_veracrypt() {
    log_info "Downloading and installing VeraCrypt..."

    local installer_dir=$(get_installer_dir)

    log_info "Fetching latest VeraCrypt release information..."

    # Try to get the latest release URL, fallback to known working version
    local veracrypt_url=$(curl -s --connect-timeout 10 https://api.github.com/repos/veracrypt/VeraCrypt/releases/latest | \
        grep "browser_download_url.*Ubuntu-24.04-amd64.deb\"" | \
        grep -v "\.sig\"" | \
        head -n 1 | \
        cut -d '"' -f 4)

    # Fallback to known working version if API fails
    if [ -z "$veracrypt_url" ]; then
        log_warning "Could not fetch latest release info, using known version"
        veracrypt_url="https://github.com/veracrypt/VeraCrypt/releases/download/VeraCrypt_1.26.20/veracrypt-1.26.20-Ubuntu-24.04-amd64.deb"
    fi

    cd "$installer_dir"

    # Extract the original filename from the URL to preserve Ubuntu version info
    local filename=$(basename "$veracrypt_url")

    log_info "Target filename: $filename"

    # Check if file already exists
    if [ -f "$filename" ]; then
        log_warning "VeraCrypt already downloaded: $filename"
    else
        log_info "Downloading VeraCrypt from $veracrypt_url..."
        wget -O "$filename" "$veracrypt_url"
    fi

    if [ -f "$filename" ]; then
        log_success "VeraCrypt available at $installer_dir/$filename"
        log_info "Installing VeraCrypt with dependencies..."
        sudo apt-get install -y "./$filename"
        log_success "VeraCrypt installed successfully"
    else
        log_error "Failed to download VeraCrypt"
    fi
}

# Download and install Obsidian
install_obsidian() {
    log_info "Downloading and installing Obsidian..."

    local installer_dir=$(get_installer_dir)

    log_info "Fetching latest Obsidian release information..."

    # Try to get the latest release URL for amd64.deb
    local obsidian_url=$(curl -s --connect-timeout 10 https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest | \
        grep "browser_download_url.*amd64.deb\"" | \
        head -n 1 | \
        cut -d '"' -f 4)

    # Fallback to known working version if API fails
    if [ -z "$obsidian_url" ]; then
        log_warning "Could not fetch latest release info, using known version"
        obsidian_url="https://github.com/obsidianmd/obsidian-releases/releases/download/v1.7.7/obsidian_1.7.7_amd64.deb"
    fi

    cd "$installer_dir"

    # Extract the original filename from the URL
    local filename=$(basename "$obsidian_url")

    log_info "Target filename: $filename"

    # Check if file already exists
    if [ -f "$filename" ]; then
        log_warning "Obsidian already downloaded: $filename"
    else
        log_info "Downloading Obsidian from $obsidian_url..."
        wget -O "$filename" "$obsidian_url"
    fi

    if [ -f "$filename" ]; then
        log_success "Obsidian available at $installer_dir/$filename"
        log_info "Installing Obsidian with dependencies..."
        sudo apt-get install -y "./$filename"
        log_success "Obsidian installed successfully"
    else
        log_error "Failed to download Obsidian"
    fi
}

# Download and install LocalSend
install_localsend() {
    log_info "Downloading and installing LocalSend..."

    local installer_dir=$(get_installer_dir)

    log_info "Fetching latest LocalSend release information..."

    # Try to get the latest release URL for linux-x86-64.deb
    local localsend_url=$(curl -s --connect-timeout 10 https://api.github.com/repos/localsend/localsend/releases/latest | \
        grep "browser_download_url.*linux-x86-64.deb\"" | \
        head -n 1 | \
        cut -d '"' -f 4)

    # Fallback to known working version if API fails
    if [ -z "$localsend_url" ]; then
        log_warning "Could not fetch latest release info, using known version"
        localsend_url="https://github.com/localsend/localsend/releases/download/v1.15.4/LocalSend-1.15.4-linux-x86-64.deb"
    fi

    cd "$installer_dir"

    # Extract the original filename from the URL
    local filename=$(basename "$localsend_url")

    log_info "Target filename: $filename"

    # Check if file already exists
    if [ -f "$filename" ]; then
        log_warning "LocalSend already downloaded: $filename"
    else
        log_info "Downloading LocalSend from $localsend_url..."
        wget -O "$filename" "$localsend_url"
    fi

    if [ -f "$filename" ]; then
        log_success "LocalSend available at $installer_dir/$filename"
        log_info "Installing LocalSend with dependencies..."
        sudo apt-get install -y "./$filename"
        log_success "LocalSend installed successfully"
    else
        log_error "Failed to download LocalSend"
    fi
}

# Download and install Visual Studio Code
install_vscode() {
    log_info "Downloading and installing Visual Studio Code..."

    local installer_dir=$(get_installer_dir)
    local vscode_url="https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"

    cd "$installer_dir"

    # Get the original filename from the redirect URL
    log_info "Fetching Visual Studio Code download information..."
    local redirect_info=$(wget --spider --max-redirect=5 "$vscode_url" 2>&1)
    local final_url=$(echo "$redirect_info" | grep -o "Location:.*\.deb" | tail -1 | sed 's/Location: //' | tr -d '\r')
    local filename=$(basename "$final_url" | cut -d'?' -f1)

    if [ -z "$filename" ] || [[ ! "$filename" == *.deb ]]; then
        filename="code_latest_amd64.deb"  # Fallback to generic name
    fi

    log_info "Target filename: $filename"

    # Check if file already exists
    if [ -f "$filename" ]; then
        log_warning "Visual Studio Code already downloaded: $filename"
    else
        log_info "Downloading Visual Studio Code from $vscode_url..."
        wget -O "$filename" "$vscode_url"
    fi

    if [ -f "$filename" ]; then
        log_success "Visual Studio Code available at $installer_dir/$filename"
        log_info "Installing Visual Studio Code with dependencies..."
        sudo apt-get install -y "./$filename"
        log_success "Visual Studio Code installed successfully"
    else
        log_error "Failed to download Visual Studio Code"
    fi
}

# Install VSCodium via it's apt repository
install_vscodium() {
    log_info "Installing VSCodium..."

    if command_exists codium; then
        log_warning "VSCodium is already installed"
    else
        log_info "Installing VSCodium from repository..."
        sudo apt-get install -y codium
        log_success "VSCodium installed successfully"
    fi
}

# Download and install MultiMC
install_multimc() {
    log_info "Downloading and installing MultiMC..."

    local installer_dir=$(get_installer_dir)

    # Get the download page to extract the current download link
    log_info "Fetching MultiMC download information..."
    local download_page=$(curl -s --connect-timeout 10 "https://multimc.org/" || echo "")

    if [ -z "$download_page" ]; then
        log_error "Failed to fetch MultiMC download page"
        return 1
    fi

    # Extract the .deb download URL from the page
    local multimc_url=$(echo "$download_page" | grep -o 'https://files\.multimc\.org/downloads/multimc_[^"]*\.deb' | head -1)

    if [ -z "$multimc_url" ]; then
        log_warning "Could not extract download URL from page, using fallback URL"
        multimc_url="https://files.multimc.org/downloads/multimc_1.6-1.deb"
    fi

    cd "$installer_dir"

    # Extract filename from URL
    local filename=$(basename "$multimc_url")

    log_info "Target filename: $filename"

    # Check if file already exists
    if [ -f "$filename" ]; then
        log_warning "MultiMC already downloaded: $filename"
    else
        log_info "Downloading MultiMC from $multimc_url..."
        wget -O "$filename" "$multimc_url"
    fi

    if [ -f "$filename" ]; then
        log_success "MultiMC available at $installer_dir/$filename"
        log_info "Installing MultiMC with dependencies..."
        sudo apt-get install -y "./$filename"
        log_success "MultiMC installed successfully"
    else
        log_error "Failed to download MultiMC"
    fi
}

# Install Spotify via apt repository
install_spotify() {
    log_info "Installing Spotify..."

    if command_exists spotify; then
        log_warning "Spotify is already installed"
        return 0
    fi

    log_info "Installing Spotify from repository..."
    sudo apt-get install -y spotify-client

    log_success "Spotify installed successfully"
}

# Install ONLYOFFICE Desktop Editors via apt repository
install_onlyoffice() {
    log_info "Installing ONLYOFFICE Desktop Editors..."

    if command_exists onlyoffice-desktopeditors; then
        log_warning "ONLYOFFICE Desktop Editors is already installed"
        return 0
    fi

    log_info "Installing ONLYOFFICE Desktop Editors from repository..."
    sudo apt-get install -y onlyoffice-desktopeditors

    log_success "ONLYOFFICE Desktop Editors installed successfully"
}

# Install Filezilla via apt repository
install_filezilla() {
    install_apt_package "filezilla" "Filezilla"
}

# Install Texmaker via apt repository
install_texmaker() {
    install_apt_package "texmaker" "Texmaker"
}

# Install VLC Media Player via apt repository
install_vlc() {
    install_apt_package "vlc" "VLC Media Player"
}

# Install Ollama
install_ollama() {
    log_info "Installing Ollama..."

    if command_exists ollama; then
        log_warning "Ollama is already installed"
    else
        log_info "Installing Ollama using the official script..."
        curl -fsSL https://ollama.com/install.sh | sh
        log_success "Ollama installed successfully"
    fi

    # Download AI models after Ollama installation
    download_ai_models
}

# Pull (Download) Ollama AI models from global array
download_ai_models() {
    log_info "Downloading AI models..."

    # Check if Ollama is installed
    if ! command_exists ollama; then
        log_error "Ollama is not installed. Please install Ollama first."
        return 1
    fi

    # Check if AI model download is enabled
    if [ "$DOWNLOAD_AI_MODELS" != "true" ]; then
        log_disabled "AI model download is disabled (DOWNLOAD_AI_MODELS=false)"
        return 0
    fi

    # Check if AI_MODELS array is empty
    if [ ${#AI_MODELS[@]} -eq 0 ]; then
        log_warning "No AI models defined in AI_MODELS array"
        return 0
    fi

    log_info "Found ${#AI_MODELS[@]} models to download"

    # Download each model from the global array
    for model in "${AI_MODELS[@]}"; do
        log_info "Downloading model: $model"

        # Check if model is already downloaded
        if ollama list | grep -q "^$model"; then
            log_warning "Model $model is already downloaded"
        else
            log_info "Pulling model: $model"
            if ollama pull "$model"; then
                log_success "Successfully downloaded model: $model"
            else
                log_error "Failed to download model: $model"
            fi
        fi
    done

    log_success "AI model download process completed"
}

# Install Hugo static site generator via Snap
install_hugo() {
    log_info "Installing Hugo static site generator..."

    # Check if Snap is installed first
    if ! command_exists snap; then
        log_error "Snap is not installed. Please install Snap first to install Hugo."
        return 1
    fi

    # Check if Hugo is already installed
    if command_exists hugo; then
        log_warning "Hugo is already installed"
        return 0
    fi

    log_info "Installing Hugo Extended via Snap..."
    sudo snap install hugo --channel=extended/stable

    log_info "Enabling automatic updates for Hugo..."
    sudo snap refresh --unhold hugo

    log_info "Configuring Hugo permissions..."
    # Allow access to removable media
    sudo snap connect hugo:removable-media
    # Allow access to SSH keys
    sudo snap connect hugo:ssh-keys

    log_success "Hugo installed successfully via Snap"
}

# Install Node.js via Snap
install_node() {
    log_info "Installing Node.js..."

    # Check if Snap is installed first
    if ! command_exists snap; then
        log_error "Snap is not installed. Please install Snap first to install Node.js."
        return 1
    fi

    # Check if Node.js is already installed
    if command_exists node; then
        log_warning "Node.js is already installed"
        return 0
    fi

    log_info "Installing Node.js via Snap..."
    sudo snap install node --classic

    log_success "Node.js installed successfully via Snap"
}

# Install Android Studio via Snap
install_android_studio() {
    log_info "Installing Android Studio..."

    # Check if Snap is installed first
    if ! command_exists snap; then
        log_error "Snap is not installed. Please install Snap first to install Android Studio."
        return 1
    fi

    # Check if Android Studio is already installed
    if command_exists android-studio; then
        log_warning "Android Studio is already installed"
        return 0
    fi

    log_info "Installing Android Studio via Snap..."
    sudo snap install android-studio --classic

    log_success "Android Studio installed successfully via Snap"
}

# Install JDownloader via Flatpak
install_jdownloader() {
    log_info "Installing JDownloader..."

    # Check if Flatpak is installed first
    if ! command_exists flatpak; then
        log_error "Flatpak is not installed. Please install Flatpak first to install JDownloader."
        return 1
    fi

    # Check if JDownloader is already installed
    if flatpak list | grep -q "org.jdownloader.JDownloader"; then
        log_warning "JDownloader is already installed"
        return 0
    fi

    log_info "Installing JDownloader via Flatpak..."
    sudo flatpak install -y flathub org.jdownloader.JDownloader

    log_success "JDownloader installed successfully via Flatpak"
}

# =============================================================================
# FONTS INSTALLATION
# =============================================================================

# Install fonts
install_fonts() {
    if [ "$INSTALL_FONTS" != "true" ]; then
        log_disabled "Font installation is disabled"
        return 0
    fi

    log_info "=== Installing Fonts ==="

    # Check if FONTS array is empty
    if [ ${#FONTS[@]} -eq 0 ]; then
        log_warning "No fonts defined in FONTS array"
        return 0
    fi

    log_info "Found ${#FONTS[@]} fonts to install"

    # Install each font from the global array
    for font_config in "${FONTS[@]}"; do
        install_font_from_config "$font_config"
    done

    # Update font cache
    log_info "Updating font cache..."
    sudo fc-cache -f
    log_success "Font cache updated successfully"
}

# Install font from configuration string
install_font_from_config() {
    local font_config="$1"
    local font_name=$(echo "$font_config" | cut -d'|' -f1)
    local font_url=$(echo "$font_config" | cut -d'|' -f2)

    log_info "Installing $font_name font..."

    local installer_dir=$(get_installer_dir)
    local safe_font_name=$(echo "$font_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
    local filename="${safe_font_name}.zip"

    cd "$installer_dir"

    # Download font if not already present
    if [ -f "$filename" ]; then
        log_warning "$font_name font already downloaded: $filename"
    else
        log_info "Downloading $font_name font from $font_url..."
        wget -O "$filename" "$font_url"
    fi

    if [ -f "$filename" ]; then
        install_font_from_zip "$filename" "$font_name"
    else
        log_error "Failed to download $font_name font"
    fi
}

# Install font from zip file with automatic type detection
install_font_from_zip() {
    local zip_file="$1"
    local font_name="$2"
    local safe_font_name=$(echo "$font_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')

    # Create temporary directory for extraction
    local temp_dir="/tmp/font_install_$$"
    mkdir -p "$temp_dir"

    # Extract zip to temporary directory
    log_info "Extracting $font_name font files..."
    unzip -q "$zip_file" -d "$temp_dir"

    # Detect font types in the extracted files
    local has_ttf=$(find "$temp_dir" -name "*.ttf" -o -name "*.TTF" | wc -l)
    local has_otf=$(find "$temp_dir" -name "*.otf" -o -name "*.OTF" -o -name "*.ttc" -o -name "*.TTC" | wc -l)

    if [ "$has_ttf" -gt 0 ]; then
        install_font_files "$temp_dir" "$safe_font_name" "truetype" "ttf TTF"
    fi

    if [ "$has_otf" -gt 0 ]; then
        install_font_files "$temp_dir" "$safe_font_name" "opentype" "otf OTF ttc TTC"
    fi

    if [ "$has_ttf" -eq 0 ] && [ "$has_otf" -eq 0 ]; then
        log_error "No TTF, OTF, or TTC font files found in $font_name"
    fi

    # Clean up temporary directory
    rm -rf "$temp_dir"
}

# Install font files of a specific type
install_font_files() {
    local temp_dir="$1"
    local safe_font_name="$2"
    local font_type="$3"
    local extensions="$4"

    local font_dir="/usr/share/fonts/$font_type/$safe_font_name"

    # Check if font is already installed
    if [ -d "$font_dir" ] && [ "$(ls -A "$font_dir" 2>/dev/null)" ]; then
        log_warning "$safe_font_name ($font_type) font is already installed"
        return 0
    fi

    log_info "Creating $safe_font_name font directory at $font_dir..."
    sudo mkdir -p "$font_dir"

    # Copy font files directly to the target directory, flattening the structure
    local files_copied=0
    for ext in $extensions; do
        while IFS= read -r -d '' font_file; do
            if [ -f "$font_file" ]; then
                local basename_file=$(basename "$font_file")
                sudo cp "$font_file" "$font_dir/$basename_file"
                files_copied=$((files_copied + 1))
            fi
        done < <(find "$temp_dir" -name "*.$ext" -type f -print0)
    done

    if [ "$files_copied" -gt 0 ]; then
        # Set proper permissions
        sudo chmod 644 "$font_dir"/*
        sudo chown root:root "$font_dir"/*

        log_success "$safe_font_name ($font_type) font installed successfully to $font_dir ($files_copied files)"
    else
        log_error "No $font_type font files found for $safe_font_name"
        sudo rmdir "$font_dir" 2>/dev/null || true
    fi
}



# =============================================================================
# APPLICATIONS ORCHESTRATION
# =============================================================================

# Install package managers
install_package_managers() {
    log_info "=== Installing Package Managers ==="

    install_with_toggle "INSTALL_SNAP" "install_snap" "Snap Package Manager"
    install_with_toggle "INSTALL_FLATPAK" "install_flatpak" "Flatpak Package Manager"
}

# Install applications
install_applications() {
    log_info "=== Installing Applications ==="

    install_with_toggle "INSTALL_BRAVE" "install_brave" "Brave Browser"
    install_with_toggle "INSTALL_LIBREWOLF" "install_librewolf" "LibreWolf Browser"
    install_with_toggle "INSTALL_MULLVAD" "install_mullvad" "Mullvad VPN"
    install_with_toggle "INSTALL_BITWARDEN" "install_bitwarden" "Bitwarden"
    install_with_toggle "INSTALL_VERACRYPT" "install_veracrypt" "VeraCrypt"
    install_with_toggle "INSTALL_OBSIDIAN" "install_obsidian" "Obsidian"
    install_with_toggle "INSTALL_LOCALSEND" "install_localsend" "LocalSend"
    install_with_toggle "INSTALL_VSCODE" "install_vscode" "Visual Studio Code"
    install_with_toggle "INSTALL_VSCODIUM" "install_vscodium" "VSCodium"
    install_with_toggle "INSTALL_MULTIMC" "install_multimc" "MultiMC"
    install_with_toggle "INSTALL_SPOTIFY" "install_spotify" "Spotify"
    install_with_toggle "INSTALL_ONLYOFFICE" "install_onlyoffice" "ONLYOFFICE Desktop Editors"
    install_with_toggle "INSTALL_FILEZILLA" "install_filezilla" "Filezilla"
    install_with_toggle "INSTALL_TEXMAKER" "install_texmaker" "Texmaker"
    install_with_toggle "INSTALL_VLC" "install_vlc" "VLC Media Player"
    install_with_toggle "INSTALL_OLLAMA" "install_ollama" "Ollama"
}

# Install snap applications
install_snap_applications() {
    log_info "=== Installing Snap Applications ==="

    install_with_toggle "INSTALL_HUGO" "install_hugo" "Hugo Static Site Generator"
    install_with_toggle "INSTALL_NODE" "install_node" "Node.js"
    install_with_toggle "INSTALL_ANDROID_STUDIO" "install_android_studio" "Android Studio"
}

# Install flatpak applications
install_flatpak_applications() {
    log_info "=== Installing Flatpak Applications ==="

    install_with_toggle "INSTALL_JDOWNLOADER" "install_jdownloader" "JDownloader"
}

# =============================================================================
# MAIN EXECUTION FLOW
# =============================================================================

# Show help information
show_help() {
    echo "Mint Base Setup Script"
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -y, --yes     Automatically answer yes to all prompts (non-interactive mode)"
    echo "  -h, --help    Show this help message and exit"
    echo ""
    echo "Examples:"
    echo "  $0              # Interactive mode (default)"
    echo "  $0 -y           # Non-interactive mode"
    echo "  sudo $0 -y      # Non-interactive mode with sudo"
    echo ""
    echo "This script installs system tools, containerization software,"
    echo "programming languages, and applications for Linux Mint/Ubuntu."
}

# Main function
main() {
    local auto_yes=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y|--yes)
                auto_yes=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    log_info "Starting Mint Base Setup Script..."
    log_info "This script will install system tools, containerization, programming languages, and applications"

    # Skip confirmation if -y flag is provided
    if [ "$auto_yes" = false ]; then
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Setup cancelled by user"
            exit 0
        fi
    else
        log_info "Auto-confirmation enabled (-y flag detected)"
    fi

    create_installer_dir

    log_info "=== Installing System Updates ==="
    update_system

    # Setup application repositories
    setup_repositories

    # Install system tools
    if [ "$INSTALL_SYSTEM_TOOLS" = "true" ]; then
        log_info "=== Installing System Tools ==="
        install_system_tools
    else
        log_disabled "System tools installation is disabled"
    fi

    # Install package managers
    install_package_managers

    # Install containerization tools
    install_containerization

    # Install programming languages
    install_programming_languages

    # Install applications
    install_applications

    # Install snap applications
    install_snap_applications

    # Install flatpak applications
    install_flatpak_applications

    # Install fonts
    install_fonts

    # Final system upgrade
    log_info "=== Performing Final System Upgrade ==="
    log_info "Running distribution upgrade to ensure all packages are up to date..."
    sudo apt-get dist-upgrade -y
    log_success "Distribution upgrade completed"

    log_success "Mint Base Setup completed successfully!"
    log_info "All applications have been installed automatically"
    log_info "Downloaded .deb files are saved in: $(get_installer_dir)/"
    log_info "Note: All .deb files preserve their original GitHub release filenames"

    # Prompt for system restart
    echo
    log_info "A system restart is recommended to ensure all changes take effect properly."

    if [ "$auto_yes" = false ]; then
        read -p "Do you want to restart the system now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Restarting system in 5 seconds... (Press Ctrl+C to cancel)"
            sleep 5
            sudo reboot
        else
            log_info "System restart skipped. Please restart manually when convenient."
            log_warning "Some changes may require a restart to take full effect."
        fi
    else
        log_info "Auto-confirmation mode: Skipping restart prompt"
        log_info "System restart skipped. Please restart manually when convenient."
        log_warning "Some changes may require a restart to take full effect."
    fi
}

# Run main function
main "$@"
