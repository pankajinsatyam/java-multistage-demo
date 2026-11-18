#!/usr/bin/env bash
# Builds all 4 image versions and prints their sizes side by side.
# Usage:  ./compare-sizes.sh          -> build + show sizes
#         ./compare-sizes.sh --test   -> also start each image and call it
set -euo pipefail

VARIANTS=(
  "1-single-stage"
  "2-multistage-jre"
  "3-multistage-alpine"
  "4-multistage-jlink"
)

for v in "${VARIANTS[@]}"; do
  echo ""
  echo "=============================================="
  echo " Building hello-app:$v"
  echo "=============================================="
  docker build -f "Dockerfile.$v" -t "hello-app:$v" .
done

echo ""
echo "================ IMAGE SIZES ================="
printf "%-22s %s\n" "VERSION" "SIZE (MB)"
for v in "${VARIANTS[@]}"; do
  bytes=$(docker image inspect "hello-app:$v" --format '{{.Size}}')
  printf "%-22s %s\n" "$v" "$((bytes / 1024 / 1024))"
done
echo "=============================================="

# When running in GitHub Actions, also show the table on the run's Summary page
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "## Docker image sizes"
    echo ""
    echo "| Version | Size (MB) |"
    echo "|---|---|"
    for v in "${VARIANTS[@]}"; do
      bytes=$(docker image inspect "hello-app:$v" --format '{{.Size}}')
      echo "| $v | $((bytes / 1024 / 1024)) |"
    done
  } >> "$GITHUB_STEP_SUMMARY"
fi

if [[ "${1:-}" == "--test" ]]; then
  echo ""
  echo "Starting each image and calling it..."
  port=8081
  for v in "${VARIANTS[@]}"; do
    cid=$(docker run -d -p "$port:8080" "hello-app:$v")
    ok="no"
    for _ in $(seq 1 30); do
      if curl -sf "http://localhost:$port/" >/dev/null; then ok="yes"; break; fi
      sleep 1
    done
    printf "%-22s responds: %s   %s\n" "$v" "$ok" "$(curl -s "http://localhost:$port/" || true)"
    docker rm -f "$cid" >/dev/null
    port=$((port + 1))
  done
fi
