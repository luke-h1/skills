# skills

My global Claude Code / agent skills, versioned so a new laptop is one command away.

Two kinds of global skills live in `~/.claude/skills`:

- **Marketplace skills** - symlinks into `~/.agents/skills`, installed from GitHub via
  the skills CLI. Fully described by `~/.agents/.skill-lock.json`, so they don't need
  to be committed - just the lock file. Reinstalled by cloning each source repo.
- **Local custom skills** - real directories that exist nowhere else (my security /
  bug-bounty skills). These are vendored into `skills/` here.

## New laptop

```sh
git clone https://github.com/luke-h1/skills ~/srv/dev/skills
cd ~/srv/dev/skills
./install.sh
```

That symlinks the vendored local skills into `~/.claude/skills` and reinstalls every
marketplace skill from its source. Restart Claude Code afterwards.

## Keeping it up to date

```sh
bin/skill sync           # capture current global skills into the repo (stages changes)
bin/skill sync --push     # ...and commit + push
bin/skill schedule        # run `sync --push` automatically every day at 22:00 (launchd)
bin/skill unschedule      # stop that
bin/skill status          # what's tracked vs scheduled
```

Put `bin/` on your `PATH` (or `alias skill=~/srv/dev/skills/bin/skill`) to just run `skill sync`.

## Layout

```
bin/skill                   the CLI (sync / install / schedule / status)
install.sh                  new-laptop bootstrap -> bin/skill install
skills/<name>/              vendored local custom skills
manifest/skill-lock.json    marketplace skills manifest (copy of ~/.agents/.skill-lock.json)
manifest/local-skills.txt   list of vendored local skills
manifest/*.json             plugin marketplace config, for reference
```

Marketplace skills failing to install usually means the source repo moved or went
private - rerun `install`, and the ones already present are skipped.
