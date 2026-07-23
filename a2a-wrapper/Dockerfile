FROM python:3.12-slim

WORKDIR /app

# Install deps first for better layer caching.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

# Fail the build early if imports/app wiring are broken, instead of crash-looping at runtime.
# Import-only: config reads env with defaults and the Foundry client connects lazily, so no network is touched.
RUN python -c "import app.main"

ENV PORT=8080
EXPOSE 8080

CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
