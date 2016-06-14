#!/usr/bin/env bash
#
# entrypoint.sh: The entry-point run within the container to run user commands.
#
# Sets up the environment in which the user's command will run, then uses `sudo`
# to run it under the correct UID/GID.
#
set -e

# If no command to run specified, just quit.
[[ $# == 0 ]] && exit 0

[[ "$WORK_GID" == 0 ]] && unset WORK_GID
[[ "$WORK_UID" == 0 ]] && unset WORK_UID

# Adjust `stack` user's UID/GID to match that of the user on the host OS.
# Since we don't know the UID/GID ahead of time, this cannot be done when
# creating the image.  If we don't do this, any files created by the user's
# commands in the bind-mounted work directory will be owned by an incorrect UID
# instead of the user running the commands.

if [[ -n "$WORK_UID" ]] && [[ -n "$WORK_GID" ]] ; then
  addgroup -g "$WORK_GID" stack
  adduser -D -h "$WORK_HOME" -G stack -u "$WORK_UID" stack
  export PATH="$WORK_HOME/bin:$WORK_HOME/.local/bin:$PATH"
fi
if [[ -n "$WORK_HOME" ]] ; then
  [[ -d "$WORK_HOME/.cabal" ]] && export PATH="$WORK_HOME/.cabal/bin:$PATH"
fi
if [[ -n "$WORK_WD" ]] ; then
  cd "$WORK_WD"
fi

if [[ -n "$WORK_UID" ]] && [[ -n "$WORK_GID" ]] ; then
  # Use `sudo` to run the user's command as the correct UID/GID.
  exec sudo -EHu stack PATH="$PATH" /usr/bin/env -- "$@"
else
  exec "$@"
fi
