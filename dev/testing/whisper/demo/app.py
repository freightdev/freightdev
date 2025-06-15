
from fastapi import FastAPI, Request, Form
from fastapi.responses import Response
from pydantic import BaseModel
import os

app = FastAPI()

@app.post("/twiml-welcome")
async def twiml_welcome():
    twiml = """<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say voice="Polly.Joanna">Hi, this is Fast & Easy AI. Want a load or want to speak to Jesse?</Say>
    <Record action="/handle-recording" maxLength="10" />
</Response>
"""
    return Response(content=twiml, media_type="application/xml")

@app.post("/handle-recording")
async def handle_recording(request: Request):
    form = await request.form()
    recording_url = form.get("RecordingUrl")
    print("🎤 New recording received:", recording_url)
    return Response(content="""<Response><Say>Thanks, we will follow up shortly.</Say></Response>""", media_type="application/xml")
