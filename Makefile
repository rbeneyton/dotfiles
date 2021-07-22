all:
	true

utils:
	mkdir -p ~/utils/

rust-install:
	type rustc || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

rust-update: rust-install
	rustup update

dotter-install: utils rust-update
	$(eval SRC := ~/utils/dotter/)
	rm -rf $(SRC)
	git clone https://github.com/SuperCuber/dotter.git $(SRC)
	cargo build --manifest-path $(SRC)/Cargo.toml --release
	cp $(SRC)/target/release/dotter ~/bin
	rm -rf $(SRC)/target
	# rm -rf $(SRC)

neovim-install: utils
	# apt-get-install ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip curl
	$(eval SRC := ~/utils/neovim/)
	$(eval INSTALL := ~/utils/neovim_install/)
	rm -rf $(SRC)
	git clone --branch release-0.5 --single-branch --depth 10 https://github.com/neovim/neovim.git $(SRC)
	# git --git-dir $(SRC) checkout -b release-0.5 origin/release-0.5
	make -C $(SRC) CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$(INSTALL)"
	rm -rf $(INSTALL)
	make -C $(SRC) install
	rm -rf $(SRC)

debian-install: debian-install-base debian-install-net debian-install-graphic

debian-install-base:
	apt-get install git tig build-essential tmux dstat tree cmake pkg-config conda

debian-install-net:
	apt-get install network-manager-openconnect network-manager-gnome network-manager-openconnect-gnome

debian-install-graphic:
	apt-get install awesome awesome-extra
	# libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3
	apt-get install parcellite mesa-utils fonts-dejavu fonts-dejavu-core fonts-dejavu-extra light ibam
	apt-get install blueman pulseaudio-module-bluetooth pasystray pavucontrol
	# bluez bluez-utils ?

debian-install-misc:
	wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > /usr/share/keyrings/signal-desktop-keyring.gpg
	echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' > /etc/apt/sources.list.d/signal-xenial.list
	apt-get update
	apt-get install signal-desktop

debian-install-kernel-mac:
	# 1) i915
	# apt-get install firmware-misc-nonfree
	# 2) camera
	# https://archive.org/details/AppleUSBVideoSupport
	apt-get install isight-firmware-tools
	# 3) no slow due to security
	# https://make-linux-fast-again.com/
	# /etc/default/grub GRUB_CMDLINE_LINUX= + update-grub
	# 4) skip weird interupt (see $ grep . -r /sys/firmware/acpi/interrupts/)
	# acpi_osi=!Darwin acpi_mask_gpe=0x17
	# /etc/default/grub GRUB_CMDLINE_LINUX= + update-grub
	# 5) sound
	# echo "options snd_hda_intel model=intel-mac-auto" > /etc/modprobe.d/50-sound.conf
	# update-initramfs -u
	# 6) temperature
	# apt-get install lm-sensors
	# sensors


.PHONY: rust-install

