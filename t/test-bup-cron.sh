#!/usr/bin/env bash

BUP_SRC=../bup
cd $BUP_SRC
# make paths absolute, crudely
BUP_SRC=$PWD
. ./wvtest-bup.sh
cd -

set -o pipefail

WVSTART "Testing bup-cron..."

top="$(WVPASS pwd)" || exit $?
tmpdir="$(WVPASS wvmktempdir)" || exit $?

export BUP_DIR="$tmpdir/repo.bup"
export GIT_DIR="$BUP_DIR"
HOST=localhost

git() { command git --no-pager "$@"; }
bup-cron() { "$top/bup-cron" --debug -vvv --pidfile "$tmpdir/bup-cron.pid" "$@"; }

WVPASS bup init
WVPASS cd "$tmpdir"

# Can bup-cron be called
WVPASS bup-cron -h >/dev/null

# Create some data to backup
WVSTART "create src data"
WVPASS mkdir -p "$tmpdir/src/"{dir1,dir2,dir1/x,dir1/x/a,dir/x/b}
WVPASS date    > "$tmpdir/src/dir1/d10"
WVPASS date -u > "$tmpdir/src/dir1/d11"
WVPASS date -u > "$tmpdir/src/dir2/d20"
WVPASS date    > "$tmpdir/src/dir2/d21"

# Basic options
WVSTART "bup-cron: basic options"
branch_name="$HOSTNAME-${tmpdir//\//_}_src_dir1"
WVPASS bup-cron "$tmpdir/src/dir1"
WVPASSEQ "$(WVPASS bup ls /)" "$branch_name"
WVPASSEQ "$(WVPASS bup ls /$branch_name/latest/)" "d10
d11
x"
WVPASS bup restore -C "$tmpdir/dst" "$branch_name/latest"
WVPASS "$BUP_SRC/t/compare-trees" "$tmpdir/src/dir1/" "$tmpdir/dst/latest"
WVPASSEQ "$(WVPASS ls "$tmpdir/dst/latest/")" "d10
d11
x"
WVPASS rm -fr "$tmpdir/dst"

# test --name and branch isolation
branch_name="B2-${tmpdir//\//_}_src_dir2"
WVPASS bup-cron --name B2 "$tmpdir/src/dir2"
WVPASSEQ "$(WVPASS bup ls /$branch_name/latest/)" "d20
d21"
# - stuff from dir1 must not be in B2
WVPASS bup restore -C "$tmpdir/dst" "$branch_name/latest"
WVPASS "$BUP_SRC/t/compare-trees" "$tmpdir/src/dir2/" "$tmpdir/dst/latest"
WVPASSEQ "$(WVPASS ls "$tmpdir/dst/latest/")" "d20
d21"
WVPASS rm -fr "$tmpdir/dst"

WVSTART "bup-cron: --parity generates parity blocks"
branch_name="$HOSTNAME-${tmpdir//\//_}_src_dir1"
WVPASS bup-cron --parity "$tmpdir/src/dir1"
# copy-pasted from upstream t/test-fsck.sh
WVPASS bup fsck
WVPASS bup fsck --quick
WVPASS bup damage "$BUP_DIR"/objects/pack/*.pack -n10 -s1 -S0
WVFAIL bup fsck --quick
if bup fsck --par2-ok; then
    WVFAIL bup fsck -r
    WVPASS bup fsck -r
fi

WVSTART "bup-cron: --check fails then recovers properly"
WVPASS bup damage "$BUP_DIR"/objects/pack/*.pack -n10 -s1 -S0
WVFAIL bup-cron --parity --check "$tmpdir/src/dir1"
WVFAIL bup fsck -r
WVPASS bup fsck -r
WVPASS bup-cron --parity --check "$tmpdir/src/dir1"

WVSTART "bup-cron: --repairs recovers properly"
WVPASS bup damage "$BUP_DIR"/objects/pack/*.pack -n10 -s1 -S0
WVFAIL bup-cron --parity --repair "$tmpdir/src/dir1"
WVPASS bup fsck
WVPASS bup-cron --parity --check "$tmpdir/src/dir1"

WVSTART "bup-cron: --stats generates git notes, the last one with content"
branch_name=stats-${tmpdir//\//_}_src_dir2
WVPASS bup-cron --name stats --stats "$tmpdir/src/dir2"
WVPASS git show $branch_name

WVSTART "bup-cron: test remote host support in $HOST:$BUP_DIR"
branch_name=remote-${tmpdir//\//_}_src_dir1
WVPASS bup-cron --name remote -r $HOST:$BUP_DIR "$tmpdir/src/dir1"
WVPASSEQ "$(WVPASS bup ls /$branch_name/latest/)" "d10
d11
x"

WVSTART "bup-cron: test remote stats support"
branch_name=remote-${tmpdir//\//_}_src_dir1
WVPASS bup-cron --name remote --stats -r $HOST:$BUP_DIR "$tmpdir/src/dir1"
WVPASS git notes show $branch_name

# MISSING TESTS:
# * logfile
# * syslog
# * clear?
# * exclude patterns?
# * pidfile
# if ROOT:
# - test snapshot
#	- lvm
#	- VSS

WVPASS rm -fr "$tmpdir"
echo "bup-cron tests completed"
