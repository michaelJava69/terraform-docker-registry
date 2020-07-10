provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
}


terraform {
  backend "s3" {

    # This backend configuration is filled in automatically at test time by Terratest. If you wish to run this example
    # manually, uncomment and fill in the config below.

     bucket         = "terraform-s3-docker-registry"
     key            = "terraform/terraform.tfstate"
     region         = "us-east-2"
     dynamodb_table = "terraform-s3-docker-registry-locks"
     encrypt        = true

  }
}



# We could create an extra VPC, properly set a subnet and
# have the whole thing configured (internet gateway, an updated
# routing table etc).
#
# However, given that this is only a sample, we can make use of
# the default VPC (assuming you didn't delete your default VPC
# in your region, you can too).
data "aws_vpc" "main" {
  default = true
}

# Provide the public key that we want in our instance so we can
# SSH into it using the other side (private) of it.
resource "aws_key_pair" "main" {
  key_name_prefix = "sample-key"
  public_key      = "${file("./keys/key.rsa.pub")}"
}

# Create a security group that allows anyone to access our
# instance's port 5000 (where the main registry functionality
# lives).
#
# Naturally, you'd not do this if you're deploying a private
# registry - something you could do is allow the internal cidr
# and not 0.0.0.0/0.
resource "aws_security_group" "allow-registry-ingress" {
  name = "allow-registry-ingress"

  description = "Allows ingress SSH traffic and egress to any address."
  vpc_id      = "${data.aws_vpc.main.id}"

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }




  tags = {
    Name = "allow_registry-ingress"
  }
}

# Allow SSHing into the instance
resource "aws_security_group" "allow-ssh-and-egress" {
  name = "allow-ssh-and-egress"

  description = "Allows ingress SSH traffic and egress to any address."
  vpc_id      = "${data.aws_vpc.main.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
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

  tags = {
    Name = "allow_ssh-and-egress"
  }
}

# Template the registry configuration with the desired
# bucket and region information.
#
# Note.: no credentials are needed given that the golang
# aws sdk is going to retrieve them from the instance
# role that we set to the machine.
data "template_file" "registry-config" {
  template = "${file("./registry.yml.tpl")}"

  vars = {
    bucket = "${var.bucket}"
    region = "${var.region}"
  }
}

# Template the instance initialization script with information
# regarding the region and bucket that the user configured.
data "template_cloudinit_config" "init" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"

    content = <<EOF
#cloud-config
write_files:
  - content: ${base64encode("${data.template_file.registry-config.rendered}")}
    encoding: b64
    owner: root:root
    path: /etc/registry.yml
    permissions: '0755'
EOF
  }


  part {
    content_type = "text/x-shellscript"
    content      = "${file("./instance-init.sh")}"
  }




}

#resource null_resource "ansible_web" {
#  depends_on = [
#    "aws_instance.main"
#  ]

#  provisioner "local-exec" {
#    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key '${var.ansible_pem_key}' -i '${aws_instance.main.public_ip},' ansible/main.yml"
#  }
#}


# Create an instance in the default VPC with a specified
# SSH key so we can properly SSH into it to verify whether
# everything is worked as intended.
resource "aws_instance" "main" {
  instance_type        = "t2.micro"
  ami                  = "${data.aws_ami.ubuntu.id}"
  # key_name             = "${aws_key_pair.main.id}"
  key_name 		= "${var.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.main.name}"
  user_data            = "${data.template_cloudinit_config.init.rendered}"

  tags = {
     Name = "terraform-docker-registry"
  }


  provisioner "file" {
    source      = "nginx_sblock.sh"
    destination = "/tmp/nginx_sblock.sh"
    # destination = "/var/lib/cloud/scripts/per-boot/dns.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("Michael-EU-West2.pem")}"
      host        = "${self.public_dns}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod u+x /tmp/nginx_sblock.sh",
      "cd ..",
      "cd ..",
      "sleep 2m",
      "sudo ./tmp/nginx_sblock.sh"

    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("Michael-EU-West2.pem")}"
      host        = "${self.public_dns}"
    }

  }

  vpc_security_group_ids = [
    "${aws_security_group.allow-ssh-and-egress.id}",
    "${aws_security_group.allow-registry-ingress.id}",
  ]
}

output "public-ip" {
  description = "Public IP of the instance created"
  value       = "${aws_instance.main.public_ip}"
}
