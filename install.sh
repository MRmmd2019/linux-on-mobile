#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# ===== UI colors =====
RED='\e[1;31m'; GREEN='\e[1;32m'; CYAN='\e[1;36m'; YELLOW='\e[1;33m'; RESET='\e[0m'

banner() {
  clear
  echo -e "${CYAN}"
  echo "╔════════════════════════════════════════════╗"
  echo "║   🚀 Linux-on-Mobile Installer v5.0        ║"
  echo "║   📱 Run full Linux desktops on Android    ║"
  echo "║   🛠️ Termux + proot-distro + TigerVNC      ║"
  echo "╚════════════════════════════════════════════╝"
  echo -e "${RESET}"
}

abort() { echo -e "\n${RED}✖ ${1:-Aborted}${RESET}"; exit 1; }
info()  { echo -e "${CYAN}ℹ${RESET} $*"; }
ok()    { echo -e "${GREEN}✔${RESET} $*"; }
warn()  { echo -e "${YELLOW}⚠${RESET} $*"; }

trap 'abort "Interrupted by user."' INT TERM

banner

# ===== sanity checks =====
[[ -d "/data/data/com.termux/files/usr" ]] || abort "Not running inside Termux."

info "Installing Termux dependencies..."
pkg update -y >/dev/null 2>&1
pkg install -y proot-distro tigervnc whiptail coreutils >/dev/null 2>&1 || abort "Package install failed."
ok "Termux deps ready."

# ===== discover available distros from proot-distro =====
AVAILABLE=$(proot-distro list | awk '/Available distributions:/{flag=1;next}/^$/{flag=0}flag{print $1}' || true)
# Filter common aliases we support best
CANDIDATES=(ubuntu debian archlinux fedora opensuse)
MENU_ITEMS=()
for d in "${CANDIDATES[@]}"; do
  if echo "$AVAILABLE" | grep -qx "$d"; then
    case "$d" in
      ubuntu)   MENU_ITEMS+=("ubuntu"   "Ubuntu (recommended)") ;;
      debian)   MENU_ITEMS+=("debian"   "Debian (stable)") ;;
      archlinux)MENU_ITEMS+=("archlinux" "Arch Linux (rolling)") ;;
      fedora)   MENU_ITEMS+=("fedora"   "Fedora (advanced/experimental)") ;;
      opensuse) MENU_ITEMS+=("opensuse" "openSUSE (advanced/experimental)") ;;
    esac
  fi
done

[[ ${#MENU_ITEMS[@]} -gt 0 ]] || abort "No supported distro aliases found in proot-distro."

DISTRO=$(whiptail --title "🐧 Choose Linux Distro" \
  --menu "Select a base distro to install:" 18 70 10 \
  "${MENU_ITEMS[@]}" 3>&1 1>&2 2>&3) || abort "Cancelled."

# ===== desktop choices per distro (safe defaults) =====
# We prefer DEs that work well under proot (no systemd dependency at runtime)
DESKTOP_OPTIONS() {
  case "$1" in
    ubuntu|debian)
      echo "xfce" "XFCE (light & stable)" \
           "lxde" "LXDE (super light)" \
           "mate" "MATE (classic)" \
           "cinnamon" "Cinnamon (modern)" \
           "plasma" "KDE Plasma (minimal, heavier)" \
           "gnome-min" "GNOME minimal (experimental)"
      ;;
    archlinux)
      echo "xfce" "XFCE (light & stable)" \
           "lxde" "LXDE (super light)" \
           "mate" "MATE (classic)" \
           "cinnamon" "Cinnamon (modern)" \
           "plasma" "KDE Plasma (minimal, heavier)"
      ;;
    fedora|opensuse)
      echo "xfce" "XFCE (recommended here)" \
           "lxde" "LXDE (light)" \
           "mate" "MATE (classic)"
      ;;
    *) echo "xfce" "XFCE (default)";;
  esac
}

DESKTOP=$(whiptail --title "🎨 Choose Desktop Environment" \
  --menu "Select desktop for $DISTRO:" 20 72 10 \
  $(DESKTOP_OPTIONS "$DISTRO") 3>&1 1>&2 2>&3) || abort "Cancelled."

