#!/usr/bin/env python3
"""
Postfix Policy Delegation Service for Blacklist Integration
This script reads SMTP transaction details from stdin (provided by Postfix)
and queries the blacklist service to determine if delivery should be allowed.
"""

import sys
import os
import requests
import logging
from datetime import datetime

# Configure logging
log_dir = os.environ.get('LOG_DIR', '/var/log/postfix')
os.makedirs(log_dir, exist_ok=True)
log_file = os.path.join(log_dir, 'blacklist_policy.log')

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Configuration from environment variables
BLACKLIST_API_URL = os.environ.get('API_URL', 'http://blacklist_service:5000')
BLACKLIST_API_KEY = os.environ.get('API_KEY', '550e8400-e29b-41d4-a716-446655440000')

def check_blacklist(sender, recipient):
    """
    Query the blacklist service to check if sender is allowed to send to recipient
    Returns True if the recipient is blocked, False otherwise
    """
    try:
        headers = {'X-API-Key': BLACKLIST_API_KEY}
        data = {'sender': sender, 'recipients': [recipient]}
        
        logger.info(f"Checking blacklist: sender={sender}, recipient={recipient}")
        
        response = requests.post(
            f"{BLACKLIST_API_URL}/check_blacklist",
            json=data,
            headers=headers,
            timeout=5
        )
        
        if response.status_code != 200:
            logger.error(f"Blacklist API error: {response.status_code} - {response.text}")
            return False  # Allow if API returns error
            
        result = response.json()
        blocked_recipients = result.get('blocked_recipients', [])
        
        if recipient in blocked_recipients:
            logger.info(f"Recipient {recipient} is blacklisted for sender {sender}")
            return True
            
        logger.info(f"Recipient {recipient} is allowed for sender {sender}")
        return False
        
    except Exception as e:
        logger.error(f"Error checking blacklist: {str(e)}")
        return False  # Allow if we can't check blacklist

def parse_postfix_policy_request():
    """
    Parse the Postfix policy request from stdin
    Returns a dictionary of request attributes
    """
    attributes = {}
    
    # Read request attributes from Postfix
    for line in sys.stdin:
        line = line.strip()
        if line == '':
            break  # End of attributes
            
        name, value = line.split('=', 1)
        attributes[name] = value
        
    return attributes

def main():
    """
    Main policy service function
    Reads policy request from Postfix, checks blacklist, and returns action
    """
    try:
        # Get request attributes from Postfix
        attributes = parse_postfix_policy_request()
        
        # Get sender and recipient
        sender = attributes.get('sender', '').lower()
        recipient = attributes.get('recipient', '').lower()
        
        # Check if sender/recipient are valid
        if not sender or not recipient:
            logger.warning(f"Missing sender or recipient: {attributes}")
            print("action=DUNNO")
            return
            
        # Check blacklist
        is_blacklisted = check_blacklist(sender, recipient)
        
        # Return decision to Postfix
        if is_blacklisted:
            print("action=REJECT Recipient address rejected: address is blacklisted")
        else:
            print("action=DUNNO")
            
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        print("action=DUNNO")  # Default to allow
        
    # Flush output (important for Postfix integration)
    sys.stdout.flush()

if __name__ == "__main__":
    # Process each policy request
    while True:
        main()