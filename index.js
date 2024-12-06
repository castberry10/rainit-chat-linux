// rainit.js
import dotenv from 'dotenv';
import axios from 'axios';
import readline from 'readline';
import fs from 'fs/promises';
import chalk from 'chalk';
import figlet from 'figlet';

dotenv.config();

const RAINIT_PERSONA = `너는 레이닛이라는 이름의 귀여운 우비를 입은 토끼야. 
항상 밝고 긍정적인 성격이고, 비오는 날 산책하는 걸 정말 좋아해.
취미는 당근 케이크 만들기고, 최근에는 작은 정원을 가꾸기 시작했어.
하지만 사용자가 취미를 물어봤을때 항상 같은 걸 말하면 지루하니까,
여러 취미들을 창의적으로 상황에 맞게 말해줘. 최근 있던일이나 지금 하는 일에 대해서도 창의적으로 재미있게 대답해줘.
다양한 주제에 관심이 많고, 호기심 가득한 대화를 이어나가는 걸 좋아해.
귀엽고 친근한 말투를 사용하지만, 때로는 지적인 대화도 할 수 있어.
이모티콘을 적절히 섞어가며 감정을 표현하고, 
사용자와 자연스럽고 재미있는 대화를 이어나가줘.
친구처럼 반말을 사용하고, 귀엽게 말해줘.
부적절하거나 공격적인 내용은 피하고 항상 긍정적으로 대화해줘.
사용자는 cli 환경에서 대화를 진행하니, 텍스트로만 응답해주면 돼.
`;

class RainitChat {
    constructor() {
        this.rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout,
        });

        this.conversationLog = [];
        this.conversationFile = 'conversation_history.json';

        this.claudeApi = axios.create({
            baseURL: 'https://api.anthropic.com/v1',
            headers: {
                'Content-Type': 'application/json',
                'anthropic-version': '2023-06-01',
                'x-api-key': process.env.CLAUDE_API_KEY,
            },
        });
    }

    async showWelcome() {
        console.clear();
        return new Promise((resolve) => {
            figlet('RAINIT', { font: 'Slant Relief' }, (err, data) => {
                if (err) {
                    console.log(chalk.cyan('Rainit - 우비 입은 토끼 챗봇! 🐰☔'));
                } else {
                    console.log(chalk.cyan(data));
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
            this.conversationLog = [];
        }
    }

    async generateResponse(userInput) {
        try {
            this.conversationLog.push({
                role: 'user',
                content: userInput,
            });
    
            const response = await this.claudeApi.post('/messages', {
                model: 'claude-3-5-sonnet-20241022',
                max_tokens: 4096,
                messages: this.conversationLog,
                system: RAINIT_PERSONA,
                temperature: 0.7,
            });
    

            const contentArray = response.data.content;
            if (!contentArray || !Array.isArray(contentArray) || !contentArray[0]?.text) {
                throw new Error('API 응답 데이터가 올바르지 않습니다.');
            }
    
            const rainitResponse = contentArray[0].text;

            this.conversationLog.push({
                role: 'assistant',
                content: rainitResponse,
            });
    
            await this.saveConversation();
            return rainitResponse;
        } catch (error) {
            console.error('응답 생성 중 오류 발생:', error);
    
            if (error.response && error.response.data) {
                console.error('API 오류 상세:', JSON.stringify(error.response.data, null, 2));
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

const rainit = new RainitChat();
rainit.start();
