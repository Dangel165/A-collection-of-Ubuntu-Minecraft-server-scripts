#!/bin/bash

# ================================
# 설정 
# ================================
LOG_FILE="" # Minecraft 서버 로그 파일 경로
RCON_ENABLED=true                          # RCON 사용 여부 (true/false)
RCON_HOST=""                               # RCON 서버 IP
RCON_PORT=                                 # RCON 포트
RCON_PASSWORD=""                           # RCON 비밀번호

# 현재 AFK 상태인 플레이어 목록을 저장하는 파일
STATE_FILE=""
# 이 스크립트 자체의 로그를 저장하는 파일
LOG_OUT=""

# 상태 파일이 없으면 생성합니다.
touch "$STATE_FILE"

# ================================
#  Screen 세션 감지
# ================================
# 'minecraft' 서버가 실행 중인 screen 세션 이름을 찾습니다.
SCREEN_NAME=$(screen -ls | grep -Eo '[0-9]+\.minecraft.*' | head -n1 | cut -d. -f2)

if [[ -z "$SCREEN_NAME" ]]; then
    echo "[ERROR] Minecraft 서버 screen 세션을 찾을 수 없습니다." | tee -a "$LOG_OUT"
    exit 1
fi

echo "[INFO] 감지된 screen 세션: $SCREEN_NAME" | tee -a "$LOG_OUT"
echo "[INFO] AFK 보호 스크립트 시작됨: $(date)" | tee -a "$LOG_OUT"

# ================================
#  함수 
# ================================

# 함수: 서버에 명령어 전송 (RCON 우선 사용, 실패 시 Screen으로 대체)
send_cmd() {
    local cmd="$1"
    if [[ "$RCON_ENABLED" == true ]]; then
        # 1. RCON 시도
        mcrcon -H "$RCON_HOST" -P "$RCON_PORT" -p "$RCON_PASSWORD" "$cmd" >/dev/null 2>&1
        # RCON 실패 여부 확인 (종료 코드가 0이 아니면 실패)
        if [[ $? -ne 0 ]]; then
            echo "[WARN] RCON 실패 ⚠️ Screen을 대신 사용: $cmd" | tee -a "$LOG_OUT"
            # 2. Screen 사용 (명령어 입력 + 엔터)
            screen -S "$SCREEN_NAME" -p 0 -X stuff "$cmd$(printf '\r')"
        fi
    else
        # RCON 비활성화 시, Screen 직접 사용
        screen -S "$SCREEN_NAME" -p 0 -X stuff "$cmd$(printf '\r')"
    fi
}

# 함수: AFK 보호 적용 (플레이어를 크리에이티브 모드로 변경)
apply_protection() {
    local player="$1"
    # 이미 AFK로 표시된 플레이어인지 확인
    if grep -q "^$player$" "$STATE_FILE"; then
        return
    fi

    # 플레이어를 AFK로 표시하고 게임 모드 적용
    echo "$player" >> "$STATE_FILE"
    send_cmd "say [AFK Protect] $player 님이 AFK 상태가 되었습니다."
    send_cmd "gamemode creative $player" # <--- 보호 모드: 크리에이티브로 변경

    echo "[$(date)] AFK 보호 적용됨: $player" >> "$LOG_OUT"
}

# 함수: AFK 보호 해제 (플레이어를 서바이벌 모드로 복구)
remove_protection() {
    local player="$1"
    # 현재 AFK로 표시된 플레이어인지 확인
    if grep -q "^$player$" "$STATE_FILE"; then
        # 상태 파일에서 플레이어 제거 및 게임 모드 복구
        sed -i "/^$player$/d" "$STATE_FILE"
        send_cmd "say [AFK Protect] $player 님이 AFK 상태를 해제했습니다."
        send_cmd "gamemode survival $player" # <--- 보호 해제: 서바이벌로 복구
        echo "[$(date)] AFK 보호 해제됨: $player" >> "$LOG_OUT"
    fi
}

# ================================
#  메인 루프 (로그 파일 실시간 추적)
# ================================

# 로그 파일($LOG_FILE)을 실시간으로 추적하고 라인별로 읽습니다.
tail -Fn0 "$LOG_FILE" | while read -r line; do
    
    # AFK 메시지 확인 (예: 'dangel is now AFK'와 같은 문자열)
    if [[ "$line" =~ "is now AFK" ]]; then
        # 플레이어 이름 추출 (표준 사용자 이름 형식 [A-Za-z0-9_] 가정)
        # grep -oP: Perl 정규식으로 매칭되는 부분만 출력
        player=$(echo "$line" | grep -oP '([A-Za-z0-9_]+) is now AFK' | awk '{print $1}')
        # 플레이어 이름이 추출되었다면 보호 적용 함수 호출
        [[ -n "$player" ]] && apply_protection "$player"
    fi

    # AFK 해제 메시지 확인 (예: 'dangel is no longer AFK')
    if [[ "$line" =~ "is no longer AFK" ]]; then
        # 플레이어 이름 추출
        player=$(echo "$line" | grep -oP '([A-Za-z0-9_]+) is no longer AFK' | awk '{print $1}')
        # 플레이어 이름이 추출되었다면 보호 해제 함수 호출
        [[ -n "$player" ]] && remove_protection "$player"
    fi
done