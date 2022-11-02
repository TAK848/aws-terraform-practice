provider "aws" {
  profile = "terraform"
  region  = "ap-northeast-1"
}

resource "aws_instance" "hello-world" {
  ami           = "ami-0de5311b2a443fb89"
  instance_type = "t2.micro"

  tags = {
    Name = "HelloWorld"
  }

  user_data = <<-EOF
#!/bin/bash
amazon-linux-extras install nginx1.12 -y
systemctl start nginx
EOF
}
