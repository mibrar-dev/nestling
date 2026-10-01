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
  sleep 30
done
