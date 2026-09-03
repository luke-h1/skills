# skills

Versioned backup of my global Claude skills. New laptop = one command.

- Marketplace skills → tracked via `manifest/skill-lock.json`, recloned on install.
- Local custom skills → vendored in `skills/`, symlinked back on install.

## Usage

```sh
bin/skill sync          # capture current global skills into the repo
bin/skill sync --push    # ...and commit + push
bin/skill install        # restore every skill onto this machine
bin/skill schedule       # daily auto sync+push at 22:00 (launchd)
bin/skill unschedule     # stop it
bin/skill status         # what's tracked / scheduled
```

## New laptop

```sh
git clone https://github.com/luke-h1/skills ~/srv/dev/skills
cd ~/srv/dev/skills && ./install.sh   # then restart Claude Code
```

Tip: `alias skill=~/srv/dev/skills/bin/skill`.