# ===== resolution & VNC password =====
validate_geom() { [[ "$1" =~ ^[0-9]{3,4}x[0-9]{3,4}$ ]]; }
GEOM=$(whiptail --inputbox "📐 Enter VNC resolution (e.g. 1280x720)" 10 60 "1280x720" 3>&1 1>&2 2>&3) || abort "Cancelled."
validate_geom "$GEOM" || abort "Invalid geometry format. Use WxH like 1280x720."

PASS=$(whiptail --passwordbox "🔑 Enter VNC password (min 6 chars)" 10 60 3>&1 1>&2 2>&3) || abort "Cancelled."
[[ ${#PASS} -ge 6 ]] || abort "Password too short."
PASS2=$(whiptail --passwordbox "🔐 Confirm VNC password" 10 60 3>&1 1>&2 2>&3) || abort "Cancelled."
[[ "$PASS" == "$PASS2" ]] || abort "Passwords do not match."

# ===== install distro (idempotent) =====
info "Installing $DISTRO (this may take a while)..."
proot-distro install "$DISTRO" >/dev/null 2>&1 || warn "Install may already exist; continuing."
ok "$DISTRO ready."

# ===== build per-distro install script =====
build_install_script() {
  cat <<'EOS'
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
DESKTOP_ENV="${DESKTOP_ENV:?}"
DISTRO_ID="${DISTRO_ID:?}"

install_debian_ubuntu() {
  apt update -y && apt upgrade -y
  apt install -y sudo dbus-x11 xterm pulseaudio gvfs tigervnc-standalone-server
  case "$DESKTOP_ENV" in
    xfce)     apt install -y xfce4 xfce4-goodies ;;
    lxde)     apt install -y lxde ;;
    mate)     apt install -y mate-desktop-environment ;;
    cinnamon) apt install -y cinnamon ;;
    plasma)   apt install -y kde-plasma-desktop ;;
    gnome-min)apt install -y gnome-session gnome-terminal nautilus ;;
    *) echo "Unknown desktop: $DESKTOP_ENV"; exit 1 ;;
  esac
}

install_arch() {
  pacman -Sy --noconfirm
  pacman -S --noconfirm dbus xorg-xauth xorg-xsetroot xorg-xrdb tigervnc xterm sudo pulseaudio
  case "$DESKTOP_ENV" in
    xfce)     pacman -S --noconfirm xfce4 xfce4-goodies ;;
    lxde)     pacman -S --noconfirm lxde ;;
    mate)     pacman -S --noconfirm mate mate-extra ;;
    cinnamon) pacman -S --noconfirm cinnamon nemo xed ;;
    plasma)   pacman -S --noconfirm plasma-desktop konsole dolphin ;;
    *) echo "Unknown desktop: $DESKTOP_ENV"; exit 1 ;;
  esac
}

install_fedora() {
  dnf -y update
  dnf -y install tigervnc-server dbus-x11 xterm pulseaudio alsa-lib
  case "$DESKTOP_ENV" in
    xfce) dnf -y groupinstall "Xfce Desktop" || dnf -y install xfce4* ;;
    lxde) dnf -y install @lxde-desktop || dnf -y install lxde* openbox ;;
    mate) dnf -y groupinstall "MATE Desktop" || dnf -y install mate-desktop* ;;
    *) echo "For Fedora, use XFCE/LXDE/MATE"; exit 1 ;;
  esac
}

install_opensuse() {
  zypper -n refresh
  zypper -n install tigervnc xterm pulseaudio
  case "$DESKTOP_ENV" in
    xfce) zypper -n install -t pattern xfce || zypper -n install xfce4-panel xfce4-session xfce4-settings Thunar ;;
    lxde) zypper -n install lxde-common lxde-session openbox lxde-icon-theme ;;
    mate) zypper -n install -t pattern mate || zypper -n install mate-desktop mate-session-manager caja ;;
    *) echo "For openSUSE, use XFCE/LXDE/MATE"; exit 1 ;;
  esac
}

