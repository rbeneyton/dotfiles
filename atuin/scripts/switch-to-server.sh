#!/bin/bash
# Merge legacy ~/.local/share/atuin into the per-host dir introduced by
# 7c7e966 (atuin new setup: server+daemon), without deleting the legacy copy.
# Safe to re-run: INSERT OR IGNORE dedups on (timestamp, cwd, command).
set -euo pipefail

host=$(hostname -s)
old=~/.local/share/atuin
new=~/.local/share/atuin.$host

if pgrep -u "$USER" -f '^atuin daemon' > /dev/null; then
    echo "stopping atuin daemon"
    pkill -u "$USER" -f '^atuin daemon'
    sleep 1
fi

if [ ! -f "$old/history.db" ]; then
    echo "no legacy history at $old/history.db, nothing to merge"
    exit 0
fi

mkdir -p "$new"

if [ ! -f "$new/history.db" ]; then
    echo "no history yet at $new, copying legacy db as-is"
    cp "$old/history.db" "$new/history.db"
else
    cp "$new/history.db" "$new/history.db.pre-merge.bak"
    before=$(sqlite3 -readonly "$new/history.db" 'select count(*) from history;')
    sqlite3 "$new/history.db" "
        attach '$old/history.db' as old;
        insert or ignore into history select * from old.history;
    "
    after=$(sqlite3 -readonly "$new/history.db" 'select count(*) from history;')
    echo "history rows: $before -> $after (backup: $new/history.db.pre-merge.bak)"
fi

if [ ! -f ~/.config/atuin/key ] && [ -f "$old/key" ]; then
    echo "copying shared key to ~/.config/atuin/key"
    cp "$old/key" ~/.config/atuin/key
fi

export ATUIN_DATA_DIR="$new"
echo "starting atuin daemon"
setsid --fork atuin daemon start > "$new/daemon.log" 2>&1

echo "done. legacy dir left untouched at $old — remove manually once verified."
