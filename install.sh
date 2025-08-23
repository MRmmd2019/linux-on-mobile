#!/data/data/com.termux/files/usr/bin/bash
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
echo "║   🚀 Linux-on-Mobile Installer v3.0        ║"
echo "║   📱 Run full Linux desktops on Android    ║"
echo "║   🛠️ Powered by Termux + VNC               ║"
echo "╚════════════════════════════════════════════╝"
echo -e "${RESET}"
}
banner
sleep 1

# بررسی محیط
if [ ! -d "/data/data/com.termux/files/usr" ]; then
  echo -e "${RED} ❌ Not running inside Termux!${RESET}"
  exit 1
fi

# نصب پیش‌نیازها
echo -ne "📦 Installing required packages"
pkg update -y >/dev/null 2>&1
pkg install -y proot-distro tigervnc whiptail coreutils >/dev/null 2>&1 || { echo -e "${RED}Package install failed${RESET}"; exit 1; }
echo -e "${GREEN} Done!${RESET}"

# انتخاب توزیع
DISTRO=$(whiptail --title "🐧 Choose Linux Distro" --menu "Select one:" 20 60 10 \
  "ubuntu" "Ubuntu (recommended)" \
  "debian" "Debian (stable)" \
  "archlinux" "Arch Linux (advanced)" \
  "fedora" "Fedora (fresh)" \
  "opensuse" "openSUSE (Leap)" \
  3>&1 1>&2 2>&3) || { echo -e "${RED}Cancelled${RESET}"; exit 1; }

# انتخاب دسکتاپ
DESKTOP=$(whiptail --title "🎨 Choose Desktop" --menu "Select one:" 20 60 10 \
  "xfce" "XFCE (light & fast)" \
  "lxde" "LXDE (super light)" \
  "mate" "MATE (classic)" \
  "cinnamon" "Cinnamon (modern)" \
  "plasma" "KDE Plasma (minimal)" \
  3>&1 1>&2 2>&3) || { echo -e "${RED}Cancelled${RESET}"; exit 1; }

# رزولوشن
GEOM=$(whiptail --inputbox "📐 Enter VNC resolution (e.g. 1280x720)" 10 60 "1280x720" 3>&1 1>&2 2>&3) || exit 1

# پسورد VNC
PASS=$(whiptail --passwordbox "🔑 Enter VNC password" 10 60 3>&1 1>&2 2>&3) || exit 1

# نصب توزیع
echo -ne "🛠️ Installing $DISTRO"
proot-distro install "$DISTRO" >/dev/null 2>&1 || { echo -e "${RED}Install failed${RESET}"; exit 1; }
echo -e "${GREEN} Done!${RESET}"

# نصب دسکتاپ داخل توزیع
echo -ne "🎨 Installing $DESKTOP desktop"
proot-distro login "$DISTRO" -- bash -c "
apt update -y && apt upgrade -y || exit 1
apt install -y sudo dbus-x11 xterm || exit 1
case \"$DESKTOP\" in
  xfce) apt install -y xfce4 xfce4-goodies ;;
  lxde) apt install -y lxde ;;
  mate) apt install -y mate-desktop-environment ;;
  cinnamon) apt install -y cinnamon ;;
  plasma) apt install -y kde-plasma-desktop ;;
esac
apt install -y tigervnc-standalone-server || exit 1
" >/dev/null 2>&1 || { echo -e "${RED}Desktop install failed${RESET}"; exit 1; }
echo -e "${GREEN} Done!${RESET}"

# ایجاد اسکریپت‌های اجرا/توقف VNC
mkdir -p $HOME/.vnc-scripts
cat > $HOME/.vnc-scripts/start-vnc.sh <<EOF
#!/bin/bash
mkdir -p ~/.vnc
echo "$PASS" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd
vncserver -geometry "$GEOM" :1
EOF

cat > $HOME/.vnc-scripts/stop-vnc.sh <<EOF
#!/bin/bash
vncserver -kill :1
EOF

chmod +x $HOME/.vnc-scripts/*

# پیام پایانی
whiptail --title "✅ Installation Complete" --msgbox "Start VNC: bash ~/.vnc-scripts/start-vnc.sh\nStop VNC: bash ~/.vnc-scripts/stop-vnc.sh\nConnect to: 127.0.0.1:5901" 12 60
