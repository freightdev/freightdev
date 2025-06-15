
import whisper
import requests

def download_and_transcribe(url, output_file="caller_input.wav"):
    print("⬇️ Downloading audio...")
    audio = requests.get(url)
    with open(output_file, "wb") as f:
        f.write(audio.content)

    print("🧠 Transcribing with Whisper...")
    model = whisper.load_model("base")
    result = model.transcribe(output_file)
    print("📄 Transcription:", result["text"])
    return result["text"]

# Example usage:
# download_and_transcribe("https://api.twilio.com/calls/recording.mp3")
