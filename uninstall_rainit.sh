#!/bin/bash

# 오류 발생시 스크립트 중단
set -e

# sudo 권한 체크
if [ "$EUID" -ne 0 ]; then 
    echo "🔒 이 스크립트는 sudo 권한이 필요합니다."
    echo "sudo ./uninstall-rainit.sh 로 다시 실행해주세요."
    exit 1
fi

echo "🗑️  Rainit 제거를 시작합니다..."

# 실행 중인 프로세스 종료
echo "🔍 실행 중인 Rainit 프로세스 확인 중..."
RAINIT_PID=$(pgrep -f "node.*rainit")
if [ ! -z "$RAINIT_PID" ]; then
    echo "⚠️  실행 중인 Rainit 프로세스를 종료합니다..."
    kill "$RAINIT_PID" 2>/dev/null || true
    sleep 1
fi

# 실행 파일 제거
if [ -f "/usr/local/bin/rainit" ]; then
    echo "📤 실행 파일 제거 중..."
    if ! rm -f "/usr/local/bin/rainit"; then
        echo "❌ 실행 파일 제거 실패"
        exit 1
    fi
    echo "✓ 실행 파일이 제거되었습니다."
else
    echo "ℹ️  실행 파일이 이미 제거되어 있습니다."
fi

# 설치 디렉토리 제거
INSTALL_DIR="$HOME/.rainit"
if [ -d "$INSTALL_DIR" ]; then
    echo "📁 설치 디렉토리 제거 중..."
    if ! rm -rf "$INSTALL_DIR"; then
        echo "❌ 설치 디렉토리 제거 실패"
        exit 1
    fi
    echo "✓ 설치 디렉토리가 제거되었습니다."
else
    echo "ℹ️  설치 디렉토리가 이미 제거되어 있습니다."
fi

# 대화 기록 파일 제거 여부 확인
HISTORY_FILE="$HOME/conversation_history.json"
if [ -f "$HISTORY_FILE" ]; then
    read -p "💭 대화 기록을 삭제하시겠습니까? (y/N): " choice
    case "$choice" in 
        y|Y)
            if ! rm -f "$HISTORY_FILE"; then
                echo "⚠️  대화 기록 삭제 실패"
            else
                echo "✓ 대화 기록이 삭제되었습니다."
            fi
            ;;
        *)
            echo "ℹ️  대화 기록이 유지됩니다."
            ;;
    esac
fi

echo "✨ Rainit이 성공적으로 제거되었습니다!"