###  ECR 生命周期策略
aws ecr put-lifecycle-policy \
    --repository-name "cctip/cctip-face-compare-service" \
    --lifecycle-policy-text "file://policy.json"

{
   "rules": [
       {
           "rulePriority": 1,
           "description": "Expire images more than 10",
           "selection": {
               "tagStatus": "any",
               "countType": "imageCountMoreThan",
               "countNumber": 10
           },
           "action": {
               "type": "expire"
           }
       }
   ]
}

### check ecr images
[root@CC-k8s-master-aws-pro tmp]# aws ecr list-images      --repository-name cctip/cctip-face-compare-service
