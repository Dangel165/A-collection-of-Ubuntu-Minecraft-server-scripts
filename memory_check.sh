#!/bin/bash

# 서버 메모리 사용량 확인 함수
check_memory() {
    total_memory=$(free -m | awk '/Mem:/ {printf "%.1f", $2/1024}')   # 총 메모리 GB
    used_memory=$(free -m | awk '/Mem:/ {printf "%.1f", $3/1024}')    # 사용 중 메모리 GB
    usage_percent=$(awk "BEGIN {printf \"%.1f\", ($used_memory/$total_memory)*100}")  # 사용률 %
    echo "${used_memory}GB / ${total_memory}GB (사용률: ${usage_percent}%)"
}

# 서버 콘솔에 메시지 전송 (자동으로 minecraft_server 세션 선택)
send_to_console() {
    message="$1"
    # 실행 중인 세션 중 이름에 minecraft_server가 들어간 세션 자동 선택
    SESSION_NAME=$(screen -ls | grep minecraft_server | awk '{print $1}' | sed 's/^[0-9]*\.//')
    
    if [ -n "$SESSION_NAME" ]; then
        # 숫자 제거 후 메시지 전송
        screen -S "${SESSION_NAME}" -X stuff "say ${message}\n"
    else
        echo "실행 중인 minecraft_server 스크린 세션이 없습니다."
    fi
}

# 메모리 사용량 확인 후 서버 채팅에 한국어로 출력
memory_usage=$(check_memory)
send_to_console "메모리 사용량: ${memory_usage}"