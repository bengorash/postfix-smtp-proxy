from flask import Flask, request
import os
from setup_env import CONFIG, logger

app = Flask(__name__)

def load_blacklist():
    blacklist_file = CONFIG['BLACKLIST_FILE']
    blacklist = {}
    try:
        logger.info(f"Starting to load blacklist from: {blacklist_file}")
        if os.path.exists(blacklist_file):
            with open(blacklist_file, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line:
                        parts = line.split(':', 2)
                        if len(parts) >= 2:
                            sender = parts[0].strip().lower()
                            recipient = parts[1].split(' ', 1)[0].strip().lower()
                            blacklist[(sender, recipient)] = True
                            logger.info(f"Loaded blacklist entry: {sender}:{recipient}")
        logger.info(f"Loaded blacklist from {blacklist_file}: {len(blacklist)} entries")
    except Exception as e:
        logger.error(f"Failed to load blacklist: {str(e)}", exc_info=True)
    return blacklist

BLACKLIST = load_blacklist()

@app.route('/health')
def health():
    """Health check endpoint that must return 'healthy' for Docker health checks"""
    logger.info("Health check requested")
    return "healthy\n", 200

@app.route('/', methods=['POST'])
def check_policy():
    try:
        data = request.form
        sender = data.get('sender', '').strip('<>').lower()
        recipient = data.get('recipient', '').strip('<>').lower()
        logger.info(f"Checking policy: sender={sender}, recipient={recipient}")
        
        if (sender, recipient) in BLACKLIST:
            logger.info(f"Blocked: {sender} -> {recipient}")
            return "action=REJECT Blocked by policy\n\n", 200
        logger.info(f"Allowed: {sender} -> {recipient}")
        return "action=DUNNO\n\n", 200
    except Exception as e:
        logger.error(f"Error in check_policy: {str(e)}", exc_info=True)
        return "action=DEFER Temporary failure\n\n", 451

if __name__ == "__main__":
    logger.info("Starting blacklist service on 0.0.0.0:5000...")
    app.run(host='0.0.0.0', port=5000, debug=False)