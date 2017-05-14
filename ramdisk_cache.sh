#!/bin/bash

#    Debian-Systemd-Ramdisk (DSR) is a config repo used to create a ramdisk with systemd.
#    Copyright (C) 2017  Rémi Ducceschi (remileduc) <remi.ducceschi@gmail.com>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program. If not, see <http://www.gnu.org/licenses/>.

# script used to save cache from ramdisk to persistent storage / put stuff in cache ramdisk

set -efu

cache="/var/cache"
log="/var/log"
cacheUser="/home/xinouch/.cache"
persistent="/mnt/persistent/system"
persistentLog="/mnt/persistent/log"
persistentUser="/mnt/persistent/home"
lockfile=".cache.lock"
logfile="/tmp/ramdisk_cache.log"

# first we copy system cache
# if the lockfile exists in cache, we save the cache in persistent
if [ -e "$cache"/"$lockfile" ]; then
	rsync -aqu --delete --exclude "$lockfile" "$cache/" "$persistent/"
	echo "$(date -Iseconds) - system cache saved to persistent" >> "$logfile"
else # we put persistent cache in ramdisk
	rsync -aq "$persistent/" "$cache/"
	touch "$cache"/"$lockfile"
	echo "$(date -Iseconds) - system cache loaded from persistent" >> "$logfile"
fi

# second we copy system log
# if the lockfile exists in cache, we save the cache in persistent
if [ -e "$log"/"$lockfile" ]; then
	rsync -aqu --delete --exclude "$lockfile" "$log/" "$persistentLog/"
	echo "$(date -Iseconds) - logs saved to persistent" >> "$logfile"
else # we put persistent cache in ramdisk
	rsync -aq "$persistentLog/" "$log/"
	touch "$log"/"$lockfile"
	echo "$(date -Iseconds) - logs loaded from persistent" >> "$logfile"
fi

# then we copy user cache
# if the lockfile exists in cache, we save the cache in persistent
if [ -e "$cacheUser"/"$lockfile" ]; then
	rsync -aqu --delete --exclude "$lockfile" "$cacheUser/" "$persistentUser/"
	echo "$(date -Iseconds) - user cache saved to persistent" >> "$logfile"
else # we put persistent cache in ramdisk
	rsync -aq "$persistentUser/" "$cacheUser/"
	touch "$cacheUser"/"$lockfile"
	echo "$(date -Iseconds) - user cache loaded from persistent" >> "$logfile"
fi
