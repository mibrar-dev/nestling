#!/bin/bash
# run_wave.sh ID [ID ...]
# Runs screen loops in parallel, one per simulator in docs/screens/SIMS.txt,
# never running two screens of the same feature at once (they share files).
# bash 3.2 compatible (no wait -n, no associative arrays).
MAIN="$(cd "$(dirname "$0")/../.." && pwd)"
SIMS=($(grep -v '^#' "$MAIN/docs/screens/SIMS.txt"))
QUEUE=("$@")
RUN_DIR="$MAIN/docs/screens/_status/run"; mkdir -p "$RUN_DIR"; rm -f "$RUN_DIR"/*
feature_of() { awk -F'\t' -v id="$1" '$1==id{print $4}' "$MAIN/docs/screens/SCREENS.tsv"; }
busy_feature() { grep -lx "$1" "$RUN_DIR"/*.feature >/dev/null 2>&1; }
while [ ${#QUEUE[@]} -gt 0 ] || ls "$RUN_DIR"/*.pid >/dev/null 2>&1; do
  # reap finished loops
  for p in "$RUN_DIR"/*.pid; do [ -e "$p" ] || continue
    if ! kill -0 "$(cat "$p")" 2>/dev/null; then b="${p%.pid}"; rm -f "$p" "$b.feature" "$b.sim"; fi; done
  # start new loops on free simulators
  for sim in "${SIMS[@]}"; do
    grep -lx "$sim" "$RUN_DIR"/*.sim >/dev/null 2>&1 && continue
    [ ${#QUEUE[@]} -eq 0 ] && break
    pick=-1
    for i in "${!QUEUE[@]}"; do f=$(feature_of "${QUEUE[$i]}"); busy_feature "$f" || { pick=$i; break; }; done
    [ $pick -lt 0 ] && break
    id="${QUEUE[$pick]}"; QUEUE=("${QUEUE[@]:0:$pick}" "${QUEUE[@]:$((pick+1))}")
    bash "$MAIN/tools/screens/loop.sh" "$id" "$sim" > "$MAIN/docs/screens/_status/$id.loop.log" 2>&1 &
    echo $! > "$RUN_DIR/$id.pid"; feature_of "$id" > "$RUN_DIR/$id.feature"; echo "$sim" > "$RUN_DIR/$id.sim"
  done
  sleep 20
done
echo "wave done: $*"
