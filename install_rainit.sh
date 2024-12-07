#!/bin/bash

# 오류 발생시 스크립트 중단
set -e

# sudo 권한 체크
if [ "$EUID" -ne 0 ]; then 
    echo "🔒 이 스크립트는 sudo 권한이 필요합니다."
    echo "sudo ./build-rainit.sh 로 다시 실행해주세요."
    exit 1
fi

echo "🚀 Rainit 설치 시작..."

# 필요한 도구 설치 확인
if ! command -v node &> /dev/null; then
    echo "Node.js가 설치되어 있지 않습니다. 설치를 시작합니다..."
    if ! curl -fsSL https://deb.nodesource.com/setup_18.x | bash -; then
        echo "❌ Node.js 저장소 설정 실패"
        exit 1
    fi
    if ! apt-get install -y nodejs; then
        echo "❌ Node.js 설치 실패"
        exit 1
    fi
fi

if ! command -v git &> /dev/null; then
    echo "Git이 설치되어 있지 않습니다. 설치를 시작합니다..."
    if ! apt-get install -y git; then
        echo "❌ Git 설치 실패"
        exit 1
    fi
fi

# 설치 디렉토리 생성 및 이동
INSTALL_DIR="$HOME/.rainit"
echo "📁 설치 디렉토리 준비 중..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# GitHub 저장소 클론
echo "📦 GitHub 저장소 클론 중..."
if ! git clone https://github.com/castberry10/rainit-chat-linux.git .; then
    echo "❌ GitHub 저장소 클론 실패"
    exit 1
fi

# 필요한 패키지 설치
echo "📚 의존성 패키지 설치 중..."
if ! npm install; then
    echo "❌ npm 패키지 설치 실패"
    exit 1
fi

# 실행 스크립트 생성
echo "🔨 실행 스크립트 생성 중..."
cat > "/usr/local/bin/rainit" << 'EOL'
#!/bin/bash
if [ -f "$HOME/.rainit/index.js" ]; then
    cd "$HOME/.rainit"
    node index.js
else
    echo "❌ Rainit이 올바르게 설치되지 않았습니다."
    exit 1
fi
EOL

chmod +x "/usr/local/bin/rainit"

# 환경 변수 설정
if [ ! -f "$INSTALL_DIR/.env" ]; then
    echo "🔑 환경 변수 설정 중..."
    echo "CLAUDE_API_KEY=your_api_key_here" > "$INSTALL_DIR/.env"
    echo "환경 변수 파일이 생성되었습니다. $INSTALL_DIR/.env 파일에 API 키를 설정해주세요."
fi

# 권한 설정
chown -R $SUDO_USER:$SUDO_USER "$INSTALL_DIR"

# 완료 메시지
echo "✨ 설치가 완료되었습니다!"
echo "사용 방법:"
echo "1. $INSTALL_DIR/.env 파일에 Claude API 키를 설정하세요."
echo "2. 터미널에서 'rainit' 명령어를 입력하여 실행하세요."