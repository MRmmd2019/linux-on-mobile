<div align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&height=140&text=Linux+on+Android+Installer&fontSize=36&fontColor=black&desc=🚀+نصب+دسکتاپ+کامل+لینوکس+روی+اندروید+بدون+روت!&descSize=18&descAlignY=65&color=gradient&animation=fadeIn" />
</div>

<h1 align="center">🎯 خوش اومدی به ابزار نصب لینوکس روی اندروید | Welcome to Linux Installer for Android 🎯</h1>

<p align="center">
  👋 این ریپو طراحی شده برای اجرای دسکتاپ کامل لینوکس روی گوشی اندرویدی <br>
  📲 بدون نیاز به روت یا تنظیمات پیچیده — فقط نصب کن و اجرا کن <br>
  🛠️ مناسب برای توسعه‌دهنده‌های عاشق ترمینال و لینوکس! <br><br>

  👋 This repo lets you run full Linux desktops on Android phones<br>
  📲 No root or complex setup needed — just install and run<br>
  🛠️ Perfect for terminal-loving Linux developers
</p>

<img src="https://github.com/SamirPaulb/SamirPaulb/blob/main/assets/rainbow-superthin.webp?raw=true" width="100%" />

<h2 align="center">🧠 درباره Termux و این ابزار | About Termux & This Tool</h2>

<div align="center">

📱 ترموکس یک امولاتور ترمینال و محیط لینوکسی برای اندرویده که بدون روت اجرا می‌شه <br>
🐧 این ابزار از proot-distro برای نصب توزیع‌های لینوکس و VNC برای اجرای دسکتاپ استفاده می‌کنه <br>
🔗 اطلاعات بیشتر: [termux.com](https://termux.com) | [andronix.app](https://docs.andronix.app/android-12/andronix-on-android-12-and-beyond)

</div>

<div align="center">

```yaml
📦 توزیع‌ها: Ubuntu, Debian, Kali, Arch, Fedora, Mint  
🎨 دسکتاپ‌ها: XFCE, LXDE, LXQt, MATE, Cinnamon, KDE, GNOME  
🚫 نیاز به روت؟ خیر! | No Root Required  
🔥 مناسب برای: توسعه ابزار، تست، آموزش، SSH، هک اخلاقی  
🔥 Ideal for: dev tools, testing, learning, SSH, ethical hacking
```

</div>

<img src="https://github.com/SamirPaulb/SamirPaulb/blob/main/assets/rainbow-superthin.webp?raw=true" width="100%" />

<h2 align="center">⚙️ راه‌اندازی سریع | Quick Setup Guide</h2>

- 🚀 [دانلود Termux از F-Droid](https://f-droid.org/packages/com.termux/)
- 🔧 نصب پیش‌نیازها:
```bash
pkg update -y && pkg upgrade -y
pkg install -y git
```

- 📥 کلون ریپو:
```bash
git clone https://github.com/MRmmd2019/linux-on-mobile.git
cd linux-on-mobile
bash install.sh
```

- ▶️ اجرای دسکتاپ:
```bash
start-<distro>-<desktop>-vnc
```

- ❌ توقف دسکتاپ:
```bash
stop-<distro>-<desktop>-vnc
```

> 💡 اگر نصب با مشکل مواجه شد، دوباره اجرای `install.sh` رو امتحان کن

<img src="https://github.com/SamirPaulb/SamirPaulb/blob/main/assets/rainbow-superthin.webp?raw=true" width="100%" />

<h2 align="center">🛡 رفع مشکل Android 12 Phantom Process Killer( Process completed (signal 9) - press Enter )</h2>

📱 اندروید ۱۲ به بعد مکانیزمی داره که باعث بسته‌شدن Termux هنگام اجرای چند پردازش می‌شه

📱 Starting from Android 12, there's a mechanism that causes Termux to close when multiple processes are running.
### راه‌ حل اول با گوشی: | Solution 1 – Using the Phone:

1. فعال‌کردن Enable Developer Options | Developer Options
3. ورود به تنظیمات توسعه‌دهنده | Enter Developer Settings 
3. رفتن به Enter Developer Settings | Feature Flags 
4. غیرفعال‌کردن گزینه Disable the option `settings_enable_monitor_phantom_procs` | `settings_enable_monitor_phantom_procs`

### راه حل دوم با adb و کامپیوتر (پیشنهاد می شود): | Solution 2 – Using adb and PC (Recommended):

#### فعال‌سازی Enable USB Debugging | USB Debugging
```bash
Settings → Developer Options → USB Debugging → ON
```
#### اتصال گوشی به کامپیوتر با کابل USB و بررسی اتصال | Connect the phone to PC via USB cable and check connection
```bash
adb devices
```
> منبع: [مستندات Andronix](https://docs.andronix.app/android-12/andronix-on-android-12-and-beyond)

<img src="https://github.com/SamirPaulb/SamirPaulb/blob/main/assets/rainbow-superthin.webp?raw=true" width="100%" />

<h2 align="center">🌐 ارتباط با من | Contact Me</h2>

<p align="center">
  <a href="https://t.me/yourTelegramUsername">
    <img src="https://img.shields.io/badge/TELEGRAM-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white" />
  </a>
  <a href="mailto:iran.mohammad1389@gmail.com">
    <img src="https://img.shields.io/badge/EMAIL-D14836?style=for-the-badge&logo=gmail&logoColor=white" />
  </a>
  <a href="https://linkedin.com/in/yourLinkedIn">
    <img src="https://img.shields.io/badge/LINKEDIN-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" />
  </a>
  <a href="https://mohammad.dev">
    <img src="https://img.shields.io/badge/WEBSITE-000000?style=for-the-badge&logo=About.me&logoColor=white" />
  </a>
</p>

<img src="https://github.com/SamirPaulb/SamirPaulb/blob/main/assets/rainbow-superthin.webp?raw=true" width="100%" />

<div align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&height=120&section=footer&color=gradient" />
</div>
