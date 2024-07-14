#!/usr/bin/bash

set -o pipefail

podman-compose up -d  # healthcheck has been set in the compose file

sleep 5s

is_ready() {
  podman-compose exec -T web bash -c "curl -sL http://127.0.0.1:8080/" >/dev/null
  if podman-compose logs web | tail -n 1 | grep '"GET /accounts/login/ HTTP/1.1" 200' >/dev/null; then
    return 0
  fi
  return 1
}

for i in seq 1 5; do
  is_ready && exit 0
  if [ $i -eq 5 ]; then
    break
  fi
  echo "Sleep 2s and have another try ..." >&2
  sleep 2s
done

echo "The frontend web seems not respond an HTTP request." >&2
exit 1

# vim: tabstop=2 shiftwidth=2 expandtab autoindent
