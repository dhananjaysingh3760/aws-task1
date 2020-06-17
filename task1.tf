provider "aws" {
    region = "ap-south-1"
    profile = "dhananjay"
} 

resource "aws_security_group" "sg" {
  name        = "security-group"
  description = "allow ssg and http"
  vpc_id      = "vpc-e2f6eb8a"

  ingress {
    description = "SSH protocol"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP protocol"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_instance" "web" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "mykey"
  security_groups = [ "security-group" ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("/home/dhananjay/cloudComputing/mykey.pem")
    host     = aws_instance.web.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "task1"
  }

}

resource "aws_ebs_volume" "ebs1" {
  availability_zone = aws_instance.web.availability_zone
  size              = 1
  tags = {
    Name = "task1"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.ebs1.id}"
  instance_id = "${aws_instance.web.id}"
  force_detach = true
}

resource "null_resource" "nullremote3"  {

depends_on = [
    aws_volume_attachment.ebs_att,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("/home/dhananjay/cloudComputing/mykey.pem")
    host     = aws_instance.web.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/dhananjaysingh3760/memory-game.git /var/www/html/"
    ]
  }
}

resource "null_resource" "nulllocal2"  {
  provisioner "local-exec" {
      command = "git clone https://github.com/dhananjaysingh3760/memory-game.git ./gitcode"
    }
}  

resource "aws_s3_bucket" "task1" {
  bucket = "fatalerror3760task1"
  acl    = "public-read"
  tags = {
      Name = "fatalerror3760task1"
      Environment = "Dev"
  }
}

resource "aws_s3_bucket_object" "bucket_obj1" {
  bucket = "${aws_s3_bucket.task1.id}"
  key    = "blue.mp3"
  source = "./gitcode/sounds/blue.mp3"
  acl	 = "public-read"
}

resource "aws_s3_bucket_object" "bucket_obj2" {
  bucket = "${aws_s3_bucket.task1.id}"
  key    = "green.mp3"
  source = "./gitcode/sounds/green.mp3"
  acl	 = "public-read"
}

resource "aws_s3_bucket_object" "bucket_obj3" {
  bucket = "${aws_s3_bucket.task1.id}"
  key    = "red.mp3"
  source = "./gitcode/sounds/red.mp3"
  acl	 = "public-read"
}

resource "aws_s3_bucket_object" "bucket_obj4" {
  bucket = "${aws_s3_bucket.task1.id}"
  key    = "wrong.mp3"
  source = "./gitcode/sounds/wrong.mp3"
  acl	 = "public-read"
}

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_s3_bucket_object" "bucket_obj5" {
  bucket = "${aws_s3_bucket.task1.id}"
  key    = "yellow.mp3"
  source = "./gitcode/sounds/yellow.mp3"
  acl	 = "public-read"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.task1.bucket_regional_domain_name}"
    origin_id   = "${local.s3_origin_id}"

  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "music from s3"
  default_root_object = "index.html"

  
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.s3_origin_id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["IN"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

output "cloudfront_ip_addr"{
value = aws_cloudfront_distribution.s3_distribution.domain_name
}

resource "null_resource" "nullocal1" {
	provisioner "local-exec" {
		command = "echo ${aws_cloudfront_distribution.s3_distribution.domain_name} > cdndomain.txt"
	}
}