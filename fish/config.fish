set --global --export SHELL fish # not done by default

set --universal fish_greeting # no fish welcome

# purge all universal abbrevations (idempotent init script)
abbr --erase (abbr --list)

# never ever use universal path
set --erase --universal fish_user_paths

abbr --global --add bash "NOFISH=1 bash"

# XXX no way to delete *all* previously registered functions to avoid configuration hysteresis

# [[[ own installs

function path_add --argument toadd
    # fish_add_path --path $argv
    path_remove $toadd
    set toadd (path resolve $toadd)
    set --global --export PATH $toadd $PATH
end
function path_remove --argument todel
    set todel (path resolve $todel)
    if contains $todel $PATH
        set --local idx (contains -i $todel $PATH)
        set --global --erase PATH[$idx]
    end
    true
end

function manpath_add --argument toadd
    set toadd (path resolve $toadd)
    if set --query MANPATH
        if ! contains $toadd $MANPATH
            set --global --export MANPATH $MANPATH $toadd
        end
    else
        set --global --export MANPATH $toadd
    end
    true
end

function pythonpath_add --argument toadd
    pythonpath_remove $toadd
    set toadd (path resolve $toadd)
    if set --query PYTHONPATH
        if ! contains $toadd $PYTHONPATH
            set --global --export PYTHONPATH $toadd $PYTHONPATH
        end
    else
        set --global --export PYTHONPATH $toadd
    end
    true
end
function pythonpath_remove --argument todel
    set todel (path resolve $todel)
    if set --query PYTHONPATH
        if contains $todel $PYTHONPATH
            set --local idx (contains -i $todel $PYTHONPATH)
            set --global --erase PYTHONPATH[$idx]
        end
    end
    true
end

path_add $HOME/bin

path_add $HOME/firefox

set --global --export UTILS $HOME/utils.(hostname -s)

path_add $UTILS/git_install/bin
manpath_add $UTILS/git_install/share/man

path_add $UTILS/tig_install/bin
manpath_add $UTILS/tig_install/share/man

path_add $UTILS/gcc_install/bin
manpath_add $UTILS/gcc_install/share/man

path_add $UTILS/gdb_install/bin
manpath_add $UTILS/gdb_install/share/man

path_add $UTILS/neovim_install/bin
manpath_add $UTILS/neovim_install/share/man

path_add $UTILS/tmux_install/bin
manpath_add $UTILS/tmux_install/share/man

path_add $UTILS/llvm_install/bin
manpath_add $UTILS/llvm_install/share/man
if type llvm-symbolizer &>/dev/null
    # FIXME safe which
    set --global --export ASAN_SYMBOLIZER_PATH (which llvm-symbolizer)
end
set --global --export ASAN_OPTIONS abort_on_error=1:detect_leaks=1
set --global --export LSAN_OPTIONS use_stacks=0:use_registers=0:use_globals=1:use_tls=1

path_add $UTILS/fish_install/bin
manpath_add $UTILS/fish_install/share/man

# XXX fish MANPATH bug #2090
manpath_add ":"

# rust
path_add $HOME/.cargo/bin

# ]]]
# [[[ main settings

set --global --export LANG 'en_US.utf8'
set --global --export LC_TIME 'C.UTF-8' # never 12H AM/PM date format

# gdb fix
set --global --export SOURCE_HIGHLIGHT_DATADIR $HOME/.source-highlight

set --global --export RUSTFLAGS "-C target-cpu=native"

ulimit -c unlimited

# ]]]
# [[[ misc

