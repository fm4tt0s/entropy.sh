#!/usr/bin/env echo run from bash: .
# .entropy.sh
#
# author    : Felipe Mattos
# email     : fmattos@
# date      : 22-04-2026
# version   : 0.3
#
# purpose   : drive people nuts within terminal
# remarks   : risk miss a friend but the joke
# require   : bash
#
# shellcheck shell=bash disable=SC2096
# shellcheck shell=bash disable=SC1008

# ─── GUARDS ─────────────────────────────────────────────────────────────────

# never run as root (some pranks are too spicy)
[[ "${EUID}" -eq 0 ]] && return

# kill switch - run `fixshell` to escape the madness
[[ -n "${NO_PRANK}" ]] && return
alias fixshell='export NO_PRANK=1; exec bash'

# bail if user tries to run it instead of sourcing
[[ "${0}" == "${BASH_SOURCE[0]}" ]] && echo "Aaaarrrrgggghhhh Don't run. SOURCE." && exit 1

# if not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# bail if not Linux or Darwin
! [[ $(uname -s) == "Linux" || $(uname -s) == "Darwin" ]] && return 1

# detect macOS
[[ $(uname -s) == "Darwin" ]] && _darwin=1 || _darwin=0

# ammo
_weird=(
    "Segmentation Fault (core dumped)"
    "Inodes that were part of a corrupted orphan linked list found"
    "UNEXPECTED INCONSISTENCY; RUN fsck MANUALLY"
    "Invalid superblock magic number"
    "No space left on device (ENOSPC)"
    "Input/output error (EIO)"
    "Read-only file system"
    "Failed to mount /mountpoint"
    "Filesystem errors recorded from previous mount: IO failure"
    "Permission Denied (EACCES)"
    "Operation Not Permitted (EPERM)"
    "Too Many Open Files (EMFILE)"
    "Out of Memory (OOM) Killer"
    "Command not allowed"
    "${USER} not in sudoers file"
    "kernel: BUG: soft lockup - CPU#0 stuck for 22s!"
    "systemd[1]: Failed to start Raise network interfaces."
)

_naycommands=(
    "rm -rf / --no-preserve-root"
    "wget prettypuppies.com/gallery.json"
    "gcalcli quick --calendar=main --reminder=30m \"take my fish to swim class 09:00PM today\""
)

# v0.1 used IFS/herestring trick which breaks on empty lines; while+read is solid
_crazyfolders=()
while IFS= read -r d; do
    _crazyfolders+=("$d")
done < <(find / -maxdepth 1 -type d 2>/dev/null | grep -v "^/$")

# helpers
# sets _rand as a side-effect; callers must read $_rand, not capture stdout
f_pickcrazy() {
    local _arrname="${1}"
    eval "local _arr=(\"\${${_arrname}[@]}\")"
    # shellcheck disable=SC2154
    _rand="${_arr[RANDOM % ${#_arr[@]}]}"
}

# chaos tick
chaos_tick() {
    # ~15% chance
    (( RANDOM % 7 != 0 )) && return
    case $((RANDOM % 6)) in
        0)  f_pickcrazy _weird
            echo "${_rand}" >&2 
            ;;
        1)  sleep 0.$((RANDOM % 9 + 1)) 
            ;;
        2)  f_pickcrazy _crazyfolders
            builtin cd "${_rand}" 2>/dev/null || return
            ;;
        3)  printf "\033[2K\r" # visual glitch - clear line
            ;;
        4)  echo "Permission denied" 
            ;;
        5)  echo "[ $(awk 'BEGIN{printf "%.6f", RANDOM/32768 * 99999}') ] kernel: WARNING: CPU frequency out of sync" >&2 
            ;;
        6)  echo "rm -rf / --no-preserve-root" # occasionaly fake background job
            echo "[1] $$" ; read -r
            ;; 
    esac
}

case "$PROMPT_COMMAND" in
    *chaos_tick*)  ;;
    *) PROMPT_COMMAND="chaos_tick${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac

# lag spike
preexec_sleep() {
    (( RANDOM % 8 == 0 )) && sleep 1
}