case "$DISTRO_ID" in
  ubuntu|debian) install_debian_ubuntu ;;
  archlinux)     install_arch ;;
  fedora)        install_fedora ;;      # experimental
  opensuse)      install_opensuse ;;    # experimental
  *) echo "Unsupported distro id: $DISTRO_ID"; exit 1 ;;
esac

# Prepare VNC dirs
mkdir -p /root/.vnc
EOS
}

# ===== run install in target distro =====
info "Installing desktop '$DESKTOP' inside $DISTRO..."
proot-distro login "$DISTRO" -- env DESKTOP_ENV="$DESKTOP" DISTRO_ID="$DISTRO" bash -lc "$(build_install_script)" >/dev/null 2>&1 || abort "Desktop install failed."
ok "Desktop installed."

# ===== configure VNC password and xstartup securely =====
info "Configuring VNC..."
proot-distro login "$DISTRO" -- env DESKTOP_ENV="$DESKTOP" VNC_PASS="$PASS" bash -lc '
set -Eeuo pipefail
mkdir -p /root/.vnc
echo "$VNC_PASS" | vncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd
unset VNC_PASS

cat > /root/.vnc/xstartup << "EOS"
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Start D-Bus if available
if command -v dbus-launch >/dev/null 2>&1; then
  eval "$(dbus-launch --sh-syntax)"
fi

export LANG=C.UTF-8
export LC_ALL=C.UTF-8

DESKTOP_ENV_PLACEHOLDER
EOS

case "$DESKTOP_ENV" in
  xfce)     sed -i "s|DESKTOP_ENV_PLACEHOLDER|xsetroot -solid grey \&\nstartxfce4 \&|g" /root/.vnc/xstartup ;;
  lxde)     sed -i "s|DESKTOP_ENV_PLACEHOLDER|xsetroot -solid grey \&\nstartlxde \&|g" /root/.vnc/xstartup ;;
  mate)     sed -i "s|DESKTOP_ENV_PLACEHOLDER|xsetroot -solid grey \&\nmate-session \&|g" /root/.vnc/xstartup ;;
  cinnamon) sed -i "s|DESKTOP_ENV_PLACEHOLDER|xsetroot -solid grey \&\ncinnamon-session \&|g" /root/.vnc/xstartup ;;
  plasma)   sed -i "s|DESKTOP_ENV_PLACEHOLDER|xsetroot -solid grey \&\nstartplasma-x11 \&|g" /root/.vnc/xstartup ;;
  gnome-min)sed -i "s|DESKTOP_ENV_PLACEHOLDER|xsetroot -solid grey \&\ngnome-session \&|g" /root/.vnc/xstartup ;;
  *) echo "Unknown desktop in xstartup"; exit 1 ;;
esac

chmod +x /root/.vnc/xstartup
' >/dev/null 2>&1 || abort "VNC configuration failed."
unset PASS
ok "VNC configured."

# ===== write management scripts =====
SCRIPTS_DIR="$HOME/.lom"
mkdir -p "$SCRIPTS_DIR"
echo "$DISTRO" > "$SCRIPTS_DIR/.distro"
echo "$GEOM"   > "$SCRIPTS_DIR/.geom"

cat > "$SCRIPTS_DIR/start.sh" <<'EOS'
#!/usr/bin/env bash
set -e
DISTRO="$(cat "$HOME/.lom/.distro")"
GEOM="$(cat "$HOME/.lom/.geom")"
# Ensure VNC password exists
proot-distro login "$DISTRO" -- bash -lc 'test -f /root/.vnc/passwd || { echo "VNC password missing. Re-run installer."; exit 1; }'
# Start VNC server (localhost only for safety)
proot-distro login "$DISTRO" -- bash -lc 'vncserver -localhost yes -geometry "'"$GEOM"'" :1'
echo "VNC started. Connect to 127.0.0.1:5901 (Display :1)"
EOS

cat > "$SCRIPTS_DIR/stop.sh" <<'EOS'
#!/usr/bin/env bash
set -e
DISTRO="$(cat "$HOME/.lom/.distro")"
proot-distro login "$DISTRO" -- bash -lc 'vncserver -kill :1' || true
echo "VNC stopped (if it was running)."
EOS

