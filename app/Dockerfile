FROM python:3.11-slim AS builder

ARG VENV_PATH=/opt/venv
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN python -m venv ${VENV_PATH} \
 && ${VENV_PATH}/bin/pip install --upgrade pip setuptools wheel \
 && ${VENV_PATH}/bin/pip install --no-cache-dir -r requirements.txt

RUN apt-get purge -y --auto-remove build-essential gcc \
 && rm -rf /var/lib/apt/lists/*

COPY app.py .

# ===============================
FROM python:3.11-slim

ARG VENV_PATH=/opt/venv
WORKDIR /app

RUN groupadd -g 1000 appgroup \
 && useradd -m -u 1000 -g appgroup -s /usr/sbin/nologin appuser

ENV PYTHONUNBUFFERED=1 \
    PATH=${VENV_PATH}/bin:$PATH \
    VIRTUAL_ENV=${VENV_PATH}


COPY --from=builder --chown=appuser:appgroup ${VENV_PATH} ${VENV_PATH}
COPY --chown=appuser:appgroup . .

USER appuser

EXPOSE 80
CMD ["/opt/venv/bin/python", "-m", "gunicorn", "-w", "2", "-k", "gthread", "-b", "0.0.0.0:80", "app:app"]
