#!/usr/bin/env fish

# This script checks submodule's remote tracking default branches and report distance of local HEAD
# side-effect: update local tracked branch

git fetch --quiet --prune origin

set default (git remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}')

if test -z "$default" -o "$default" = "(unknown)"
    set default (git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed "s|origin/||")
end

if test -z "$default"
    echo "$sm_path: could not determine default branch, skipping" >&2
    exit 0
end

set behind (git rev-list --count HEAD..origin/$default 2>/dev/null; or echo 0)

if test "$behind" != 0
    echo "$sm_path $behind ($default)"
end
