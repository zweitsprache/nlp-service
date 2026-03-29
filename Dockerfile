FROM python:3.11-slim

# Install git (needed for DEMorphy from GitHub) and curl
RUN apt-get update && apt-get install -y --no-install-recommends git curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt requirements-base.txt .

# Install DAWG-Python first (pure Python, no C compiler needed)
# then install the rest without DEMorphy, then DEMorphy --no-deps to skip the broken 'dawg' C package
COPY requirements-base.txt .
RUN pip install --no-cache-dir DAWG-Python && \
    pip install --no-cache-dir -r requirements-base.txt && \
    pip install --no-cache-dir --no-deps "DEMorphy @ git+https://github.com/DuyguA/DEMorphy.git"

# Create 'dawg' shim so demorphy can import it (DAWG-Python installs as 'dawg_python')
RUN python -c "
import site, os
shim = 'from dawg_python import DAWG, CompletionDAWG, BytesDAWG, RecordDAWG, IntDAWG, IntCompletionDAWG\n'
for d in site.getsitepackages():
    path = os.path.join(d, 'dawg.py')
    if os.path.isdir(d):
        open(path, 'w').write(shim)
        print('Wrote shim to', path)
        break
"

# Download the DEMorphy words.dg dictionary (Git LFS file, ~163MB)
RUN DEMORPHY_DATA=$(python -c "import demorphy, os; print(os.path.join(os.path.dirname(demorphy.__file__), 'data'))") && \
    curl -L -o "${DEMORPHY_DATA}/words.dg" \
    "https://media.githubusercontent.com/media/DuyguA/DEMorphy/master/demorphy/data/words.dg"

COPY main.py .

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
