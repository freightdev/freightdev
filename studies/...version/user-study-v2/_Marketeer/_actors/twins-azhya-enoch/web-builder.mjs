// web-builder.mjs
import { existsSync, mkdirSync, writeFileSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const PUBLIC_DIR = join(__dirname, 'public');

if (!existsSync(PUBLIC_DIR)) mkdirSync(PUBLIC_DIR, { recursive: true });

const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Azhya & Enoch AI</title>
  <link rel="stylesheet" href="style.css" />
</head>
<body>
  <header>Azhya & Enoch AI Assistant</header>
  <main>
    <section>
      <p>Ask me anything related to coding, business, or stock trading!</p>
      <textarea id="user-input" rows="4" placeholder="Type your question here..."></textarea>
      <div style="margin-top: 1rem;">
        <button id="send-text">💬 Send</button>
        <button id="start-voice">🎤 Start Voice</button>
        <button id="stop-voice">🛑 Stop Voice</button>
      </div>
    </section>
    <section>
      <h3>AI Response:</h3>
      <div id="output">Awaiting input...</div>
    </section>
  </main>
  <script src="/socket.io/socket.io.js"></script>
  <script src="script.js"></script>
</body>
</html>
`;

const css = `body {
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  background: #121212;
  color: #f0f0f0;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: start;
  min-height: 100vh;
}

header {
  background: #1f1f1f;
  width: 100%;
  padding: 1rem 2rem;
  text-align: center;
  font-size: 1.5rem;
  font-weight: bold;
  border-bottom: 1px solid #333;
}

main {
  padding: 2rem;
  width: 100%;
  max-width: 800px;
  box-sizing: border-box;
}

button {
  background-color: #4a90e2;
  border: none;
  color: white;
  padding: 1rem 2rem;
  font-size: 1rem;
  border-radius: 8px;
  cursor: pointer;
  margin-bottom: 2rem;
  transition: background 0.3s;
}

button:hover {
  background-color: #357ab8;
}

#output {
  background-color: #1e1e1e;
  border: 1px solid #333;
  padding: 1rem;
  border-radius: 8px;
  min-height: 100px;
  white-space: pre-wrap;
  line-height: 1.5;
}
`;

const js = `const socket = io();

const userInput = document.getElementById('user-input');
const sendTextBtn = document.getElementById('send-text');
const startVoiceBtn = document.getElementById('start-voice');
const stopVoiceBtn = document.getElementById('stop-voice');
const output = document.getElementById('output');

sendTextBtn.addEventListener('click', () => {
  const text = userInput.value.trim();
  if (text) {
    appendToOutput(\`🧑 You: \${text}\`);
    socket.emit('text-input', text);
    userInput.value = '';
  }
});

let recognition;
if ('webkitSpeechRecognition' in window || 'SpeechRecognition' in window) {
  const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
  recognition = new SpeechRecognition();
  recognition.lang = 'en-US';
  recognition.continuous = false;
  recognition.interimResults = false;

  recognition.onstart = () => appendToOutput('🎤 Listening...');
  recognition.onresult = (event) => {
    const transcript = event.results[0][0].transcript;
    appendToOutput(\`🧑 You (voice): \${transcript}\`);
    socket.emit('voice-input', transcript);
  };
  recognition.onerror = (event) => appendToOutput(\`❌ Voice Error: \${event.error}\`);
  recognition.onend = () => appendToOutput('🛑 Voice recognition ended.');
} else {
  appendToOutput('⚠️ Voice recognition not supported in this browser.');
}

startVoiceBtn.addEventListener('click', () => recognition?.start());
stopVoiceBtn.addEventListener('click', () => recognition?.stop());

socket.on('ai-response', (data) => {
  if (data?.text) appendToOutput(\`🤖 AI: \${data.text}\`);
  if (data?.audio) playAudio(data.audio);
});

socket.on('code-generated', (data) => {
  appendToOutput(\`🛠️ Code Generated:\\n\${JSON.stringify(data, null, 2)}\`);
});

function appendToOutput(message) {
  const paragraph = document.createElement('p');
  paragraph.textContent = message;
  output.appendChild(paragraph);
  output.scrollTop = output.scrollHeight;
}

function playAudio(audioSrc) {
  const audio = new Audio(audioSrc);
  audio.play();
}
`;

writeFileSync(join(PUBLIC_DIR, 'index.html'), html);
writeFileSync(join(PUBLIC_DIR, 'style.css'), css);
writeFileSync(join(PUBLIC_DIR, 'script.js'), js);

console.log('✅ Web builder created: public/index.html, style.css, script.js');
