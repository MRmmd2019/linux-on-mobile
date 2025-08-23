#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

clear

# 🎨 رنگ‌ها
RED='\e[1;31m'
GREEN='\e[1;32m'
CYAN='\e[1;36m'
YELLOW='\e[1;33m'
RESET='\e[0m'

banner() {
  echo -e "${CYAN}"
  echo "╔════════════════════════════════════════════╗"
  echo "║   🚀 Linux-on-Mobile Installer v4.0        ║"
  echo "║   📱 Run full Linux desktops on Android    ║"
  echo "║   🛠️ Powered by Termux + proot-distro + VNC║"
  echo "╚════════════════════════════════════════════╝"
  echo -e "${RESET}"
}
banner
sleep 0.5

# بررسی محیط
if [[ ! -d "/data/data/com.termux/files/usr" ]]; then
  echo -e "${RED}❌ Not running inside Termux!${RESET}"
  exit 1
fi

# Trap برای خروج تمیز
cleanup() { echo -e "\n${YELLOW}⚠️  Aborted by user.${RESET}"; exit 1; }
trap cleanup INT TERM

# نصب پیش‌نیازها (Termux)
echo -ne "📦 Installing required packages"
pkg update -y >/dev/null 2>&1
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