# function/alias aren't replaced when typing, abbrevations are
if type eza &>/dev/null
    # usefull options at end for easy modification
    alias e "eza --icons --long --time-style=iso --classify --git --all --sort newest"
    alias es "eza --icons --long --time-style=iso --classify --git --sort size"
    alias ee "eza --icons --long --time-style=iso --classify --git --sort ext"
    alias en "eza --icons --long --time-style=iso --classify --git --sort name"
    alias et "eza --tree --time-style=iso --classify --git --long"
    abbr --global --add et2 "eza --tree --time-style=iso --classify --git --long --level=2"
    abbr --global --add et3 "eza --tree --time-style=iso --classify --git --long --level=3"
    abbr --global --add et4 "eza --tree --time-style=iso --classify --git --long --level=4"
    alias ls "eza --classify --git --sort name"
    alias ll "eza --icons --long --time-style=iso --classify --git --sort newest"
    alias lla "eza --icons --long --time-style=iso --classify --git --sort newest --all"
    set --global --erase LS_COLORS
    # xit in green on black, underline
    set --global --export EZA_COLORS "*xit=1;32;04"
else
    set --global --export LS_COLORS 'no=00:fi=00:di=00;94:ln=00;36:pi=40;33:so=00;35:bd=40;33;01:cd=40;33;01:or=01;05;37;41:mi=01;05;37;41:ex=00;32:*.cmd=00;32:*.exe=00;32:*.com=00;32:*.btm=00;32:*.bat=00;32:*.sh=00;32:*.csh=00;32:*.tar=00;31:*.tgz=00;31:*.arj=00;31:*.taz=00;31:*.lzh=00;31:*.zip=00;31:*.z=00;31:*.Z=00;31:*.gz=00;31:*.bz2=00;31:*.bz=00;31:*.tz=00;31:*.rpm=00;31:*.cpio=00;31:*.jpg=00;35:*.gif=00;35:*.bmp=00;35:*.xbm=00;35:*.xpm=00;35:*.png=00;35:*.tif=00;35:*.c=00;96:*.h=00;95:*.py=00;92'

    alias ls "/bin/ls --color=tty"
    alias ll "ls -lrth"
    alias lla "ls -lrth -a"
end
alias datefull 'date +"%Y/%m/%d %T.%N"'
alias cal 'ncal -M -b -3'
alias caly 'ncal -M -b -y'
if test -f $HOME/bin/rg
    function rg
        command $HOME/bin/rg --engine auto --search-zip $argv
    end
    alias rgv "rg --vimgrep"
    alias grg "rg --ignore-nested-git"
    alias grgv "rg --ignore-nested-git --vimgrep"
else
    alias grep "command grep --color=auto"
end
alias psu "ps -flwu $USER w f"
alias topu "top -u $USER"
alias cutd "cut -d\' \'"
alias trs 'tr -s "  " " " | sed -e "s/^\s*//"'
if type bat &>/dev/null
    alias cat bat
end
alias less "less -WsJ -j3 -x2"
alias lless "less -WsNJ -j3 -x2"
alias l less
alias bc "bc --quiet --mathlib"
alias c cargo
function rust-gdb
    #RUST_GDB=/usr/bin/gdb command rust-gdb --quiet --ex start --ex 'break rust_panic' $argv
    command rust-gdb --quiet --ex start --ex 'break rust_panic' $argv
end
# Mason-installed version
alias ruff-nvim $HOME/.local/share/nvim/mason/packages/ruff/venv/bin/ruff
alias clang-format-nvim $HOME/.local/share/nvim/mason/packages/clang-format/venv/bin/clang-format

function mkcd
    command mkdir -p $argv
    if test $status = 0
        cd $argv
    end
end

abbr f fd
function p
    command pstree -ap | less
end
alias m make
alias mm "make -j"

abbr --global --add style /bin/astyle --indent=spaces=4 --style=linux --max-instatement-indent=40 --min-conditional-indent=2 --pad-oper --pad-header --unpad-paren --break-elseifs --align-pointer=name

abbr --global --add automirror AUTOMIRROR_PRIMARY_DISPLAY=eDP1 AUTOMIRROR_NOTIFY_COMMAND=echo ~/.bash_automirror.sh
abbr --global --add fixcursor 'echo -en "\e]50;CursorShape=0\x7"'
abbr --global --add fixcursortmux 'echo -en "\e[0 q"'

