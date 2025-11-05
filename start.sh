#!/bin/bash

# 서버 디렉토리로 이동(경로 입력)
cd /home/***/minecraft || exit 1

# 스크린 세션 이름
SCREEN_NAME="minecraft_server"

# 기존 스크린 세션이 있으면 종료
if screen -list | grep -q "$SCREEN_NAME"; then
    echo "Existing screen session found. Quitting..."
    screen -S "$SCREEN_NAME" -X quit
    sleep 2
fi

# JVM 옵션: user_jvm_args.txt 사용
# RAM 직접 지정도 가능: -Xms10G -Xmx12G

# 새로운 스크린 세션에서 서버 실행
# -L 옵션: 로그 기록
# -dmS: 백그라운드 실행
screen -L -Logfile "$SCREEN_NAME.log" -dmS "$SCREEN_NAME" ./run.sh nogui

# 대기 후 확인
sleep 2

# 실행 메시지
echo "Minecraft 1.20.1 Forge server has been started in screen session '$SCREEN_NAME'."
echo "Use 'screen -r $SCREEN_NAME' to attach."