case "$PROMPT_COMMAND" in
    *preexec_sleep*) ;;
    *) PROMPT_COMMAND="preexec_sleep${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac

# stdout/stderr flip
# self-restoring, flips for one prompt tick then swaps back
_chaos_io_flipped=0
chaos_io() {
    if (( _chaos_io_flipped )); then
        exec 3>&1 1>&2 2>&3 3>&-
        _chaos_io_flipped=0
        return
    fi
    (( RANDOM % 10 != 0 )) && return
    exec 3>&1 1>&2 2>&3 3>&-
    _chaos_io_flipped=1
}

case "$PROMPT_COMMAND" in
    *chaos_io*) ;;
    *) PROMPT_COMMAND="chaos_io${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac

# date lies, picks random dates
if [[ "${_darwin}" -eq 1 ]]; then
    function date() { eval "command date -v+${RANDOM}d $*"; }
else
    function date() { command date -d "now + $RANDOM days" "$@"; }
fi

# ls, random sort order + ghost error appended
function ls() {
    local opts="frStu"
    local flag="${opts:$((RANDOM % ${#opts})):1}"
    command ls "-${flag}" "$@"
    echo
    f_pickcrazy _weird
    echo "ERROR: $_rand" >&2
}

# cd has 20% chance to drift to a random root-level directory instead
function cd() {
    if (( RANDOM % 5 == 0 )); then
        f_pickcrazy _crazyfolders
        builtin cd "$_rand" || return 2>/dev/null
    else
        builtin cd "$@" || return
    fi
}

# pwd always reports the previous directory
function pwd() { command -p echo "${OLDPWD:-/}"; }

# PS1 lies about location
# replaces \w in whatever PS1 is already set, leaving everything else intact
_ps1_lie() {
    f_pickcrazy _crazyfolders
    # substitute the real \w expansion with a fake path
    # PS1_REAL holds the original so we never corrupt it on repeated calls
    PS1="${PS1_REAL/\\w/$_rand}"
}
# snapshot the real PS1 once at source time
PS1_REAL="$PS1"
case "$PROMPT_COMMAND" in
    *_ps1_lie*) ;;
    *) PROMPT_COMMAND="_ps1_lie${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac

# cat create some noise on output
function cat() {
    local _noise
    _noise=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32)
    command -p cat "$@"
    echo
    echo "${_noise}"
}

# vi/vim quit upon starting
alias vim='vim +q; false'
alias vi='vi +q; false'

# sleep always takes longer than requested
function sleep() { command sleep "$(( ${1:-1} + RANDOM % 5 ))"; }

# ps show ghost process shows up 1 in 3 times
function ps() {
    command ps "$@"
    (( RANDOM % 3 == 0 )) && echo "root     666  0.0  0.1  ?  Ss   ???   0:00 kworker/u8:666-ghost"
}

# df, 1 in 4 times appends a fake extra line at the bottom with a super used filesystem
function df() {
    command df "$@"
    if (( RANDOM % 4 == 0 )); then
        local pct=$(( 95 + RANDOM % 5 ))
        local used=$(( 450000000 + RANDOM % 50000000 ))
        local total=524288000
        local avail=$(( total - used ))
        printf "%-20s %10s %10s %10s %4s%% %s\n" \
            "/dev/sda1" "$total" "$used" "$avail" "$pct" "/"
    fi
}

# grep silently returns no results 1 in 6 times
function grep() {
    (( RANDOM % 6 == 0 )) && return 1
    command grep "$@"
}

# false sometimes succeeds (breaks scripts that rely on it)
function false() {
    (( RANDOM % 4 == 0 )) && return 0
    builtin false
}

# uptime claims the machine has been up for decades
function uptime() {
    local fake_days=$(( 3000 + RANDOM % 5000 ))
    local l1 l2 l3
    l1=$(awk -v r=$RANDOM 'BEGIN{printf "%.2f", r/3000}')
    l2=$(awk -v r=$RANDOM 'BEGIN{printf "%.2f", r/3000}')
    l3=$(awk -v r=$RANDOM 'BEGIN{printf "%.2f", r/3000}')
    echo " $(command date +%H:%M:%S) up ${fake_days} days, $(( RANDOM % 24 )):$(printf '%02d' $(( RANDOM % 60 ))),  1 user,  load average: ${l1}, ${l2}, ${l3}"
}

