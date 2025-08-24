#!/bin/bash

echo "🚀 GitHub Repository Setup"
echo "=========================="
echo ""

echo "This script will help you push your project to GitHub."
echo ""

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo "❌ Git repository not found. Please run 'git init' first."
    exit 1
fi

# Check if we have commits
if ! git rev-parse HEAD >/dev/null 2>&1; then
    echo "❌ No commits found. Please make an initial commit first."
    exit 1
fi

echo "✅ Git repository is ready"
echo ""

# Get GitHub username
read -p "Enter your GitHub username: " github_username

if [ -z "$github_username" ]; then
    echo "❌ GitHub username is required"
    exit 1
fi

# Get repository name
read -p "Enter repository name (default: pisoftsolutions): " repo_name
repo_name=${repo_name:-pisoftsolutions}

echo ""
echo "📋 Repository Details:"
echo "Username: $github_username"
echo "Repository: $repo_name"
echo "URL: https://github.com/$github_username/$repo_name"
echo ""

read -p "Continue? (y/n): " confirm

if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo ""
echo "🔧 Setting up GitHub repository..."

# Add remote origin
git remote add origin "https://github.com/$github_username/$repo_name.git"

# Set main branch
git branch -M main

echo "✅ Remote repository added"
echo ""

echo "📝 Next steps:"
echo "1. Go to https://github.com/new"
echo "2. Create a new repository named: $repo_name"
echo "3. DO NOT initialize with README, .gitignore, or license"
echo "4. Click 'Create repository'"
echo "5. Run: git push -u origin main"
echo ""

echo "🔒 Security Check:"
echo "The following files should NOT be in your repository:"
echo "- .env (contains API keys)"
echo "- config/master.key (Rails master key)"
echo "- log/*.log (log files)"
echo ""

echo "✅ Setup complete! Follow the steps above to create and push to GitHub."
