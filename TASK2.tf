provider "aws" {
  region = "ap-south-1"
  profile = "gajju"
}


resource "aws_security_group" "s1" {
  name        = "s1"
  description = "Allow SSH and HTTP"
  vpc_id      = "vpc-67f4e90f"
  

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "s1"
  }
}


resource "aws_instance" "gajju" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  subnet_id = "subnet-b30d37db"
  key_name = "mykey111222"
  security_groups = ["${aws_security_group.s1.id}"]
  tags = {
    Name = "gajju"
  }

}


resource "aws_efs_file_system"  "foo"{
	creation_token="my-product"
  tags={
       Name= "my-product"
 }
}


resource "aws_efs_mount_target"  "EFS_M1"{
  file_system_id= aws_efs_file_system.foo.id
   subnet_id = "subnet-b30d37db"
   security_groups = ["${aws_security_group.s1.id}"]
}
resource "null_resource" "VOLUME1" {
  depends_on = [
    aws_efs_mount_target.EFS_M1,
  ]
connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/black/Downloads/aws-credentials/mykey111222.pem")
    host     = aws_instance.gajju.public_ip
  }

provisioner "remote-exec"{
   
       inline = [
         
          "sudo yum install httpd php git -y",
	  "sudo systemctl start httpd",
	  "sudo systemctl enable httpd",
          "sudo mkfs.ext4  /dev/xvdf",
          "sudo rm -rf /var/www/html/*",
          "sudo mount  /dev/xvdf  /var/www/html",
          "sudo git clone https://github.com/PRINCE1409/TASK-2-HYBRID.git /html_repo",
	  "sudo cp -r /html_repo/* /var/www/html",
	  "sudo rm -rf /html_repo"
         ]

    }
}


resource "aws_s3_bucket" "bucket1" {
  bucket = "gajjubucket1"
  acl    = "public-read"
  force_destroy = true
  versioning {
 enabled = true
} 
  tags = {
    Name        = "gajjubucket1"
  }
}

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_s3_bucket_object" "uploading_object" {
  bucket = aws_s3_bucket.bucket1.bucket
  key    = "task_img.png"
  acl = "private"
  force_destroy = true
  source = "C:/Users/black/Downloads/favicon.png"
  etag = filemd5("C:/Users/black/Downloads/favicon.png")
  depends_on= [aws_s3_bucket.bucket1]
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.bucket1.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

 

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

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

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false


      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

 

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["IN"]
    }
  }
  tags = {
    Environment = "pop"
  }


 
  viewer_certificate {
    cloudfront_default_certificate = true
  }


connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/black/Downloads/aws-credentials/mykey111222.pem")
    host     = aws_instance.gajju.public_ip
  }

}
