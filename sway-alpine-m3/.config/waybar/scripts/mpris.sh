#!/bin/sh
# Waybar MPRIS module — JSON output with full tooltip
# Depends: playerctl

usec_to_time() {
    _total="$1"
    [ -z "$_total" ] && { printf "0:00"; return; }
    _total=$(( _total + 0 )) 2>/dev/null || { printf "0:00"; return; }
    [ "$_total" -le 0 ] 2>/dev/null && { printf "0:00"; return; }
    _secs=$(( _total / 1000000 ))
    _m=$(( _secs / 60 ))
    _s=$(( _secs % 60 ))
    printf "%d:%02d" "$_m" "$_s"
}

escape_json() {
    printf '%s' "$1" | sed \
        -e 's/\\/\\\\/g' \
        -e 's/"/\\"/g' \
        -e 's/'"$(printf '\t')"'/\\t/g' \
        -e 's/'"$(printf '\r')"'/\\r/g' \
        | awk '{printf "%s\\n", $0}' | sed '$ s/\\n$//'
}

title=$(playerctl metadata --format '{{title}}' 2>/dev/null)
artist=$(playerctl metadata --format '{{artist}}' 2>/dev/null)
album=$(playerctl metadata --format '{{album}}' 2>/dev/null)
player=$(playerctl metadata --format '{{playerName}}' 2>/dev/null)
status=$(playerctl status 2>/dev/null)
length_usec=$(playerctl metadata --format '{{mpris:length}}' 2>/dev/null)

_pos_raw=$(playerctl position 2>/dev/null)
_pos_int=0
if [ -n "$_pos_raw" ]; then
    _pos_int=$(printf '%s' "$_pos_raw" | cut -d. -f1 2>/dev/null)
    _pos_int=$(( _pos_int + 0 )) 2>/dev/null
fi
pos_usec=$(( _pos_int * 1000000 )) 2>/dev/null

if [ -z "$title" ]; then
    printf '{"text":"󰝚","tooltip":"No media playing","class":"stopped"}\n'
    exit 0
fi

icon="󰝚"
case "$status" in
    Playing) icon="󰎈" ;;
    Paused)  icon="󰏤" ;;
esac

display_text=$(printf '%s' "${icon} ${title}${artist:+" - ${artist}"}" \
    | awk '{if(length>50) print substr($0,1,47)"..."; else print}')

_tooltip="Status: ${status}
Title:  ${title}"
[ -n "$artist" ] && _tooltip="${_tooltip}
Artist: ${artist}"
[ -n "$album" ] && _tooltip="${_tooltip}
Album:  ${album}"
[ -n "$player" ] && _tooltip="${_tooltip}
Player: ${player}"

if [ "$pos_usec" -gt 0 ] 2>/dev/null && [ -n "$length_usec" ] && [ "$length_usec" -gt 0 ] 2>/dev/null; then
    _now=$(usec_to_time "$pos_usec")
    _total=$(usec_to_time "$length_usec")
    _tooltip="${_tooltip}
${_now} / ${_total}"
fi

tooltip_esc=$(escape_json "$_tooltip")
_class=$(printf '%s' "$status" | tr '[:upper:]' '[:lower:]')

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
    "$display_text" "$tooltip_esc" "$_class"
