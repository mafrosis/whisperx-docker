FROM python:3.12-slim-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    git \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
ENV RUSTUP_VERSION=1.27.1
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain 1.80.0
ENV PATH="/root/.cargo/bin:${PATH}"

# Install WhisperX dependencies (triton not needed for CPU-only)
RUN pip install --no-cache-dir \
    "ctranslate2>=4.5.0" \
    "faster-whisper>=1.1.1" \
    "nltk>=3.9.1" \
    "numpy==2.0.2" \
    "onnxruntime<1.20,>=1.19" \
    "pandas<2.3,>=2.2.3" \
    "av<16.0.0" \
    "pyannote-audio>=3.3.2,<4.0.0" \
    "transformers>=4.48.0" \
    "torch==2.7.1" \
    "torchaudio==2.7.1"

# Install WhisperX v3.5.0 without dependencies to avoid triton pull
RUN pip install --no-cache-dir --no-deps \
	git+https://github.com/m-bain/whisperx.git@v3.5.0

WORKDIR /app

# Suppress warning log about CPU vendor
ENV ORT_LOG_LEVEL=3
# Suppress pyannote warnings
ENV PYTHONWARNINGS="ignore::DeprecationWarning,ignore::UserWarning"

ENTRYPOINT ["whisperx", "--output_format", "txt", "--model", "large-v3", "--compute_type", "int8", "--language", "en", "--diarize", "--min_speakers", "2", "--beam_size", "5"]