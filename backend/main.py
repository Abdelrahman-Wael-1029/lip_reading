from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
import shutil
import os

app = FastAPI()

def transcribe_video(video_path: str) -> str:
    # Dummy implementation — replace with actual inference logic
    return f"Transcript of {video_path}"

@app.post("/transcribe/")
async def transcribe(file: UploadFile = File(...)):
    original_name = file.filename
    save_name = original_name
    base, ext = os.path.splitext(original_name)
    counter = 1

    # Check if file already exists and rename if needed
    while os.path.exists(save_name):
        save_name = f"{base}_{counter}{ext}"
        counter += 1

    # Save the uploaded file
    with open(save_name, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    try:
        transcript = transcribe_video(save_name)
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)

    return JSONResponse(content={"transcript": transcript})
