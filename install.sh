#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }

echo ""
echo -e "${BOLD}Claude Code SaaS Skills — Installer${NC}"
echo "======================================="
echo ""

SKILLS_DIR="$HOME/.claude/skills"
REPO_URL="https://github.com/DariuszCiesielski/claude-code-saas-skills.git"
TEMP_DIR=""
SOURCE_DIR=""
CLONED=false

# Determine source: local repo or clone
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/skills" ]; then
    info "Using local skills directory: $SCRIPT_DIR/skills"
    SOURCE_DIR="$SCRIPT_DIR/skills"
else
    info "Cloning repository..."
    TEMP_DIR=$(mktemp -d)
    if ! git clone --depth 1 "$REPO_URL" "$TEMP_DIR" 2>/dev/null; then
        error "Failed to clone repository. Check your internet connection."
        exit 1
    fi
    SOURCE_DIR="$TEMP_DIR/skills"
    CLONED=true
    success "Repository cloned."
fi

# Create skills directory
mkdir -p "$SKILLS_DIR"

# Install skills
COUNT=0
ERRORS=0

while IFS= read -r skill_file; do
    skill_dir=$(dirname "$skill_file")
    skill_name=$(basename "$skill_dir")

    target_dir="$SKILLS_DIR/$skill_name"
    mkdir -p "$target_dir"

    if cp "$skill_file" "$target_dir/SKILL.md" 2>/dev/null; then
        success "Installed: $skill_name"
        COUNT=$((COUNT + 1))
    else
        error "Failed to install: $skill_name"
        ERRORS=$((ERRORS + 1))
    fi
done < <(find "$SOURCE_DIR" -name "SKILL.md" -type f | sort)

# Cleanup
if [ "$CLONED" = true ] && [ -n "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
fi

# Summary
echo ""
echo "======================================="
if [ "$ERRORS" -eq 0 ]; then
    success "${BOLD}Done! Installed $COUNT skills to $SKILLS_DIR${NC}"
else
    echo -e "${GREEN}[OK]${NC} Installed $COUNT skills. ${RED}$ERRORS failed.${NC}"
fi
echo ""
info "Skills are now available in Claude Code. Just start a conversation!"
echo ""
