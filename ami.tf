# Pick the latest ubuntu bionic  (18.04) ami released by the
# Canonical team.
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"

    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}