abbr --global --add composekeylist cat /usr/share/X11/locale/en_US.UTF-8/Compose

# command starting with ' ' aren't recorded
# history: correct order, timestamp, pager from bottom
alias h 'history --reverse --show-time | bat --language fish --force-colorization --pager "less -R +G" --style plain'

alias i ipython3
alias is "PYTHONNOUSERSITE=on ipython3"

# conda
# path_add /opt/conda/bin
function condainit
    eval conda "shell.fish" hook $argv | source
end

# video reader of the month (with true hardware decoding)
if type mpv &>/dev/null
    alias vlc "mpv --hwdec=auto"
end

# pdf reader of the month
alias pdf zathura

# designed-to-be-kill commands
function oom
    command choom -n 1000 -- $argv
end

function cargo
    oom cargo $argv
end
function make
    oom make $argv
end

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

abbr tm tmux
function tmuxa
    if test (count $argv) -gt 0
        tmux new-session -A -D -s $argv
    else
        tmux attach\; choose-tree
    end
end
alias tmuxl 'tmux ls'
alias tc 'clear; tmux clear-history'
function tmuxd
    tmux select-layout even-vertical &>/dev/null
    tmux split-window
    sleep 1 # perfectible™
    tmux send-keys "$argv"
    tmux send-keys C-m
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
    tmuxps | grep -v 'grep,' | /bin/grep "$argv"
end

# ]]]
# [[[ editor

if test -r "$UTILS/neovim_install/bin/nvim"
    set --global --export EDITOR $UTILS/neovim_install/bin/nvim
    set --global --export MANPAGER 'nvim +Man!'
    function vim
        $EDITOR $argv
    end
    alias vimdiff "nvim -d"
else
    set --global --export EDITOR vim
    set --global --export MANPAGER "/bin/sh -c \"unset PAGER;col -b -x | vim -R -c 'set ft=man nomod nolist nonumber norelativenumber readonly' -c 'map q :q<CR>' -c 'map <SPACE> <C-D>' -\""
end
function v
    $EDITOR $argv
end
alias va "$EDITOR ~/dotfiles/start.txt"
alias vr "$EDITOR -R"
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

alias vgr "$EDITOR -c :cwindow -q -"
function vrg -d "rg then pipe results into nvim"
    rg --vimgrep $argv | $EDITOR -c :cwindow -q -
end
function vgrg -d "rg (no submodule) then pipe results into nvim"
    grg --vimgrep $argv | $EDITOR -c :cwindow -q -
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

alias g git
function gside -d "git with side-by-side diffs"
    command git -c delta.side-by-side=true $argv
end
function gwhitespace -d "git with # lines in commit message"
    command git -c commit.cleanup=whitespace $argv
end
function glfs -d "git with lfs diff expanded"
    command git -c diff.lfs.textconv=cat $argv
end
function gnosub -d "git with no submodule info"
    command git \
        -c diff.ignoreSubmodules=all \
        -c status.submoduleSummary=0 \
        $argv
end

function ganonrebase -d "git rebase without updating committer"
    command git -c rebase.instructionFormat='%s%nexec GIT_COMMITTER_DATE="%cI" GIT_COMMITTER_NAME="%aN" GIT_COMMITTER_EMAIL="%aE" git commit --amend --no-edit%n' rebase -i $argv
end

# TODO safer method
function gem -d "open git modified files (default HEAD, use argv to specify range/path)"
    set -f BCK (pwd)
    up
    git jump --stdout diff $argv | $EDITOR -c ":cwindow" -q -
    # $EDITOR (git status --ignore-submodules --porcelain | /bin/grep --color=no "^[ M]M" | trs | cut -d" " -f2)
    cd $BCK
