NPROC=$(shell nproc)

all:
	true

BIN = ${HOME}/bin
UTILS = ${HOME}/utils
$(UTILS):
	mkdir -p $@

GNU_MIRROR = https://ftp.igh.cnrs.fr/pub/gnu/
GNU_MIRROR = https://mirror.ibcp.fr/pub/gnu/

utils-install: gdb-install tig-install dotter-install neovim-install fish-install

# trigger dotter update
up:
	dotter --local-config $(shell hostname).toml --verbose
# preview
dry:
	dotter --local-config $(shell hostname).toml --verbose --dry-run
# force
upforce:
	dotter --local-config $(shell hostname).toml --verbose --force

# {{{ dotter

dotter-install: utils rust-update
	$(eval SRC := ~/utils/dotter/)
	rm -rf $(SRC)
	git clone git://github.com/SuperCuber/dotter.git $(SRC)
	cargo build --manifest-path $(SRC)/Cargo.toml --release
	cp $(SRC)/target/release/dotter $(BIN)
	rm -rf $(SRC)/target
	rm -rf $(SRC)

# }}}
# {{{ git/tig

GIT_INSTALL = $(UTILS)/git_install
$(GIT_INSTALL) : | $(GCC_INSTALL) $(UTILS)
	# apt-get-install asciidoc
	$(eval NAME := git)
	$(eval SRC := $(UTILS)/$(NAME))
	$(eval TAR := $(UTILS)/$(NAME).tar.gz)
	$(eval INSTALL := $(UTILS)/$(NAME)_install)
	# no out-of-source-tree support
	rm -rf $(SRC)
	mkdir -p $(SRC)
	wget https://www.kernel.org/pub/software/scm/git/git-2.34.1.tar.gz -O $(TAR)
	tar xvf $(TAR) -C $(SRC) --strip-components 1
	rm $(TAR)
	(env -i - HOME=${HOME} PATH=${PATH} LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			cd $(SRC); \
			CPP=$(GCC_INSTALL)/bin/cpp \
			CC=$(GCC_INSTALL)/bin/gcc \
			CFLAGS='-march=native -flto -O3' \
			$(SRC)/configure \
				--prefix=$(INSTALL) \
				--with-curl \
				--with-libpcre2 \
				; \
			make -j $$(($(NPROC) + 1)) all; \
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
	git clone --branch master --single-branch --depth 30 git://github.com/jonas/tig.git $(SRC)
	make -C $(SRC) configure
	(env -i - HOME=${HOME} PATH=${PATH} LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			cd $(SRC); \
			CPP=$(GCC_INSTALL)/bin/cpp \
			CC=$(GCC_INSTALL)/bin/gcc \
			CFLAGS='-march=native -flto -O3' \
			$(SRC)/configure \
				--prefix=$(INSTALL) \
				; \
			make -j $$(($(NPROC) + 1)) all; \
			make doc; \
			rm -rf $(INSTALL); \
			make install install-doc; \
			rm -rf $(SRC);")
tig : $(TIG_INSTALL)

# }}}
# {{{ neovim

NEOVIM_INSTALL = $(UTILS)/neovim_install
$(NEOVIM_INSTALL) : | $(GCC_INSTALL) $(UTILS)
	# apt-get-install ninja-build gettext
	$(eval NAME := neovim)
	$(eval SRC := ${HOME}/utils/$(NAME)/)
	$(eval INSTALL := ${HOME}/utils/$(NAME)_install/)
	$(eval BUILD := $(SRC)/build/)
	# rm -rf $(SRC)
	# git clone --branch release-0.5 --single-branch --depth 10 git://github.com/neovim/neovim.git $(SRC)
	# git clone --branch release-0.5 --single-branch --depth 10 git@github.com:rbeneyton/neovim.git $(SRC)
	rm -rf $(BUILD)
	mkdir -p $(BUILD)
	(env -i - HOME=${HOME} PATH=${PATH} LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			cd $(BUILD); \
			CPP=$(GCC_INSTALL)/bin/cpp \
			CC=$(GCC_INSTALL)/bin/gcc \
			CFLAGS='-march=native -flto -O3 -DNDEBUG' \
			CXX=$(GCC_INSTALL)/bin/g++ \
			CXXFLAGS='-march=native -flto -O3 -DNDEBUG' \
			LDFLAGS='-Wl,-rpath,$(GCC_INSTALL)/lib64 -L$(GCC_INSTALL)/lib64' \
			make -C $(SRC) distclean; \
			nice -n 20 \
				make -C $(SRC) \
					-j $$(($(NPROC) + 1)) \
					CMAKE_BUILD_TYPE=Invalid \
					CMAKE_INSTALL_PREFIX=$(INSTALL) \
				; \
			rm -rf $(INSTALL); \
			make -C $(SRC) install; \
			make -C $(SRC) distclean; \
	")
neovim-install: $(NEOVIM_INSTALL)

NEOVIM_LSP_PYTHON = $(UTILS)/pyls
$(NEOVIM_LSP_PYTHON) : | $(UTILS)
	# apt-get install conda
	$(eval CONDA := /opt/conda/bin/conda)
	$(eval NAME := pyls)
	$(eval SRC := ${HOME}/utils/$(NAME)/)
	rm -rf $(SRC)
	$(CONDA) create -y -p $(SRC)
	$(CONDA) install -y -p $(SRC) -c conda-forge python-language-server
	rm -f $(BIN)/pyls
	ln -s ~/utils/pyls/bin/pyls $(BIN)
neovim-lsp-python: $(NEOVIM_LSP_PYTHON)

NEOVIM_LSP_RUST = $(BIN)/rust-analyzer
$(NEOVIM_LSP_RUST) : | $(UTILS) rust-update
	$(eval NAME := rls)
	$(eval SRC := ${HOME}/utils/$(NAME)/)
	rm -rf $(SRC)
	git clone --branch release --single-branch --depth 10 git://github.com/rust-analyzer/rust-analyzer.git $(SRC)
	cargo build --manifest-path $(SRC)/Cargo.toml --release
	cp $(SRC)/target/release/$(NAME) $(BIN)
	rm -rf $(SRC)
neovim-lsp-rust: $(NEOVIM_LSP_RUST)

# }}}
# {{{ alacritty

ALACRITTY = $(BIN)/alacritty
$(ALACRITTY) : | $(UTILS) rust-update
	$(eval NAME := alacritty)
	$(eval SRC := ${HOME}/utils/$(NAME)/)
	rm -rf $(SRC)
	git clone --branch master --single-branch --depth 10 git://github.com/alacritty/alacritty.git $(SRC)
	cargo build --manifest-path $(SRC)/Cargo.toml --release
	cp $(SRC)/target/release/$(NAME) $(BIN)
	rm -rf $(SRC)
alacritty: $(ALACRITTY)

# }}}
# {{{ tmux

libevent-install: utils
	$(eval NAME := libevent)
	$(eval SRC := ${HOME}/utils/$(NAME)/)
	$(eval TAR := ${HOME}/utils/$(NAME).tar.gz)
	$(eval INSTALL := ${HOME}/utils/$(NAME)_install/)
	rm -rf $(SRC)
	mkdir -p $(SRC)
	wget https://github.com/libevent/libevent/releases/download/release-2.1.12-stable/libevent-2.1.12-stable.tar.gz -O $(TAR)
	tar xvf $(TAR) -C $(SRC) --strip-components 1
	rm $(TAR)
	cd $(SRC) && \
		CFLAGS="-march=native -O3" \
		CXXFLAGS="-march=native -O3" \
		$(SRC)/configure --prefix=$(INSTALL) \
		--disable-debug-mode
	make -C $(SRC) -j all
	rm -rf $(INSTALL)
	make -C $(SRC) install
	rm -rf $(SRC)

tmux-install: utils libevent-install
	$(eval NAME := tmux)
	$(eval SRC := ${HOME}/utils/$(NAME)/)
	$(eval INSTALL := ${HOME}/utils/$(NAME)_install/)
	$(eval LIBEVENT := ${HOME}/utils/libevent_install/lib/)
	rm -rf $(SRC)
	git clone --branch master --single-branch --depth 300 git://github.com/tmux/tmux.git $(SRC)
	cd $(SRC) && \
		./autogen.sh && \
		CFLAGS="-march=native -O3" \
		CXXFLAGS="-march=native -O3" \
		PKG_CONFIG_PATH=$(LIBEVENT)/pkgconfig/ \
		$(SRC)/configure --prefix=$(INSTALL) \
		--disable-debug
	make -C $(SRC) -j all
	rm -rf $(INSTALL)
	make -C $(SRC) install
	patchelf --set-rpath $(LIBEVENT) $(INSTALL)/bin/tmux
	rm -rf $(SRC)

# }}}
# {{{ gcc/gdb/llvm

GMP_INSTALL = $(UTILS)/gmp_install
$(GMP_INSTALL) : | $(UTILS)
	$(eval NAME := gmp)
	$(eval SRC := $(UTILS)/$(NAME))
	$(eval TAR := $(UTILS)/$(NAME).tar.xz)
	$(eval INSTALL := $(UTILS)/$(NAME)_install)
	$(eval BUILD := $(SRC)/build)
	rm -rf $(SRC)
	mkdir -p $(SRC)
	wget $(GNU_MIRROR)/gmp/gmp-6.2.1.tar.xz -O $(TAR)
	tar xf $(TAR) -C $(SRC) --strip-components 1
	rm $(TAR)
	mkdir -p $(BUILD)
	(env -i - HOME=${HOME} PATH=${PATH} LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			cd $(BUILD); \
			CPP=/usr/bin/cpp \
			CC=/usr/bin/gcc \
			CFLAGS='-march=native -O3' \
			CXX=/usr/bin/g++ \
			CXXFLAGS='-march=native -O3' \
			$(SRC)/configure --help; \
			$(SRC)/configure \
				--prefix=$(INSTALL) \
				; \
			nice -n 20 \
				make -j $$(($(NPROC) + 1)); \
			make check; \
			rm -rf $(INSTALL); \
			make install; \
			rm -rf $(BUILD) $(SRC);")
gmp : $(GMP_INSTALL)

MPFR_INSTALL = $(UTILS)/mpfr_install
$(MPFR_INSTALL) : | $(GMP_INSTALL) $(UTILS)
	$(eval NAME := mpfr)
	$(eval SRC := $(UTILS)/$(NAME))
	$(eval TAR := $(UTILS)/$(NAME).tar.xz)
	$(eval INSTALL := $(UTILS)/$(NAME)_install)
	$(eval BUILD := $(SRC)/build)
	rm -rf $(SRC)
	mkdir -p $(SRC)
	wget $(GNU_MIRROR)/mpfr/mpfr-4.1.0.tar.xz -O $(TAR)
	tar xf $(TAR) -C $(SRC) --strip-components 1
	rm $(TAR)
	mkdir -p $(BUILD)
	(env -i - HOME=${HOME} PATH=${PATH} LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			cd $(BUILD); \
			CPP=/usr/bin/cpp \
			CC=/usr/bin/gcc \
			CFLAGS='-march=native -O3' \
			$(SRC)/configure --help; \
			$(SRC)/configure \
				--prefix=$(INSTALL) \
				--with-gmp=$(GMP_INSTALL) \
				; \
			nice -n 20 \
				make -j $$(($(NPROC) + 1)); \
			make check; \
			rm -rf $(INSTALL); \
			make install; \
			rm -rf $(BUILD) $(SRC);")
mpfr : $(MPFR_INSTALL)

MPC_INSTALL = $(UTILS)/mpc_install
$(MPC_INSTALL) : | $(GMP_INSTALL) $(MPFR_INSTALL) $(UTILS)
	$(eval NAME := mpc)
	$(eval SRC := $(UTILS)/$(NAME))
	$(eval TAR := $(UTILS)/$(NAME).tar.xz)
	$(eval INSTALL := $(UTILS)/$(NAME)_install)
	$(eval BUILD := $(SRC)/build)
	rm -rf $(SRC)
	mkdir -p $(SRC)
	wget $(GNU_MIRROR)/mpc/mpc-1.2.1.tar.gz -O $(TAR)
	tar xf $(TAR) -C $(SRC) --strip-components 1
	rm $(TAR)
	mkdir -p $(BUILD)
	(env -i - HOME=${HOME} PATH=${PATH} LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			cd $(BUILD); \
			CPP=/usr/bin/cpp \
			CC=/usr/bin/gcc \
			CFLAGS='-march=native -O3' \
			$(SRC)/configure --help; \
			$(SRC)/configure \
				--prefix=$(INSTALL) \
				--with-gmp=$(GMP_INSTALL) \
				--with-mpfr=$(MPFR_INSTALL) \
				; \
			nice -n 20 \
				make -j $$(($(NPROC) + 1)); \
			make check; \
			rm -rf $(INSTALL); \
			make install; \
			rm -rf $(BUILD) $(SRC);")
mpc : $(MPC_INSTALL)

GCC_INSTALL = $(UTILS)/gcc_install
$(GCC_INSTALL) : | $(MPC_INSTALL) $(GMP_INSTALL) $(MPFR_INSTALL) $(UTILS)
$(GCC_INSTALL) :
	# apt-get-install gcc-multilib flex
	$(eval NAME := gcc)
	$(eval SRC := $(UTILS)/$(NAME))
	$(eval INSTALL := $(UTILS)/$(NAME)_install)
	$(eval BUILD := $(SRC)/build)
	rm -rf $(SRC)
	git clone --branch releases/gcc-11 --single-branch --depth 10 git://gcc.gnu.org/git/gcc.git $(SRC)
	mkdir -p $(BUILD)
	# -disable-multilib --disable-shared # gcc bug 66955
	(env -i - HOME=${HOME} PATH=${PATH} LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			cd $(BUILD); \
			CC=/usr/bin/gcc \
			CXX=/usr/bin/g++ \
			$(SRC)/configure \
				--prefix=$(INSTALL) \
				--with-gmp=$(GMP_INSTALL) \
				--with-mpfr=$(MPFR_INSTALL) \
				--with-mpc=$(MPC_INSTALL) \
				--enable-languages=c,c++,lto \
				--host=x86_64-pc-linux-gnu \
				--disable-nls \
				--disable-docs \
				--disable-multilib \
				; \
			nice -n 20 \
				make -j $$(($(NPROC) + 1)) bootstrap; \
			rm -rf $(INSTALL); \
			make install-strip; \
			rm -rf $(BUILD) $(SRC);")
gcc : $(GCC_INSTALL)

GDB_INSTALL = $(UTILS)/gdb_install
# $(GDB_INSTALL) : | $(GCC_INSTALL) $(UTILS)
$(GDB_INSTALL) :
	$(eval NAME := gdb)
	$(eval SRC := $(UTILS)/$(NAME))
	$(eval TAR := $(UTILS)/$(NAME).tar.xz)
	$(eval INSTALL := $(UTILS)/$(NAME)_install)
	$(eval BUILD := $(SRC)/build)
	rm -rf $(SRC)
	# git clone --branch gdb-10-branch --single-branch --depth 10 git://sourceware.org/git/binutils-gdb.git $(SRC)
	mkdir -p $(SRC) $(BUILD)
	wget $(GNU_MIRROR)/gdb/gdb-10.2.tar.xz -O $(TAR)
	tar xf $(TAR) -C $(SRC) --strip-components 1
	# rm $(TAR)
	# recursiv make/configure isn't possible with gdb
	# autoreconf -f -i $(SRC) neither
	# we escape from our Makefile environment to do the build
	# "manual" fresh login (TODO: remove some entries in PATH)
	# XXX never ever use make -j
	(env -i - HOME=${HOME} PATH=${PATH} LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			cd $(BUILD); \
			CPP=/usr/bin/cpp \
			CC=/usr/bin/gcc \
			CFLAGS='-march=native -O3' \
			CXX=/usr/bin/g++ \
			CXXFLAGS='-march=native -O3' \
			$(SRC)/configure \
				--prefix=$(INSTALL) \
				--with-gmp=$(GMP_INSTALL) \
				--with-mpfr=$(MPFR_INSTALL) \
				--with-mpc=$(MPC_INSTALL) \
				--with-curses \
				--enable-tui \
				--enable-lto \
				; \
			nice -n 20 \
				make -j $$(($(NPROC) + 1)); \
			rm -rf $(INSTALL); \
			make -C gdb install; \
			make -C gdbserver install; \
			rm -rf $(BUILD) $(SRC);")
gdb : $(GDB_INSTALL)

LLVM_INSTALL = $(UTILS)/llvm_install
$(LLVM_INSTALL) : | $(GCC_INSTALL) $(UTILS)
	$(eval NAME := llvm)
	$(eval SRC := ${HOME}/utils/$(NAME)/)
	$(eval INSTALL := ${HOME}/utils/$(NAME)_install/)
	$(eval BUILD := $(SRC)/build/)
	rm -rf $(SRC)
	git clone --branch release/12.x --single-branch --depth 300 git://github.com/llvm/llvm-project.git $(SRC)
	mkdir -p $(BUILD)
	(env -i - HOME=${HOME} PATH=${PATH} LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			cd $(BUILD); \
			CPP=$(GCC_INSTALL)/bin/cpp \
			cmake -G 'Unix Makefiles' \
				-DCMAKE_C_COMPILER=$(GCC_INSTALL)/bin/gcc \
				-DCMAKE_C_FLAGS='-march=native' \
				-DCMAKE_CXX_COMPILER=$(GCC_INSTALL)/bin/g++ \
				-DCMAKE_CXX_FLAGS='-march=native' \
				-DCMAKE_CXX_LINK_FLAGS='-Wl,-rpath,$(GCC_INSTALL)/lib64 -L$(GCC_INSTALL)/lib64' \
				-DLLVM_ENABLE_LTO=ON \
				-DLLVM_TARGETS_TO_BUILD='WebAssembly;X86' \
				-DLLVM_ENABLE_PROJECTS='clang;clang-tools-extra;lldb' \
				-DCMAKE_BUILD_TYPE=Release \
				-DCLANG_TOOLS_EXTRA_INCLUDE_DOCS=ON \
				-DCLANG_ENABLE_CLANGD=ON \
				-DCMAKE_INSTALL_PREFIX=$(INSTALL) \
				$(SRC)/llvm \
				; \
			nice -n 20 \
				make -j $$(($(NPROC) + 1)); \
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
	rustup update

# }}}
# {{{ debian specific

debian-install: debian-install-base debian-install-net debian-install-graphic

debian-install-base:
	apt-get install git tig build-essential tmux dstat tree cmake pkg-config conda patchelf
	apt-get-install libtool libtool-bin autogen autoconf autoconf-archive automake cmake g++ pkg-config unzip curl
	apt-get-install firejail
	apt-get-install libcurl4-gnutls-dev
	apt-get-install sqlite3

debian-install-net:
	apt-get install network-manager-openconnect network-manager-gnome network-manager-openconnect-gnome

debian-install-graphic:
	apt-get install awesome awesome-extra
	# libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3
	apt-get install parcellite mesa-utils fonts-dejavu fonts-dejavu-core fonts-dejavu-extra
	apt-get install redshift redshift-gtk
	apt-get-install x11-xkb-utils inputplug # xkb + detect/reload
	apt-get install blueman pulseaudio-module-bluetooth
	apt-get install pasystray pavucontrol
	# apt-get install light ibam # laptop only
	# bluez bluez-utils ?
	# 1) keychron Fn keys
	echo "options hid_apple fnmode=2" > /etc/modprobe.d/hid_apple.conf
	update-initramfs -u

debian-install-misc:
	# signal
	wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > /usr/share/keyrings/signal-desktop-keyring.gpg
	echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' > /etc/apt/sources.list.d/signal-xenial.list
	apt-get update
	apt-get install signal-desktop

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

# }}}
# {{{ user tools

misc-user:
	# yt-dlp
	curl --silent --location https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o ~/bin/yt-dlp
	chmod u+x ~/bin/yt-dlp
	# starfish
	cargo install starship --locked

# }}}
# {{{ fish

FISH_INSTALL = $(UTILS)/fish_install
# $(FISH_INSTALL) : | $(GCC_INSTALL) $(UTILS)
$(FISH_INSTALL) :
	$(eval NAME := fish)
	$(eval SRC := $(UTILS)/$(NAME))
	$(eval TAR := $(UTILS)/$(NAME).tar.xz)
	$(eval INSTALL := $(UTILS)/$(NAME)_install)
	$(eval BUILD := $(SRC)/build)
	rm -rf $(SRC)
	mkdir -p $(SRC)
	mkdir -p $(BUILD)
	wget https://github.com/fish-shell/fish-shell/releases/download/3.4.1/fish-3.4.1.tar.xz -O $(TAR)
	tar xvf $(TAR) -C $(SRC) --strip-components 1
	rm $(TAR)
	(env -i - HOME=${HOME} PATH=${PATH} LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			cd $(BUILD); \
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
				make -j $$(($(NPROC) + 1)); \
			rm -rf $(INSTALL); \
			make install; \
			rm -rf $(BUILD) $(SRC);")
fish : $(FISH_INSTALL)

# }}}
# {{{ misc

FREERDP_INSTALL = $(UTILS)/freerdp_install
# $(FREERDP_INSTALL) : | $(GCC_INSTALL) $(UTILS)
$(FREERDP_INSTALL) :
	$(eval NAME := freerdp)
	$(eval SRC := $(UTILS)/$(NAME))
	$(eval TAR := $(UTILS)/$(NAME).tar.xz)
	$(eval INSTALL := $(UTILS)/$(NAME)_install)
	$(eval BUILD := $(SRC)/build)
	rm -rf $(SRC)
	git clone --branch master --single-branch --depth 10 git://github.com/FreeRDP/FreeRDP.git $(SRC)
	mkdir -p $(BUILD)
	(env -i - HOME=${HOME} PATH=${PATH} LOGNAME=${LOGNAME} MAIL=${MAIL} LANG=${LANG} \
		bash --noprofile --norc -c " \
			set -e; \
			cd $(BUILD); \
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
				make -j $$(($(NPROC) + 1)); \
			rm -rf $(INSTALL); \
			make install; \
			rm -rf $(BUILD) $(SRC);")
freerdp : $(FREERDP_INSTALL)

# }}}

.PHONY: rust-install

