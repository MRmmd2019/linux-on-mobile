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
echo "║   🚀 Linux-on-Mobile Installer v1.0        ║"
echo "║   📱 Run full Linux desktops on Android    ║"
echo "║   🛠️ Powered by Termux + VNC               ║"
echo "╚════════════════════════════════════════════╝"
echo -e "${RESET}"
}
banner
sleep 1

# بررسی محیط
echo -ne "🔍 Checking Termux environment..."
sleep 0.5
if [ ! -d "/data/data/com.termux/files/usr" ]; then
  echo -e "${RED} ❌ Not running inside Termux!${RESET}"
  exit 1
else
  echo -e "${GREEN} OK${RESET}"
fi

# نصب پیش‌نیازها
echo -ne "📦 Installing required packages"
for i in {1..3}; do echo -n "."; sleep 0.4; done
pkg update -y >/dev/null 2>&1
pkg install -y proot-distro tigervnc whiptail coreutils >/dev/null 2>&1
echo -e "${GREEN} Done!${RESET}"

# انتخاب توزیع
DISTRO=$(whiptail --title "🐧 Choose Linux Distro" --menu "Select one:" 20 60 10 \
  "ubuntu" "Ubuntu (recommended)" \
  "debian" "Debian (stable)" \
  "archlinux" "Arch Linux (advanced)" \
  "fedora" "Fedora (fresh)" \
  "opensuse" "openSUSE (Leap)" \
  3>&1 1>&2 2>&3)

# انتخاب دسکتاپ
DESKTOP=$(whiptail --title "🎨 Choose Desktop" --menu "Select one:" 20 60 10 \
  "xfce" "XFCE (light & fast)" \
  "lxde" "LXDE (super light)" \
  "mate" "MATE (classic)" \
  "cinnamon" "Cinnamon (modern)" \
  "plasma" "KDE Plasma (minimal)" \
  3>&1 1>&2 2>&3)

# رزولوشن
GEOM=$(whiptail --inputbox "📐 Enter VNC resolution (e.g. 1280x720)" 10 60 "1280x720" 3>&1 1>&2 2>&3)

# پسورد VNC
PASS=$(whiptail --passwordbox "🔑 Enter VNC password" 10 60 3>&1 1>&2 2>&3)

# نصب توزیع
echo -ne "🛠️ Installing $DISTRO"
for i in {1..5}; do echo -n "."; sleep 0.3; done
proot-distro install "$DISTRO" >/dev/null 2>&1
echo -e "${GREEN} Done!${RESET}"

# نصب دسکتاپ داخل توزیع
echo -ne "🎨 Installing $DESKTOP desktop"
for i in {1..5}; do echo -n "."; sleep 0.3; done
proot-distro login "$DISTRO" -- bash -c "
apt update -y && apt upgrade -y
case $DESKTOP in
  xfce) apt install -y xfce4 xfce4-goodies ;;
  lxde) apt install -y lxde ;;
  mate) apt install -y mate-desktop-environment ;;
  cinnamon) apt install -y cinnamon ;;
  plasma) apt install -y kde-plasma-desktop ;;
esac
apt install -y tigervnc-standalone-server
" >/dev/null 2>&1
echo -e "${GREEN} Done!${RESET}"

# ایجاد اسکریپت‌های اجرا/توقف VNC
mkdir -p $HOME/.vnc-scripts
cat > $HOME/.vnc-scripts/start-vnc.sh <<EOF
#!/bin/bash
vncserver -geometry $GEOM -passwd <<EOPASS
$PASS
$PASS
n
EOPASS
EOF

cat > $HOME/.vnc-scripts/stop-vnc.sh <<EOF
#!/bin/bash
vncserver -kill :1
EOF

chmod +x $HOME/.vnc-scripts/*

# پیام پایانی
echo -e "${CYAN}"
echo "╔════════════════════════════════════════════╗"
echo "║   ✅ Installation Complete!                ║"
echo "║                                            ║"
echo "║   ▶️ Start VNC: bash ~/.vnc-scripts/start-vnc.sh ║"
echo "║   ⛔ Stop VNC : bash ~/.vnc-scripts/stop-vnc.sh  ║"
echo "║   📡 Connect to: 127.0.0.1:5901 (Display :1)   ║"
echo "║                                            ║"
echo "║   🎉 Enjoy your Linux desktop on Android!  ║"
echo "╚════════════════════════════════════════════╝"
echo -e "${RESET}"
