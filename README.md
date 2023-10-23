# pi-setup
script to configure sdcard for raspberry pi archlinux arm with customization

## usage:
* plug in an sdcard
* edit the init scripts in `customize/`
* * change the username in `customize/root/username`
* * use `wpa_passphrase` to create `customize/root/wpa_supplicant.conf`
* for first time running script use `sudo ./setup.sh --full`
* after os is installed, for repeat updating customization: `sudo ./setup.sh`

## features:
* allows changing the default user/pass from alarm:alarm to different settings
* does archlinux arm keyring initialization and installs packages on first boot
* sets up pi for autologin to default user to run `main.sh` on boot
