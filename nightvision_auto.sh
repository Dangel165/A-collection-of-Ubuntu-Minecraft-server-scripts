#!/bin/bash

# ================================
# RCON 연결 정보를 여기에 입력합니다.
# ================================
RCON_HOST="192.168.219.100" # 서버 IP 주소
RCON_PORT="25575"          # RCON 포트 번호
RCON_PASSWORD="9135"       # RCON 비밀번호

# ================================
# 플레이어 목록 
# 야간투시 효과를 부여할 플레이어 닉네임 목록입니다.
# ================================
PLAYER_LIST=(
    
)

# ================================
# 🚀 함수: 현재 접속 중인 플레이어 목록 가져오기
# ================================
get_online_players() {
    # 'list' 명령어 실행 후, 접속 중인 플레이어 목록만 추출하고 공백으로 구분된 문자열로 만듭니다.
    local ONLINE_STRING
    ONLINE_STRING=$(mcrcon -H "$RCON_HOST" -P "$RCON_PORT" -p "$RCON_PASSWORD" "list" 2>/dev/null \
    | grep "There are" \
    | cut -d ':' -f 2- \
    | tr -d '[:space:]\r' \
    | tr ',' ' ' \
    | xargs) || echo "" # 실패 시 빈 문자열 반환

    echo "$ONLINE_STRING"
}

# ================================
# 5초마다 접속 중인 플레이어에게 나이트 비전 효과를 새로고침합니다.
# ================================
while true; do

    echo "[INFO] 야간 시야 효과 확인 루프를 시작합니다." 

    # 현재 서버에 접속 중인 플레이어 목록을 하나의 문자열로 가져옵니다.
    ONLINE_PLAYERS=$(get_online_players)
    
    # ----------------
    # 1. 온라인 플레이어에게만 나이트 비전 효과 적용
    # ----------------
    APPLIED_COUNT=0
    TOTAL_LIST_COUNT=${#PLAYER_LIST[@]}
    
    echo "[INFO] 등록된 $TOTAL_LIST_COUNT명의 플레이어를 접속 목록과 비교합니다." 

    for PLAYER in "${PLAYER_LIST[@]}"; do
        
        # 플레이어 이름의 공백을 제거하고 처리합니다.
        PROCESSED_PLAYER=$(echo "$PLAYER" | tr -d '[:space:]' | xargs)
        
        # **접속 확인:** 접속 중인 플레이어 문자열에 현재 플레이어 이름이 포함되어 있는지 확인합니다.
        if [[ "$ONLINE_PLAYERS" == *"$PROCESSED_PLAYER"* ]]; then
            
            # 접속 중인 플레이어에게 나이트 비전 효과(1,000,000틱 = 약 555일)를 적용하고 입자 효과를 숨깁니다(true).
            echo "[DEBUG] 접속 중인 플레이어에게 효과 적용: $PROCESSED_PLAYER"
            
            mcrcon -H "$RCON_HOST" -P "$RCON_PORT" -p "$RCON_PASSWORD" "execute as $PROCESSED_PLAYER run effect give @s minecraft:night_vision 1000000 1 true" >/dev/null 2>&1 || true
            APPLIED_COUNT=$((APPLIED_COUNT + 1))
        
        # else: 접속 중이 아니면 효과를 적용하지 않고 넘어갑니다.
        fi
    done
    
    echo "[SUCCESS] 나이트 비전 새로고침 완료. 총 $APPLIED_COUNT 명에게 적용되었습니다."

    # 5초 대기
    sleep 5
done