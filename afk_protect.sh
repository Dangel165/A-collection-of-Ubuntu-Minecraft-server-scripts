#!/bin/bash

LOG_FILE=
RCON_ENABLED=true
RCON_HOST=
RCON_PORT=
RCON_PASSWORD=

STATE_FILE=
LOG_OUT=

touch "$STATE_FILE"

SCREEN_NAME=$(screen -ls | grep -Eo '[0-9]+\.minecraft.*' | head -n1 | cut -d. -f2)

if [[ -z "$SCREEN_NAME" ]]; then
    echo "[ERROR] Minecraft server screen session not found." | tee -a "$LOG_OUT"
    exit 1
fi

echo "[INFO] Detected screen session: $SCREEN_NAME" | tee -a "$LOG_OUT"
echo "[INFO] AFK protection script started: $(date)" | tee -a "$LOG_OUT"

send_cmd() {
    local cmd="$1"
    if [[ "$RCON_ENABLED" == true ]]; then
        mcrcon -H "$RCON_HOST" -P "$RCON_PORT" -p "$RCON_PASSWORD" "$cmd" >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            echo "[WARN] RCON failed �� using screen instead: $cmd" | tee -a "$LOG_OUT"
            screen -S "$SCREEN_NAME" -p 0 -X stuff "$cmd$(printf '\r')"
        fi
    else
        screen -S "$SCREEN_NAME" -p 0 -X stuff "$cmd$(printf '\r')"
    fi
}

apply_protection() {
    local player="$1"
    if grep -q "^$player$" "$STATE_FILE"; then
        return
    fi

    echo "$player" >> "$STATE_FILE"
    send_cmd "say [AFK Protect] $player is now AFK."
    send_cmd "effect give $player minecraft:resistance 999999 255 true"
    send_cmd "effect give $player minecraft:regeneration 999999 255 true"
    send_cmd "effect give $player minecraft:water_breathing 999999 1 true"
    send_cmd "effect give $player minecraft:fire_resistance 999999 1 true"

    echo "[$(date)] AFK protection applied: $player" >> "$LOG_OUT"
}

remove_protection() {
    local player="$1"
    if grep -q "^$player$" "$STATE_FILE"; then
        sed -i "/^$player$/d" "$STATE_FILE"
        send_cmd "say [AFK Protect] $player is no longer AFK."
        send_cmd "effect clear $player"
        echo "[$(date)] AFK protection removed: $player" >> "$LOG_OUT"
    fi
}

tail -Fn0 "$LOG_FILE" | while read -r line; do
    if [[ "$line" =~ "is now AFK" ]]; then
        player=$(echo "$line" | grep -oP '([A-Za-z0-9_]+) is now AFK' | awk '{print $1}')
        [[ -n "$player" ]] && apply_protection "$player"
    fi

    if [[ "$line" =~ "is no longer AFK" ]]; then
        player=$(echo "$line" | grep -oP '([A-Za-z0-9_]+) is no longer AFK' | awk '{print $1}')
        [[ -n "$player" ]] && remove_protection "$player"
    fi
done
