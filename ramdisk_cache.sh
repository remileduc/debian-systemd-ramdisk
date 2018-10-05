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

# we create a dictionnary whose values are strings with space separated paths.
# the first path is the mounted ramdisk, the second path is the save folder.

declare -A ramdisks=(
#	["test"]="mounted persistent" # mkdir mounted persistent; touch persistent/test
	["cache"]="/var/cache /mnt/persistent/system"
	["log"]="/var/log /mnt/persistent/log"
	["usercache"]="/home/sid/.cache /mnt/persistent/home"
	["firefoxsession"]="/home/sid/.mozilla /mnt/persistent/firefox"
)
lockfile=".cache.lock"
logfile="/tmp/ramdisk_cache.log"

function manageRamdisk { # mounted, persistent
	mounted="$1"
	persistent="$2"

	# if the lockfile exists in mounted, we save the content in persistent
	if [ -e "$mounted"/"$lockfile" ]; then
		rsync -aqu --delete --exclude "$lockfile" "$mounted/" "$persistent/"
		echo "$(date -Iseconds) - $mounted saved to persistent" >> "$logfile"
	else # we put persistent content in ramdisk
		rsync -aq "$persistent/" "$mounted/"
		touch "$mounted"/"$lockfile"
		echo "$(date -Iseconds) - $mounted loaded from persistent" >> "$logfile"
	fi
}

for ramdisk in $@; do
	mounted="$(echo ${ramdisks[$ramdisk]} | cut -sd ' ' -f 1)"
	persistent="$(echo ${ramdisks[$ramdisk]} | cut -sd ' ' -f 2)"

	# if wrong parameter, we terminate
	if [ -z "$mounted" ] || [ -z "$persistent" ]; then
		echo "'$ramdisk' is not valid." >> "$logfile"
		echo "'$ramdisk' is not valid. Use one of these:"
		for r in "${!ramdisks[@]}"; do
			echo -e "\t$r"
		done
		exit 1
	fi

	manageRamdisk "$mounted" "$persistent"
done