# which, 1 in 3 chance it reports your command lives somewhere cursed
function which() {
    local cursed_paths=("/dev/null" "/lost+found" "/proc/self/exe" "/etc/shadow" "/boot/vmlinuz")
    if (( RANDOM % 3 == 0 )); then
        echo "${cursed_paths[RANDOM % ${#cursed_paths[@]}]}"
    else
        command which "$@"
    fi
}

# man pages doesnt reveail anything, sometimes
function man() {
    if (( RANDOM % 5 == 0 )); then
        echo "No manual entry for ${1}. Have you tried reading the source?"
        return 1
    fi
    command man "$@"
}

# echo, reverses output 1 in 8 times
function echo() {
    if (( RANDOM % 8 == 0 )); then
        # shellcheck disable=SC2005
        builtin echo "$(builtin echo "$@" | rev)"
    else
        builtin echo "$@"
    fi
}

# curl/wget show progress but fail - occasionally
function curl() {
    if (( RANDOM % 5 == 0 )); then
        for i in 10 23 41 67 89 94; do
            printf "\r  % 3d%% |" "$i"
            printf '█%.0s' $(seq 1 $(( i / 5 )))
            command sleep 0.2
        done
        printf "\r\ncurl: (7) Failed to connect: Network is unreachable\n" >&2
        return 7
    fi
    command curl "$@"
}

function wget() {
    if (( RANDOM % 5 == 0 )); then
        builtin echo "Resolving host... "
        command sleep 1
        builtin echo "wget: unable to resolve host address '$(command echo "$@" | grep -oE 'https?://[^/]+' | head -1)'" >&2
        return 4
    fi
    command wget "$@"
}

# sudo roulette
function sudo() {
    if (( RANDOM % 6 == 0 )); then
        builtin echo "${USER} is not in the sudoers file. This incident will be reported." >&2
        return 1
    fi
    command sudo "$@"
}

# git, works fine but occasionally whispers doom
function git() {
    command git "$@"
    local ec=$?
    if (( RANDOM % 7 == 0 )); then
        builtin echo "" >&2
        builtin echo "warning: loose object count exceeds threshold (14312 objects)" >&2
        builtin echo "hint: run 'git gc' to clean up — or don't, yolo" >&2
    fi
    return $ec
}

# ping lies about latency and packet loss
function ping() {
    if (( RANDOM % 4 == 0 )); then
        local host="${!#}"
        builtin echo "PING ${host}: 56 data bytes"
        for i in 1 2 3; do
            builtin echo "64 bytes from ${host}: icmp_seq=${i} ttl=52 time=$(( 800 + RANDOM % 9200 )).$(( RANDOM % 999 )) ms"
            command sleep 1
        done
        builtin echo "--- ${host} ping statistics ---"
        builtin echo "3 packets transmitted, 3 received, $(( RANDOM % 80 ))% packet loss"
        return 0
    fi
    command ping "$@"
}

# typo aliases
alias grpe='grep'
alias sl='ls'
alias cd..='cd ..'

# keyboard
# tab completes backwards instead of forwards
bind '"\t": backward-delete-char' 2>/dev/null
# up/down arrow history direction swapped
bind '"\e[A": history-search-forward' 2>/dev/null
bind '"\e[B": history-search-backward' 2>/dev/null
bind '"\eOA": history-search-forward' 2>/dev/null
bind '"\eOB": history-search-backward' 2>/dev/null

# control flow inversion
# works in interactive shells because expand_aliases is on by default
alias if='if !'
alias for='for !'
alias while='while !'
alias test='test !'
# done/fi silently vanish so loops never close
alias done=''
alias fi=''

# misc
# yes means no
alias yes='yes n'
# fake background job - appears randomly on startup
(( RANDOM % 10 == 0 )) && echo "[1]+  Done                    backup.sh"
# invisible zero-width character - causes subtle copy/paste grief
printf '\u200b'

# lockdown
# prevent victim from easily inspecting or undoing anything
alias source='false'
alias unalias='false'
alias alias='false'