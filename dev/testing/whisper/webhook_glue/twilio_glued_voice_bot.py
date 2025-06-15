
from fastapi import FastAPI, Request
from fastapi.responses import Response
import openai
import requests
import os

openai.api_key = os.getenv("OPENAI_API_KEY")

app = FastAPI()

@app.post("/twiml-welcome")
async def twiml_welcome():
    # Initial TwiML to greet and begin recording
    twiml = """<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say voice="Polly.Joanna">Hi, this is Fast and Easy Dispatching. Tell me what you're looking for, and I'll try to help.</Say>
    <Record action="/handle-recording" maxLength="15" />
</Response>
"""
    return Response(content=twiml, media_type="application/xml")

@app.post("/handle-recording")
async def handle_recording(request: Request):
    # Twilio posts recording URL here
    form = await request.form()
    recording_url = form.get("RecordingUrl")
    print("🎤 Got audio file from Twilio:", recording_url)

    # Download .wav file
    audio_data = requests.get(recording_url).content
    with open("caller_input.wav", "wb") as f:
        f.write(audio_data)

    # Whisper transcription
    whisper_result = openai.Audio.transcribe(
        model="whisper-1",
        file=open("caller_input.wav", "rb")
    )
    transcript = whisper_result["text"]
    print("🧠 Transcribed:", transcript)

    # GPT response
    gpt_reply = openai.ChatCompletion.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": "You are a smart, fast, friendly dispatcher assistant. Reply clearly and helpfully."},
            {"role": "user", "content": transcript}
        ]
    ).choices[0].message.content.strip()

    print("🤖 GPT replied:", gpt_reply)

    # Respond to caller
    twiml_response = f"""<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say voice="Polly.Joanna">{gpt_reply}</Say>
</Response>
"""
    return Response(content=twiml_response, media_type="application/xml")
