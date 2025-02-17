1) aws ecr create-repository --repository-name resume_modifier_market_backend --region us-east-2 #创建repo
2) 
3) aws, terraform, docker installl
4) aws register, create a user
5) create access key for the user
6) aws cli set up
7) cd terraform | ssh-keygen -t rsa -b 2048 -f ./id_rsa
8) terraform init | terraform apply
9) ssh -i id_rsa ec2-user@<your_ec2_ip_address>
10) touch build.sh | vim build.sh | chmod +x build.sh | ./build.sh

docker run -d --name market-frontend -p 3000:80 376129840507.dkr.ecr.us-east-2.amazonaws.com/market-frontend:latest

aws ecr create-repository --repository-name editor-frontend --region us-east-2



aws logs create-log-group --log-group-name "/ecs/market_backend" --region us-east-2


aws ecs execute-command \
  --cluster resume-editor \
  --task 99cc508bd4304181922816cb6f99e60a \
  --container market-frontend \
  --interactive \
  --command "/bin/bash"


aws ecs update-service \
  --cluster resume-editor \
  --service market-frontend \
  --enable-execute-command



  aws ecs update-service \
  --cluster resume-editor \
  --service market-frontend \
  --task-definition market_frontend_family:32 \
  --enable-execute-command


