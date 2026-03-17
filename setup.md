# Arch Linux on WSL2 — Setup Guide

> Fresh WSL2 + Arch install reference. Everything after this is handled by `install.sh`.

---

## 1. WSL2 Prerequisites

Open PowerShell as Admin:

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
wsl --set-default-version 2
wsl --update
```

> [!IMPORTANT]
> Restart your PC before proceeding.

---

## 2. Install Arch via ArchWSL

1. Go to [https://github.com/yuk7/ArchWSL/releases/latest](https://github.com/yuk7/ArchWSL/releases/latest)
2. Download `Arch.zip` from Assets — **not** the source code zip
3. Extract to `D:\Arch\` — keep `Arch.exe` and `rootfs.tar.gz` together
4. Double-click `Arch.exe` to install

```powershell
wsl --list --verbose    # verify Arch appears as VERSION 2
wsl -d Arch             # launch
```

> [!NOTE]
> `Arch.exe` and `rootfs.tar.gz` are reusable for reinstalls — never delete them from `D:\Arch\`.

---

## 3. Initial Arch Config

Run inside Arch (you're root by default on first launch):

```bash
pacman-key --init
pacman-key --populate archlinux
pacman -Syu
```

> [!IMPORTANT]
> Never skip keyring init — missing it causes PGP signature errors on every package install.

### Keyring errors

If you see `signature is unknown trust` or `invalid or corrupted package`:

```bash
pacman -Sy archlinux-keyring --noconfirm
pacman -Syu --noconfirm
```

Nuclear reset if still failing:

```bash
rm -rf /etc/pacman.d/gnupg
pacman-key --init
pacman-key --populate archlinux
pacman -Syu
```

### Enable systemd

```bash
echo -e "[boot]\nsystemd=true" | sudo tee /etc/wsl.conf
```

```powershell
wsl --shutdown
wsl -d Arch
```

---

## 4. User Setup

```bash
useradd -m -G wheel yourusername
passwd yourusername
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
```

Set as default user from PowerShell:

```powershell
D:\Arch\Arch.exe config --default-user yourusername
wsl -d Arch    # verify — prompt should show your username
```

---

## 5. Run install.sh

```bash
sudo pacman -S --needed git
git clone https://github.com/Chaganti-Reddy/ArchWSL-dotfiles ~/dotfiles
cd ~/dotfiles
bash install.sh
```

After the script finishes:

```bash
exec zsh              # activate zsh
nvm install --lts     # install Node LTS
```

Add `~/.ssh/id_ed25519.pub` to [GitHub SSH Keys](https://github.com/settings/keys).

---

## 6. Windows Terminal

Set Arch as default in `settings.json` (`Ctrl+,` → Open JSON):

```json
"defaultProfile": "{bf507a66-4ed0-50bd-89af-4f19a39042a1}"
```

Arch profile:

```json
{
  "name": "Arch",
  "commandline": "wsl.exe -d Arch",
  "startingDirectory": "//wsl.localhost/Arch/home/karna",
  "colorScheme": "Hyprfox",
  "cursorShape": "bar",
  "font": {
    "face": "Iosevka Nerd Font",
    "size": 12,
    "weight": "medium"
  }
}
```

---

## 7. Uninstall & Reinstall

### Backup first

```bash
cp -r ~/.config /mnt/d/ArchBackup/config
cp -r ~/.ssh    /mnt/d/ArchBackup/ssh
```

### Uninstall

```powershell
wsl --unregister Arch
```

> [!WARNING]
> Deletes everything inside Arch. No undo.

### Reinstall

Double-click `Arch.exe` on `D:\Arch\` and follow from [Section 3](#3-initial-arch-config).

---

## 8. Common Issues

| Issue | Solution |
|---|---|
| `unknown trust` / corrupted package | `pacman -Sy archlinux-keyring && pacman -Syu` |
| `pacman-key` hangs | Wait it out — can take up to 20 min, don't cancel |
| User not in sudoers | `echo "user ALL=(ALL) ALL" >> /etc/sudoers` |
| No internet | `echo "nameserver 8.8.8.8" > /etc/resolv.conf` |
| `wsl --update` fails | Download WSL kernel manually from [Microsoft](https://aka.ms/wsl2kernel) |
| Arch not starting after reinstall | `D:\Arch\Arch.exe config --default-user username` |
| Clock skew after suspend | `sudo hwclock -s` |

---

## 9. Quick Reference

```powershell
wsl -d Arch                  # launch Arch
wsl -d Arch -u root          # launch as root
wsl --shutdown               # stop all WSL instances
wsl --list --verbose         # list distros
wsl --unregister Arch        # wipe Arch completely
wsl --update                 # update WSL2 + WSLg
```

| Location | Path |
|---|---|
| Windows C drive from Arch | `/mnt/c/` |
| Windows D drive from Arch | `/mnt/d/` |
| Arch home from Windows | `\\wsl.localhost\Arch\home\karna` |
| Windows Terminal settings | `%APPDATA%\Microsoft\Windows Terminal\settings.json` |
| WSL config | `/etc/wsl.conf` |
| DNS config | `/etc/resolv.conf` |

---

> [Chaganti-Reddy](https://github.com/Chaganti-Reddy) · March 2026
