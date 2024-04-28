data "aws_availability_zone" "example" {
  name = "eu-north-1a"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = "dev-kohi-tf-state"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "terraform_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto_conf" {
  bucket = aws_s3_bucket.terraform_state.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster"
}

resource "aws_instance" "example" {
  ami               = var.ami
  instance_type     = var.instance_type
  key_name          = "dev-kohi"
  security_groups   = ["devsec-kohi"]
  availability_zone = "eu-north-1a"
  tags = {
    Name    = "public_instance"
    Project = var.Project
    ENV     = var.ENV
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [tags]
    prevent_destroy       = true
  }
  user_data = <<-EOF
    #!/bin/bash
    #Update command downloads the references 
    #upgrade command goes directly to sources
    #If I was working on a big project the best practice is to choose specifiec version 
    #the apt-get is ideal for older versions of machines

    sudo apt-get update -y
    sudo apt-get upgrade -y 
    # Install Docker for my environment
    sudo apt-get  install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker

    # Install Python3 and pip
    sudo apt install -y python3 python3-pip

    # Install Django
    sudo pip3 install django

    #install ecs 
    sudo apt-get install -y ecs-init
    sudo systemctl start ecs
    sudo systemctl enable ecs  
    echo "Copying the SSH Key to the server"
    echo -e "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCDq4W2wf1ceZEaRDBsd3ruQaPSSDJ2uqmn54L2UL+fBSy7uN1Xe4VJLSSfSdEZ3frGHw6xeDFVT80oMSu+orIe2sSavLePVgBd12jAIRmzBxhM2hDwg3qGFRlthqbO9HXKtlXaUxMupqyGfnFHUI1bqavGvuzUcqV4hwUG0PA11xHq1HJ2Tw8fwyuSAtZAKUIA3+mL0ctYCBphBY9oR5lWEkOWvAOzBVUlENi3Eq80SosI3wvb2JtN3PpegzQOwTOhTDASa8spjvxt8fpJ4r2XVfS3IzQvc/iXu4z0lR9x8KOX2BNkx/98Gdp4srKHqIEmGIh+6BrVg2Di1QqEcbhB
    " >> /home/ubuntu/.ssh/authorized_keys
                EOF
}
resource "aws_ebs_volume" "example" {
  availability_zone = aws_instance.example.availability_zone
  size              = 8
  type              = "gp2"
  tags = {
    Name = "ebs_volume"
  }
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [tags]
    prevent_destroy       = true
  }
}

resource "aws_volume_attachment" "example" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.example.id
  instance_id = aws_instance.example.id
  lifecycle {
    create_before_destroy = true
    prevent_destroy       = true
  }
}

resource "aws_ecs_task_definition" "my_task" {
  family                = "my-task"
  container_definitions = file("./task-definition.json")
}

resource "aws_ecs_service" "my_service" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task.arn
  desired_count   = 2
  launch_type     = "EC2"
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [tags]
    prevent_destroy       = true
  }
}

#create a RDS Database Instance
resource "aws_db_instance" "myrds" {
  # There is no such field named "type" in the RDS configuration block 
  engine                 = "postgres"
  identifier             = "myrds"
  allocated_storage      = 20
  engine_version         = "15.5"
  instance_class         = "db.t3.micro"
  username               = var.db_username
  password               = var.db_password
  skip_final_snapshot    = true
  publicly_accessible    = true
  vpc_security_group_ids = ["sg-066bfb9b184af19b4"]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [tags]
    prevent_destroy       = true
  }
  #In order to find the database instantly, we will use tags
  tags = {
    Name    = "dev-kohi-DB"
    Project = "Kohi"
    ENV     = "Dev"
  }
}