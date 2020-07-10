provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_key_pair" "example" {
  key_name   = "examplekey"
  public_key = file("../terraform.pub")
}

resource "aws_instance" "Terraform1" {
  key_name               = aws_key_pair.example.key_name
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
      "forever start index.js",
      "sudo apk add wget",
      "sleep 2",
      "wget -q -O wget.out --header=\"Content-Type:application/json\" --post-file=./testing/createfoodbank.json http://localhost:3001/foodbankbulk >> out.txt"

    ]
  }
}
resource "aws_lb_target_group_attachment" "growapiv1" {
  target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:435852888074:targetgroup/growapiv1/ee5a89d4dd871e47"
  target_id        = "${aws_instance.Terraform1.id}"
  port             = 3001
}
