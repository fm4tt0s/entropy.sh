# entropy.sh

![Scream!](screaming.png)


> *drive people nuts within terminal*

A sourceable bash prank file. Works on Linux and macOS. Leaves no traces in the filesystem, makes no permanent changes — everything lives in the shell session and vanishes the moment the victim closes their terminal. Or runs `fixshell`. Whichever comes first.

---

## Install

Drop it in the target's `~/.bashrc` or `~/.bash_profile`:

```bash
source /path/to/entropy.sh
```

Or append it silently:

```bash
echo "source /path/to/entropy.sh" >> ~/.bashrc
```

---

## Escape hatch

There is one. Type:

```bash
fixshell
```

This sets `NO_PRANK=1` and respawns a clean bash session. Useful for when you feel bad. Don't feel bad.

---

## What it does

### Prompt & navigation

| Thing | What actually happens |
|---|---|
| `pwd` | Always reports the *previous* directory |
| `cd` | 20% chance of silently drifting to a random root-level directory instead |
| `PS1` | The working directory in the prompt is replaced with a random path — colours, hostname, and everything else untouched |

### Core commands

| Command | Chaos |
|---|---|
| `ls` | Output sorted randomly every time; a fake filesystem error appended to stderr |
| `rm` | Always prints `Done.` and does nothing |
| `cat` | Appends 32 random alphanumeric characters after every file |
| `date` | Returns a date randomly between today and ~89 years from now |
| `sleep` | Sleeps 1–4 seconds longer than asked |
| `false` | Succeeds 1 in 4 times |
| `grep` | Silently returns no results 1 in 6 times |
| `echo` | Reverses output 1 in 8 times |

### System info

| Command | Lie |
|---|---|
| `df` | Appends a fake `/dev/sda1` entry at 95–99% full |
| `ps` | 1 in 3 chance of a ghost `kworker/u8:666` process owned by root |
| `uptime` | Claims the machine has been running for 3,000–8,000 days |
| `ping` | 1 in 4 chance of fabricated 800–10,000ms latency with random packet loss |
| `which` | 1 in 3 chance of reporting your binary lives in `/etc/shadow` or `/proc/self/exe` |

### Dev tools

| Command | Chaos |
|---|---|
| `vim` / `vi` | Quits immediately on launch and returns exit code 1 |
| `git` | Works normally, but occasionally warns of 14,312 loose objects |
| `curl` | 1 in 5 chance of rendering a fake progress bar then dying with `Network is unreachable` |
| `wget` | 1 in 5 chance of resolving the host for a second then failing |
| `sudo` | 1 in 6 chance of reporting you to the sudoers committee |
| `man` | 1 in 5 chance of `No manual entry. Have you tried reading the source?` |
| `history` | Output is shuffled; `rm -rf / --no-preserve-root` planted in history |

### Keyboard

| Key | Remapped to |
|---|---|
| `Tab` | Backspace (deletes character behind cursor) |
| `↑` | Searches history *forward* instead of backward |
| `↓` | Searches history *backward* instead of forward |

### Control flow

Alias inversion works in interactive shells because `expand_aliases` is enabled by default:

```
if   → if !      (conditions always inverted)
for  → for !
while → while !
test → test !
done → (empty)   (loops never close)
fi   → (empty)   (if blocks never close)
```

### Background noise

- `PROMPT_COMMAND` runs `chaos_tick` on every prompt (~15% chance): fake kernel panics on stderr, random lag, silent directory drift, terminal line clears
- Random 1-second lag spike injected before ~12% of prompts
- 1 in 10 chance of stdout/stderr being swapped for one prompt tick then restored
- `yes` prints `n`
- 1 in 10 chance of a fake `[1]+ Done  backup.sh` job notification on startup
- A zero-width space (`U+200B`) printed on startup — causes subtle copy/paste grief
- Typo aliases: `grpe`, `sl`, `cd..` all work; the real commands occasionally don't

### Lockdown

Applied last so nothing above breaks during sourcing:

```bash
alias source='false'
alias unalias='false'
alias alias='false'
```

Once the file is sourced, the victim cannot inspect aliases, remove them, or source anything else without knowing about `fixshell` or opening a new terminal.

---

## Safety

- **Never runs as root** — bails immediately if `EUID` is 0
- **Non-interactive shells are left alone** — scripts, cron jobs, and CI are unaffected
- **No filesystem writes** — everything is in-memory for the session only
- **Linux and macOS only** — returns cleanly on anything else

---

## Requirements

- `bash` (interactive session)
- Standard coreutils: `awk`, `tr`, `shuf`, `find`, `seq`
- `bind` (readline — present in any interactive bash)

---

*v0.3 — fm4tt0s@*