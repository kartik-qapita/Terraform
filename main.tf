#Terraform Script for EC2 Instance with 5-EBS Volumes & Mounting,Software Installation Bash Script.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

#Provider :
provider "aws" {
  access_key = ""
  secret_key = ""
  region     = "ap-south-1"
}

#Resource-1 : ebs_volume.tf
#DATA : Bash Script
data "template_file" "userdata" {
  template = file("mount-and-install.sh")
}

#EC2 Instance : 
resource "aws_instance" "phantoms-dev-instance" {
  ami                         = "ami-08ee6644906ff4d6c" #ubuntu 18.04LTS
  availability_zone           = "ap-south-1b"
  instance_type               = "t2.micro" #FREE TIER
  subnet_id                   = "subnet-"  #PRIVATE SUBNET
  vpc_security_group_ids      = [""]
  associate_public_ip_address = true                                 #ASSIGNS PUBLIC IP TO INSTANCE 
  user_data                   = data.template_file.userdata.rendered #RUNS OUR SCRIPT
  tags = {
    environment = "development"
  }
}
