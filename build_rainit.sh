#!/bin/bash

# build-rainit.sh
echo "🚀 Rainit 빌드 시작..."

# 필요한 도구 설치 확인
if ! command -v node &> /dev/null; then
    echo "Node.js가 설치되어 있지 않습니다. 설치를 시작합니다..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

if ! command -v git &> /dev/null; then
    echo "Git이 설치되어 있지 않습니다. 설치를 시작합니다..."
    sudo apt-get install -y git
fi

# 임시 작업 디렉토리 생성
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# GitHub 저장소 클론
echo "📦 GitHub 저장소 클론 중..."
git clone https://github.com/castberry10/rainit-chat-linux.git
cd rainit-chat-linux

# 필요한 패키지 설치
echo "📚 의존성 패키지 설치 중..."
npm install

# 빌드
echo "🔨 빌드 중..."
npm run build

# 실행 파일 설치
echo "📥 실행 파일 설치 중..."
sudo cp bin/rainit-chat /usr/local/bin/rainit
sudo chmod +x /usr/local/bin/rainit

# 환경 변수 설정
if [ ! -f ~/.rainit-env ]; then
    echo "🔑 환경 변수 설정 중..."
    echo "CLAUDE_API_KEY=your_api_key_here" > ~/.rainit-env
    echo "환경 변수 파일이 생성되었습니다. ~/.rainit-env 파일에 API 키를 설정해주세요."
fi

# 임시 디렉토리 정리
cd
rm -rf "$TEMP_DIR"

# 완료
echo "✨ 설치가 완료되었습니다!"
echo "사용 방법:"
echo "1. ~/.rainit-env 파일에 Claude API 키를 설정하세요."
echo "2. 터미널에서 'rainit' 명령어를 입력하여 실행하세요."