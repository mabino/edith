#!/bin/bash
# Interactive Notarization Script for Edith
# A colorful, user-friendly script for code signing and notarization

set -e

# ══════════════════════════════════════════════════════════════════════════════
# Colors and Formatting
# ══════════════════════════════════════════════════════════════════════════════
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Symbols
CHECK="✓"
CROSS="✗"
ARROW="→"
STAR="★"
GEAR="⚙"
LOCK="🔐"
PACKAGE="📦"
ROCKET="🚀"
HOURGLASS="⏳"
SPARKLES="✨"

# ══════════════════════════════════════════════════════════════════════════════
# Helper Functions
# ══════════════════════════════════════════════════════════════════════════════

print_header() {
    echo ""
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${MAGENTA}║${RESET}  ${CYAN}${BOLD}$1${RESET}  ${MAGENTA}║${RESET}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

print_banner() {
    clear
    echo ""
    echo -e "${CYAN}    ╔═══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}    ║${RESET}                                                           ${CYAN}║${RESET}"
    echo -e "${CYAN}    ║${RESET}   ${BOLD}${WHITE}███████╗${BLUE}██████╗ ${GREEN}██╗${YELLOW}████████╗${RED}██╗  ██╗${RESET}                   ${CYAN}║${RESET}"
    echo -e "${CYAN}    ║${RESET}   ${BOLD}${WHITE}██╔════╝${BLUE}██╔══██╗${GREEN}██║${YELLOW}╚══██╔══╝${RED}██║  ██║${RESET}                   ${CYAN}║${RESET}"
    echo -e "${CYAN}    ║${RESET}   ${BOLD}${WHITE}█████╗  ${BLUE}██║  ██║${GREEN}██║${YELLOW}   ██║   ${RED}███████║${RESET}                   ${CYAN}║${RESET}"
    echo -e "${CYAN}    ║${RESET}   ${BOLD}${WHITE}██╔══╝  ${BLUE}██║  ██║${GREEN}██║${YELLOW}   ██║   ${RED}██╔══██║${RESET}                   ${CYAN}║${RESET}"
    echo -e "${CYAN}    ║${RESET}   ${BOLD}${WHITE}███████╗${BLUE}██████╔╝${GREEN}██║${YELLOW}   ██║   ${RED}██║  ██║${RESET}                   ${CYAN}║${RESET}"
    echo -e "${CYAN}    ║${RESET}   ${BOLD}${WHITE}╚══════╝${BLUE}╚═════╝ ${GREEN}╚═╝${YELLOW}   ╚═╝   ${RED}╚═╝  ╚═╝${RESET}                   ${CYAN}║${RESET}"
    echo -e "${CYAN}    ║${RESET}                                                           ${CYAN}║${RESET}"
    echo -e "${CYAN}    ║${RESET}         ${LOCK} ${BOLD}Notarization & Code Signing Tool${RESET}  ${LOCK}            ${CYAN}║${RESET}"
    echo -e "${CYAN}    ║${RESET}                                                           ${CYAN}║${RESET}"
    echo -e "${CYAN}    ╚═══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

print_step() {
    local step=$1
    local total=$2
    local message=$3
    echo -e "${BLUE}${BOLD}[${step}/${total}]${RESET} ${CYAN}${ARROW}${RESET} ${message}"
}

print_success() {
    echo -e "     ${GREEN}${CHECK} $1${RESET}"
}

print_error() {
    echo -e "     ${RED}${CROSS} $1${RESET}"
}

print_warning() {
    echo -e "     ${YELLOW}! $1${RESET}"
}

print_info() {
    echo -e "     ${DIM}$1${RESET}"
}

prompt_input() {
    local prompt=$1
    local var_name=$2
    local is_secret=${3:-false}
    
    echo -ne "${YELLOW}${ARROW}${RESET} ${WHITE}${prompt}${RESET}: "
    if [ "$is_secret" = true ]; then
        read -s input
        echo ""
    else
        read input
    fi
    eval "$var_name='$input'"
}

prompt_confirm() {
    local prompt=$1
    echo -ne "${YELLOW}?${RESET} ${WHITE}${prompt}${RESET} ${DIM}[y/N]${RESET}: "
    read -n 1 reply
    echo ""
    [[ "$reply" =~ ^[Yy]$ ]]
}

spinner() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 10 ))
        printf "\r     ${CYAN}${spin:$i:1}${RESET} ${message}"
        sleep 0.1
    done
    printf "\r"
}

