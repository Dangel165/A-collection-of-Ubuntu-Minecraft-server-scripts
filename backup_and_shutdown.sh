#!/bin/bash

# 설정
SERVER_DIR=
BACKUP_DIR=
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/minecraft_backup_$DATE.tar.gz"
RCON_HOST=                   # 로컬 IP 주소
RCON_PORT=
RCON_PASSWORD=

# 백업 디렉토리 확인 (없으면 생성)
mkdir -p "$BACKUP_DIR"

# 서버가 작동 중인지 확인 (스크린 세션 이름: minecraft_server)
if screen -list | grep -q "minecraft_server"; then
    echo "서버 작동 중, 백업 시작..."

    # 백업할 월드 목록
    WORLDS=("world" "world_nether" "world_the_end")

    # 서버 켜진 상태에서도 안정적으로 백업
    tar --warning=no-file-changed -czf "$BACKUP_FILE" -C "$SERVER_DIR" "${WORLDS[@]}"

    echo "백업 완료: $BACKUP_FILE"

    # 1분 후 서버 종료 안내
    echo "1분 후 서버를 종료합니다..."
    mcrcon -H $RCON_HOST -P $RCON_PORT -p $RCON_PASSWORD "say §e[서버] 1분 후 서버가 자동으로 종료됩니다. 잠시만 기다려주세요!"
    sleep 60

    # 서버 종료
    echo "서버 종료 중..."
    mcrcon -H $RCON_HOST -P $RCON_PORT -p $RCON_PASSWORD "stop"

    # 스크린 세션 종료
    echo "스크린 세션 종료 중..."
    screen -S minecraft_server -X quit
else
    echo "서버가 작동하지 않습니다."
fi



