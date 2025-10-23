#!/bin/bash
set -e

# Uruchom sshd (w tle) i utrzymaj kontener żywy
if command -v /usr/sbin/sshd >/dev/null 2>&1; then
  /usr/sbin/sshd
fi

# domyślne zachowanie zgodne z oryginalnym poleceniem: sleep infinity
exec sleep infinity