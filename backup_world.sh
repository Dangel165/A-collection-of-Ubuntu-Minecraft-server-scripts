#!/bin/bash

# ==============================
# 설정 변수
# ==============================
WORLD_PATH=                       # 마인크래프트 서버 월드 경로
BACKUP_PATH="$WORLD_PATH/backups" # 백업 파일이 저장될 경로
LOG_FILE="$BACKUP_PATH/backup_log.txt" # 백업 과정 로그 파일
SCREEN_NAME="minecraft_server" # 마인크래프트 서버가 실행 중인 screen 세션 이름
DATE=$(date +'%Y-%m-%d_%H-%M-%S') # 현재 날짜와 시간 (백업 파일명에 사용)

# ==============================
# 경로 유효성 확인
# ==============================
if [[ ! -d "$WORLD_PATH" ]]; then
    echo "[$(date)] ERROR: World path not found: $WORLD_PATH" | tee -a "$LOG_FILE"
    exit 1
fi

mkdir -p "$BACKUP_PATH"
echo "[$(date)] Backup started..." | tee -a "$LOG_FILE"

# ==============================
# 서버 저장 기능 비활성화
# ==============================
screen -S "$SCREEN_NAME" -p 0 -X stuff "say [Server] Starting world backup...^M" # 서버 채팅에 백업 시작 메시지 출력
screen -S "$SCREEN_NAME" -p 0 -X stuff "save-off^M" # 자동 저장 기능 비활성화
screen -S "$SCREEN_NAME" -p 0 -X stuff "save-all^M" # 수동으로 현재 상태 저장

# 5초 대기 (저장이 완료될 시간을 확보)
sleep 5

# ==============================
# 백업할 월드 목록 구성 (필요한 것만)
# ==============================
WORLD_FILES=("world") # 기본 오버월드
[[ -d "$WORLD_PATH/world_nether" ]] && WORLD_FILES+=("world_nether") # 네더 월드가 있으면 추가
[[ -d "$WORLD_PATH/world_the_end" ]] && WORLD_FILES+=("world_the_end") # 엔더 월드가 있으면 추가

BACKUP_FILE="$BACKUP_PATH/minecraft_all_worlds_$DATE.tar.gz"
echo "[$(date)] Backing up all worlds into one file: ${WORLD_FILES[*]}" | tee -a "$LOG_FILE"

# ==============================
# 백업 실행 (tar 압축)
# ==============================
tar -czf "$BACKUP_FILE" -C "$WORLD_PATH" "${WORLD_FILES[@]}" # 월드 디렉토리들을 .tar.gz로 압축
echo "[$(date)] Backup completed: $BACKUP_FILE" | tee -a "$LOG_FILE"

# ==============================
# 서버 저장 기능 다시 활성화
# ==============================
screen -S "$SCREEN_NAME" -p 0 -X stuff "save-on^M" # 자동 저장 기능 재활성화
screen -S "$SCREEN_NAME" -p 0 -X stuff "say [Server] World backup completed successfully!^M" # 서버 채팅에 백업 완료 메시지 출력

# ==============================
# 오래된 백업 파일 정리 (2일 이상)
# ==============================
find "$BACKUP_PATH" -type f -name "*.tar.gz" -mtime +2 -exec rm -f {} \; # 2일이 넘은 .tar.gz 파일 삭제
echo "[$(date)] Old backups (2+ days) removed." | tee -a "$LOG_FILE"

echo "[$(date)] Backup process completed successfully!" | tee -a "$LOG_FILE"