from fastapi import FastAPI, File, UploadFile
from fastapi.responses import PlainTextResponse
import shutil
import os
from uuid import uuid4

app = FastAPI()

# المسار اللي هيتخزن فيه الفيديوهات
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@app.post("/upload", response_class=PlainTextResponse)
async def upload_video(file: UploadFile = File(...)):
    try:
        file_extension = file.filename.split(".")[-1]
        unique_filename = f"{uuid4()}.{file_extension}"
        file_path = os.path.join(UPLOAD_DIR, unique_filename)

        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # رجع اسم الفيديو أو مسار أو رابط حسب اللي تحتاجه
        return f"Video uploaded successfully: {unique_filename}"

    except Exception as e:
        return f"Upload failed: {str(e)}"
