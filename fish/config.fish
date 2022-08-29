set -gx SHELL fish # not done by default

set -U fish_greeting # no fish welcome

# purge all universal abbrevations (idempotent init script)
for a in (abbr --list)
    abbr --erase $a
end
# purge universal path
set -e -U fish_user_paths

# [[[ own installs

function pathadd
    fish_add_path --global $argv
end
function manpathadd
    set -gx MANPATH $MANPATH $argv
end

pathadd $HOME/bin

pathadd $HOME/utils/git_install/bin
manpathadd $HOME/utils/git_install/share/man

pathadd $HOME/utils/tig_install/bin
manpathadd $HOME/utils/tig_install/share/man

pathadd $HOME/utils/gcc_install/bin
manpathadd $HOME/utils/gcc_install/share/man

pathadd $HOME/utils/gdb_install/bin
manpathadd $HOME/utils/gdb_install/share/man

pathadd $HOME/utils/neovim_install/bin
manpathadd $HOME/utils/neovim_install/share/man

pathadd $HOME/utils/tmux_install/bin
manpathadd $HOME/utils/tmux_install/share/man

pathadd $HOME/utils/llvm_install/bin
manpathadd $HOME/utils/llvm_install/share/man
if type llvm-symbolizer &> /dev/null
    # FIXME safe which
    set -gx ASAN_SYMBOLIZER_PATH="$(which llvm-symbolizer)"
end
set -gx ASAN_OPTIONS abort_on_error=1:detect_leaks=1
set -gx LSAN_OPTIONS use_stacks=0:use_registers=0:use_globals=1:use_tls=1

pathadd $HOME/utils/fish_install/bin
manpathadd $HOME/utils/fish_install/share/man

# rust
pathadd $HOME/.cargo/bin

# ]]]

set -gx LANGUAGE en_US:en
set -gx LANG 'C.UTF-8' # never 12H AM/PM date format

ulimit -c unlimited

# [[[ aliases

# [[[ misc

    # function aren't replaced, abbrevation are
    function ls
        command /bin/ls --color=tty $argv
    end
    abbr --global --add ll ls -lrth
    abbr --global --add llo ls -lh
    abbr --global --add lla ls -lrth -a
    function grep
        command grep --color=auto $argv
    end
    abbr --global --add gr grep
    abbr --global --add psu ps -flwu $USER w f
    abbr --global --add topu top -u $USER
    abbr --global --add cutd cut -d\' \'
    function trs
        command tr -s "  " " " | sed -e "s/^\s*//" $argv
    end
    function less
        command /usr/bin/less -WsJ -j3 -x2 $argv
    end
    abbr --global --add lless less -WsNJ -j3 -x2
    abbr --global --add l less

    function mkcd
        command mkdir -p $argv
        if test $status = 0
            cd $argv
        end
    end

    abbr --global --add f find . -name
    function p
        command pstree -ap | less
    end
    abbr --global --add m make
    abbr --global --add gdb gdb -q

    abbr --global --add style /bin/astyle --indent=spaces=4 --style=linux --max-instatement-indent=40 --min-conditional-indent=2 --pad-oper --pad-header --unpad-paren --break-elseifs --align-pointer=name

    abbr --global --add automirror AUTOMIRROR_PRIMARY_DISPLAY=eDP1 AUTOMIRROR_NOTIFY_COMMAND=echo ~/.bash_automirror.sh
    abbr --global --add fixcursor echo -en "\e]50;CursorShape=0\x7"
    abbr --global --add fixcursortmux echo -en "\e[0 q"

    abbr --global --add composekeylist cat /usr/share/X11/locale/en_US.UTF-8/Compose

    # command starting with ' ' aren't recorded
    abbr --global --add h history

    abbr --global --add i ipython3
    abbr --global --add is PYTHONNOUSERSITE=on ipython3

    # conda
    abbr --global --add condainit /opt/conda/etc/profile.d/conda.sh

# ]]]
# [[[ tmux

    # Predictable SSH authentication socket location for tmux
    set -gx SOCK "/tmp/ssh-agent-$USER-screen"
    set -gx SSH_AUTH_SOCK $SOCK
    function tmuxssh-add -d "reset current tmux associated ssh agent (pass key-file as optional argument)"
        rm -f $SSH_AUTH_SOCK
        pkill -U $USER --signal SIGKILL ssh-agent
        ssh-agent -a $SSH_AUTH_SOCK
        ssh-add $argv
    end
    function tmuxa
        command tmux -2 att -d -t $argv
    end
    function tmuxl
        command tmux ls
    end
    function tmuxn
        command tmux -2 new -s $argv
    end
    function tmuxd
        tmux select-layout even-vertical 1>/dev/null 2>/dev/null
        tmux split-window
        sleep 1 # perfectible™
        tmux send-keys "$argv"
        tmux send-keys 'C-m'
    end
    function tmuxps -d "get all process sorted by their tmux sessions/windows/pane"
        tmux list-panes -a -F '#{session_name} #{window_name} #{window_index}.#{pane_index} =#{pane_pid}' | column -t | while read -d '=' pane_prefix pane_pid
            pstree -a -l --hide-threads -U -p $pane_pid | sed -e "/,$pane_pid/d" -e "/pstree,/d" -e "/sed,/d" -e "/(tmux: client/d" -e "s@^@$pane_prefix@"
        end
    end

