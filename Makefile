NPROC_REAL=$(shell nproc)
NPROC=$$(($(NPROC_REAL) / 1 + 1)) # small oversubscribe
GNU_MIRROR = https://ftp.igh.cnrs.fr/pub/gnu/
GNU_MIRROR = https://mirror.ibcp.fr/pub/gnu/
# use virgin PATH to avoid to be pollute by env (only local git & rust used directly)
CLEAN_PATH = /usr/local/bin:/usr/bin:/bin
CLEAN_LD_LIBRARY_PATH =
# leave empty if /run/user/$(shell id -u) limit reached
BUILD_TREE = ${XDG_RUNTIME_DIR}/dotfiles
CARGO = ${HOME}/.cargo/bin/cargo
ENV = env

BIN = ${HOME}/bin
$(BIN):
	mkdir -p $@

toto:
	echo $(NPROC)

UTILS = ${HOME}/utils.$(shell hostname -s)
$(UTILS):
	mkdir -p $@
utils : $(UTILS)

utils-install: gdb git tig tmux dotter neovim neovim-lsp-python fish

# trigger dotter update
up:
	$(BIN)/dotter --local-config $(shell hostname).toml --verbose
# preview
dry:
	$(BIN)/dotter --local-config $(shell hostname).toml --verbose --dry-run
# force
upforce:
	$(BIN)/dotter --local-config $(shell hostname).toml --verbose --force

# {{{ dotter

DOTTER = $(BIN)/dotter
$(DOTTER) : | $(BIN) $(UTILS) rust-update
	$(eval NAME := dotter)
	$(eval SRC := $(if $(BUILD_TREE),$(BUILD_TREE)/$(NAME),$(UTILS)/$(NAME)/))
	rm -rf $(SRC)
	git clone --branch master --single-branch --depth 30 https://github.com/SuperCuber/dotter.git $(SRC)
	$(CARGO) build --manifest-path $(SRC)/Cargo.toml --release
	cp -f $$(cargo metadata --manifest-path $(SRC)/Cargo.toml --format-version 1 2>/dev/null | jq -r '.target_directory')/release/$(NAME) $(BIN)/
	rm -rf $(SRC)
dotter: $(DOTTER)

# }}}
# {{{ git/tig

