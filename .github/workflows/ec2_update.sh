#!/bin/bash

AWS_DEFAULT_REGION="us-east-2"
AWS_ACCOUNT_ID="376129840507"
# Stop and remove containers
docker stop editor-frontend editor-backend market-frontend market-backend
docker rm editor-frontend editor-backend market-frontend market-backend

# Pull the latest images
docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/editor-frontend:latest
docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/editor-backend:latest
docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/market-frontend:latest
docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/market-backend:latest

# Run the new containers
docker run -d --name editor-frontend -p 3001:80 ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/editor-frontend:latest
docker run -d --name editor-backend -p 5000:5001 -e OPENAI_API_KEY=${OPENAI_API_KEY} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/editor-backend:latest
docker run -d --name market-frontend -p 3000:3000 ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/market-frontend:latest
docker run -d --name market-backend -p 5001:5001 ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/market-backend:latest

# Clean up old images
docker image prune -f

docker ps
