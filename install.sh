#!/usr/bin/env bash
# Dotfiles installer: packages (Arch) + symlinks from this repo into $HOME.
set -Eeuo pipefail

readonly SCRIPT_NAME="${0##*/}"
# Default repo root = directory containing this script (works for ~/dotfiles, ~/.dotfiles, etc.)
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)}"

# Set once at startup by detect_target_os() — use these for all install decisions.
DOTFILES_OS_KERNEL=""
DOTFILES_OS_ID=""
DOTFILES_TARGET_OS=""

# Arch package list — add entries here as needed.
readonly -a ARCH_PACKAGES=(
  btop
  firefox
  konsole
)

log_info() { printf '[%s] %s\n' "$SCRIPT_NAME" "$*"; }
log_error() { printf '[%s] ERROR: %s\n' "$SCRIPT_NAME" "$*" >&2; }

fail() {
  log_error "$@"
  exit 1
}

on_err() {
  local status=$?
  local line=${BASH_LINENO[0]:-?}
  log_error "Command failed (exit ${status}) at ${BASH_SOURCE[0]}:${line}"
  exit "$status"
}
trap on_err ERR

# Populates DOTFILES_OS_KERNEL, DOTFILES_OS_ID, DOTFILES_TARGET_OS (exported for subshells).
detect_target_os() {
  DOTFILES_OS_KERNEL=$(uname -s)

  case "$DOTFILES_OS_KERNEL" in
    Linux)
      if [[ -r /etc/os-release ]]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        DOTFILES_OS_ID="${ID:-unknown}"
        if [[ $DOTFILES_OS_ID == arch ]]; then
          DOTFILES_TARGET_OS="arch-linux"
        else
          DOTFILES_TARGET_OS="${DOTFILES_OS_ID}-linux"
        fi
      else
        DOTFILES_OS_ID="unknown"
        DOTFILES_TARGET_OS="unknown-linux"
      fi
      ;;
    Darwin)
      DOTFILES_OS_ID="darwin"
      DOTFILES_TARGET_OS="macos"
      ;;
    *)
      DOTFILES_OS_ID="unknown"
      DOTFILES_TARGET_OS="${DOTFILES_OS_KERNEL}-unknown"
      ;;
  esac

  export DOTFILES_OS_KERNEL DOTFILES_OS_ID DOTFILES_TARGET_OS
}

detect_target_os

is_arch() {
  [[ ${DOTFILES_OS_ID:-} == arch ]]
}

require_directory() {
  local path=$1
  if [[ ! -d $path ]]; then
    fail "Expected directory does not exist: ${path} (set REPO_DIR, or invoke install.sh from inside the repo)"
  fi
}

require_file() {
  local path=$1
  if [[ ! -f $path ]]; then
    fail "Required file missing: ${path}"
  fi
}

check_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    fail "sudo is not installed or not in PATH; cannot install packages on Arch."
  fi
  if ! sudo -v; then
    fail "sudo authentication failed; cannot install packages."
  fi
}

install_arch_packages() {
  log_info "Installing Arch packages (pacman): ${ARCH_PACKAGES[*]}"
  if ! sudo pacman -S --noconfirm --needed "${ARCH_PACKAGES[@]}"; then
    fail "pacman failed. Inspect the error output above (mirrors, disk space, keys)."
  fi
  log_info "Arch packages installed or already satisfied."
}

ensure_vim_dirs() {
  local d
  for d in "$HOME/.vim/undo" "$HOME/.vim/backup" "$HOME/.vim/swap"; do
    if ! mkdir -p "$d"; then
      fail "Could not create directory: $d"
    fi
  done
}

# Symlink $REPO_DIR/$1 -> $HOME/$2 (backs up existing target).
link_into_home() {
  local rel=$1
  local dest_name=$2
  local src=$REPO_DIR/$rel
  local dest=$HOME/$dest_name

  require_file "$src"

  if [[ -e $dest ]] || [[ -L $dest ]]; then
    local backup=${dest}.bak.$(date +%s)
    log_info "Backing up existing ${dest_name} -> ${backup}"
    if ! mv "$dest" "$backup"; then
      fail "Could not move aside existing file: ${dest}"
    fi
  fi

  if ! ln -s "$src" "$dest"; then
    fail "Could not create symlink: ${dest} -> ${src}"
  fi
  log_info "Linked ~/${dest_name} -> ${src}"
}

main() {
  [[ -n ${REPO_DIR:-} ]] || fail "REPO_DIR is empty; set it to the absolute path of this repository."

  log_info "Installing for target OS: ${DOTFILES_TARGET_OS} (kernel=${DOTFILES_OS_KERNEL}, os-id=${DOTFILES_OS_ID})"

  require_directory "$REPO_DIR"

  require_file "$REPO_DIR/common/.bashrc"
  require_file "$REPO_DIR/common/.vimrc"
  require_file "$REPO_DIR/common/.gitconfig"

  if is_arch; then
    check_sudo
    install_arch_packages
  else
    log_info "Not Arch Linux (DOTFILES_TARGET_OS=${DOTFILES_TARGET_OS}); skipping pacman package installation."
  fi

  ensure_vim_dirs

  link_into_home "common/.bashrc" ".bashrc"
  link_into_home "common/.vimrc" ".vimrc"
  link_into_home "common/.gitconfig" ".gitconfig"

  if is_arch; then
    require_file "$REPO_DIR/arch-linux/.bashrc_arch"
    link_into_home "arch-linux/.bashrc_arch" ".bashrc_arch"
  fi

  log_info "Dotfiles installed successfully."
}

main "$@"