GIT_INSTALL = $(UTILS)/git_install
$(GIT_INSTALL) : | $(GCC_INSTALL) $(UTILS)
	$(eval NAME := git)
	$(eval SRC := $(if $(BUILD_TREE),$(BUILD_TREE)/$(NAME),$(UTILS)/$(NAME)/))
	$(eval TAR := $(UTILS)/$(NAME).tar.xz)
	$(eval INSTALL := $(UTILS)/$(NAME)_install)
	# no out-of-source-tree support
	# mount -o remount,size=6G,noatime /run/user/1000
	rm -rf $(SRC)
	mkdir -p $(SRC)
	wget https://www.kernel.org/pub/software/scm/git/git-2.50.1.tar.xz -O $(TAR)
	tar --xz -xvf $(TAR) -C $(SRC) --strip-components 1
	rm $(TAR)
	($(ENV) -C $(SRC) -i - HOME=${HOME} PATH=$(CLEAN_PATH) LD_LIBRARY_PATH=$(CLEAN_LD_LIBRARY_PATH) LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			make configure; \
			CPP=$(GCC_INSTALL)/bin/cpp \
			CC=$(GCC_INSTALL)/bin/gcc \
			CFLAGS='-march=native -flto -O3' \
			$(SRC)/configure \
				--prefix=$(INSTALL) \
				--with-curl \
				--with-libpcre2 \
				--without-tcltk \
				; \
			make -j $(NPROC) all; \
			make doc; \
			rm -rf $(INSTALL); \
			make install install-doc; \
			cp $(SRC)/contrib/contacts/git-contacts $(INSTALL)/bin/; \
			cp $(SRC)/contrib/git-jump/git-jump $(INSTALL)/bin/; \
			cp $(SRC)/contrib/git-resurrect.sh $(INSTALL)/bin/; \
			cp $(SRC)/contrib/rerere-train.sh $(INSTALL)/bin/; \
			cp $(SRC)/contrib/workdir/git-new-workdir $(INSTALL)/bin/; \
			rm -rf $(SRC);")
git : $(GIT_INSTALL)

TIG_INSTALL = $(UTILS)/tig_install
$(TIG_INSTALL) : | $(GCC_INSTALL) $(GIT_INSTALL) $(UTILS)
	$(eval NAME := tig)
	$(eval SRC := $(if $(BUILD_TREE),$(BUILD_TREE)/$(NAME),$(UTILS)/$(NAME)/))
	$(eval INSTALL := $(UTILS)/$(NAME)_install)
	# no out-of-source-tree support
	rm -rf $(SRC)
	# TODO https://github.com/jonas/tig/pull/1298
	# git clone --branch ansi-support --single-branch --depth 30 https://github.com/jonas/tig.git $(SRC)
	git clone --branch master --single-branch --depth 30 https://github.com/jonas/tig.git $(SRC)
	($(ENV) -C $(SRC) -i - HOME=${HOME} PATH=$(CLEAN_PATH) LD_LIBRARY_PATH=$(CLEAN_LD_LIBRARY_PATH) LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			./autogen.sh; \
			CPP=$(GCC_INSTALL)/bin/cpp \
			CC=$(GCC_INSTALL)/bin/gcc \
			CFLAGS='-march=native -flto -O3' \
			$(SRC)/configure \
				--prefix=$(INSTALL) \
				; \
			make -j $(NPROC) all; \
			make doc; \
			rm -rf $(INSTALL); \
			make install install-doc; \
			rm -rf $(SRC);")
tig : $(TIG_INSTALL)

# }}}
# {{{ neovim

NEOVIM_INSTALL = $(UTILS)/neovim_install
$(NEOVIM_INSTALL) : | $(GCC_INSTALL) $(UTILS)
	$(eval NAME := neovim)
	$(eval SRC := $(if $(BUILD_TREE),$(BUILD_TREE)/$(NAME),$(UTILS)/$(NAME)/))
	$(eval INSTALL := $(UTILS)/$(NAME)_install/)
	$(eval BUILD := $(SRC)/build/)
	rm -rf $(SRC)
	git clone --branch release-0.11 --single-branch --depth 50 https://github.com/rbeneyton/neovim.git $(SRC)
	# cp -ar ${HOME}/work/neovim/ $(SRC)
	rm -rf $(BUILD)
	mkdir -p $(BUILD)
	($(ENV) -C $(BUILD) -i - \
		HOME=${HOME} PATH=$(CLEAN_PATH) LD_LIBRARY_PATH=$(CLEAN_LD_LIBRARY_PATH) \
		LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			CPP=$(GCC_INSTALL)/bin/cpp \
			CC=$(GCC_INSTALL)/bin/gcc \
			CFLAGS='-march=native -flto -O3' \
			CXX=$(GCC_INSTALL)/bin/g++ \
			CXXFLAGS='-march=native -flto -O3' \
			LDFLAGS='-Wl,-rpath,$(GCC_INSTALL)/lib64 -L$(GCC_INSTALL)/lib64' \
			make -C $(SRC) distclean; \
			nice -n 20 \
				make -C $(SRC) \
					-j $(NPROC) \
					CMAKE_BUILD_TYPE=Release \
					CMAKE_INSTALL_PREFIX=$(INSTALL) \
					CMAKE_TLS_VERIFY=ON \
					CMAKE_INACTIVITY_TIMEOUT=1000 \
					CMAKE_TIMEOUT=1000 \
				; \
			rm -rf $(INSTALL); \
			make -C $(SRC) install; \
			make -C $(SRC) distclean; \
			rm -rf $(SRC);")
neovim: $(NEOVIM_INSTALL)

# }}}
# {{{ alacritty

ALACRITTY = $(BIN)/alacritty
$(ALACRITTY) : | $(BIN) $(UTILS) rust-update
	$(eval NAME := alacritty)
	$(eval SRC := $(if $(BUILD_TREE),$(BUILD_TREE)/$(NAME),$(UTILS)/$(NAME)/))
	$(eval BUILD := $(SRC)/build)
	rm -rf $(SRC)
	git clone --branch v0.15 --single-branch --depth 10 https://github.com/alacritty/alacritty.git $(SRC)
	$(CARGO) build \
		--target-dir $(BUILD) \
		--manifest-path $(SRC)/Cargo.toml \
		--release
	cp -f $(BUILD)/release/$(NAME) $(BIN)/
	rm -rf $(SRC)
alacritty: $(ALACRITTY)

# }}}
# {{{ wezterm

WEZTERM = $(BIN)/wezterm
$(WEZTERM) : | $(BIN) $(UTILS) rust-update
	$(eval NAME := wezterm)
	$(eval SRC := $(if $(BUILD_TREE),$(BUILD_TREE)/$(NAME),$(UTILS)/$(NAME)/))
	$(eval BUILD := $(SRC)/build)
	rm -rf $(SRC)
	git clone --depth=1 --branch=main --recursive https://github.com/wez/wezterm.git
	$(CARGO) build \
		--target-dir $(BUILD) \
		--manifest-path $(SRC)/Cargo.toml \
		--no-default-features \
		--features vendored-fonts \
		--release
	cp -f $(BUILD)/release/$(NAME) $(BIN)/
	cp -f $(BUILD)/release/$(NAME)-gui $(BIN)/
	rm -rf $(SRC)
wezterm: $(WEZTERM)

# }}}
# {{{ tmux

LIBEVENT_INSTALL = $(UTILS)/libevent_install
$(LIBEVENT_INSTALL) : | $(UTILS)
	$(eval NAME := libevent)
	$(eval SRC := $(if $(BUILD_TREE),$(BUILD_TREE)/$(NAME),$(UTILS)/$(NAME)/))
	$(eval TAR := $(UTILS)/$(NAME).tar.gz)
	$(eval INSTALL := $(UTILS)/$(NAME)_install/)
	rm -rf $(SRC)
	mkdir -p $(SRC)
	wget https://github.com/libevent/libevent/releases/download/release-2.1.12-stable/libevent-2.1.12-stable.tar.gz -O $(TAR)
	tar xvf $(TAR) -C $(SRC) --strip-components 1
	rm $(TAR)
	($(ENV) -C $(SRC) -i - HOME=${HOME} PATH=$(CLEAN_PATH) LD_LIBRARY_PATH=$(CLEAN_LD_LIBRARY_PATH) LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			CPP=$(GCC_INSTALL)/bin/cpp \
			CC=$(GCC_INSTALL)/bin/gcc \
			CFLAGS='-march=native -flto -O3' \
			CXXFLAGS='-march=native -flto -O3' \
			$(SRC)/configure \
				--prefix=$(INSTALL) \
				--disable-debug \
				; \
			make -C $(SRC) -j all; \
			rm -rf $(INSTALL); \
			make -C $(SRC) install; \
			rm -rf $(SRC);")
libevent: $(LIBEVENT_INSTALL)

TMUX_INSTALL = $(UTILS)/tmux_install
$(TMUX_INSTALL) : | $(UTILS) $(LIBEVENT_INSTALL) $(GCC_INSTALL)
	$(eval NAME := tmux)
	$(eval SRC := $(if $(BUILD_TREE),$(BUILD_TREE)/$(NAME),$(UTILS)/$(NAME)/))
	$(eval INSTALL := $(UTILS)/$(NAME)_install/)
	rm -rf $(SRC)
	# git clone --branch master --single-branch --depth 300 https://github.com/tmux/tmux.git $(SRC)
	# git clone --branch 3.4 --single-branch --depth 300 https://github.com/tmux/tmux.git $(SRC)
	git clone --branch master --single-branch --depth 300 https://github.com/rbeneyton/tmux.git $(SRC)
	($(ENV) -C $(SRC) -i - HOME=${HOME} PATH=$(CLEAN_PATH) LD_LIBRARY_PATH=$(CLEAN_LD_LIBRARY_PATH) LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			./autogen.sh; \
			CPP=$(GCC_INSTALL)/bin/cpp \
			CC=$(GCC_INSTALL)/bin/gcc \
			CFLAGS='-march=native -flto -O3' \
			CXXFLAGS='-march=native -flto -O3' \
			PKG_CONFIG_PATH=$(LIBEVENT_INSTALL)/lib/pkgconfig/ \
			$(SRC)/configure \
				--prefix=$(INSTALL) \
				--disable-debug \
				; \
			make -C $(SRC) -j all; \
			rm -rf $(INSTALL); \
			make -C $(SRC) install; \
			patchelf --set-rpath $(LIBEVENT_INSTALL)/lib $(INSTALL)/bin/tmux; \
			rm -rf $(SRC);")
tmux: $(TMUX_INSTALL)

# }}}
# {{{ gcc/gdb/llvm

-include gcc/build.mak
GCC_INSTALL ?= $(shell dirname $$(dirname $$(which gcc | echo /)))
gcc : $(GCC_INSTALL)
	@echo GCC_INSTALL: $(GCC_INSTALL)

-include gdb/build.mak
GDB_INSTALL ?= $(shell dirname $$(dirname $$(which gdb | echo /)))
gdb : $(GDB_INSTALL)
	@echo GDB_INSTALL: $(GDB_INSTALL)

-include llvm/build.mak
LLVM_INSTALL ?= $(shell dirname $$(dirname $$(which clang | echo /)))
llvm : $(LLVM_INSTALL)
	@echo LLVM_INSTALL: $(LLVM_INSTALL)

# }}}
# {{{ rust

rust-install:
	type rustc || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

rust-update: rust-install
	${HOME}/.cargo/bin/rustup update
	rustup component add rustfmt clippy rust-docs rust-std rust-src rust-analyzer
	# rustup #2411
	rm -f ~/bin/rust-analyzer
	ln -s $(shell rustup which --toolchain stable rust-analyzer) ~/bin/rust-analyzer

# }}}
# {{{ user tools

misc-user: $(BIN) rg
	# yt-dlp
	rm -f $(BIN)/yt-dlp
	curl --silent --location https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o $(BIN)/yt-dlp
	chmod u+x $(BIN)/yt-dlp
	$(CARGO) install --force --locked flamegraph
	$(CARGO) install --force --locked cargo-criterion
	$(CARGO) install --force --locked starship
	$(CARGO) install --force --locked hyperfine
	$(CARGO) install --force --locked eza
	$(CARGO) install --force --locked bat
	$(CARGO) install --force --locked just
	$(CARGO) install --force --locked cargo-atcoder
	$(CARGO) install --force --locked --git https://github.com/astral-sh/ruff.git ruff
	$(CARGO) install --force --locked cargo-expand
	$(CARGO) install --force --locked fd-find
	$(CARGO) install cargo-cache
	# install completions
	fd --gen-completions=fish > ~/.config/fish/completions/fd.fish
	# $(CARGO) install --force --locked --features=dataframe nu
	$(CARGO) install --force --locked --git https://github.com/dandavison/delta.git
	delta --generate-completion fish > ~/.config/fish/completions/delta.fish
	$(CARGO) install --force --locked --git https://github.com/I60R/page.git
	$(CARGO) install --force --locked atuin
	atuin gen-completions --shell fish > ~/.config/fish/completions/atuin.fish


RG = $(BIN)/rg
$(RG) : | $(BIN) $(UTILS) rust-update
	$(eval NAME := rg)
	$(eval SRC := $(if $(BUILD_TREE),$(BUILD_TREE)/$(NAME),$(UTILS)/$(NAME)/))
	$(eval BUILD := $(SRC)/build)
	rm -rf $(SRC)
	# git clone --branch master --single-branch --depth 30 https://github.com/BurntSushi/ripgrep $(SRC)
	# version with 'no submodule' option
	git clone --branch ignoreNestedRepos --single-branch --depth 30 https://github.com/zaneduffield/ripgrep.git $(SRC)
	# TODO simd
	RUSTC_BOOTSTRAP=encoding_rs \
		$(CARGO) build \
			--target-dir $(BUILD) \
			--manifest-path $(SRC)/Cargo.toml \
			--release \
			--features 'pcre2'
	cp -f $(BUILD)/release/$(NAME) $(BIN)/
	rm -rf $(SRC)
rg: $(RG)

# }}}
# {{{ debian specific

debian-install: debian-install-base debian-install-net debian-install-graphic

debian-install-base:
	apt remove systemd-oomd # avoid https://github.com/systemd/systemd/issues/25376
	# /etc/systemd/system.conf: DefaultOOMPolicy=continue
	apt-get install ntp
	apt-get install make # chicken & egg, here to remember
	apt-get install time # no shell builtin
	apt-get install ncal
	apt-get install nfs-common curl
	apt-get install git git-lfs tig build-essential tmux dstat tree cmake pkg-config patchelf
	# apt-get install conda
	apt-get install libtool libtool-bin autogen autoconf autoconf-archive automake cmake g++ pkg-config unzip curl
	apt-get install firejail
	# apt-get install libcurl4-gnutls-dev
	apt-get install sqlite3
	apt-get install flex # for gcc (bug 84715 using multilib but not in src tree /o\)
	apt-get install zlib1g-dev # zlib.h
	apt-get install asciidoc gettext xmlto # git
	apt-get install -t bookworm-backports libcurl4-openssl-dev # git ssl
	apt-get install docbook-utils libncurses-dev libpcre2-posix2 # tig
	apt-get install texinfo # gdb
	apt-get install libgmp-dev # gdb
	apt-get install libmpfr-dev # gdb
	apt-get install pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3  # alacritty
	apt-get install python3-pynvim # nvim
	apt-get install python3-venv # nvim Mason
	apt-get install libssl-dev # libevent
	apt-get install bison # tmux
	apt-get install bash-completion
	apt-get install gnuplot # criterion
	apt-get install source-highlight libsource-highlight-dev # gdb
	apt-get install inxi # hardware scan
	apt-get install xserver-xorg-input-synaptics xinput # touchpad
	apt-get install protobuf-compiler # atuin
	apt-get install jq # here
	apt-get install ncdu
	apt-get install webp
	apt-get install lldb-19 python3-lldb-19
	apt-get clean

debian-install-net:
	apt-get install iputils-ping iputils-tracepath net-tools
	apt-get install network-manager-openconnect network-manager-gnome network-manager-openconnect-gnome
	apt-get install dnsmasq # +edit /etc/NetworkManager/dnsmasq.d/custom-dns & /etc/NetworkManager/NetworkManager.conf
	apt-get install tlp tlp-rdw
	apt-get install sylpheed
	apt-get clean

debian-install-graphic:
	apt-get install awesome awesome-extra
	# libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3
	apt-get install parcellite mesa-utils
	apt-get install redshift redshift-gtk
	apt-get install diodon xss-lock suckless-tools
	# apt-get install kshutdown # no 400MB for one utility
	apt-get install light
	apt-get install x11-xkb-utils inputplug # xkb + detect/reload
	apt-get install blueman pulseaudio-module-bluetooth
	apt-get install pipewire easyeffects mda-lv2
	apt-get install pasystray pavucontrol
	apt-get install arandr
	# apt-get install flameshot
	# apt-get install light ibam # laptop only
	apt-get install zathura zathura-djvu zathura-pdf-poppler zathura-ps
	# bluez bluez-utils ?
	# 1) keychron Fn keys
	echo "options hid_apple fnmode=2" > /etc/modprobe.d/hid_apple.conf
	update-initramfs -u
	# no bell-sound, ever
	echo "blacklist pcspkr" > /etc/modprobe.d/blacklist.conf
	# apt-get install intel-media-va-driver-non-free
	apt-get install i965-va-driver-shaders intel-gpu-tools
	apt install vlc mpv
	# wezterm build deps
	apt install -t bookworm-backports libx11-xcb-dev libxcb-ewmh-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-image0-dev libxcb-keysyms1-dev libxcb-randr0-dev libxcb-render0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev xorg-dev libxcb-util-dev
	apt-get clean

debian-install-misc:
	# signal
	wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > /usr/share/keyrings/signal-desktop-keyring.gpg
	echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' > /etc/apt/sources.list.d/signal-xenial.list
	apt-get update
	apt-get install signal-desktop
	apt-get clean
	# conda
	curl https://repo.anaconda.com/pkgs/misc/gpgkeys/anaconda.asc | gpg --dearmor > /usr/share/keyrings/conda-archive-keyring.gpg
	gpg --keyring /usr/share/keyrings/conda-archive-keyring.gpg --no-default-keyring --fingerprint 34161F5BF5EB1D4BFBBB8F0A8AEB4F8B29D82806
	echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/conda-archive-keyring.gpg] https://repo.anaconda.com/pkgs/misc/debrepo/conda stable main' > /etc/apt/sources.list.d/conda.list
	apt-get update
	apt-get install conda
	apt-get clean
	# misc
	# sound
	# switch to sink on bluetooth connect
	mkdir -p /etc/pipewire/pipewire-pulse.conf.d
	cp root/pipewire_switch-on-connect.conf /etc/pipewire/pipewire-pulse.conf.d/switch-on-connect.conf

debian-install-kernel-mac:
	# 1) i915
	apt-get install firmware-misc-nonfree
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
	echo "options snd_hda_intel model=intel-mac-auto" > /etc/modprobe.d/50-sound.conf
	update-initramfs -u
	# 6) temperature
	apt-get install lm-sensors
	# sensors
	apt-get clean

debian-install-kernel-p14:
	# 1) psmouse restart required
	# psmouse.synaptics_intertouch=1
	# /etc/default/grub GRUB_CMDLINE_LINUX= + update-grub

debian-up:
	apt-get update
	apt-get upgrade
	apt-get dist-upgrade
	apt-get -t bullseye-backports dist-upgrade
	apt-get clean

# }}}
# {{{ fish

FISH_INSTALL = $(UTILS)/fish_install
$(FISH_INSTALL) : | $(UTILS) rust-update
	$(eval NAME := fish)
	$(eval SRC := $(UTILS)/$(NAME))
	$(eval TAR := $(UTILS)/$(NAME).tar.xz)
	$(eval INSTALL := $(UTILS)/$(NAME)_install)
	$(eval BUILD := $(SRC)/build)
	rm -rf $(SRC)
	mkdir -p $(SRC)
	mkdir -p $(BUILD)
	wget https://github.com/fish-shell/fish-shell/releases/download/4.0.2/fish-4.0.2.tar.xz -O $(TAR)
	tar xvf $(TAR) -C $(SRC) --strip-components 1
	rm $(TAR)
	($(ENV) -C $(BUILD) -i - HOME=${HOME} PATH=$(CLEAN_PATH) LD_LIBRARY_PATH=$(CLEAN_LD_LIBRARY_PATH) LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			cmake \
				-DCMAKE_INSTALL_PREFIX=$(INSTALL) \
				$(SRC) \
				; \
			make ; \
			rm -rf $(INSTALL); \
			make install; \
			rm -rf $(BUILD) $(SRC);")
fish : $(FISH_INSTALL)

# }}}
# {{{ misc

FREERDP_INSTALL = $(UTILS)/freerdp_install
$(FREERDP_INSTALL) : | $(GCC_INSTALL) $(UTILS)
	$(eval NAME := freerdp)
	$(eval SRC := $(UTILS)/$(NAME))
	$(eval TAR := $(UTILS)/$(NAME).tar.xz)
	$(eval INSTALL := $(UTILS)/$(NAME)_install)
	$(eval BUILD := $(SRC)/build)
	rm -rf $(SRC)
	git clone --branch master --single-branch --depth 10 https://github.com/FreeRDP/FreeRDP.git $(SRC)
	mkdir -p $(BUILD)
	($(ENV) -C $(BUILD) -i - HOME=${HOME} PATH=$(CLEAN_PATH) LD_LIBRARY_PATH=$(CLEAN_LD_LIBRARY_PATH) LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			cmake -G 'Unix Makefiles' \
				-DCMAKE_C_COMPILER=$(GCC_INSTALL)/bin/gcc \
				-DCMAKE_C_FLAGS='-march=native -O3 -flto' \
				-DCMAKE_CXX_COMPILER=$(GCC_INSTALL)/bin/g++ \
				-DCMAKE_CXX_FLAGS='-march=native -O3 -flto' \
				-DCMAKE_CXX_LINK_FLAGS='-static-libgcc -static-libstdc++' \
				-DCMAKE_BUILD_TYPE=Invalid \
				-DCMAKE_INSTALL_PREFIX=$(INSTALL) \
				$(SRC) \
				; \
			nice -n 20 \
				make -j $(NPROC); \
			rm -rf $(INSTALL); \
			make install; \
			rm -rf $(BUILD) $(SRC);")
freerdp : $(FREERDP_INSTALL)

# }}}

.PHONY: utils-install up dry upforce rust-install rust-update