end
function ges -d "open git staged files"
    set -f BCK (pwd)
    up
    git jump --stdout diff --staged | $EDITOR -c ":cwindow" -q -
    # $EDITOR (git status --ignore-submodules --porcelain | /bin/grep --color=no "^M" | trs | cut -d" " -f2)
    cd $BCK
end
function ge -d "open git edited files"
    set -f BCK (pwd)
    up
    git jump --stdout diff HEAD | $EDITOR -c ":cwindow" -q -
    # $EDITOR (git status --ignore-submodules --porcelain | /bin/grep --color=no "^[ M][ M]" | trs | cut -d" " -f2)
    cd $BCK
end
function gep -d "open patched files from given commit range (HEAD~[..]HEAD by default)"
    set -f FROM $argv[1] HEAD~ # fish's default value method
    set -f FROM $FROM[1]
    if string match --quiet "*..*" $FROM
        set -f RANGE $FROM
    else
        set -f TO $argv[2] HEAD # fish's default value method
        set -f TO $TO[1]
        set -f RANGE $FROM..$TO
    end
    set -f BCK (pwd)
    up
    git jump --stdout diff $RANGE | $EDITOR -c ":cwindow" -q -
    # $EDITOR (git show --pretty="format:" --name-only $RANGE | grep . | sort | uniq)
    cd $BCK
end

alias t "tig --date-order -500"
alias ta "tig --date-order --all -500"
alias topo "tig --topo-order -500"
alias topoa "tig --topo-order --all -500"
alias tigreflog "git reflog --format=raw --decorate=full | tig --pretty=raw"

# tig <git-ls-file> direct completion
complete -c tig -n 'not contains -- -- (commandline -opc)' -xa '(set -l t (commandline -ct); complete -C"git log $t")'

function up -d "go to the upper git repo head"
    set BCK (pwd)
    set A (pwd)
    while git rev-parse --show-toplevel &>/dev/null
        set A (git rev-parse --show-toplevel 2> /dev/null)
        cd (dirname $A)
    end
    cd $BCK # keep `cd -` expected behavior
    if git -C $A rev-parse --show-toplevel &>/dev/null
        cd $A
        set --erase A
        true
    else
        set --erase A
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
abbr --global --add gm git mergetool
abbr --global --add gc git commit
abbr --global --add ggr git grep -n
abbr --global --add tempo git commit -a -m tempo
function gbr -d "get flat list of branches, for using in scripts"
    command git branch $argv | sed "s/\*//" | sed "s/^\s*//"
end

set --export FILTER_BRANCH_SQUELCH_WARNING 1

# ]]]
# [[[ build

# always generate compile_commands.json
set -gx CMAKE_EXPORT_COMPILE_COMMANDS ON

# ]]]
# [[[ interactiv only settings

if status --is-interactive

    # [[[ prompt

    if type starship &>/dev/null
        starship init fish | source
    else
        # TODO? a minimal fish prompt?
    end

    # ]]]
    # [[[ own keymap

    if type bind &>/dev/null and type stty &>/dev/null
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
        # q[K->] w[<-EATW]         u[OK] i[TAB] o[HIST-] p[HIST-]
        # d[EATW->] f[word->] g[eat->] h[<-eat] j[<-word] k[accept]
        #                v[->]              n[<-]  m[ENTER]

        # bind \t complete-and-search # always search mode (shift+tab) on tab
        bind \cD delete-or-exit # restore usual behavior
        bind \cK accept-autosuggestion or kill-line # C-k hybrid mode (accept suggestion or usual kill-line)
        bind \cY accept-autosuggestion execute # C-y accept suggestion + execute
    end

    # ]]]
    # [[[ history

    if type atuin &>/dev/null
        atuin init --disable-up-arrow fish | source
    end

    # ]]]
end

# ]]]

# dotter/handlebars+fold incompatibility: temporary [[[ / ]]]]
# vim: foldmethod=marker
# vim: foldmarker=[[[,]]]
