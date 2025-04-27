import os
from dotenv import load_dotenv
from logging_config import setup_logging

load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), '.env'))

BASE_APP_PATH = os.getenv('BASE_APP_PATH')
if not BASE_APP_PATH:
    raise ValueError("Missing required environment variable: BASE_APP_PATH")

CONFIG = {
    'API_URL': os.getenv('API_URL', 'http://localhost:5000'),
    'API_KEY': os.getenv('API_KEY'),  # Required
    'SMTP_HOST': os.getenv('SMTP_HOST', 'smtp.gmail.com'),
    'SMTP_PORT': int(os.getenv('SMTP_PORT', '587')),
    'SMTP_USER': os.getenv('SMTP_USER', ''),  # Optional
    'SMTP_PASS': os.getenv('SMTP_PASS', ''),  # Optional
    'DB_PATH': os.path.join(BASE_APP_PATH, 'data', 'smtp_proxy.db'),
    'BLACKLIST_FILE': os.path.join(BASE_APP_PATH, 'sender_blacklist'),
    'LOG_DIR': os.path.join(BASE_APP_PATH, 'logs'),
}

required_sensitive_vars = ['API_KEY']  # Only API_KEY is required
for var in required_sensitive_vars:
    if not CONFIG[var]:
        raise ValueError(f"Missing required sensitive environment variable: {var}")

logger, combined_logger, trans_logger = setup_logging(CONFIG['LOG_DIR'])