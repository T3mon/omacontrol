NIGHTLIGHT_CONF="${OMACONTROL_HYPRSUNSET_CONF:-$HOME/.config/hypr/hyprsunset.conf}"
NIGHTLIGHT_STOCK="${OMARCHY_PATH:-/usr/share/omarchy}/config/hypr/hyprsunset.conf"
NIGHTLIGHT_BEGIN="# >>> omacontrol night light"
NIGHTLIGHT_END="# <<< omacontrol night light"

nightlight_schedule_state() {
  jq -c '(.nightlight // {}) as $n | {
    enabled: (if ($n | has("enabled")) then $n.enabled else false end),
    on: ($n.on // "20:00"),
    off: ($n.off // "07:00"),
    temperature: ($n.temperature // 4000),
    gradual: (if ($n | has("gradual")) then $n.gradual else false end),
    deep: ($n.deep // 3000),
    ramp: ($n.ramp // 180)
  }' <<<"$(read_store)"
}

nightlight_schedule_get() {
  jq -r --arg k "$1" '.[$k] | tostring' <<<"$(nightlight_schedule_state)"
}

nightlight_valid_time() {
  [[ $1 =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]
}

nightlight_schedule_set() {
  local field=$1 value=$2 was
  was=$(nightlight_schedule_get enabled)
  case $field in
    schedule)
      [[ $value == true || $value == false ]] || die "'$value' is not true or false"
      note_store '.nightlight = ((.nightlight // {}) | .enabled = ($v == "true"))' --arg v "$value" ;;
    on|off)
      nightlight_valid_time "$value" || die "'$value' is not a time like 20:00"
      note_store '.nightlight = ((.nightlight // {}) | .[$f] = $v)' --arg f "$field" --arg v "$value" ;;
    temp)
      [[ $value =~ ^[0-9]+$ ]] && (( value >= 1000 && value <= 6500 )) \
        || die "'$value' is not a temperature between 1000 and 6500"
      note_store '.nightlight = ((.nightlight // {}) | .temperature = ($v | tonumber))' --arg v "$value" ;;
    gradual)
      [[ $value == true || $value == false ]] || die "'$value' is not true or false"
      note_store '.nightlight = ((.nightlight // {}) | .gradual = ($v == "true"))' --arg v "$value" ;;
    deep)
      [[ $value =~ ^[0-9]+$ ]] && (( value >= 1000 && value <= 6500 )) \
        || die "'$value' is not a temperature between 1000 and 6500"
      note_store '.nightlight = ((.nightlight // {}) | .deep = ($v | tonumber))' --arg v "$value" ;;
    ramp)
      [[ $value =~ ^[0-9]+$ ]] && (( value >= 10 && value <= 720 )) \
        || die "'$value' is not a number of minutes between 10 and 720"
      note_store '.nightlight = ((.nightlight // {}) | .ramp = ($v | tonumber))' --arg v "$value" ;;
    *) die "unknown night light field '$field'" ;;
  esac
  nightlight_render || die "could not write $NIGHTLIGHT_CONF"
  [[ $(nightlight_schedule_get enabled) == "$was" ]] || render_managed
  nightlight_restart
}

nightlight_outside_block() {
  read_file "$NIGHTLIGHT_CONF" 2>/dev/null | awk -v b="$NIGHTLIGHT_BEGIN" -v e="$NIGHTLIGHT_END" '
    $0 == b { skip = 1; next }
    $0 == e { skip = 0; next }
    !skip'
}

# Omarchy's stock file holds an identity profile at 07:00 that would switch a
# later morning time off early, so only an untouched stock copy is replaced;
# anything the user wrote stays and the block goes beneath it.
nightlight_render() {
  local state enabled on off tp gradual deep ramp outside stock
  state=$(nightlight_schedule_state)
  enabled=$(jq -r .enabled <<<"$state")
  on=$(jq -r .on <<<"$state")
  off=$(jq -r .off <<<"$state")
  tp=$(jq -r .temperature <<<"$state")
  gradual=$(jq -r .gradual <<<"$state")
  deep=$(jq -r .deep <<<"$state")
  ramp=$(jq -r .ramp <<<"$state")
  outside=$(nightlight_outside_block)
  stock=$(read_file "$NIGHTLIGHT_STOCK" 2>/dev/null)

  if [[ $enabled != true ]]; then
    if [[ -z ${outside//[[:space:]]/} && -n $stock ]]; then
      printf '%s\n' "$stock" | write_file "$NIGHTLIGHT_CONF"
    else
      printf '%s\n' "$outside" | write_file "$NIGHTLIGHT_CONF"
    fi
    return
  fi

  [[ $outside == "$stock" ]] && outside=""
  {
    [[ -n ${outside//[[:space:]]/} ]] && printf '%s\n\n' "$outside"
    echo "$NIGHTLIGHT_BEGIN"
    echo "profile {"
    echo "    time = $off"
    echo "    identity = true"
    echo "}"
    nightlight_profiles "$on" "$off" "$tp" "$gradual" "$deep" "$ramp"
    echo "$NIGHTLIGHT_END"
  } | write_file "$NIGHTLIGHT_CONF"
}

# hyprsunset jumps between profiles rather than fading, so a gradual night is
# a step every ten minutes. The ramp stops short of the off time, or the last
# step would land on top of the morning's identity profile.
nightlight_profiles() {
  local on=$1 off=$2 start=$3 gradual=$4 deep=$5 ramp=$6
  local on_min off_min window steps i at t
  on_min=$(( 10#${on%%:*} * 60 + 10#${on##*:} ))
  off_min=$(( 10#${off%%:*} * 60 + 10#${off##*:} ))
  window=$(( (off_min - on_min + 1440) % 1440 ))
  (( window == 0 )) && window=1440
  if [[ $gradual == true ]]; then
    (( ramp > window - 10 )) && ramp=$(( window - 10 ))
    (( ramp < 10 )) && ramp=10
    steps=$(( ramp / 10 ))
  else
    steps=0
  fi
  for (( i = 0; i <= steps; i++ )); do
    at=$(( (on_min + i * 10) % 1440 ))
    if (( steps == 0 )); then
      t=$start
    else
      t=$(( start + (deep - start) * i / steps ))
      t=$(( (t + 25) / 50 * 50 ))
    fi
    echo ""
    echo "profile {"
    printf '    time = %02d:%02d\n' $(( at / 60 )) $(( at % 60 ))
    echo "    temperature = $t"
    echo "}"
  done
}

render_nightlight_lua() {
  [[ $(nightlight_schedule_get enabled) == true ]] || return 0
  echo ""
  echo "-- Night light schedule: hyprsunset applies it, so it has to run from login."
  echo 'o.launch_on_start("hyprsunset")'
}

# hyprsunset reads its profiles only at start-up, so a new schedule needs a
# fresh process; the bar's indicator never polls and has to be told to look.
nightlight_restart() {
  local i
  pkill -x hyprsunset >/dev/null 2>&1
  for i in {1..10}; do
    pgrep -x hyprsunset >/dev/null 2>&1 || break
    sleep 0.1
  done
  setsid -f uwsm-app -- hyprsunset >/dev/null 2>&1 </dev/null
  for i in {1..20}; do
    hyprctl hyprsunset temperature >/dev/null 2>&1 && break
    sleep 0.1
  done
  omarchy-shell -q nightlight refresh >/dev/null 2>&1
  return 0
}
