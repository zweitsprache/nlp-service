FROM python:3.11-slim

# Install git (needed for DEMorphy from GitHub) and curl
RUN apt-get update && apt-get install -y --no-install-recommends git curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements-base.txt requirements.txt dawg.py .

# 1. DAWG-Python (pure Python fallback for the 'dawg' C extension)
# 2. FastAPI + spaCy + German model
# 3. DEMorphy --no-deps (avoids pulling in the broken 'dawg' C package)
RUN pip install --no-cache-dir DAWG-Python && \
    pip install --no-cache-dir -r requirements-base.txt && \
    pip install --no-cache-dir --no-deps "DEMorphy @ git+https://github.com/DuyguA/DEMorphy.git"

# Copy dawg.py shim into site-packages so `import dawg` resolves to dawg_python
RUN cp dawg.py $(python -c "import site; print(site.getsitepackages()[0])")/dawg.py

# Download the DEMorphy words.dg dictionary (Git LFS, ~163MB)
RUN DEMORPHY_DATA=$(python -c "import demorphy, os; print(os.path.join(os.path.dirname(demorphy.__file__), 'data'))") && \
    curl -L -o "${DEMORPHY_DATA}/words.dg" \
    "https://media.githubusercontent.com/media/DuyguA/DEMorphy/master/demorphy/data/words.dg"

COPY main.py .

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
