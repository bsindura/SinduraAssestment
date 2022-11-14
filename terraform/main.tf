resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags       = {
    Name     = "${var.prefix}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id  = aws_vpc.main.id

  tags    = {
    Name = "${var.prefix}-igw"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_range

  tags = {
    Name = "${var.prefix}-public-sn"
  }
}

resource "aws_route_table" "main" {
  vpc_id        = aws_vpc.main.id

  route {
    cidr_block  = "0.0.0.0/0"
    gateway_id  = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.prefix}-public-rt"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "main" {
  name        = "${var.prefix}-public-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-public-sg"
  }
}

resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.main.id
}

resource "aws_network_interface" "main" {
  subnet_id   = aws_subnet.main.id
  security_groups = [aws_security_group.main.id]


  tags = {
    Name = "${var.prefix}-public-nic"
  }
}

resource "aws_eip" "main" {
  vpc   = true
  tags  = {
    Name = "${var.prefix}-eip"
  }
}

resource "aws_instance" "main" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  # security_groups = [aws_security_group.main.id]

  network_interface {
    network_interface_id = aws_network_interface.main.id
    device_index         = 0
  }

#   user_data = <<EOF
# echo "INFO: Installing required packages"
# sudo apt-get update -y
# sudo apt-get install ca-certificates curl gnupg lsb-release -y

# sudo mkdir -p /etc/apt/keyrings
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# echo \
#   "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
#   \$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# echo "Installing the Docker Engine"
# sudo apt-get update -y

# if [[ \$? -ne 0 ]]; then
# 	echo "Incase of any GPG error"
# 	sudo chmod a+r /etc/apt/keyrings/docker.gpg
# 	sudo apt-get update
# fi

# sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

# echo "INFO: Starting the docker service"
# sudo systemctl start docker

# echo "INFO: Enabling the docker server"
# sudo systemctl enable docker
# EOF
  tags = {
    Name = "${var.prefix}-vm"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.main.id
  allocation_id = aws_eip.main.id
}
