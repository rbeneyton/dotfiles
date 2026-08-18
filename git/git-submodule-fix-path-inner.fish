#!/usr/bin/env fish

# Detects a submodule whose git-dir storage under .git/modules/ no longer
# matches its current name (typically left over after a manual move/rename
# where .gitmodules was updated but .git/modules wasn't). Git then aborts
# recursive operations (checkout, status, ...) with:
#   BUG: submodule.c:xxxx: submodule name '<name>' not a suffix of git dir '<path>'
# On detection, asks whether to relocate the git-dir and fix up the pointers.
#
# Run via: git submodule --quiet foreach git-submodule-fix-path-inner

if not set -q name; or not set -q sm_path; or not set -q toplevel
    echo "git-submodule-fix-path-inner: must be run via 'git submodule foreach', not standalone" >&2
    exit 1
end

set sm_root $toplevel/$sm_path
set gitfile $sm_root/.git

if not test -f $gitfile
    # embedded/bare working tree or not checked out: nothing to relocate
    exit 0
end

set gitdir_rel (string replace -r '^gitdir: ' '' -- (/bin/cat $gitfile))
set actual (realpath $sm_root/$gitdir_rel)
set super_gitdir (git -C $toplevel rev-parse --absolute-git-dir)
set expected (realpath -m $super_gitdir/modules/$name)

if test "$actual" = "$expected"
    exit 0
end

echo "submodule '$name':"
echo "  stored at : $actual"
echo "  expected  : $expected"

read -l -P "  fix (move git-dir + update pointers)? [y/N] " answer
if test "$answer" != y -a "$answer" != Y
    echo "  skipped"
    exit 0
end

if not test -d $actual
    echo "  error: $actual does not exist, cannot move" >&2
    exit 1
end

mkdir -p (dirname $expected)
or begin
    echo "  error: mkdir $(dirname $expected) failed" >&2
    exit 1
end

mv $actual $expected
or begin
    echo "  error: mv $actual $expected failed" >&2
    exit 1
end

set worktree_rel (realpath --relative-to=$expected $sm_root)
sed -i "s@^\(\s*worktree = \).*@\1$worktree_rel@" $expected/config
or begin
    echo "  error: updating worktree path in $expected/config failed" >&2
    exit 1
end

set gitdir_new_rel (realpath --relative-to=$sm_root $expected)
echo "gitdir: $gitdir_new_rel" >$gitfile
or begin
    echo "  error: writing $gitfile failed" >&2
    exit 1
end

echo "  fixed"
