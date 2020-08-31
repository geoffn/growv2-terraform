provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_key_pair" "growapikp" {
  key_name   = "growapikp"
  public_key = file("../terraform.pub")
}
resource "aws_lb_target_group" "growapi-testgroup" {
  name     = "growapi-testgroup"
  port     = 3001
  protocol = "HTTP"
  vpc_id   = "vpc-c8e2e0b2"
}

resource "aws_lb" "growapi-test" {
  name               = "growapi-test"
  internal           = false
  load_balancer_type = "application"
  subnets            = ["subnet-030cfa65", "subnet-6e303550", "subnet-74ea182b", "subnet-b5ab00bb", "subnet-d2e915f3", "subnet-eb9011a6", ]
  #availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]
  security_groups = ["sg-0822ddbc3a0fec3da"]
}

resource "aws_lb_listener" "growapi-test" {
  load_balancer_arn = aws_lb.growapi-test.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:435852888074:certificate/ced2cb80-eca7-4aec-b674-4c3ddf83ec56"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.growapi-testgroup.arn
  }
}

resource "aws_lb_listener" "growapi-test80" {
  load_balancer_arn = aws_lb.growapi-test.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_instance" "growapinode1" {
  key_name               = aws_key_pair.growapikp.key_name
  ami                    = "ami-002a48030440e00da"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["sg-0822ddbc3a0fec3da"]

  tags = {
    Name = "APIGrowV1Terraform"
  }

  connection {
    type        = "ssh"
    user        = "alpine"
    private_key = file("../terraform")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod 666 /etc/apk/repositories",
      "sudo echo 'http://dl-cdn.alpinelinux.org/alpine/v3.6/main' >> /etc/apk/repositories",
      "sudo echo 'http://dl-cdn.alpinelinux.org/alpine/v3.6/community' >> /etc/apk/repositories",
      "sudo apk update",
      "sudo apk add mongodb=3.4.4-r0",
      "sudo chmod 644 /etc/apk/repositories",
      "sudo mongo --version",
      "sudo service mongodb start",
      "sudo apk add --update npm",
      "rm master.zip",
      "wget https://github.com/geoffn/growv2api/archive/master.zip",
      "unzip master.zip",
      "cd growv2api-master",
      "npm install",
      "sudo npm install forever -g",
      "forever start index.js"
      #"sudo apk add wget",
      #"sleep 2",
      #"wget -q -O wget.out --header=\"Content-Type:application/json\" --post-file=./testing/createfoodbank.json http://localhost:3001/foodbankbulk >> out.txt"

    ]
  }
}
resource "aws_lb_target_group_attachment" "growapi-testgroup" {
  target_group_arn = aws_lb_target_group.growapi-testgroup.arn
  target_id        = "${aws_instance.growapinode1.id}"
  port             = 3001
}
