# GPT4o-NOTES.md

## ✅ What This AI Can Do (Right Now)

This project is a **local AI assistant shell** powered by GPT-4o or any plugged-in model. It supports a clean user interface with both text and voice interaction — depending on the browser.

---

### 💬 Text-Based Chat

* ✅ Ask questions via the input box.
* ✅ AI responds in real time using socket.io.
* ✅ Supports any topics like coding, business, or stocks (basic answers).

---

### 🗣️ Voice Recognition (Input)

* ✅ Works in **Chrome only** (using `webkitSpeechRecognition`).
* ❌ Does not work in Firefox or other browsers.
* 🎤 User can press “Start Voice” to speak and AI will transcribe and respond.

---

### 🔊 Voice Synthesis (Output)

* ✅ AI speaks its response aloud (Text-to-Speech).
* ✅ Browser must support `speechSynthesis` (Chrome preferred).
* 🧠 Voice is styled based on AI personality (e.g. Azhya = confident, strategic tone).

---

### 📈 Basic Stock Prediction (Optional)

* ✅ Comes with a `StockPredictor` script using:

  * Yahoo Finance (via `yfinance`)
  * Random Forest model (for price forecasting)
  * Technical indicators (RSI, MACD, etc.)
* ❌ Not live in the UI yet
* 🔪 Must be run manually with:

  ```bash
  python stock_predictor.py "AAPL"
  ```

---

## ❌ What It *Does NOT* Do (Yet)

### 💰 Money & Payments

* ❌ No way to deposit \$10
* ❌ No wallet, stripe, or crypto integration
* ❌ No way to turn money into automation (yet)

---

### 🌍 Web Search or Web Scraping

* ❌ Does NOT search Google or fetch web pages
* ❌ No Puppeteer, Cheerio, or SerpAPI integration
* ❌ Cannot fetch rates, news, or prices in real-time

---

### 📊 Real-Time Trading

* ❌ No connection to Robinhood, Alpaca, E-Trade, Coinbase, etc.
* ❌ No financial automation, orders, or execution logic
* ❌ Not authorized or compliant to handle real funds

---

### 🧠 Autonomous Tasks

* ❌ Does not plan or run tasks on its own
* ❌ Does not have memory or persistent state
* ❌ Does not execute code or scripts by itself

---

## 🛠️ How to Use

1. Run the backend:

   ```bash
   node server.js
   ```
2. Visit [http://localhost:3000](http://localhost:3000)
3. Interact via typing or voice (Chrome only)

---

## 🧹 Architecture Overview

| Component            | Role                                     |
| -------------------- | ---------------------------------------- |
| `server.js`          | Runs Express + socket.io backend         |
| `web-builder.mjs`    | Creates frontend files (HTML/CSS/JS)     |
| `voice-handler.js`   | Handles browser speech recognition + TTS |
| `ai-core.js`         | Processes message logic                  |
| `stock_predictor.py` | Predicts stock trends (manually run)     |