# ]]]
# [[[ editor

    if test -r "$HOME/utils/neovim_install/bin/nvim"
        set -gx EDITOR $HOME/utils/neovim_install/bin/nvim
        set -gx MANPAGER 'nvim +Man!'
        abbr --global --add vim $EDITOR
        abbr --global --add vimdiff nvim -d
    else
        set -gx EDITOR vim
        set -gx MANPAGER="/bin/sh -c \"unset PAGER;col -b -x | vim -R -c 'set ft=man nomod nolist nonumber norelativenumber readonly' -c 'map q :q<CR>' -c 'map <SPACE> <C-D>' -\""
    end
    function v
        $EDITOR $argv
    end
    abbr --global --add va $EDITOR ~/dotfiles/start.txt
    abbr --global --add vr $EDITOR -R
    function vs -d "open closest upper obsession session"
        set A $PWD
        while $PWD != "/"
            if test -r Session.vim
                $EDITOR -S Session.vim
                cd $A
                return
            end
            cd ..
        end
        cd $A
        false
    end
    function vl -d "open latest saved vim session"
        command $EDITOR -S ~/.cache/session.vim
    end
    # sun mgmt
    function theme_light
        set -x theme="light"
    end
    function theme_dark
        set -e theme
    end
    function vimlight
        theme='light' $EDITOR $argv
    end
    function manlight
        theme='light' man $argv
    end

# ]]]
# [[[ git

    abbr --global --add g git

    # TODO safer method
    function gem -d "open git modified files"
        $EDITOR $(git status --ignore-submodules --porcelain | grep --color=no "^[ M]M" | trs | cut -d" " -f2)
    end
    function ges -d "open git staged files"
        $EDITOR $(git status --ignore-submodules --porcelain | grep --color=no "^M" | trs | cut -d" " -f2)
    end
    function ge -d "open git edited files"
        $EDITOR $(git status --ignore-submodules --porcelain | grep --color=no "^[ M][ M]" | trs | cut -d" " -f2)
    end
    function gep -d "open patched files of last git commit"
        $EDITOR $(git show --pretty="format:" --name-only)
    end

    abbr --global --add t tig --date-order -500

    function up -d "go to the upper git repo head"
        set -x B $(pwd)
        set -x A $(pwd)
        while git rev-parse --show-toplevel 1> /dev/null 2> /dev/null
            set -x A $(git rev-parse --show-toplevel 2> /dev/null)
            cd $(dirname $A)
        end
        cd $A
        set -u A
        # fail is outside a git repo
        if git rev-parse --show-toplevel 2> /dev/null
            true
        else
            cd $B
            false
        end
    end

    abbr --global --add gl git logp -10
    abbr --global --add gll git logp -25
    abbr --global --add glll git logp -50
    abbr --global --add gllll git logp -87

    abbr --global --add gs git status
    abbr --global --add gv git v
    abbr --global --add ga git add
    abbr --global --add gap git add -p
    abbr --global --add gc git commit
    abbr --global --add ggr git grep -n
    abbr --global --add tempo git commit -a -m tempo
    function gbr -d "get flat list of branches, for using in scripts"
        command git branch $argv | sed "s/\*//" | sed "s/^\s*//"
    end

# ]]]

# ]]]
# [[[ interactiv only settings

if status --is-interactive
    set -gx LS_COLORS 'no=00:fi=00:di=00;94:ln=00;36:pi=40;33:so=00;35:bd=40;33;01:cd=40;33;01:or=01;05;37;41:mi=01;05;37;41:ex=00;32:*.cmd=00;32:*.exe=00;32:*.com=00;32:*.btm=00;32:*.bat=00;32:*.sh=00;32:*.csh=00;32:*.tar=00;31:*.tgz=00;31:*.arj=00;31:*.taz=00;31:*.lzh=00;31:*.zip=00;31:*.z=00;31:*.Z=00;31:*.gz=00;31:*.bz2=00;31:*.bz=00;31:*.tz=00;31:*.rpm=00;31:*.cpio=00;31:*.jpg=00;35:*.gif=00;35:*.bmp=00;35:*.xbm=00;35:*.xpm=00;35:*.png=00;35:*.tif=00;35:*.c=00;96:*.h=00;95:*.py=00;92'

    # [[[ prompt

    if type starship &> /dev/null
        starship init fish | source
    else
        # TODO? a minimal fish prompt?
    end

    # ]]]
    # [[[ own keymap

    if type bind &> /dev/null and type stty &> /dev/null
        # use fish_key_reader to get key
        bind \cF forward-word # C-f
        bind \a delete-char # C-g
        #see stty -a
        stty lnext undef #^V
        bind \cV forward-char
        stty werase undef #^W
        stty eof undef #^D
        bind \b backward-delete-char # C-h
        bind \n backward-word # C-j
        bind \cN backward-char # C-n
        bind \cP history-prefix-search-backward # C-p
        bind \cO history-prefix-search-forward # C-o
        bind \cD kill-word
        #personal mapping:
        # w[<-EATW]                      o[HIST-] p[HIST-]
        # d[EATW->] f[word->] g[eat->] h[<-eat] j[<-word]
        #                v[->]              n[<-]  m[ENTER]

        bind \t complete-and-search # always search mode (shift+tab) on tab
        bind \cD delete-or-exit # restore usual behavior
    end

    # ]]]
end

# ]]]

# dotter/handlebars+fold incompatibility: temporary [[[ / ]]]]
# vim: foldmarker=[[[,]]]
