#!/bin/bash

# Source Vars
source $CONFIG

# Change to the Home Directory
cd ~

# Clone the Sync Repo
git clone $FOX_SYNC
cd sync

# Setup Branch names
if [ "$FOX_BRANCH" = "fox_12.0" ]; then
	printf "Warning! Using fox_12.1 instead of fox_12.0.\n"
	FOX_BRANCH="fox_12.1"
elif [ "$FOX_BRANCH" = "fox_8.0" ]; then
	printf "Warning! Using fox_8.1 instead of fox_8.0.\n"
	FOX_BRANCH="fox_8.1"
fi

# Setup the Sync Branch
if [ -z "$SYNC_BRANCH" ]; then
    export SYNC_BRANCH=$(echo ${FOX_BRANCH} | cut -d_ -f2)
fi

# Sync the Sources
./orangefox_sync.sh --branch $SYNC_BRANCH --path $SYNC_PATH || { echo "ERROR: Failed to Sync OrangeFox Sources!" && exit 1; }

# Change to the Source Directory
cd $SYNC_PATH

# Clone the theme if not already present
if [ ! -d bootable/recovery/gui/theme ]; then
git clone https://gitlab.com/OrangeFox/misc/theme.git bootable/recovery/gui/theme || { echo "ERROR: Failed to Clone the OrangeFox Theme!" && exit 1; }
fi

# Clone the Commonsys repo, only for fox_9.0
if [ "$FOX_BRANCH" = "fox_9.0" ]; then
git clone --depth=1 https://github.com/TeamWin/android_vendor_qcom_opensource_commonsys.git -b android-9.0 vendor/qcom/opensource/commonsys || { echo "WARNING: Failed to Clone the Commonsys Repo!"; }
fi

# Clone Trees
git clone $DT_LINK $DT_PATH || { echo "ERROR: Failed to Clone the Device Trees!" && exit 1; }

# Clone the Kernel Sources
# only if the Kernel Source is Specified in the Config
[ ! -z "$KERNEL_SOURCE" ] && git clone --depth=1 --single-branch $KERNEL_SOURCE $KERNEL_PATH

# Magisk
if [[ $OF_USE_LATEST_MAGISK = "true" || $OF_USE_LATEST_MAGISK = "1" ]]; then
	echo "Downloading the Latest Release of Magisk..."
	LATEST_MAGISK_URL="$(curl -sL https://api.github.com/repos/topjohnwu/Magisk/releases/latest | jq -r . | grep browser_download_url | grep Magisk- | cut -d : -f 2,3 | sed 's/"//g')"
	mkdir -p ~/Magisk
	cd ~/Magisk
	aria2c $LATEST_MAGISK_URL 2>&1 || wget $LATEST_MAGISK_URL 2>&1
	echo "Magisk Downloaded Successfully"
	echo "Renaming .apk to .zip ..."
	#rename 's/.apk/.zip/' Magisk*
	mv $("ls" Magisk*.apk) $("ls" Magisk*.apk | sed 's/.apk/.zip/g')
	cd $SYNC_PATH >/dev/null
	echo "Done!"
fi

# Neutron Clang
if [[ $OF_USE_NEUTRON_CLANG = "true" || $OF_USE_NEUTRON_CLANG = "1" ]]; then
	echo "Downloading the Latest Release of Neutron Clang..."
    cd $SYNC_PATH/prebuilts/clang/host/linux-x86
    git clone https://gitlab.com/dakkshesh07/neutron-clang.git -b Neutron-15 $CUSTOM_CLANG_FOLDER
    echo "Neutron Clang Downloaded Successfully"
	cd $SYNC_PATH >/dev/null
	echo "Done!"
fi


# Proton Clang
if [[ $OF_USE_PROTON_CLANG = "true" || $OF_USE_PROTON_CLANG = "1" ]]; then
	echo "Downloading the Latest Release of Proton Clang..."
    cd $SYNC_PATH/prebuilts/clang/host/linux-x86
    git clone https://github.com/kdrag0n/proton-clang.git --depth=1 -b master $CUSTOM_CLANG_FOLDER
    echo "Proton Clang Downloaded Successfully"
	cd $SYNC_PATH >/dev/null
	echo "Done!"
fi

# Clone extra skkk patches
if [[ $OF_CLONE_SKKK_PATCHES = "true" ]]; then
    cd $SYNC_PATH/system/core
     echo "Cloning other miscellaneous patches..."
	git fetch https://gerrit.twrp.me/android_system_core refs/changes/75/5675/6 && git cherry-pick FETCH_HEAD || { echo "WARNING: Failed to Clone a misc. patch! Trying to clone again" && git fetch https://gerrit.twrp.me/android_system_core refs/changes/75/5675/6 && git cherry-pick FETCH_HEAD; } # first_stage_init # skkk #sm8350 
    cd $SYNC_PATH/bootable/recovery
	git fetch https://gerrit.twrp.me/android_bootable_recovery refs/changes/93/5693/2 && git cherry-pick FETCH_HEAD || { echo "WARNING: Failed to Clone a misc. patch! Trying to clone again" && git fetch https://gerrit.twrp.me/android_bootable_recovery refs/changes/93/5693/2 && git cherry-pick FETCH_HEAD; } # exfat #skkk
fi

# Exit
exit 0
