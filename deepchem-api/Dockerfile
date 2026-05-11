# ---- Stage 1: train models ----
FROM python:3.10-slim AS trainer

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc g++ libxrender1 libxext6 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# CPU-only PyTorch (significantly smaller than CUDA build)
RUN pip install --no-cache-dir \
    "torch==2.1.2+cpu" \
    --index-url https://download.pytorch.org/whl/cpu

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY train_models.py .
RUN python train_models.py


# ---- Stage 2: runtime image ----
FROM python:3.10-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libxrender1 libxext6 libglib2.0-0 libexpat1 \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    "torch==2.1.2+cpu" \
    --index-url https://download.pytorch.org/whl/cpu

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy trained models from stage 1
COPY --from=trainer /app/saved_models /app/saved_models

# Copy application source
COPY main.py predictor.py ./
COPY static/ ./static/

EXPOSE 8080

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "1"]
