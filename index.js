// rainit.js
import dotenv from 'dotenv';
import axios from 'axios';
import readline from 'readline';
import fs from 'fs/promises';
import chalk from 'chalk';
import figlet from 'figlet';

dotenv.config();

// ASCII 아트 텍스트
const RAINIT_ASCII = ``;

// Rainit 캐릭터 설정
const RAINIT_PERSONA = `너는 Rainit이라는 이름의 귀여운 우비를 입은 토끼야. 
항상 밝고 긍정적인 성격이고, 비오는 날 산책하는 걸 정말 좋아해.
취미는 당근 케이크 만들기고, 최근에는 작은 정원을 가꾸기 시작했어.
다양한 주제에 관심이 많고, 호기심 가득한 대화를 이어나가는 걸 좋아해.
귀엽고 친근한 말투를 사용하지만, 때로는 지적인 대화도 할 수 있어.
이모티콘을 적절히 섞어가며 감정을 표현하고, 
사용자와 자연스럽고 재미있는 대화를 이어나가줘.
부적절하거나 공격적인 내용은 피하고 항상 긍정적으로 대화해줘.`;

class RainitChat {
    constructor() {
        this.rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        this.conversationLog = [];
        this.conversationFile = 'conversation_history.json';
        
        // Claude API 설정 수정
        this.claudeApi = axios.create({
            baseURL: 'https://api.anthropic.com/v1',
            headers: {
                'Content-Type': 'application/json',
                'anthropic-version': '2023-06-01', 
                'x-api-key': process.env.CLAUDE_API_KEY
            }
        });
    }

    async showWelcome() {
        console.clear();
        return new Promise((resolve) => {
            figlet('RAINIT', {
                font: 'Slant Relief',
                horizontalLayout: 'default',
                verticalLayout: 'default'
            }, (err, data) => {
                if (err) {
                    console.log(chalk.cyan(RAINIT_ASCII));
                } else {
                    console.log(chalk.cyan(data));
                    console.log(chalk.cyan(RAINIT_ASCII));
                }
                console.log(chalk.yellow('\n안녕! 난 우비 입은 토끼 레이닛이야! 함께 이야기해볼까? 🐰☔\n'));
                resolve(null);
            });
        });
    }

    async saveConversation() {
        try {
            await fs.writeFile(
                this.conversationFile,
                JSON.stringify(this.conversationLog, null, 2)
            );
        } catch (error) {
            console.error('대화 저장 중 오류 발생:', error);
        }
    }

    async loadConversation() {
        try {
            const data = await fs.readFile(this.conversationFile, 'utf-8');
            this.conversationLog = JSON.parse(data);
        } catch (error) {
            // 파일이 없는 경우 무시
            this.conversationLog = [];
        }
    }

    async generateResponse(userInput) {
        try {
            // 대화 기록 추가
            this.conversationLog.push({
                sender: "user",
                text: userInput,
                timestamp: new Date().toISOString()
            });
    
            // Claude API 요청
            const response = await this.claudeApi.post('/messages', {
                model: "claude-3-5-sonnet-20241022",
                max_tokens: 4096,
                messages: [
                    {
                        role: "user",
                        content: userInput
                    }
                ],
                system: RAINIT_PERSONA,
                temperature: 0.7
            });
    
            const rainitResponse = response.data.content[0].text;
            
            // 응답 저장
            this.conversationLog.push({
                sender: "rainit",
                text: rainitResponse,
                timestamp: new Date().toISOString()
            });
    
            await this.saveConversation();
            return rainitResponse;
    
        } catch (error) {
            console.error('응답 생성 중 오류 발생:', error);
            if (error.response && error.response.data) {
                console.error('API 오류 상세:', error.response.data);
            }
            return '앗, 미안해... 지금은 머리가 좀 복잡한 것 같아... 😅';
        }
    }

    async start() {
        await this.showWelcome();
        await this.loadConversation();

        const askQuestion = () => {
            this.rl.question(chalk.green('user > '), async (input) => {
                if (input.toLowerCase() === 'exit') {
                    console.log(chalk.yellow('\nRainit: 오늘 정말 즐거웠어! 다음에 또 만나자! 👋🐰\n'));
                    this.rl.close();
                    return;
                }

                const response = await this.generateResponse(input);
                console.log(chalk.cyan('rainit > ') + response + '\n');
                askQuestion();
            });
        };

        askQuestion();
    }
}

// 애플리케이션 실행
const rainit = new RainitChat();
rainit.start();