cat > "$SCRIPTS_DIR/change-resolution.sh" <<'EOS'
#!/usr/bin/env bash
set -e
newg="$1"
[[ "$newg" =~ ^[0-9]{3,4}x[0-9]{3,4}$ ]] || { echo "Usage: change-resolution.sh WxH (e.g. 1280x720)"; exit 1; }
echo "$newg" > "$HOME/.lom/.geom"
echo "Saved. Restart VNC to apply."
EOS

cat > "$SCRIPTS_DIR/change-vnc-pass.sh" <<'EOS'
#!/usr/bin/env bash
set -e
DISTRO="$(cat "$HOME/.lom/.distro")"
read -rsp "New VNC password (min 6 chars): " p1; echo
read -rsp "Confirm password: " p2; echo
[[ "${#p1}" -ge 6 && "$p1" == "$p2" ]] || { echo "Invalid/mismatch password."; exit 1; }
proot-distro login "$DISTRO" -- env VNC_PASS="$p1" bash -lc 'echo "$VNC_PASS" | vncpasswd -f > /root/.vnc/passwd; chmod 600 /root/.vnc/passwd'
echo "VNC password updated."
EOS

chmod +x "$SCRIPTS_DIR/"*.sh

# ===== optional TUI manager =====
cat > "$SCRIPTS_DIR/manager.sh" <<'EOS'
#!/usr/bin/env bash
set -Eeuo pipefail
menu() {
  whiptail --title "📟 Linux-on-Mobile Manager" --menu "Choose an action:" 18 70 10 \
    "start" "Start VNC" \
    "stop" "Stop VNC" \
    "res" "Change resolution" \
    "pass" "Change VNC password" \
    "shell" "Open shell in distro" \
    "info" "Show current config" \
    "exit" "Exit" \
    3>&1 1>&2 2>&3
}
while true; do
  choice=$(menu) || exit 0
  case "$choice" in
    start)  bash "$HOME/.lom/start.sh"   | whiptail --title "Start VNC" --msgbox "$(cat -)" 12 60 ;;
    stop)   msg=$(bash "$HOME/.lom/stop.sh"); whiptail --title "Stop VNC" --msgbox "$msg" 10 50 ;;
    res)    newg=$(whiptail --inputbox "New resolution (e.g. 1280x720)" 10 60 "$(cat "$HOME/.lom/.geom")" 3>&1 1>&2 2>&3) || continue
            bash "$HOME/.lom/change-resolution.sh" "$newg" && whiptail --title "Resolution" --msgbox "Saved: $newg\nRestart VNC to apply." 10 50 ;;
    pass)   bash "$HOME/.lom/change-vnc-pass.sh" ;;
    shell)  dist="$(cat "$HOME/.lom/.distro")"; termux-open-url "intent:#Intent;action=android.intent.action.VIEW;S.browser_fallback_url=about:blank;end"; proot-distro login "$dist" ;;
    info)   dist="$(cat "$HOME/.lom/.distro")"; geom="$(cat "$HOME/.lom/.geom")"
            whiptail --title "Config" --msgbox "Distro: $dist\nResolution: $geom\nConnect: 127.0.0.1:5901 (Display :1)\nStart: bash ~/.lom/start.sh\nStop:  bash ~/.lom/stop.sh" 12 70 ;;
    exit)   exit 0 ;;
  esac
done
EOS
chmod +x "$SCRIPTS_DIR/manager.sh"

# ===== final message =====
banner
echo -e "${GREEN}✅ Installation Complete${RESET}\n"
echo -e "${CYAN}How to use:${RESET}"
echo -e "  ${YELLOW}Start VNC:${RESET} bash ~/.lom/start.sh"
echo -e "  ${YELLOW}Stop  VNC:${RESET} bash ~/.lom/stop.sh"
echo -e "  ${YELLOW}Manager  :${RESET} bash ~/.lom/manager.sh  (TUI for start/stop/change settings)"
echo -e "  ${YELLOW}Connect  :${RESET} 127.0.0.1:5901 (Display :1) via VNC Viewer"
echo -e "\n${CYAN}Saved config:${RESET}"
echo -e "  Distro: ${GREEN}$DISTRO${RESET}"
echo -e "  Resolution: ${GREEN}$GEOM${RESET}"
echopkg update -y >/dev/null 2>&1
pkg install -y proot-distro tigervnc whiptail coreutils >/dev/null 2>&1 || { echo -e "${RED} Package install failed${RESET}"; exit 1; }
echo -e " ${GREEN}Done!${RESET}"

