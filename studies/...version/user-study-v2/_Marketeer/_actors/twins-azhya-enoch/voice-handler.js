// voice-handler.js
let speechRecognitionAvailable = false;
let speechSynthesisAvailable = false;

if (typeof window !== 'undefined') {
  speechRecognitionAvailable = !!(window.SpeechRecognition || window.webkitSpeechRecognition);
  speechSynthesisAvailable = !!window.speechSynthesis;
}

class VoiceHandler {
  constructor() {
    this.isListening = false;
    this.recognition = null;
    this.synthesis = null;

    if (typeof window !== 'undefined') {
      this.setupVoiceRecognition();
    }
  }

  setupVoiceRecognition() {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (SpeechRecognition) {
      this.recognition = new SpeechRecognition();
      this.recognition.continuous = true;
      this.recognition.interimResults = false;
      this.recognition.lang = 'en-US';
    }

    if (window.speechSynthesis) {
      this.synthesis = window.speechSynthesis;
    }
  }

  async speechToText() {
    return new Promise((resolve, reject) => {
      if (!this.recognition) {
        reject(new Error('Speech recognition not supported in this environment.'));
        return;
      }

      this.recognition.onresult = (event) => {
        const transcript = event.results[event.results.length - 1][0].transcript;
        this.recognition.stop();
        this.isListening = false;
        resolve(transcript);
      };

      this.recognition.onerror = (event) => {
        this.recognition.stop();
        this.isListening = false;
        reject(event.error);
      };

      this.recognition.start();
      this.isListening = true;
    });
  }

  async textToSpeech(text, aiPersonality = 'azhya') {
    return new Promise((resolve, reject) => {
      if (!this.synthesis) {
        reject(new Error('Speech synthesis not supported in this environment.'));
        return;
      }

      const utterance = new SpeechSynthesisUtterance(text);

      if (aiPersonality === 'azhya') {
        utterance.pitch = 1.2;
        utterance.rate = 0.9;
        utterance.volume = 1.0;
      } else {
        utterance.pitch = 0.8;
        utterance.rate = 1.0;
        utterance.volume = 1.0;
      }

      utterance.onend = () => resolve('Speech completed');
      utterance.onerror = (event) => reject(event.error);

      this.synthesis.speak(utterance);
    });
  }

  startListening() {
    if (this.recognition && !this.isListening) {
      this.recognition.start();
      this.isListening = true;
    }
  }

  stopListening() {
    if (this.recognition && this.isListening) {
      this.recognition.stop();
      this.isListening = false;
    }
  }
}

export const voiceHandler = typeof window !== 'undefined' ? new VoiceHandler() : {
  speechToText: async () => {
    throw new Error('speechToText() not available in Node environment.');
  },
  textToSpeech: async () => {
    throw new Error('textToSpeech() not available in Node environment.');
  },
  startListening: () => {},
  stopListening: () => {}
};
