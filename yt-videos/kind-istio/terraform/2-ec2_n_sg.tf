# retrieve the latest AMI
data "aws_ami" "latest_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["amazon"]
}

# create EC2 resource
resource "aws_instance" "demo_istio_node" {
  ami           = data.aws_ami.latest_ami.id
  instance_type = var.cluster_node_type
  key_name      = var.key_pair
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.demo_istio_sg.id
  ]
  root_block_device {
    volume_size = 20
  }
  tags =  merge(var.tags, {
    Name = var.node_name
} )
}

resource "aws_security_group" "demo_istio_sg" {
  # Http traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # port forwarding for addons
    #kaili
    ingress {
    from_port   = 20001
    to_port     = 20001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    #grafana
    ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    #prometheus
    ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    #jaeger
    ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}