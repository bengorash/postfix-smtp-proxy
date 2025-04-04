FROM python:3.11-slim

WORKDIR /app/togotrek/postfix

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY blacklist_service.py setup_env.py logging_config.py sender_blacklist ./

EXPOSE 5000

CMD ["python", "blacklist_service.py"]