#!/bin/bash
# watch.sh — emits new events + STALL warnings (log idle > 15 min while running). bash 3.2 safe.
ST="$(cd "$(dirname "$0")/../.." && pwd)/docs/screens/_status"; EV="$ST/events.log"; touch "$EV"
seen=$(wc -l < "$EV" | tr -d ' ')
while true; do
  n=$(wc -l < "$EV" | tr -d ' '); if [ "$n" -gt "$seen" ]; then sed -n "$((seen+1)),${n}p" "$EV"; seen=$n; fi
  now=$(date +%s)
  for s in "$ST"/*.status; do [ -e "$s" ] || continue; name=$(basename "$s" .status); l="$ST/$name.log"
    if grep -qE "START|RETRY" "$s" && [ -f "$l" ]; then
      age=$(( now - $(stat -f %m "$l") ))
      if [ $age -gt 900 ] && [ ! -e "$ST/.$name.warned" ]; then echo "$(date +%H:%M:%S) STALL $name idle=${age}s"; touch "$ST/.$name.warned"; fi
      [ $age -le 900 ] && rm -f "$ST/.$name.warned"
    fi; done
  # Disk guard: flutter test fails with "No space left" when the disk fills (5 Oct 04:10).
  free=$(df -g / | awk 'NR==2{print $4}')
  if [ "${free:-99}" -lt 8 ]; then [ -e "$ST/.disk.warned" ] || { echo "$(date +%H:%M:%S) DISK_LOW free=${free}G (rm -rf merged worktrees' app/build)"; touch "$ST/.disk.warned"; }; else rm -f "$ST/.disk.warned"; fi
  sleep 30
done
