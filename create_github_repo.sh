#!/bin/bash

# Configuration
REPO_NAME="postfix-smtp-proxy"  # Name of your GitHub repository
GITHUB_USER="bengorash"  # Replace with your GitHub username
REPO_DESC="Postfix-based SMTP proxy with blacklist filtering"  # Repository description
PROJECT_DIR="$(pwd)"  # Current directory (e.g., /app/togotrek/postfix or E:\Projects\TogoTrek\postfix-smtp-gateway\postfix)

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "Error: Git is not installed. Please install it first."
    exit 1
fi

# Check if GitHub CLI is installed and authenticated
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed. Install it with 'winget install --id GitHub.cli' (Windows) or 'sudo apt install gh' (Linux), then run 'gh auth login'."
    exit 1
fi
if ! gh auth status &> /dev/null; then
    echo "Error: GitHub CLI is not authenticated. Run 'gh auth login' to authenticate."
    exit 1
fi

# Initialize Git repository if not already initialized
if [ ! -d .git ]; then
    echo "Initializing Git repository..."
    git init
else
    echo "Git repository already initialized."
fi

# Create .gitignore file if it doesn’t exist
if [ ! -f .gitignore ]; then
    echo "Creating .gitignore..."
    cat <<EOL > .gitignore
# Docker
*.log
docker-compose.yml.bak

# Python
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
env/
venv/
.env

# System files
.DS_Store
Thumbs.db
EOL
fi

# Add all files and commit
echo "Adding files to Git..."
git add .
git commit -m "Initial commit: Add Postfix SMTP proxy project"

# Create GitHub repository
echo "Creating GitHub repository: $GITHUB_USER/$REPO_NAME..."
gh repo create "$GITHUB_USER/$REPO_NAME" --description "$REPO_DESC" --public --source=. --remote=origin

# Push to GitHub
echo "Pushing to GitHub..."
git push -u origin main

echo "GitHub repository created and code pushed successfully!"
echo "Repository URL: https://github.com/$GITHUB_USER/$REPO_NAME"
echo "Next steps:"
echo "1. Open VS Code and use the Source Control tab to manage future commits."
echo "2. Run 'git pull origin main' to sync remote changes."