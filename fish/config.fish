set --global --export SHELL fish # not done by default

set --universal fish_greeting # no fish welcome

# purge all universal abbrevations (idempotent init script)
for a in (abbr --list)
    abbr --erase $a
end
# never ever use universal path
set --erase --universal fish_user_paths

abbr --global --add bash "NOFISH=1 bash"

# XXX no way to delete *all* previously registered functions to avoid configuration hysteresis

# [[[ own installs

function pathadd
    fish_add_path --global $argv
end
function manpathadd
    if ! contains $argv $MANPATH
        set --global --export MANPATH $MANPATH $argv
    end
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
    set --global --export ASAN_SYMBOLIZER_PATH (which llvm-symbolizer)
end
set --global --export ASAN_OPTIONS abort_on_error=1:detect_leaks=1
set --global --export LSAN_OPTIONS use_stacks=0:use_registers=0:use_globals=1:use_tls=1

pathadd $HOME/utils/fish_install/bin
manpathadd $HOME/utils/fish_install/share/man

# XXX fish MANPATH bug #2090
manpathadd ":"

# rust
pathadd $HOME/.cargo/bin

# ]]]

set --global --export LANG 'en_US.utf8'
set --global --export LC_TIME 'fr_FR.UTF-8' # never 12H AM/PM date format

# gdb fix
set --global --export SOURCE_HIGHLIGHT_DATADIR $HOME/.source-highlight

ulimit -c unlimited

# [[[ aliases

# [[[ misc

    # function/alias aren't replaced when typing, abbrevations are
    alias ls "/bin/ls --color=tty"
    alias ll "ls -lrth"
    alias llo "ls -lh"
    abbr --global --add lla ls -lrth -a
    alias datefull 'date +"%Y/%m/%d %T.%N"'
    alias grep "grep --color=auto"
    abbr --global --add gr grep
    abbr --global --add psu ps -flwu $USER w f
    abbr --global --add topu top -u $USER
    abbr --global --add cutd cut -d\' \'
    alias trs 'tr -s "  " " " | sed -e "s/^\s*//"'
    alias less "less -WsJ -j3 -x2"
    alias lless "less -WsNJ -j3 -x2"
    alias l "less"
    alias bc "bc --quiet --mathlib"
    alias c "cargo"

    function mkcd
        command mkdir -p $argv
        if test $status = 0
            cd $argv
        end
    end

    function f
        command find . -name $argv
    end
    function p
        command pstree -ap | less
    end
    abbr --global --add m make
    alias gdb "gdb -q"

    abbr --global --add style /bin/astyle --indent=spaces=4 --style=linux --max-instatement-indent=40 --min-conditional-indent=2 --pad-oper --pad-header --unpad-paren --break-elseifs --align-pointer=name

    abbr --global --add automirror AUTOMIRROR_PRIMARY_DISPLAY=eDP1 AUTOMIRROR_NOTIFY_COMMAND=echo ~/.bash_automirror.sh
    abbr --global --add fixcursor 'echo -en "\e]50;CursorShape=0\x7"'
    abbr --global --add fixcursortmux 'echo -en "\e[0 q"'

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
    set --global --export SOCK "/tmp/ssh-agent-$USER-screen"
    set --global --export SSH_AUTH_SOCK $SOCK
    function tmuxssh-add -d "reset current tmux associated ssh agent (pass key-file as optional argument)"
        rm -f $SSH_AUTH_SOCK
        pkill -U $USER --signal SIGKILL ssh-agent
        ssh-agent -a $SSH_AUTH_SOCK
        ssh-add $argv
    end
    function tmuxa
        if test (count $argv) -gt 0
            tmux new-session -A -D -s $argv
        else
            tmux attach\; choose-tree
        end
    end
    alias tmuxl 'tmux ls'
    function tmuxd
        tmux select-layout even-vertical &>/dev/null
        tmux split-window
        sleep 1 # perfectible™
        tmux send-keys "$argv"
        tmux send-keys 'C-m'
    end
    function tmuxps -d "get all process sorted by their tmux sessions/windows/pane"
        tmux list-panes -a -F '#{session_name} #{window_name} #{window_index}.#{pane_index} =#{pane_pid}' |
            column -t |
            while read -d '=' pane_prefix pane_pid
                pstree -a -l --hide-threads -U -p $pane_pid |
                    sed -e "/,$pane_pid/d" \
                        -e "/pstree,/d" \
                        -e "/sed,/d" \
                        -e "/(tmux: client/d" \
                        -e "s@^@$pane_prefix@"
            end
    end
    function tmuxpsgrep -d "find the tmux sessions/windows/pane with given process name"
        tmuxps | grep -v 'grep,' | grep "$argv"
    end

