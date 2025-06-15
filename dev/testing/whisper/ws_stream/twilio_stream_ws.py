
import asyncio
import base64
import json
import websockets
import soundfile as sf
import numpy as np
import io

from faster_whisper import WhisperModel  # or use openai/whisper

# Load Whisper model (faster-whisper for real-time chunking)
model = WhisperModel("base", compute_type="int8")

async def transcribe_live(websocket):
    print("🔌 Client connected for Twilio Stream.")
    audio_buffer = bytearray()

    async for message in websocket:
        data = json.loads(message)

        if data["event"] == "start":
            print("🎙️ Stream started:", data["streamSid"])

        elif data["event"] == "media":
            payload = data["media"]["payload"]
            audio_chunk = base64.b64decode(payload)
            audio_buffer.extend(audio_chunk)

            # Optional: Stream in 1-second chunks
            if len(audio_buffer) > 8000:  # ~1 sec of μ-law
                # Convert μ-law to PCM WAV using numpy
                pcm_data = np.frombuffer(audio_buffer, dtype=np.uint8)
                linear_pcm = ((pcm_data.astype(np.int16) - 128) << 8).astype(np.int16)
                with sf.SoundFile(io.BytesIO(), mode='w', samplerate=8000, channels=1, format='WAV', subtype='PCM_16') as f:
                    f.write(linear_pcm / 32768.0)

                # Save and transcribe
                wav_bytes = f.buffer.read()
                with open("temp.wav", "wb") as temp_wav:
                    temp_wav.write(wav_bytes)
                segments, _ = model.transcribe("temp.wav")
                for segment in segments:
                    print("🧠 TRANSCRIBED:", segment.text)

                audio_buffer.clear()

        elif data["event"] == "stop":
            print("🛑 Stream ended.")
            break

    await websocket.close()

async def main():
    print("🛰️ WebSocket server listening on ws://0.0.0.0:8765")
    async with websockets.serve(transcribe_live, "0.0.0.0", 8765):
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(main())
