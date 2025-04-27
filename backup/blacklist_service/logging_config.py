import logging
import os
import sys  # Added to fix NameError
import logging.handlers

def setup_logging(log_dir):
    os.makedirs(log_dir, exist_ok=True)
    
    # Main logger for SMTP proxy
    logger = logging.getLogger('SMTPProxy')
    logger.setLevel(logging.INFO)
    
    # Combined logger for detailed debugging
    combined_logger = logging.getLogger('Combined')
    combined_logger.setLevel(logging.DEBUG)
    
    # Transaction logger for SMTP transactions
    trans_logger = logging.getLogger('SMTPTransactions')
    trans_logger.setLevel(logging.INFO)
    
    # Handler for smtp_proxy.log with rotation
    smtp_handler = logging.handlers.TimedRotatingFileHandler(
        os.path.join(log_dir, 'smtp_proxy.log'), when="midnight", interval=1, backupCount=7
    )
    smtp_handler.setFormatter(logging.Formatter('%(asctime)s [%(levelname)s] %(message)s'))
    logger.addHandler(smtp_handler)
    
    # Handler for combined.log with rotation
    combined_handler = logging.handlers.TimedRotatingFileHandler(
        os.path.join(log_dir, 'combined.log'), when="midnight", interval=1, backupCount=7
    )
    combined_handler.setFormatter(logging.Formatter('%(asctime)s [%(levelname)s] [%(name)s] %(message)s'))
    combined_logger.addHandler(combined_handler)
    logger.addHandler(combined_handler)
    trans_logger.addHandler(combined_handler)
    
    # Handler for smtp_transactions.log
    trans_handler = logging.FileHandler(os.path.join(log_dir, 'smtp_transactions.log'))
    trans_handler.setFormatter(logging.Formatter('%(asctime)s - %(message)s'))
    trans_logger.addHandler(trans_handler)
    
    # Add stdout handler for Docker logs
    stdout_handler = logging.StreamHandler(sys.stdout)
    stdout_handler.setFormatter(logging.Formatter('%(asctime)s [%(levelname)s] %(message)s'))
    logger.addHandler(stdout_handler)
    combined_logger.addHandler(stdout_handler)
    trans_logger.addHandler(stdout_handler)

    return logger, combined_logger, trans_logger