# ]]]
# [[[ editor

    if test -r "$HOME/utils/neovim_install/bin/nvim"
        set --global --export EDITOR $HOME/utils/neovim_install/bin/nvim
        set --global --export MANPAGER 'nvim +Man!'
        function vim
            $EDITOR $argv
        end
        abbr --global --add vimdiff nvim -d
    else
        set --global --export EDITOR vim
        set --global --export MANPAGER="/bin/sh -c \"unset PAGER;col -b -x | vim -R -c 'set ft=man nomod nolist nonumber norelativenumber readonly' -c 'map q :q<CR>' -c 'map <SPACE> <C-D>' -\""
    end
    function v
        $EDITOR $argv
    end
    abbr --global --add va $EDITOR ~/dotfiles/start.txt
    abbr --global --add vr $EDITOR -R
    function vs -d "open closest upper obsession session"
        set --local A $PWD
        while ! string match (dirname $A) $A
            if test -r $A/Session.vim
                $EDITOR -S $A/Session.vim
                return
            end
            set A (dirname $A)
        end
        false
    end
    function vl -d "open latest saved vim session"
        command $EDITOR -S ~/.cache/session.vim
    end
    # sun mgmt
    function theme_light
        # universal makes sense here
        set --universal --export theme light
    end
    function theme_dark
        set --erase theme
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
        set BCK $(pwd)
        set A $(pwd)
        while git rev-parse --show-toplevel 1> /dev/null 2> /dev/null
            set A $(git rev-parse --show-toplevel 2> /dev/null)
            cd $(dirname $A)
        end
        cd $A
        set --erase A
        # fail is outside a git repo
        if git rev-parse --show-toplevel &> /dev/null
            true
        else
            cd $BCK
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
    set --global --export LS_COLORS 'no=00:fi=00:di=00;94:ln=00;36:pi=40;33:so=00;35:bd=40;33;01:cd=40;33;01:or=01;05;37;41:mi=01;05;37;41:ex=00;32:*.cmd=00;32:*.exe=00;32:*.com=00;32:*.btm=00;32:*.bat=00;32:*.sh=00;32:*.csh=00;32:*.tar=00;31:*.tgz=00;31:*.arj=00;31:*.taz=00;31:*.lzh=00;31:*.zip=00;31:*.z=00;31:*.Z=00;31:*.gz=00;31:*.bz2=00;31:*.bz=00;31:*.tz=00;31:*.rpm=00;31:*.cpio=00;31:*.jpg=00;35:*.gif=00;35:*.bmp=00;35:*.xbm=00;35:*.xpm=00;35:*.png=00;35:*.tif=00;35:*.c=00;96:*.h=00;95:*.py=00;92'

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
        bind \cV forward-char # C-v (move one char, can accept)
        stty werase undef #^W
        stty eof undef #^D
        bind \b backward-delete-char # C-h
        bind \n backward-word # C-j
        bind \cN backward-char # C-n
        bind \cP history-prefix-search-backward # C-p
        bind \cO history-prefix-search-forward # C-o
        bind \cD kill-word
        #personal mapping:
        # w[<-EATW]         u[OK] i[TAB] o[HIST-] p[HIST-]
        # d[EATW->] f[word->] g[eat->] h[<-eat] j[<-word]
        #                v[->]              n[<-]  m[ENTER]

        # bind \t complete-and-search # always search mode (shift+tab) on tab
        bind \cD delete-or-exit # restore usual behavior
        bind \cF accept-autosuggestion # C-f accept suggestion
        bind \cY accept-autosuggestion execute # C-y accept suggestion + execute
    end

    # ]]]
end

# ]]]

# dotter/handlebars+fold incompatibility: temporary [[[ / ]]]]
# vim: foldmarker=[[[,]]]
