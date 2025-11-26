# Azhya-Enoch AI

> Dual-personality AI assistant for voice, trading, automation, and web control.

---

## 🔥 Overview

**Azhya-Enoch AI** is a hybrid local-first AI system featuring:

* **Azhya**: Natural voice interface and spoken assistant
* **Enoch**: Analytical and decision-making assistant for trading, automation, and control

Supports Python + Node.js environments. Ships with:

* Speech recognition & synthesis
* Live stock predictions via `yfinance` & `scikit-learn`
* Voice intent routing
* Web and DOM manipulation via Puppeteer
* Secure AI core logic engine

---

## 🚀 Installation

### 1. Clone the Repo

```bash
git clone https://github.com/YOUR_USERNAME/azhya-enoch-ai.git
cd azhya-enoch-ai
```

### 2. Python Environment Setup

```bash
poetry env use python3.11
poetry install
```

> ⚠️ Requires Python 3.11. TensorFlow fails under 3.13+.

### 3. Node.js Setup (for web agents)

```bash
npm install
```

### 4. Run Server

```bash
npm start
```

---

## 🧠 Features

### 🔊 Voice Interface

* `voice-handler.js` handles hotword detection and dynamic text-to-speech
* Python `speechrecognition`, `pyttsx3` handles audio interface

### 📈 Trading Agent

* `stock-predictor.py` pulls & predicts market trends
* Powered by `yfinance`, `pandas`, and `scikit-learn`

### 🌐 Web Automation

* `web-builder.js` runs web-based AI actions
* Uses `puppeteer`, `cheerio`, and direct JS injection

### 🧩 Core Engine

* `ai-core.js` handles prompt logic, identity swapping, and inference routing

---

## 📂 File Structure

```
azhya-enoch-ai/
├── azhya_enoch_ai/            # (Empty placeholder, define Python pkg if needed)
├── ai-core.js                 # Node.js core assistant logic
├── voice-handler.js           # Voice recognition + TTS
├── stock-predictor.py         # Trading logic
├── web-builder.js             # Puppeteer + automation logic
├── server.js                  # Local server for hybrid control
├── pyproject.toml             # Python project config
├── package.json               # Node.js dependencies
├── README.md
```

---

## ✅ Clean Build

To reset and reinstall everything:

```bash
npm run reset
npm run build
```

## 📦 Dependencies

### Python:

* `tensorflow` 2.16
* `yfinance`, `pandas`, `scikit-learn`
* `speechrecognition`, `pyttsx3`
* `selenium`, `webdriver-manager`

### Node.js:

* `express`, `socket.io`
* `puppeteer`, `cheerio`
* `openai`, `axios`, `yfinance`

---

## 🛠️ Next Steps

* Add `azhya_enoch_ai/` Python module logic
* Finalize prompt routing in `ai-core.js`
* Wire web automation triggers from Python to Node via sockets or queues

---

## 📜 License

**N/A** — private development project. Attribution required for derivative or public use.

## Notes FROM OpenAI

| Feature                      | Current?                        | Possible?                        | Notes             |
| ---------------------------- | ------------------------------- | -------------------------------- | ----------------- |
| Text chat with AI            | ✅ Yes                           | ✅ Yes                            | Working           |
| Voice input (speech → text)  | ⚠️ Chrome only                  | ✅ Yes with Whisper               | Broken in Firefox |
| Voice output (text → speech) | ⚠️ Chrome only                  | ✅ Yes                            | Browser-based     |
| Predict stock movement       | ✅ Locally with `StockPredictor` | ✅ Needs real data feed           |                   |
| Make money on its own        | ❌ No                            | 🚫 No (not without brokers/APIs) |                   |
| Accept \$10 & “run”          | ❌ No                            | 🚫 No                            |                   |
| Search the web               | ❌ No                            | ✅ Yes with Puppeteer or SerpAPI  |                   |
| Trade stocks / crypto        | ❌ No                            | ✅ With major development         |                   |
| Professional AI?             | ⚠️ Partially                    | ✅ Could be with your effort      |                   |

