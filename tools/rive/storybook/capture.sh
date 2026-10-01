#!/bin/bash
# capture.sh — render every stage x mood x pct frame for strips/boards/mp4.
# Usage: ./capture.sh [outdir]  (default design/animations/rive/storybook)
set -u
export PATH="$HOME/.rive/bin:$PATH"
PROJ="tools/rive/storybook"
OUT="${1:-design/animations/rive/storybook}"
FR="$OUT/frames"
mkdir -p "$FR"

dur_of() {
  case "$1" in
    idle) echo 180;; happy) echo 72;; eat) echo 108;; sleepy) echo 240;;
    surprised) echo 48;; proud) echo 72;; evolve) echo 90;;
  esac
}
data_of() {
  case "$1" in
    evolve) echo "evolve=1";; eat) echo "mood=eating";; *) echo "mood=$1";;
  esac
}
MOODS="idle happy eat sleepy surprised proud evolve"
PCTS="0 15 30 45 60 75 90"

# strips: stages 1-4 x moods x pcts
> "$FR/strip_jobs.txt"
for s in 1 2 3 4; do
  for m in $MOODS; do
    d=$(dur_of "$m")
    for p in $PCTS; do
      f=$(python3 -c "print(max(1, round($p*$d/100)))")
      echo "$s|$m|$p|$f|$(data_of "$m")|$FR/s${s}_${m}_${p}.png"
    done
  done
done >> "$FR/strip_jobs.txt"

# mp4: stage 3, every 2nd frame per mood
> "$FR/mp4_jobs.txt"
for m in $MOODS; do
  d=$(dur_of "$m")
  f=1
  while [ "$f" -le "$d" ]; do
    printf '3|%s|%s|%s|%s|%s\n' "$m" "$f" "$f" "$(data_of "$m")" "$FR/mp3_${m}_$(printf %03d "$f").png"
    f=$((f+2))
  done
done >> "$FR/mp4_jobs.txt"

# skins x accessories spot checks (stage 3 idle)
> "$FR/skin_jobs.txt"
for sk in sunny berry sky mint; do
  case $sk in
    sunny) c="FFFFD93D,FFFFF1B8,FFF2A900,FFF2B705";;
    berry) c="FFFF9EBB,FFFFE1EA,FFE56B8C,FFEE6E96";;
    sky)   c="FF8EC9FF,FFE2F1FF,FF5A9AE6,FF64A3E8";;
    mint)  c="FF8EE3B5,FFDDF8E8,FF4FBF84,FF54C184";;
  esac
  b=$(echo "$c" | cut -d, -f1); be=$(echo "$c" | cut -d, -f2)
  w=$(echo "$c" | cut -d, -f3); sh=$(echo "$c" | cut -d, -f4)
  base="bodyColor=$b&bellyColor=$be&wingColor=$w&shadeColor=$sh"
  echo "3|idle|0|1|$base|$FR/skin_${sk}.png" >> "$FR/skin_jobs.txt"
  for a in none bow cap scarf glasses; do
    extra=""
    case $a in bow) extra="&accBow=1";; cap) extra="&accCap=1";; scarf) extra="&accScarf=1";; glasses) extra="&accGlasses=1";; esac
    echo "3|idle|0|1|$base$extra|$FR/skinacc_${sk}_${a}.png" >> "$FR/skin_jobs.txt"
  done
done

run_one() {
  line="$1"
  s=$(echo "$line" | cut -d'|' -f1)
  adv=$(echo "$line" | cut -d'|' -f4)
  data=$(echo "$line" | cut -d'|' -f5)
  out=$(echo "$line" | cut -d'|' -f6)
  [ -f "$out" ] && return 0
  dargs=""
  old="$IFS"; IFS='&'
  # shellcheck disable=SC2162
  for p in $data; do dargs="$dargs --data=$p"; done
  IFS="$old"
  # shellcheck disable=SC2086
  rive "$PROJ" --artboard="Stage$s" $dargs --advance="$adv" --screenshot="$out" --quiet 2>/dev/null
}
export -f run_one
export PROJ

cat "$FR/strip_jobs.txt" "$FR/mp4_jobs.txt" "$FR/skin_jobs.txt" | xargs -P 4 -I{} bash -c 'run_one "{}"'
echo "captures done: $(ls "$FR"/*.png | wc -l) frames"
