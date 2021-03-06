provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_key_pair" "FETerraform" {
  key_name   = "FETerraform"
  public_key = file("../FETerraform.pub")
}


resource "aws_instance" "harvestFE" {
  key_name               = aws_key_pair.FETerraform.key_name
  ami                    = "ami-002a48030440e00da"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["sg-05ea20d5ee2e9549e"]

  tags = {
    Name = "HarvestG2Terraform"
  }

  connection {
    type        = "ssh"
    user        = "alpine"
    private_key = file("../FETerraform")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apk add --update npm",
      "wget https://github.com/geoffn/react-harvest/archive/master.zip",
      "unzip master.zip",
      "cd react-harvest-master",
      "npm install",
      "sudo npm i pm2 -g",
      "pm2 start npm -- start"
    ]
  }
}
resource "aws_lb_target_group_attachment" "growFrontEnd" {
  target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:435852888074:targetgroup/growFrontEnd/7d753250c2ea7ced"
  target_id        = "${aws_instance.harvestFE.id}"
  port             = 3000
}
