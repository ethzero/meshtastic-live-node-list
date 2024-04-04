# Meshtastic Live Node List

- [Meshtastic Live Node List](#meshtastic-live-node-list)
  - [Purpose and Goals](#purpose-and-goals)
  - [Requirements](#requirements)
    - [Hardware](#hardware)
    - [Software](#software)
    - [Web Hosting](#web-hosting)
  - [Setup Prerequisites](#setup-prerequisites)
    - [Local Host Hardware](#local-host-hardware)
    - [Meshtastic node(s)](#meshtastic-nodes)
    - [Meshtastic CLI](#meshtastic-cli)
    - [Web Hosting](#web-hosting-1)
  - [Package Installation](#package-installation)
    - [Package contents](#package-contents)
    - [Configuration](#configuration)
      - [Serial Port Identification](#serial-port-identification)
    - [CRON job](#cron-job)
  - [Verifying Installation](#verifying-installation)


## Purpose and Goals

This package assistants in periodic exporting of a Serial-over-USB connected Meshtastic node's list of nodes to a remote webserver in HTML format.

The initial goal was to write a quick-and-dirty script to periodically export the `meshtastic --nodes` ASCII-formatted table to a simple `.txt` file on a remote Linux webserver in order for me and others to diagnose mesh connectivity without constantly having to exchange screenshots over Discord.

The current version now generates static HTML pages that automatically refreshes, highlights various pre-defined nodes by name, and if a (UK) HAM callsign is detected a link is created to a (_potential_) page on QRZ.com.

I've spent sometime sharpening-up the script to be *somewhat* portable but in the early incaration it remains a project that requires an *intermediate knowledge* of Debian/Linux, SFTP+SSH keys, and Web hosting so naturally does not come with beginner-level support and it's expected you may need to adapt to your own requirements.

Future goals possibly include using a JSON-fed HTML page, Bluetooth-over-Serial connectivity, and other remote file transfers methods.

NB: [This site is not affiliated with or endorsed by the Meshtastic project](https://meshtastic.org/docs/legal/licensing-and-trademark/#noncommercial-and-community-web-sites)

## Requirements

This package has been tested with the following:
* A [Raspberry Pi 2 Model B Rev 1.1](https://www.raspberrypi.com/products/raspberry-pi-2-model-b/) running [Raspberry Pi OS (Legacy, 32-bit) Lite](https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-legacy) (aka Debian 11/bullseye)
* 2x [Heltec V3](https://heltec.org/project/wifi-lora-32-v3/)s connected via USB
* Web Hosting with Secure File Transfer Protocol/SSH File Transfer Protocol (SFTP) access and public key authentication

> [!IMPORTANT]
> SFTP authentication with username & password credentails is not currently supported

### Hardware

A low-spec Debian/Linux PC or [SBC](https://en.wikipedia.org/wiki/Single-board_computer) like a Rasberry Pi to connect your Meshtastic nodes to. It's recommended NOT to older Pis as they may not provide enough consistent current over USB.

> [!IMPORTANT]
> The nodes must be capable of providing serial data over USB and not just be USB powered.

You can check an existing Raspberry Pi Model & OS with the follow commands:

``` Shell
$ cat /sys/firmware/devicetree/base/model
Raspberry Pi 2 Model B Rev 1.1

$ cat /etc/os-release
PRETTY_NAME="Raspbian GNU/Linux 11 (bullseye)"
NAME="Raspbian GNU/Linux"
VERSION_ID="11"
VERSION="11 (bullseye)"
VERSION_CODENAME=bullseye
ID=raspbian
ID_LIKE=debian
HOME_URL="http://www.raspbian.org/"
SUPPORT_URL="http://www.raspbian.org/RaspbianForums"
BUG_REPORT_URL="http://www.raspbian.org/RaspbianBugs"
```

### Software

* The Meshtastic Python CLI

### Web Hosting

A Web Hosting package that allows uploading via **SFTP with public key authentication**. Currently username+password authentication is NOT supported.


## Setup Prerequisites 

### Local Host Hardware

> [!IMPORTANT]
>Ensure you are running the latest OS and packages.

### Meshtastic node(s)

In order for the Meshtastic Python CLI to communicate with your node(s) you **must** enable Serial output on each nodes via the mobile client:
- Device Config > [Serial output enabled](https://meshtastic.org/docs/configuration/radio/device/#serial-console)


> [!TIP]
> See also: General [Meshtastic Client Software](https://meshtastic.org/docs/software/)  help.

### Meshtastic CLI

Install the Meshtastic Python CLI to an unprivileged username (e.g.: `pi`): [Meshtastic Python CLI for Linux](https://meshtastic.org/docs/software/python/cli/installation/?install-python-cli=linux).

Once installed, you can run `meshtastic --nodes` (or if multiple serial ports are detected, typically `meshtastic --nodes --port /dev/ttyUSB0`) to verify you're getting the ASCII-table output.

### Web Hosting

> [!NOTE]
> Currently the only supported file transfer method is SFTP (not to be confused with FTPS) and uses SSH public key exchange for authentication. Key setup is beyond the scope of this documentation but there's an abundance of resources that can assist with this.

At minimum it's recommended you test the credentials on the command line:
``` Shell
$ sftp <username>@<hostname>
Connected to <hostname>
sftp>
```

## Package Installation

Download & decompress the latest `meshtastic-live-node-list` package to your `home` directory, e.g.: `/home/pi/meshtastic-live-node-list`

> [!IMPORTANT]
> You need to use the same unprivileged username as before in the [Meshtastic CLI](#meshtastic-cli) section

``` Shell
curl -Lo $HOME/meshtastic-live-node-list.zip 'https://github.com/ethzero/meshtastic-live-node-list/archive/refs/heads/main.zip'
unzip $HOME/meshtastic-live-node-list.zip -d $HOME/
```

### Package contents

| File/Directory      | Description of Contents                                      |
|---------------------|--------------------------------------------------------------|
| `live-node-list.sh`   | Main script that will be called from the Cron job            |
| `.live-node-list.rc`  | Configuration file for the main script                       |
| `live-node-list_cron` | Cron job file                                                |
| `template_html`       | Directory containing the basic HTML contents                 |
| `upload_files`        | Created on run; The contents that uploaded to the web server |
| `docs`                | Documentation for this package                               |


### Configuration

Take a copy of the package's `.live-node-list.rc` configuration and place in your home directory
``` Shell
cp -v $HOME/meshtastic-live-node-list/.live-node-list.rc $HOME/.live-node-list.rc
```

Edit the configuration file `$HOME/.live-node-list.rc` 

> [!NOTE]
> "LOCAL" typically refers to the RaspberryPi which the node(s) are attached; 
> "REMOTE" is the web hosting provider where you wish to serve the content

You'll see most of the configuration file options are commented out as there are **examples**. It's good pratice to copy-paste those options then remove the preceeding '#', e.g.:

``` Shell
## Required to access web server and place the contents of upload_files
# REMOTE_USERNAME="example_user"
# REMOTE_HOST="example.com"
# REMOTE_PATH="/srv/httpd/htdocs/live-node-list"
REMOTE_USERNAME="real_user"
REMOTE_HOST="realhost.com"
REMOTE_PATH="/srv/httpd/htdocs/live-node-list"
``` 

The script supports multiple connected Meshtastic nodes.

If you only have a single node attached:
* NODE_NAME["MainStation"]
* LOCAL_NODE_DUMP_FILE["MainStation"]
* LOCAL_SERIAL_PORT["MainStation"]
* REMOTE_HTML_FILE["MainStation"]

If you have an additional node attached, create another set with a unique name:
* NODE_NAME["YagiNode"]
* LOCAL_NODE_DUMP_FILE["YagiNode"]
* LOCAL_SERIAL_PORT["YagiNode"]
* REMOTE_HTML_FILE["YagiNode"]

#### Serial Port Identification

Heltec V3 use the `cp210x` chipset so running the following should confirm they are connected

``` Shell
$ lsusb -t
/:  Bus 01.Port 1: Dev 1, Class=root_hub, Driver=dwc_otg/1p, 480M
    |__ Port 1: Dev 2, If 0, Class=Hub, Driver=hub/5p, 480M
        |__ Port 1: Dev 3, If 0, Class=Vendor Specific Class, Driver=smsc95xx, 480M
        |__ Port 2: Dev 4, If 0, Class=Vendor Specific Class, Driver=cp210x, 12M
        |__ Port 4: Dev 5, If 0, Class=Vendor Specific Class, Driver=cp210x, 12M
        |__ Port 5: Dev 6, If 0, Class=Vendor Specific Class, Driver=brcmfmac, 480M
```

The following confirm the which Com Ports are used. The last number in `usb 1-1.2`, "2" corresponds to the "Port" above:

``` Shell
$ dmesg | grep "ttyUSB"
[   12.338704] usb 1-1.2: cp210x converter now attached to ttyUSB0
[   12.346895] usb 1-1.4: cp210x converter now attached to ttyUSB1
```

### CRON job

Edit the `$HOME/meshtastic-live-node-list/live-node-list_cron`

Change the `<username>` to reflect the current username, as before, e.g.:

``` 
*/2 * * * * pi /home/pi/meshtastic-live-node-list/live-node-list.sh 2>&1 | logger -t live-node-list
```

> [!WARNING]
> The next step will make the script "live". It's strongly advised you first 
> open up an additional terminal window and `tail -f /var/log/syslog` to view
> the script's output


``` Shell
$ sudo cp -v $HOME/meshtastic-live-node-list/live-node-list_cron /etc/cron.d/live-node-list_cron
```

## Verifying Installation

Using `tail -f /var/log/syslog`, you should see something like the following:

``` Log
Apr  1 12:34:02 rpi live-node-list: Updating Mesh Node List...
Apr  1 12:34:02 rpi live-node-list: Copying supporting web files to /home/pi/meshtastic-live-node-list/upload_files
Apr  1 12:34:02 rpi live-node-list: Gathering "Main Station" node list...
Apr  1 12:34:07 rpi live-node-list: Creating "Main Station" HTML pages...
Apr  1 12:34:07 rpi live-node-list: Uploading nodes-MainStation.html to example.com...
Apr  1 12:34:09 rpi live-node-list: sftp> put -r /home/pi/meshtastic-live-node-list/upload_files/*
Apr  1 12:34:09 rpi live-node-list: Completed: "Main Station"
Apr  1 12:34:09 rpi live-node-list: Completed updating nodes list.
```
