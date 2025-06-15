
from fastapi import FastAPI, Request
from fastapi.responses import Response
import openai
import requests
import os

openai.api_key = os.getenv("OPENAI_API_KEY")

app = FastAPI()

@app.post("/handle-recording")
async def handle_recording(request: Request):
    form = await request.form()
    recording_url = form.get("RecordingUrl")
    print("🎤 Got audio file from Twilio:", recording_url)

    # Download the audio file
    audio_data = requests.get(recording_url).content
    with open("caller_input.wav", "wb") as f:
        f.write(audio_data)

    # Transcribe with Whisper (OpenAI API version)
    whisper_response = openai.Audio.transcribe(
        model="whisper-1",
        file=open("caller_input.wav", "rb")
    )
    transcript = whisper_response["text"]
    print("🧠 Whisper transcript:", transcript)

    # Generate GPT-4 response
    chat_response = openai.ChatCompletion.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": "You are a friendly dispatch assistant that answers quickly and clearly."},
            {"role": "user", "content": transcript}
        ]
    )
    reply = chat_response.choices[0].message.content.strip()
    print("🤖 GPT-4 says:", reply)

    # Return TwiML with <Say> response
    twiml = f"""<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say voice="Polly.Joanna">{reply}</Say>
</Response>
"""
    return Response(content=twiml, media_type="application/xml")
