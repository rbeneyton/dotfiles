NPROC_REAL=$(shell nproc)
NPROC=$$(($(NPROC_REAL) / 1 + 1)) # small oversubscribe
GNU_MIRROR = https://ftp.igh.cnrs.fr/pub/gnu/
GNU_MIRROR = https://mirror.ibcp.fr/pub/gnu/
# use virgin PATH to avoid to be pollute by env (only local git & rust used directly)
CLEAN_PATH = /usr/local/bin:/usr/bin:/bin
CARGO = ${HOME}/.cargo/bin/cargo

BIN = ${HOME}/bin
$(BIN):
	mkdir -p $@

toto:
	echo $(NPROC)

UTILS = ${HOME}/utils
$(UTILS):
	mkdir -p $@

utils-install: gdb git tig tmux dotter neovim neovim-lsp-python neovim-lsp-rust fish

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
	$(eval SRC := $(UTILS)/$(NAME)/)
	rm -rf $(SRC)
	git clone --branch master --single-branch --depth 30 https://github.com/SuperCuber/dotter.git $(SRC)
	$(CARGO) build --manifest-path $(SRC)/Cargo.toml --release
	cp $(SRC)/target/release/$(NAME) $(BIN)/
	rm -rf $(SRC)
dotter: $(DOTTER)

# }}}
# {{{ git/tig