# ══════════════════════════════════════════════════════════════════════════════
# Configuration
# ══════════════════════════════════════════════════════════════════════════════
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_PATH="$BUILD_DIR/Edith.app"
ZIP_PATH="$BUILD_DIR/Edith.zip"
DMG_PATH="$BUILD_DIR/Edith.dmg"

# Environment variables (can be preset)
APPLE_ID="${APPLE_ID:-}"
TEAM_ID="${TEAM_ID:-}"
APP_PASSWORD="${APP_PASSWORD:-}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-Developer ID Application}"

# ══════════════════════════════════════════════════════════════════════════════
# Main Script
# ══════════════════════════════════════════════════════════════════════════════

print_banner

echo -e "${DIM}This script will guide you through code signing and notarizing Edith.${RESET}"
echo -e "${DIM}You'll need an Apple Developer account and app-specific password.${RESET}"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Step 1: Gather Credentials
# ─────────────────────────────────────────────────────────────────────────────
print_header "${GEAR} Configuration"

if [ -z "$APPLE_ID" ]; then
    prompt_input "Apple ID (email)" APPLE_ID
fi
echo -e "     ${GREEN}${CHECK}${RESET} Apple ID: ${CYAN}$APPLE_ID${RESET}"

if [ -z "$TEAM_ID" ]; then
    prompt_input "Team ID" TEAM_ID
fi
echo -e "     ${GREEN}${CHECK}${RESET} Team ID: ${CYAN}$TEAM_ID${RESET}"

if [ -z "$APP_PASSWORD" ]; then
    echo ""
    echo -e "     ${DIM}App-specific passwords can be generated at:${RESET}"
    echo -e "     ${BLUE}https://appleid.apple.com/account/manage${RESET}"
    echo ""
    prompt_input "App-Specific Password" APP_PASSWORD true
fi
echo -e "     ${GREEN}${CHECK}${RESET} App Password: ${CYAN}••••••••••••${RESET}"

echo ""
echo -e "     ${DIM}Signing Identity: ${SIGNING_IDENTITY}${RESET}"

# Validate inputs
if [ -z "$APPLE_ID" ] || [ -z "$TEAM_ID" ] || [ -z "$APP_PASSWORD" ]; then
    echo ""
    print_error "Missing required credentials. Cannot proceed."
    exit 1
fi

echo ""
if ! prompt_confirm "Proceed with notarization?"; then
    echo -e "${YELLOW}Aborted.${RESET}"
    exit 0
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 2: Build Release
# ─────────────────────────────────────────────────────────────────────────────
print_header "${PACKAGE} Building Release"

print_step 1 5 "Building release version..."

if [ -d "$APP_PATH" ]; then
    print_warning "Existing build found"
    if prompt_confirm "Rebuild the app?"; then
        rm -rf "$APP_PATH"
        "$SCRIPT_DIR/build.sh" Release > /dev/null 2>&1 &
        spinner $! "Compiling..."
        wait $!
        print_success "Build complete"
    else
        print_info "Using existing build"
    fi
else
    "$SCRIPT_DIR/build.sh" Release > /dev/null 2>&1 &
    spinner $! "Compiling..."
    wait $!
    print_success "Build complete"
fi

if [ ! -d "$APP_PATH" ]; then
    print_error "Build failed - app not found at $APP_PATH"
    exit 1
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 3: Code Sign
# ─────────────────────────────────────────────────────────────────────────────
print_header "${LOCK} Code Signing"

