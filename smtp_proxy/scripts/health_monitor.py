#!/usr/bin/env python3
"""
Blacklist Service Health Monitor
This script periodically checks the health of the blacklist service
and logs status to help with monitoring and debugging.
"""

import os
import sys
import time
import logging
import requests
from datetime import datetime

log_dir = os.environ.get('LOG_DIR', '/var/log/postfix')
os.makedirs(log_dir, exist_ok=True)
log_file = os.path.join(log_dir, 'health_monitor.log')

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

BLACKLIST_API_URL = os.environ.get('API_URL', 'http://blacklist_service:5000')
BLACKLIST_API_KEY = os.environ.get('API_KEY', '550e8400-e29b-41d4-a716-446655440000')
HEALTH_CHECK_INTERVAL = int(os.environ.get('HEALTH_CHECK_INTERVAL', 300))

def check_health():
    try:
        headers = {'X-API-Key': BLACKLIST_API_KEY}
        response = requests.get(
            f"{BLACKLIST_API_URL}/health",
            headers=headers,
            timeout=5
        )
        if response.status_code == 200:
            logger.info("Blacklist service is healthy")
            return True
        else:
            logger.warning(f"Blacklist service returned status code {response.status_code}")
            return False
    except requests.RequestException as e:
        logger.error(f"Error connecting to blacklist service: {str(e)}")
        return False

def main():
    logger.info(f"Starting health monitor with API URL: {BLACKLIST_API_URL}")
    while True:
        try:
            check_health()
        except Exception as e:
            logger.error(f"Unexpected error in health check: {str(e)}")
        time.sleep(HEALTH_CHECK_INTERVAL)

if __name__ == "__main__":
    main()