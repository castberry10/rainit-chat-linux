#!/bin/bash

# 오류 발생시 스크립트 중단
set -e

# sudo 권한 체크
if [ "$EUID" -ne 0 ]; then 
    echo "🔒 이 스크립트는 sudo 권한이 필요합니다."
    echo "sudo ./uninstall-rainit.sh 로 다시 실행해주세요."
    exit 1
fi

# 실제 사용자의 홈 디렉토리 경로 설정
REAL_USER=$SUDO_USER
REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
INSTALL_DIR="${REAL_HOME}/.rainit"

echo "🗑️  Rainit 제거를 시작합니다..."

# 실행 중인 프로세스 종료
echo "🔍 실행 중인 Rainit 프로세스 확인 중..."
# 실제 사용자의 프로세스만 확인
RAINIT_PID=$(sudo -u "$REAL_USER" pgrep -f "node.*rainit")
if [ ! -z "$RAINIT_PID" ]; then
    echo "⚠️  실행 중인 Rainit 프로세스를 종료합니다..."
    # 실제 사용자 권한으로 프로세스 종료
    sudo -u "$REAL_USER" kill "$RAINIT_PID" 2>/dev/null || true
    sleep 1
fi

# 실행 파일 제거 (root 권한 필요)
if [ -f "/usr/local/bin/rainit" ]; then
    echo "📤 실행 파일 제거 중..."
    rm -f "/usr/local/bin/rainit"
    echo "✓ 실행 파일이 제거되었습니다."
else
    echo "ℹ️  실행 파일이 이미 제거되어 있습니다."
fi

# 설치 디렉토리 제거
if [ -d "$INSTALL_DIR" ]; then
    echo "📁 설치 디렉토리 제거 중..."
    # 디렉토리 소유자 확인
    if [ "$(stat -c '%U' "$INSTALL_DIR")" = "$REAL_USER" ]; then
        rm -rf "$INSTALL_DIR"
        echo "✓ 설치 디렉토리가 제거되었습니다."
    else
        echo "⚠️  설치 디렉토리의 소유자가 올바르지 않습니다."
        exit 1
    fi
else
    echo "ℹ️  설치 디렉토리가 이미 제거되어 있습니다."
fi

# 대화 기록 파일 제거 여부 확인
HISTORY_FILE="${REAL_HOME}/conversation_history.json"
if [ -f "$HISTORY_FILE" ] && [ "$(stat -c '%U' "$HISTORY_FILE")" = "$REAL_USER" ]; then
    # 실제 사용자로 프롬프트 표시 및 입력 받기
    sudo -u "$REAL_USER" /bin/bash << EOF
    read -p "💭 대화 기록을 삭제하시겠습니까? (y/N): " choice
    if [[ "\$choice" =~ ^[Yy]$ ]]; then
        rm -f "$HISTORY_FILE" && echo "✓ 대화 기록이 삭제되었습니다." || echo "⚠️  대화 기록 삭제 실패"
    else
        echo "ℹ️  대화 기록이 유지됩니다."
    fi
EOF
fi

echo "✨ Rainit이 성공적으로 제거되었습니다!"