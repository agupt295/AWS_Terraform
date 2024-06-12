# Wordpress_App
Deployed a simple Wordpress application into AWS using Terraform (used as the Infrastructure as Code (IaC) tool).

## What is Terraform?
Terraform is an IaC software tool that provides a consistent command line interface (CLI) workflow to manage hundreds of cloud services. Terraform codifies cloud APIs into declarative configuration files.

## Architecture
![terraform](https://github.com/agupt295/AWS_Terraform/assets/118144312/7195c436-357b-4ccf-9069-8bd99e3851ef)


## IDE (Integrated Development Environment)
         ___        ______     ____ _                 _  ___  
        / \ \      / / ___|   / ___| | ___  _   _  __| |/ _ \ 
       / _ \ \ /\ / /\___ \  | |   | |/ _ \| | | |/ _` | (_) |
      / ___ \ V  V /  ___) | | |___| | (_) | |_| | (_| |\__, |
     /_/   \_\_/\_/  |____/   \____|_|\___/ \__,_|\__,_|  /_/ 
 ----------------------------------------------------------------- 

# Resources
## Networking
* VPC
* subset-private_ingress
* subnet-private
* subnet-public
* private_ingress-nat-gateway
* internet_gateway

## Security
* Security group
* VPC endpoint(s) internet gateway

## Application
* Amazon Elastic File System
* Amazon S3 Bucket
* Amazon EC2
* Amazon EC2 Auto Scaling
* Amazon RDS
* Elastic Load Balancing
* Amazon CloudFront
