#!/bin/bash
# Hamachi 자동 로그인 스크립트

# Hamachi 데몬 시작
sudo systemctl start logmein-hamachi

# 잠시 대기: 데몬이 완전히 올라올 시간
sleep 5

# CLI 로그인
sudo /usr/bin/hamachi login

# 계정 (attach 뒤에 계정입력)
sudo /usr/bin/hamachi attach 

# 닉네임 설정 (데몬 준비 후) (set-nick 뒤에 비번입력)
sleep 2
sudo /usr/bin/hamachi set-nick 

# Hamachi 상태 확인
sudo /usr/bin/hamachi list