# انتخاب توزیع (فقط Debian/Ubuntu پایدار)
DISTRO=$(whiptail --title "🐧 Choose Linux Distro" --menu "Select one:" 18 68 6 \
  "ubuntu"  "Ubuntu (recommended)" \
  "debian"  "Debian (stable)" \
  "archlinux [disabled]"   "Use Debian/Ubuntu for VNC auto-setup" \
  "fedora   [disabled]"    "Use Debian/Ubuntu for VNC auto-setup" \
  "opensuse [disabled]"    "Use Debian/Ubuntu for VNC auto-setup" \
  3>&1 1>&2 2>&3) || { echo -e "${RED}Cancelled${RESET}"; exit 1; }

case "$DISTRO" in
  ubuntu|debian) : ;;
  *) whiptail --title "ℹ️ Info" --msgbox "For a stable, tested setup choose Debian or Ubuntu." 8 50; exit 1 ;;
esac

# انتخاب دسکتاپ
DESKTOP=$(whiptail --title "🎨 Choose Desktop" --menu "Select one:" 18 68 6 \
  "xfce"     "XFCE (light & fast)" \
  "lxde"     "LXDE (super light)" \
  "mate"     "MATE (classic)" \
  "cinnamon" "Cinnamon (modern)" \
  "plasma"   "KDE Plasma (minimal)" \
  3>&1 1>&2 2>&3) || { echo -e "${RED}Cancelled${RESET}"; exit 1; }

# رزولوشن
GEOM=$(whiptail --inputbox "📐 Enter VNC resolution (e.g. 1280x720)" 10 60 "1280x720" 3>&1 1>&2 2>&3) || { echo -e "${RED}Cancelled${RESET}"; exit 1; }

# پسورد VNC (حداقل 6 کاراکتر برای tigervnc)
PASS=$(whiptail --passwordbox "🔑 Enter VNC password (min 6 chars)" 10 60 3>&1 1>&2 2>&3) || { echo -e "${RED}Cancelled${RESET}"; exit 1; }
if [[ ${#PASS} -lt 6 ]]; then
  whiptail --title "❗ Weak password" --msgbox "Password must be at least 6 characters." 8 50
  exit 1
fi

echo -ne "🛠️ Installing $DISTRO"
proot-distro install "$DISTRO" >/dev/null 2>&1 || { echo -e " ${RED}Install failed${RESET}"; exit 1; }
echo -e " ${GREEN}Done!${RESET}"

# نصب دسکتاپ و VNC داخل توزیع
echo -ne "🎨 Installing $DESKTOP desktop in $DISTRO"
proot-distro login "$DISTRO" -- env DESKTOP_ENV="$DESKTOP" bash -euo pipefail -c '
  export DEBIAN_FRONTEND=noninteractive
  apt update -y && apt upgrade -y

  # پایه‌ها
  apt install -y sudo dbus-x11 xterm pulseaudio gvfs

  case "$DESKTOP_ENV" in
    xfce)     apt install -y xfce4 xfce4-goodies ;;
    lxde)     apt install -y lxde ;;
    mate)     apt install -y mate-desktop-environment ;;
    cinnamon) apt install -y cinnamon ;;
    plasma)   apt install -y kde-plasma-desktop ;;
    *) echo "Unknown desktop"; exit 1 ;;
  esac

  # VNC
  apt install -y tigervnc-standalone-server

  # آماده‌سازی دایرکتوری‌های VNC
  mkdir -p /root/.vnc
' >/dev/null 2>&1 || { echo -e " ${RED}Desktop install failed${RESET}"; exit 1; }
echo -e " ${GREEN}Done!${RESET}"

