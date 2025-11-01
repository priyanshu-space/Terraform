resource "aws_vpc" "myvpc" {
    cidr_block = var.cidr
}

resource "aws_subnet" "sub1" {
    vpc_id = aws_vpc.myvpc.vpc_id
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
}

resource "aws_subnet" "sub2" {
    vpc_id = aws_vpc.myvpc.vpc_id
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true
}

#IGW:

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.myvpc.vpc_id
}

# Route table: Associates subnets with a route/path for the traffic flow.

resource "aws_route_table" "RT" {
    vpc_id = aws_vpc.myvpc.vpc_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

# Associate the route table with the private subnet

resource "aws_route_table_association" "rta1" {
    subnet_id = aws_subnet.sub1.id
    route_table_id = aws_route_table.RT.id
}

resource "aws_route_table_association" "rta2" {
    subnet_id = aws_subnet.sub2.id
    route_table_id = aws_route_table.RT.id
}

# configure security group and its inbound(ingress) and outbound(egress) rules

resource "aws_security_group" "webSg" {
    name = "websg"
    vpc_id = aws_vpc.myvpc.id

    ingress {
        description = "HTTP from VPC"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_block = ["0.0.0.0/0"]
    }
    ingress {
        description = "SSH from VPC"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_block = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_block = ["0.0.0.0/0"]
    }

    tags = {
        Name = "web-sg"
    }
}

resource "aws_s3_bucket" "example" {
    bucket = "priyanshuterraform2025project"
}

#code to make the bucket public

# configure aws ec2 instance

resource "aws_instance" "webserver1" {
  ami           = "ami-005e54dee72cc1d00" # us-west-2
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id = aws.subnet.sub1.id
  user_data = base64encode(file(userdata.sh))
}

resource "aws_instance" "webserver2" {
  ami           = "ami-005e54dee72cc1d00" # us-west-2
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id = aws.subnet.sub2.id
  user_data = base64encode(file(userdata1.sh))
}
# create alb: layer-7 load balancer

resource "aws_lb" "myalb" {
    name = "myalb"
    internal = false
    load_balancer_type = "application"

    security_groups = [aws_security_group_webSg.id]
    subnets = [aws_subnet.sub1.id, aws_subnet.sub2.id]
}