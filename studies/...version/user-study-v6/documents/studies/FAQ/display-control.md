# Display Control README - ASUS Headless Server

## How to Turn Display BACK ON (Emergency Recovery)

### Method 1: SSH into the system and run these commands
```bash
# Stop the screen-off service
sudo systemctl stop screenoff.service
sudo systemctl disable screenoff.service

# Turn display back on immediately
echo 1 > /proc/sys/kernel/printk
for i in {0..6}; do echo -en "\033[2J\033[H\033[?25h" > /dev/tty$i 2>/dev/null || true; done
for fb in /sys/class/graphics/fb*/blank; do echo 0 > "$fb" 2>/dev/null || true; done
for bl in /sys/class/backlight/*/brightness; do echo 255 > "$bl" 2>/dev/null || true; done

# Clear the screen and show cursor
clear
echo "Display should be back on now!"
```

### Method 2: Boot into recovery mode
1. Reboot the system: `sudo reboot`
2. When you see the systemd-boot menu, press `e` to edit the boot entry
3. Remove these parameters from the options line:
   - `quiet`
   - `loglevel=0` 
   - `vga=off`
   - `consoleblank=1`
4. Press Enter to boot with display enabled

### Method 3: Emergency boot parameters
If you can't SSH in, reboot and add this to boot parameters:
```
emergency systemd.unit=emergency.target
```

## Permanent Removal of Display-Off Setup

### 1. Remove the systemd service
```bash
sudo systemctl stop screenoff.service
sudo systemctl disable screenoff.service
sudo rm /etc/systemd/system/screenoff.service
sudo systemctl daemon-reload
```

### 2. Edit boot entries to restore display
Edit both boot configuration files:
```bash
sudo nano /boot/loader/entries/2025-08-05_18-02-03_linux-zen.conf
sudo nano /boot/loader/entries/2025-08-05_18-02-03_linux-zen-fallback.conf
```

**Change this line:**
```
options root=PARTUUID=8190f366-e66f-4aed-a8af-e14c49aa74b6 rw rootfstype=xfs quiet loglevel=0 vga=off consoleblank=1
```

**Back to:**
```
options root=PARTUUID=8190f366-e66f-4aed-a8af-e14c49aa74b6 rw rootfstype=xfs
```

### 3. Restore normal console behavior
```bash
# Restore kernel logging
echo 7 > /proc/sys/kernel/printk

# Clear and restore all TTYs
for i in {0..6}; do 
    echo -en "\033[2J\033[H\033[?25h" > /dev/tty$i 2>/dev/null || true
    echo "TTY$i restored" > /dev/tty$i 2>/dev/null || true
done

# Unblank framebuffers
for fb in /sys/class/graphics/fb*/blank; do 
    echo 0 > "$fb" 2>/dev/null || true
done

# Restore backlight
for bl in /sys/class/backlight/*/brightness; do 
    echo 255 > "$bl" 2>/dev/null || true
done
```

## How to Turn Display OFF Again (If Needed)

### Quick temporary disable (until reboot)
```bash
# Turn off display immediately
echo 0 > /proc/sys/kernel/printk
for i in {0..6}; do echo -en "\033[2J\033[H\033[?25l" > /dev/tty$i 2>/dev/null || true; done
for fb in /sys/class/graphics/fb*/blank; do echo 1 > "$fb" 2>/dev/null || true; done
for bl in /sys/class/backlight/*/brightness; do echo 0 > "$bl" 2>/dev/null || true; done
```

### Re-enable the permanent service
```bash
# Recreate the service
sudo tee /etc/systemd/system/screenoff.service << 'EOF'
[Unit]
Description=Disable display and console output
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo 0 > /proc/sys/kernel/printk'
ExecStart=/bin/bash -c 'for i in {0..6}; do echo -en "\033[2J\033[H\033[?25l" > /dev/tty$i 2>/dev/null || true; done'
ExecStart=/bin/bash -c 'for fb in /sys/class/graphics/fb*/blank; do echo 1 > "$fb" 2>/dev/null || true; done'
ExecStart=/bin/bash -c 'for bl in /sys/class/backlight/*/brightness; do echo 0 > "$bl" 2>/dev/null || true; done'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl enable screenoff.service
sudo systemctl start screenoff.service
```

### Add boot parameters back
Edit boot entries and add back to options line:
```
quiet loglevel=0 vga=off consoleblank=1
```

## Troubleshooting

**If SSH doesn't work:**
1. Connect a keyboard and try Ctrl+Alt+F1 through F6 to switch TTYs
2. Boot with `systemd.unit=rescue.target` parameter
3. Use a live USB to mount and edit the boot files

**If display is partially working:**
- Try different TTY combinations: Ctrl+Alt+F1, F2, F3, etc.
- Some displays need: `echo 100 > /sys/class/backlight/*/brightness` instead of 255

**Check what's running:**
```bash
systemctl status screenoff.service
systemctl list-units --failed
```

## File Locations Reference
- Boot entries: `/boot/loader/entries/`
- Service file: `/etc/systemd/system/screenoff.service`
- Framebuffers: `/sys/class/graphics/fb*/blank`
- Backlights: `/sys/class/backlight/*/brightness`
- Kernel log level: `/proc/sys/kernel/printk`