# ست کردن امن پسورد VNC داخل توزیع و ساخت xstartup متناسب با دسکتاپ
echo -ne "🔐 Configuring VNC password and xstartup"
proot-distro login "$DISTRO" -- env DESKTOP_ENV="$DESKTOP" VNC_PASS="$PASS" bash -euo pipefail -c '
  mkdir -p /root/.vnc

  # ست کردن پسورد به‌صورت امن (فقط داخل توزیع، بدون ذخیره بیرون)
  echo "$VNC_PASS" | vncpasswd -f > /root/.vnc/passwd
  chmod 600 /root/.vnc/passwd
  unset VNC_PASS

  # ساخت xstartup براساس دسکتاپ
  cat > /root/.vnc/xstartup << "EOS"
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# شروع D-Bus
if command -v dbus-launch >/dev/null 2>&1; then
  eval "$(dbus-launch --sh-syntax)"
fi

# کی‌بورد و locale (اختیاری)
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

DESKTOP_ENV_PLACEHOLDER
EOS

  # جایگذاری دستور شروع دسکتاپ
  case "$DESKTOP_ENV" in
    xfce)     sed -i "s|DESKTOP_ENV_PLACEHOLDER|startxfce4 \&|g" /root/.vnc/xstartup ;;
    lxde)     sed -i "s|DESKTOP_ENV_PLACEHOLDER|startlxde \&|g"  /root/.vnc/xstartup ;;
    mate)     sed -i "s|DESKTOP_ENV_PLACEHOLDER|mate-session \&|g" /root/.vnc/xstartup ;;
    cinnamon) sed -i "s|DESKTOP_ENV_PLACEHOLDER|cinnamon-session \&|g" /root/.vnc/xstartup ;;
    plasma)   sed -i "s|DESKTOP_ENV_PLACEHOLDER|startplasma-x11 \&|g" /root/.vnc/xstartup ;;
    *) echo "Unknown desktop"; exit 1 ;;
  esac

  chmod +x /root/.vnc/xstartup
' >/dev/null 2>&1 || { echo -e " ${RED}VNC config failed${RESET}"; exit 1; }

# از حافظه پاک کردن پسورد
unset PASS
echo -e " ${GREEN}Done!${RESET}"

# اسکریپت‌های Start/Stop (در ترموکس؛ VNC داخل توزیع اجرا می‌شود)
mkdir -p "$HOME/.vnc-scripts"

cat > "$HOME/.vnc-scripts/start-vnc.sh" <<EOF
#!/usr/bin/env bash
set -e
# Use saved geometry and distro
DISTRO="$DISTRO"
GEOM="$GEOM"
# اگر passwd هنوز ست نشده بود، از کاربر بخواه
proot-distro login "\$DISTRO" -- bash -lc 'test -f /root/.vnc/passwd || { echo "VNC password not set. Run installer again."; exit 1; }'
# اجرای VNC داخل توزیع
proot-distro login "\$DISTRO" -- bash -lc 'vncserver -geometry "$GEOM" :1'
echo "VNC started at 127.0.0.1:5901 (Display :1)"
EOF

cat > "$HOME/.vnc-scripts/stop-vnc.sh" <<'EOF'
#!/usr/bin/env bash
set -e
DISTRO_FILE="$HOME/.vnc-scripts/.distro"
if [[ -f "$DISTRO_FILE" ]]; then DISTRO="$(cat "$DISTRO_FILE")"; fi
# تلاش برای کشتن سرور :1 داخل توزیع
proot-distro login "${DISTRO:-ubuntu}" -- bash -lc 'vncserver -kill :1' || true
echo "VNC stopped (if was running)."
EOF

# ذخیره نام توزیع برای stop script
echo "$DISTRO" > "$HOME/.vnc-scripts/.distro"

chmod +x "$HOME/.vnc-scripts/"*.sh

# پیام پایانی
whiptail --title "✅ Installation Complete" --msgbox "Start VNC: bash ~/.vnc-scripts/start-vnc.sh
Stop  VNC: bash ~/.vnc-scripts/stop-vnc.sh
Connect to: 127.0.0.1:5901 (Display :1)" 12 60
