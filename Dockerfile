FROM python:3.13-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py SQL_connector.py ./

ENV PYTHONUNBUFFERED=1

RUN useradd --create-home appuser
USER appuser

CMD ["python", "app.py"]
