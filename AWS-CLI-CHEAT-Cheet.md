AWS CLI Cheatsheet
AWS CLI commands for IAM, EC2, S3, EKS, Lambda, and CloudWatch Logs.

7 sections
58 commands
Click any row to copy
Sections

Identity & Auth
IAM
EC2
S3
EKS
Lambda
CloudWatch Logs
Identity & Auth
aws sts get-caller-identity
Show current account, user ARN


aws configure
Set up AWS credentials interactively


aws configure list
Show active credentials and region


aws configure list-profiles
List all configured profiles


aws --profile staging s3 ls
Run command with specific profile


export AWS_PROFILE=staging
Set default profile for session


IAM
aws iam list-users
List all IAM users


aws iam create-user --user-name devuser
Create IAM user


aws iam delete-user --user-name devuser
Delete IAM user


aws iam list-roles
List all IAM roles


aws iam get-role --role-name MyRole
Get role details and trust policy


aws iam list-attached-role-policies --role-name MyRole
List policies attached to role


aws iam list-policies --scope Local
List customer-managed policies


aws iam create-access-key --user-name devuser
Create access key for user


aws iam list-access-keys --user-name devuser
List user's access keys


EC2
aws ec2 describe-instances --output table
List all EC2 instances as table


aws ec2 describe-instances --filters Name=instance-state-name,Values=running
Filter running instances only


aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' --output table
Show ID, state, public IP as table


aws ec2 start-instances --instance-ids i-1234567890abcdef0
Start stopped instance


aws ec2 stop-instances --instance-ids i-1234567890abcdef0
Stop running instance


aws ec2 reboot-instances --instance-ids i-1234567890abcdef0
Reboot instance


aws ec2 terminate-instances --instance-ids i-1234567890abcdef0
Terminate (delete) instance


aws ec2 describe-security-groups
List all security groups


aws ec2 describe-vpcs
List all VPCs


aws ec2 describe-subnets --filters Name=vpc-id,Values=vpc-12345
List subnets in a VPC


aws ec2 describe-key-pairs
List EC2 key pairs


S3
aws s3 ls
List all S3 buckets


aws s3 ls s3://my-bucket/
List bucket contents


aws s3 ls s3://my-bucket/ --recursive --human-readable
Recursive listing with human sizes


aws s3 cp file.txt s3://my-bucket/folder/
Upload file to bucket


aws s3 cp s3://my-bucket/file.txt .
Download file from bucket


aws s3 sync ./dist s3://my-bucket/
Sync local directory to bucket


aws s3 sync s3://my-bucket/ ./backup/
Sync bucket to local directory


aws s3 rm s3://my-bucket/file.txt
Delete single object


aws s3 rm s3://my-bucket/folder/ --recursive
Delete all objects in prefix


aws s3 mb s3://new-bucket-name
Create new bucket


aws s3 rb s3://bucket-name --force
Delete bucket and all its contents


aws s3 presign s3://my-bucket/file.txt --expires-in 3600
Generate pre-signed URL valid for 1 hour


EKS
aws eks list-clusters
List all EKS clusters


aws eks describe-cluster --name my-cluster
Cluster endpoint, version, status


aws eks update-kubeconfig --name my-cluster --region us-east-1
Update kubeconfig to access cluster


aws eks list-nodegroups --cluster-name my-cluster
List node groups in cluster


aws eks describe-nodegroup --cluster-name my-cluster --nodegroup-name ng-1
Node group details, scaling config


aws eks update-nodegroup-config --cluster-name my-cluster --nodegroup-name ng-1 --scaling-config minSize=2,maxSize=5,desiredSize=3
Update node group scaling


aws eks list-addons --cluster-name my-cluster
List installed EKS add-ons


Lambda
aws lambda list-functions
List all Lambda functions


aws lambda invoke --function-name myFunc output.json
Invoke function synchronously


aws lambda invoke --function-name myFunc --payload '{"key":"val"}' out.json
Invoke with JSON payload


aws lambda get-function --function-name myFunc
Function config, code URL, runtime


aws lambda update-function-code --function-name myFunc --zip-file fileb://code.zip
Update function code from zip


aws lambda update-function-configuration --function-name myFunc --timeout 30
Update function settings (timeout, memory)


aws lambda list-event-source-mappings --function-name myFunc
List triggers (SQS, DynamoDB, etc.)


CloudWatch Logs
aws logs describe-log-groups
List all log groups


aws logs describe-log-streams --log-group-name /aws/lambda/myFunc
List log streams in a group


aws logs tail /aws/lambda/myFunc --follow
Follow logs in real time (like tail -f)


aws logs tail /aws/lambda/myFunc --since 1h
Logs from last 1 hour


aws logs filter-log-events --log-group-name /aws/lambda/myFunc --filter-pattern ERROR
Search logs for pattern


aws logs get-log-events --log-group-name /aws/ecs/myapp --log-stream-name stream-name