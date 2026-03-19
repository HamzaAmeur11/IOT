FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

ENV APP_VERSION=v2
ENV APP_MESSAGE="Hello from IoT App - Python Flask"

EXPOSE 8888

CMD ["python", "app.py"]
