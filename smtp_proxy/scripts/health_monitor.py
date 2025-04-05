#!/usr/bin/env python3
"""
Simple Health Monitoring Service for Postfix SMTP Proxy
"""

import os
import sys
import time
import logging
import requests
import subprocess

# Configure logging
LOG_DIR = os.environ.get('LOG_DIR', '/var/log/postfix')
os.makedirs(LOG_DIR, exist_ok=True)
log_file = os.path.join(LOG_DIR, 'health_monitor.log')

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger('health_monitor')

# Configuration
API_URL = os.environ.get('API_URL', 'http://blacklist_service:5000')
CHECK_INTERVAL = int(os.environ.get('HEALTH_CHECK_INTERVAL', 60))

def check_blacklist_service():
    """Check if blacklist service is responding"""
    try:
        logger.info(f"Checking blacklist service at {API_URL}/health")
        response = requests.get(f"{API_URL}/health", timeout=5)
        if response.status_code == 200:
            logger.info("Blacklist service is healthy")
            return True
        else:
            logger.warning(f"Blacklist service returned status code {response.status_code}")
            return False
    except Exception as e:
        logger.error(f"Error connecting to blacklist service: {str(e)}")
        return False

def check_postfix_service():
    """Check if Postfix is running"""
    try:
        logger.info("Checking Postfix service")
        result = subprocess.run(["postfix", "status"], capture_output=True, text=True)
        if "is running" in result.stdout:
            logger.info("Postfix is running")
            return True
        else:
            logger.warning(f"Postfix may not be running: {result.stdout}")
            return False
    except Exception as e:
        logger.error(f"Error checking Postfix: {str(e)}")
        return False

def main():
    """Main monitoring loop"""
    logger.info("Starting health monitor")
    
    # Initial delay to let services start
    time.sleep(10)
    
    while True:
        try:
            blacklist_healthy = check_blacklist_service()
            postfix_healthy = check_postfix_service()
            
            if not blacklist_healthy:
                logger.warning("Blacklist service is not healthy")
                
            if not postfix_healthy:
                logger.warning("Postfix service is not healthy")
                # Try to restart Postfix if it's not running
                try:
                    logger.info("Attempting to restart Postfix")
                    subprocess.run(["postfix", "start"], check=True)
                except Exception as restart_error:
                    logger.error(f"Failed to restart Postfix: {str(restart_error)}")
            
            # Overall health status
            if blacklist_healthy and postfix_healthy:
                logger.info("All services are healthy")
            else:
                logger.warning("Some services are unhealthy")
                
        except Exception as e:
            logger.error(f"Unexpected error in health monitor: {str(e)}")
            
        # Sleep before next check
        time.sleep(CHECK_INTERVAL)

if __name__ == "__main__":
    main()