GIT_INSTALL = $(UTILS)/git_install
$(GIT_INSTALL) : | $(GCC_INSTALL) $(UTILS)
	$(eval NAME := git)
	$(eval SRC := $(UTILS)/$(NAME))
	$(eval TAR := $(UTILS)/$(NAME).tar.gz)
	$(eval INSTALL := $(UTILS)/$(NAME)_install)
	# no out-of-source-tree support
	rm -rf $(SRC)
	mkdir -p $(SRC)
	wget https://www.kernel.org/pub/software/scm/git/git-2.38.1.tar.gz -O $(TAR)
	tar xvf $(TAR) -C $(SRC) --strip-components 1
	rm $(TAR)
	(env -C $(SRC) -i - HOME=${HOME} PATH=$(CLEAN_PATH) LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			CPP=$(GCC_INSTALL)/bin/cpp \
			CC=$(GCC_INSTALL)/bin/gcc \
			CFLAGS='-march=native -flto -O3 -DNDEBUG' \
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
			rm -rf $(SRC);")
git : $(GIT_INSTALL)

TIG_INSTALL = $(UTILS)/tig_install
$(TIG_INSTALL) : | $(GCC_INSTALL) $(GIT_INSTALL) $(UTILS)
	$(eval NAME := tig)
	$(eval SRC := $(UTILS)/$(NAME))
	$(eval INSTALL := $(UTILS)/$(NAME)_install)
	# no out-of-source-tree support
	rm -rf $(SRC)
	git clone --branch master --single-branch --depth 30 https://github.com/jonas/tig.git $(SRC)
	(env -C $(SRC) -i - HOME=${HOME} PATH=$(CLEAN_PATH) LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			./autogen.sh; \
			CPP=$(GCC_INSTALL)/bin/cpp \
			CC=$(GCC_INSTALL)/bin/gcc \
			CFLAGS='-march=native -flto -O3 -DNDEBUG' \
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
	$(eval SRC := $(UTILS)/$(NAME)/)
	$(eval INSTALL := $(UTILS)/$(NAME)_install/)
	$(eval BUILD := $(SRC)/build/)
	rm -rf $(SRC)
	git clone --branch release-0.8 --single-branch --depth 10 https://github.com/rbeneyton/neovim.git $(SRC)
	rm -rf $(BUILD)
	mkdir -p $(BUILD)
	(env -C $(BUILD) -i - HOME=${HOME} PATH=$(CLEAN_PATH) LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			CPP=$(GCC_INSTALL)/bin/cpp \
			CC=$(GCC_INSTALL)/bin/gcc \
			CFLAGS='-march=native -flto -O3 -DNDEBUG' \
			CXX=$(GCC_INSTALL)/bin/g++ \
			CXXFLAGS='-march=native -flto -O3 -DNDEBUG' \
			LDFLAGS='-Wl,-rpath,$(GCC_INSTALL)/lib64 -L$(GCC_INSTALL)/lib64' \
			make -C $(SRC) distclean; \
			nice -n 20 \
				make -C $(SRC) \
					-j $(NPROC) \
					CMAKE_BUILD_TYPE=Release \
					CMAKE_INSTALL_PREFIX=$(INSTALL) \
				; \
			rm -rf $(INSTALL); \
			make -C $(SRC) install; \
			make -C $(SRC) distclean; \
			rm -rf $(SRC);")
neovim: $(NEOVIM_INSTALL)

NEOVIM_LSP_PYTHON = $(UTILS)/pylsp
$(NEOVIM_LSP_PYTHON) : | $(BIN) $(UTILS)
	# apt install python3-pyls
	# OR
	# apt-get install conda
	$(eval CONDA := /opt/conda/bin/conda)
	$(eval NAME := pyls)
	$(eval SRC := $(UTILS)/$(NAME)/)
	rm -rf $(SRC)
	# $(CONDA) creatm -y -p $(SRC) -c conda-forge python-language-server
	$(CONDA) create -y -p $(SRC) -c conda-forge python-lsp-server
	rm -f $(BIN)/pylsp
	ln -s $(SRC)/bin/pylsp $(BIN)/
neovim-lsp-python: $(NEOVIM_LSP_PYTHON)

NEOVIM_LSP_RUST = $(BIN)/rust-analyzer
$(NEOVIM_LSP_RUST) : | $(UTILS) rust-update
	$(eval NAME := rust-analyzer)
	$(eval SRC := $(UTILS)/$(NAME)/)
	rm -rf $(SRC)
	git clone --branch release --single-branch --depth 10 https://github.com/rust-analyzer/rust-analyzer.git $(SRC)
	$(CARGO) build --manifest-path $(SRC)/Cargo.toml --release
	cp $(SRC)/target/release/$(NAME) $(BIN)/
	rm -rf $(SRC)
neovim-lsp-rust: $(NEOVIM_LSP_RUST)

# }}}
# {{{ alacritty

ALACRITTY = $(BIN)/alacritty
$(ALACRITTY) : | $(BIN) $(UTILS) rust-update
	$(eval NAME := alacritty)
	$(eval SRC := $(UTILS)/$(NAME)/)
	rm -rf $(SRC)
	# git clone --branch master --single-branch --depth 10 https://github.com/alacritty/alacritty.git $(SRC)
	git clone --branch v0.10.1 --single-branch --depth 10 https://github.com/alacritty/alacritty.git $(SRC)
	$(CARGO) build --manifest-path $(SRC)/Cargo.toml --release
	cp $(SRC)/target/release/$(NAME) $(BIN)/
	rm -rf $(SRC)
alacritty: $(ALACRITTY)

# }}}
# {{{ tmux

LIBEVENT_INSTALL = $(UTILS)/libevent_install
$(LIBEVENT_INSTALL) : | $(UTILS)
	$(eval NAME := libevent)
	$(eval SRC := $(UTILS)/$(NAME)/)
	$(eval TAR := $(UTILS)/$(NAME).tar.gz)
	$(eval INSTALL := $(UTILS)/$(NAME)_install/)
	rm -rf $(SRC)
	mkdir -p $(SRC)
	wget https://github.com/libevent/libevent/releases/download/release-2.1.12-stable/libevent-2.1.12-stable.tar.gz -O $(TAR)
	tar xvf $(TAR) -C $(SRC) --strip-components 1
	rm $(TAR)
	(env -C $(SRC) -i - HOME=${HOME} PATH=$(CLEAN_PATH) LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			CPP=$(GCC_INSTALL)/bin/cpp \
			CC=$(GCC_INSTALL)/bin/gcc \
			CFLAGS='-march=native -flto -O3 -DNDEBUG' \
			CXXFLAGS='-march=native -flto -O3 -DNDEBUG' \
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
	$(eval SRC := $(UTILS)/$(NAME)/)
	$(eval INSTALL := $(UTILS)/$(NAME)_install/)
	$(eval LIBEVENT := $(UTILS)/libevent_install/lib/)
	rm -rf $(SRC)
	git clone --branch master --single-branch --depth 300 https://github.com/tmux/tmux.git $(SRC)
	(env -C $(SRC) -i - HOME=${HOME} PATH=$(CLEAN_PATH) LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			./autogen.sh; \
			CPP=$(GCC_INSTALL)/bin/cpp \
			CC=$(GCC_INSTALL)/bin/gcc \
			CFLAGS='-march=native -flto -O3 -DNDEBUG' \
			CXXFLAGS='-march=native -flto -O3 -DNDEBUG' \
			PKG_CONFIG_PATH=$(LIBEVENT)/pkgconfig/ \
			$(SRC)/configure \
				--prefix=$(INSTALL) \
				--disable-debug \
				; \
			make -C $(SRC) -j all; \
			rm -rf $(INSTALL); \
			make -C $(SRC) install; \
			patchelf --set-rpath $(LIBEVENT) $(INSTALL)/bin/tmux; \
			rm -rf $(SRC);")
tmux: $(TMUX_INSTALL)

# }}}
# {{{ gcc/gdb/llvm

GCC_INSTALL = $(UTILS)/gcc_install
$(GCC_INSTALL) : | $(UTILS)
$(GCC_INSTALL) :
	# apt-get-install gcc-multilib flex
	$(eval NAME := gcc)
	$(eval SRC := $(UTILS)/$(NAME))
	$(eval INSTALL := $(UTILS)/$(NAME)_install)
	$(eval BUILD := $(SRC)/build)
	rm -rf $(SRC)
	git clone --branch releases/gcc-12 --single-branch --depth 10 https://gcc.gnu.org/git/gcc.git $(SRC)
	mkdir -p $(BUILD)
	# -disable-multilib --disable-shared # gcc bug 66955
	(env -C $(BUILD) -i - HOME=${HOME} PATH=$(CLEAN_PATH) LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			(cd $(SRC) && ./contrib/download_prerequisites); \
			CC=/usr/bin/gcc \
			CXX=/usr/bin/g++ \
			$(SRC)/configure \
				--prefix=$(INSTALL) \
				--enable-languages=c,c++,lto \
				--host=x86_64-pc-linux-gnu \
				--disable-nls \
				--disable-docs \
				--disable-multilib \
				; \
			nice -n 20 \
				make -j $(NPROC) bootstrap; \
			rm -rf $(INSTALL); \
			make install-strip; \
			rm -rf $(BUILD) $(SRC);")
gcc : $(GCC_INSTALL)

GDB_INSTALL = $(UTILS)/gdb_install
$(GDB_INSTALL) : | $(GCC_INSTALL) $(UTILS)
	$(eval NAME := gdb)
	$(eval SRC := $(UTILS)/$(NAME))
	$(eval TAR := $(UTILS)/$(NAME).tar.xz)
	$(eval INSTALL := $(UTILS)/$(NAME)_install)
	$(eval BUILD := $(SRC)/build)
	rm -rf $(SRC)
	# git clone --branch gdb-10-branch --single-branch --depth 10 https://sourceware.org/git/binutils-gdb.git $(SRC)
	mkdir -p $(SRC) $(BUILD)
	wget $(GNU_MIRROR)/gdb/gdb-12.1.tar.xz -O $(TAR)
	tar xf $(TAR) -C $(SRC) --strip-components 1
	rm $(TAR)
	# recursiv make/configure isn't possible with gdb
	# autoreconf -f -i $(SRC) neither
	# XXX never ever use make -j
	(env -C $(BUILD) -i - HOME=${HOME} PATH=$(CLEAN_PATH) LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			CPP=$(GCC_INSTALL)/bin/cpp \
			CC=$(GCC_INSTALL)/bin/gcc \
			CFLAGS='-march=native -flto -O3 -DNDEBUG' \
			CXX=$(GCC_INSTALL)/bin/g++ \
			CXXFLAGS='-march=native -flto -O3 -DNDEBUG' \
			LDFLAGS='-static-libgcc -static-libstdc++' \
			$(SRC)/configure \
				--prefix=$(INSTALL) \
				--with-curses \
				--enable-tui \
				--enable-lto \
				; \
			nice -n 20 \
				make -j $(NPROC); \
			rm -rf $(INSTALL); \
			make -C gdb install; \
			make -C gdbserver install; \
			patchelf --set-rpath $(GCC_INSTALL)/lib64 $(INSTALL)/bin/gdb; \
			patchelf --set-rpath $(GCC_INSTALL)/lib64 $(INSTALL)/bin/gdbserver; \
			rm -rf $(BUILD) $(SRC);")
gdb : $(GDB_INSTALL)

LLVM_INSTALL = $(UTILS)/llvm_install
$(LLVM_INSTALL) : | $(GCC_INSTALL) $(UTILS)
	$(eval NAME := llvm)
	$(eval SRC := $(UTILS)/$(NAME)/)
	$(eval INSTALL := $(UTILS)/$(NAME)_install/)
	$(eval BUILD := $(SRC)/build/)
	rm -rf $(SRC)
	git clone --branch release/15.x --single-branch --depth 300 https://github.com/llvm/llvm-project.git $(SRC)
	mkdir -p $(BUILD)
	(env -C $(BUILD) -i - HOME=${HOME} PATH=$(CLEAN_PATH) LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			CPP=$(GCC_INSTALL)/bin/cpp \
			cmake -G 'Unix Makefiles' \
				-DCMAKE_C_COMPILER=$(GCC_INSTALL)/bin/gcc \
				-DCMAKE_C_FLAGS='-march=native' \
				-DCMAKE_CXX_COMPILER=$(GCC_INSTALL)/bin/g++ \
				-DCMAKE_CXX_FLAGS='-march=native' \
				-DCMAKE_CXX_LINK_FLAGS='-Wl,-rpath,$(GCC_INSTALL)/lib64 -L$(GCC_INSTALL)/lib64' \
				-DLLVM_ENABLE_LTO=ON \
				-DLLVM_TARGETS_TO_BUILD='WebAssembly;X86' \
				-DLLVM_ENABLE_PROJECTS='clang;clang-tools-extra;lldb;lld' \
				-DCMAKE_BUILD_TYPE=Release \
				-DCLANG_TOOLS_EXTRA_INCLUDE_DOCS=ON \
				-DCLANG_ENABLE_CLANGD=ON \
				-DCMAKE_INSTALL_PREFIX=$(INSTALL) \
				$(SRC)/llvm \
				; \
			nice -n 20 \
				make -j $(NPROC); \
			make check; \
			rm -rf $(INSTALL); \
			make install; \
			rm -rf $(BUILD) $(SRC);")
llvm : $(LLVM_INSTALL)

# }}}
# {{{ rust

rust-install:
	type rustc || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

rust-update: rust-install
	${HOME}/.cargo/bin/rustup update
	rustup component add rustfmt clippy rust-docs rust-std rust-analyzer

# }}}
# {{{ user tools

misc-user: $(BIN) rg
	# yt-dlp
	rm -f $(BIN)/yt-dlp
	curl --silent --location https://github.com/yt-dlp/yt-dlp/releases/latest/yt-dlp -o $(BIN)/yt-dlp
	chmod u+x $(BIN)/yt-dlp
	$(CARGO) install --locked starship
	$(CARGO) install --locked hyperfine
	$(CARGO) install --locked exa
	$(CARGO) install --locked bat
	# $(CARGO) install --locked just

RG = $(BIN)/rg
$(RG) : | $(BIN) $(UTILS) rust-update
	$(eval NAME := rg)
	$(eval SRC := $(UTILS)/$(NAME)/)
	rm -rf $(SRC)
	git clone --branch master --single-branch --depth 30 https://github.com/BurntSushi/ripgrep $(SRC)
	# TODO simd
	RUSTC_BOOTSTRAP=encoding_rs RUSTFLAGS="-C target-cpu=native" \
		$(CARGO) build --manifest-path $(SRC)/Cargo.toml \
		--release --features 'pcre2'
	cp $(SRC)/target/release/$(NAME) $(BIN)/
	rm -rf $(SRC)
rg: $(RG)

# }}}
# {{{ debian specific

debian-install: debian-install-base debian-install-net debian-install-graphic

debian-install-base:
	apt-get install make # chicken & egg, here to remember
	apt-get install nfs-common curl
	apt-get install git tig build-essential tmux dstat tree cmake pkg-config patchelf
	# apt-get install conda
	apt-get install libtool libtool-bin autogen autoconf autoconf-archive automake cmake g++ pkg-config unzip curl
	apt-get install firejail
	# apt-get install libcurl4-gnutls-dev
	apt-get install sqlite3
	apt-get install flex # for gcc (bug 84715 using multilib but not in src tree /o\)
	apt-get install zlib1g-dev # zlib.h
	apt-get install asciidoc gettext xmlto # git
	apt-get install docbook-utils libncurses-dev # tig
	apt-get install texinfo # gdb
	apt-get install pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3 # alacritty
	apt-get install libssl-dev # libevent
	apt-get install bison # tmux
	apt-get install bash-completion
	apt-get clean

debian-install-net:
	apt-get install iputils-ping iputils-tracepath
	apt-get install network-manager-openconnect network-manager-gnome network-manager-openconnect-gnome
	apt-get install sylpheed
	apt-get clean

debian-install-graphic:
	apt-get install awesome awesome-extra
	# libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3
	apt-get install parcellite mesa-utils fonts-dejavu fonts-dejavu-core fonts-dejavu-extra
	apt-get install redshift redshift-gtk
	apt-get install diodon xss-lock suckless-tools
	apt-get install kshutdown
	apt-get install light
	apt-get install x11-xkb-utils inputplug # xkb + detect/reload
	apt-get install blueman pulseaudio-module-bluetooth
	apt-get install pasystray pavucontrol
	# apt-get install light ibam # laptop only
	# bluez bluez-utils ?
	# 1) keychron Fn keys
	echo "options hid_apple fnmode=2" > /etc/modprobe.d/hid_apple.conf
	update-initramfs -u
	apt-get clean

debian-install-misc:
	# signal
	wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > /usr/share/keyrings/signal-desktop-keyring.gpg
	echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' > /etc/apt/sources.list.d/signal-xenial.list
	apt-get update
	apt-get install signal-desktop
	apt-get clean

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

# }}}
# {{{ fish

FISH_INSTALL = $(UTILS)/fish_install
$(FISH_INSTALL) : | $(GCC_INSTALL) $(UTILS)
	$(eval NAME := fish)
	$(eval SRC := $(UTILS)/$(NAME))
	$(eval TAR := $(UTILS)/$(NAME).tar.xz)
	$(eval INSTALL := $(UTILS)/$(NAME)_install)
	$(eval BUILD := $(SRC)/build)
	rm -rf $(SRC)
	mkdir -p $(SRC)
	mkdir -p $(BUILD)
	wget https://github.com/fish-shell/fish-shell/releases/download/3.5.1/fish-3.5.1.tar.xz -O $(TAR)
	tar xvf $(TAR) -C $(SRC) --strip-components 1
	rm $(TAR)
	(env -C $(BUILD) -i - HOME=${HOME} PATH=$(CLEAN_PATH) LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			cmake -G 'Unix Makefiles' \
				-DCMAKE_C_COMPILER=$(GCC_INSTALL)/bin/gcc \
				-DCMAKE_C_FLAGS='-march=native -O3 -flto -DNDEBUG' \
				-DCMAKE_CXX_COMPILER=$(GCC_INSTALL)/bin/g++ \
				-DCMAKE_CXX_FLAGS='-march=native -O3 -flto -DNDEBUG' \
				-DCMAKE_CXX_LINK_FLAGS='-Wl,-rpath,$(GCC_INSTALL)/lib64 -L$(GCC_INSTALL)/lib64 -static-libgcc -static-libstdc++' \
				-DCMAKE_BUILD_TYPE=Invalid \
				-DCMAKE_INSTALL_PREFIX=$(INSTALL) \
				$(SRC) \
				; \
			nice -n 20 \
				make -j $(NPROC); \
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
	(env -C $(BUILD) -i - HOME=${HOME} PATH=$(CLEAN_PATH) LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			cmake -G 'Unix Makefiles' \
				-DCMAKE_C_COMPILER=$(GCC_INSTALL)/bin/gcc \
				-DCMAKE_C_FLAGS='-march=native -O3 -flto -DNDEBUG' \
				-DCMAKE_CXX_COMPILER=$(GCC_INSTALL)/bin/g++ \
				-DCMAKE_CXX_FLAGS='-march=native -O3 -flto -DNDEBUG' \
				-DCMAKE_CXX_LINK_FLAGS='-Wl,-rpath,$(GCC_INSTALL)/lib64 -L$(GCC_INSTALL)/lib64' \
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