print_step 2 5 "Signing app with Developer ID..."

codesign --force --deep --options runtime \
    --sign "$SIGNING_IDENTITY" \
    --timestamp \
    "$APP_PATH" 2>&1 | while read line; do
    print_info "$line"
done

if codesign --verify --verbose "$APP_PATH" 2>&1 | grep -q "valid on disk"; then
    print_success "Code signature verified"
else
    print_warning "Verifying signature..."
    codesign --verify --verbose "$APP_PATH"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 4: Create Archive
# ─────────────────────────────────────────────────────────────────────────────
print_header "${PACKAGE} Creating Archive"

print_step 3 5 "Creating ZIP archive for notarization..."

rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

ZIP_SIZE=$(du -h "$ZIP_PATH" | cut -f1)
print_success "Archive created: ${ZIP_SIZE}"

# ─────────────────────────────────────────────────────────────────────────────
# Step 5: Submit for Notarization
# ─────────────────────────────────────────────────────────────────────────────
print_header "${ROCKET} Notarization"

print_step 4 5 "Submitting to Apple notary service..."
echo ""
echo -e "     ${HOURGLASS} ${DIM}This may take several minutes...${RESET}"
echo ""

xcrun notarytool submit "$ZIP_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_PASSWORD" \
    --wait 2>&1 | while IFS= read -r line; do
    if [[ "$line" == *"status: Accepted"* ]]; then
        echo -e "     ${GREEN}${SPARKLES} $line${RESET}"
    elif [[ "$line" == *"status:"* ]]; then
        echo -e "     ${CYAN}$line${RESET}"
    elif [[ "$line" == *"id:"* ]]; then
        echo -e "     ${DIM}$line${RESET}"
    else
        echo -e "     $line"
    fi
done

print_success "Notarization accepted"

# ─────────────────────────────────────────────────────────────────────────────
# Step 6: Staple Ticket
# ─────────────────────────────────────────────────────────────────────────────
print_header "${STAR} Finalizing"

print_step 5 5 "Stapling notarization ticket to app..."

xcrun stapler staple "$APP_PATH" 2>&1 | while read line; do
    if [[ "$line" == *"action worked"* ]]; then
        print_success "Ticket stapled successfully"
    else
        print_info "$line"
    fi
done

# ─────────────────────────────────────────────────────────────────────────────
# Complete!
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║${RESET}                                                                  ${GREEN}║${RESET}"
echo -e "${GREEN}║${RESET}   ${SPARKLES}  ${BOLD}${WHITE}NOTARIZATION COMPLETE!${RESET}  ${SPARKLES}                              ${GREEN}║${RESET}"
echo -e "${GREEN}║${RESET}                                                                  ${GREEN}║${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${CYAN}${ARROW}${RESET} Notarized app: ${WHITE}${APP_PATH}${RESET}"
echo ""
echo -e "  ${DIM}The app is now ready for distribution outside the Mac App Store.${RESET}"
echo -e "  ${DIM}Users will not see Gatekeeper warnings when opening Edith.${RESET}"
echo ""

# Offer to create DMG
if prompt_confirm "Create a distributable DMG?"; then
    print_step "+" "+" "Creating DMG..."
    
    rm -f "$DMG_PATH"
    hdiutil create -volname "Edith" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_PATH" > /dev/null 2>&1
    
    # Notarize the DMG too
    xcrun notarytool submit "$DMG_PATH" \
        --apple-id "$APPLE_ID" \
        --team-id "$TEAM_ID" \
        --password "$APP_PASSWORD" \
        --wait > /dev/null 2>&1
    
    xcrun stapler staple "$DMG_PATH" > /dev/null 2>&1
    
    DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)
    print_success "DMG created: ${DMG_PATH} (${DMG_SIZE})"
fi

echo ""
echo -e "${CYAN}Thanks for using Edith! ${RESET}${SPARKLES}"
echo ""
