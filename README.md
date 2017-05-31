<!--
    Debian-Systemd-Ramdisk (DSR) is a config repo used to create a ramdisk with systemd.
    Copyright (C) 2017  Rémi Ducceschi (remileduc) <remi.ducceschi@gmail.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, see <http://www.gnu.org/licenses/>.
-->

[![License GPL v3.0](https://img.shields.io/badge/license-GNU%20GPL%20v3.0-blue.svg)](https://github.com/remileduc/debian-systemd-ramdisk/blob/master/LICENSE)

debian-systemd-ramdisk
======================

Create a ramdisk for tmp and cache folders with persistent saves amoung reboots - with systemd.

Two different behaviors are explained below: how to mount the `/tmp` folder in a ramdisk, and how to mount cache folders in a ramdisk. These are different because what is in `/tmp` is meant to be destroyed on reboot, while you want to keep the cache amoung reboot to improve the responsiveness of your system.

I also mount the `/var/log` folder into a ramdisk, which has no performance improvement, but save the SDD as we write fewer on it. If you don't need it, a section tells you how to remove it.

This is a simple setup I use for my computer, don't hesitate to contribute to make it eaily usable by anyone.

TMPFS
=====

Quick not about `tmpfs`: it is a filesystem integrated in the Linux kernel. If you mount such a filesystem in a folder, everything written in this folder will in fact be written in the RAM, thus lost after reboot.

By default, when you mount a `tmpfs` filesystem, it has a max size correspondig to half of your amount of RAM. What you need to understand is that `tmpfs` will only use the RAM it needs: if you create one file of 100 Mio in it, it will only take 100 Mio in the RAM.
However, if you try to write more than the limit, you will have a disk full error.

So, on a system with 32 Gio of RAM, it is totally possible to have multiple `tmpfs` mounted with a max size of 16 Gio. Though, you should be careful: if the RAM get full, it will start to swap (on the SSD? depending on your configuration) and your system may die (a reboot will save you).

Temporary files in ramdisk
==========================

This is the most important and usefull: the temporary files stored here are supposed to be removed on reboot.

> Well... They are supposed to be removed as soon as a software don't use it anymore, but quite often, developpers forget to remove it...

If you store it in RAM, this purge will be automatically done.

Check the current state
-----------------------

Systemd mount this folder in RAM by default. If you are lucky, you don't have anything to do. To check, run the command `df -hT`:

```bash
	$ df -hT
		Sys. de fichiers Type     Taille Utilisé Dispo Uti% Monté sur
		udev             devtmpfs    16G       0   16G   0% /dev
		tmpfs            tmpfs      3,2G    9,6M  3,2G   1% /run
		/dev/nvme0n1p6   ext4       183G    5,4G  168G   4% /
		tmpfs            tmpfs       16G       0   16G   0% /dev/shm
		tmpfs            tmpfs      5,0M    4,0K  5,0M   1% /run/lock
		tmpfs            tmpfs       16G       0   16G   0% /sys/fs/cgroup
		tmpfs            tmpfs       16G     44K   16G   1% /tmp
		tmpfs            tmpfs       16G    127M   16G   1% /var/cache
		tmpfs            tmpfs       16G     38M   16G   1% /var/log
		/dev/nvme0n1p5   ext4       233M     24M  193M  11% /boot
		/dev/nvme0n1p2   vfat        95M     25M   71M  27% /boot/efi
		/dev/nvme0n1p7   ext4       262G     47G  202G  19% /home
		tmpfs            tmpfs       16G     58M   16G   1% /home/xinouch/.mozilla
		tmpfs            tmpfs       16G    434M   16G   3% /home/xinouch/.cache
		/dev/nvme0n1p4   fuseblk    500G     93G  407G  19% /mnt/w10
		/dev/sda2        fuseblk    924G    287G  637G  32% /mnt/data
		/dev/sda3        ext4       7,9G    691M  6,8G  10% /mnt/persistent
		tmpfs            tmpfs      3,2G       0  3,2G   0% /run/user/114
		tmpfs            tmpfs      3,2G     12K  3,2G   1% /run/user/1000
```

All the lines with a `tmpfs` filesystem are mounted on the RAM. So, if you have the line

```
tmpfs            tmpfs       16G    120K   16G   1% /tmp
```

your `/tmp` folder is already mounted in the RAM \o/ you don't have to do the following steps.

Enable it
---------

On Debian in particular, this behavior has been switched off... To reenable it, it is quite easy, just run the following commands as root:

```
	# ln -s /usr/share/systemd/tmp.mount /etc/systemd/system/
	# ln -s /dev/null /etc/tmpfiles.d/tmp.conf
	# systemctl enable tmp.mount
```

The second command remove the default behavior of Debian which is remove everything in `/tmp` on boot, but you don't need it anymore thanks to the ramdisk.

Reboot and voilà!

Cache in ramdisk
================

You have 2 cache folders: the system one in `/var/cache` and the user one in `/home/$USER/.cache`. We will also take care of the logs in `/var/log` along with the firefox session folder. If you don't want it, check the last subsection of this section.

We need to distinguish 2 types of folders here: the system folders and the user folders. The user folders will be mounted later in the boot, while the system folders will be mounted as soon as possible. For me, it takes 1 minute to load user data.

Change files for your config
----------------------------

### home-xinouch-.cache.mount ###

The first file to change is `home-xinouch-.cache.mount` as your user is certainly not named *xinouch*.

In the section `Unit`, change the key `ConditionPathIsSymbolicLink=`, in the `Mount` section, change the key `Where` with your path (change the name of the user):

```
	ConditionPathIsSymbolicLink=!/home/{USER}/.cache
	...
	Where=/home/{USER}/.cache
```

You also need to change the filename so it sticks to the path. To do so, you can generate the name of the file with:

```bash
	$ systemd-escape -p --suffix=mount "/home/{USER}/.cache"
	home-{USER}-.cache.mount
```

now you can simply

```bash
	$ mv home-xinouch-.cache.mount home-{USER}-.cache.mount
```

### home-xinouch-.mozilla.mount ###

Same as in the previous section.

### userramdisk.service ###

In the section [Unit], change the key `RequiresMountsFor`:

```
	RequiresMountsFor=/home/{USER}/.cache /home/{USER}/.mozilla
```

### ramdisk_cache.sh ###

You need to change the `ramdisks` variable with your paths:

```bash
	declare -A ramdisks=(
		["cache"]="/var/cache /mnt/persistent/system"
		["log"]="/var/log /mnt/persistent/log"
		["usercache"]="/home/xinouch/.cache /mnt/persistent/home"
		["firefoxsession"]="/home/xinouch/.mozilla /mnt/persistent/firefox"
	)
```

Here, we assume that everything will be saved into a partition mounted in `/mnt/persistent`. You can save it in your home if you want, though you shouldn't store root data in your home... Anyway, be sure that the filesystem for the persistency is NOT `NTFS` but a Linux thing like `ext4`, or you will destroy the permissions... It is also recommended to mount it with the following permissions, as it should be just a backup: `defaults,nodev,noexec,nosuid,noatime,nodiratime`.

Install (and copy files)
------------------------

Now that everything is correctly configured, we need to install everything in the right folders. This can be done with the following commands run as root:

```
	# cp ramdisk_cache.sh /usr/local/sbin/
	# chmod u+x /usr/local/sbin/ramdisk_cache.sh
	# cp systemramdisk.service /etc/systemd/system/
	# cp userramdisk.service /etc/systemd/system/
	# cp var-cache.mount var-log.mount home-{USER}-.cache.mount home-{USER}-.mozilla.mount /usr/share/systemd/

	# ln -s /usr/share/systemd/var-cache.mount /etc/systemd/system/var-cache.mount
	# ln -s /usr/share/systemd/var-log.mount /etc/systemd/system/var-log.mount
	# ln -s /usr/share/systemd/home-{USER}-.cache.mount /etc/systemd/system/home-{USER}-.cache.mount
	# ln -s /usr/share/systemd/home-{USER}-.mozilla.mount /etc/systemd/system/home-{USER}-.mozilla.mount

	# systemctl daemon-reload
	# systemctl enable var-cache.mount var-log.mount home-{USER}-.cache.mount home-{USER}-.mozilla.mount systemramdisk.service userramdisk.service
```

Before rebooting, we need to save the cache (and check everything works :p), so run `ramdisk_cache.sh` as root and check that your persistent folders are filled with the correct data.

We also need to setup a `cron` so the script is run every X minutes (here every hour but you can change), so you don't lose too much if your system crashes:

```
	# crontab -e
		0 * * * * /usr/local/sbin/ramdisk_cache.sh cache log usercache firefoxsession
```

Get rid of `/var/log`
---------------------

### Remove `var-log.mount` ###

#### If you already installed everything ####

```bash
	systemctl disable var-log.mount
```

#### If you haven't installed yet ####

At the install step, don't copy, link or enable the file `var-log.mount`.

### Change the service systemramdisk ###

In the section `Unit` of `systemramdisk.service`, change the keys `Before` and `RequiresMountsFor`. If you already installed it, do the changes to the file `/etc/systemd/system/systemramdisk.service`:

```
	Before=sysinit.target shutdown.target
	...
	RequiresMountsFor=/var/cache
```

### Change the script ###

Remove everything related to logs. If you already did the install, change the file `/usr/local/sbin/ramdisk_cache.sh`.

Finish by executing `systemctl daemon-reload` as root.

Change the user ramdisks
------------------------

In the same way, edit the files corresponding to the user ramdisks if you don't want it.

License
=======

GNU GPL v3.0 or above.


