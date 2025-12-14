// server.js (ES Module version)

import express from 'express';
import http from 'http';
import path from 'path';
import { Server as SocketIO } from 'socket.io';
import { fileURLToPath } from 'url';
import { processMessage } from './ai-core.js';
import { voiceHandler as VoiceHandler } from './voice-handler.js';
import * as WebBuilder from './web-builder.mjs';

// __dirname workaround in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const server = http.createServer(app);
const io = new SocketIO(server);

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.json());

// AI Personalities
const personalities = {
  azhya: {
    name: "Azhya",
    voice: "female",
    keywords: ["hey azhya", "azhya", "az"],
    specialties: ["coding", "business", "automation"]
  },
  enoch: {
    name: "Enoch",
    voice: "male",
    keywords: ["hey enoch", "enoch", "en"],
    specialties: ["trading", "analysis", "predictions"]
  }
};

// Socket connection for real-time communication
io.on('connection', (socket) => {
  console.log('User connected');

  socket.on('voice-input', async (data) => {
    try {
      const response = await processVoiceCommand(data);
      socket.emit('ai-response', response);
    } catch (error) {
      console.error('Voice processing error:', error);
      socket.emit('ai-response', { text: 'Error processing voice input.' });
    }
  });

  socket.on('text-input', async (data) => {
    try {
      const response = await processMessage(data);
      socket.emit('ai-response', response);
    } catch (error) {
      console.error('Text processing error:', error);
      socket.emit('ai-response', { text: 'Error processing text input.' });
    }
  });

  socket.on('generate-code', async (data) => {
    try {
      const generatedCode = await WebBuilder.generateProject(data);
      socket.emit('code-generated', generatedCode);
    } catch (error) {
      console.error('Code generation error:', error);
      socket.emit('code-generated', { error: 'Failed to generate project.' });
    }
  });
});

// Process voice commands
async function processVoiceCommand(audioData) {
  const transcript = await VoiceHandler.speechToText(audioData);
  const activeAI = detectAI(transcript);

  if (activeAI) {
    const response = await processMessage(transcript, activeAI);
    const audioResponse = await VoiceHandler.textToSpeech(response.text, activeAI);

    return {
      text: response.text,
      audio: audioResponse,
      actions: response.actions || []
    };
  }

  return {
    text: transcript,
    audio: null,
    actions: []
  };
}

// Detect which AI should respond
function detectAI(text) {
  const lowerText = text.toLowerCase();
  for (const [key, personality] of Object.entries(personalities)) {
    if (personality.keywords.some(keyword => lowerText.includes(keyword))) {
      return key;
    }
  }
  return null;
}

// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚀 Azhya & Enoch AI Server running on http://localhost:${PORT}`);
  console.log('📱 Open your browser and navigate to the URL above');
});
