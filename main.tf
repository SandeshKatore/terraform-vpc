################################################################################
# VPC
################################################################################

resource "aws_vpc" "myVPC" {                  //api name aws_vpc
  cidr_block                       = var.cidr
  enable_dns_hostnames             = var.enable_dns_hostnames
  enable_dns_support               = var.enable_dns_support
  tags = {
    Name = var.vpc_name        //vpc name
  }
}

###############################################################################
# Internet Gateway
###############################################################################

resource "aws_internet_gateway" "myIGW" {             //api name aws_internet_gateway

  vpc_id = aws_vpc.myVPC.id        //created vpc id  attach after creating vpc (executing first loop)
  tags = {
    "Name" = var.igw_tag          //igw name
  }
}

################################################################################
# Public subnet
################################################################################

resource "aws_subnet" "public_subnet_1" {                  //api name aws_subnet
  vpc_id                          = aws_vpc.myVPC.id        //creating subnet in created vpc
  cidr_block                      = var.public_subnets_cidr_1
  availability_zone               = data.aws_availability_zones.available_1.names[0]  //for creating subnet in region , sometime some AZ are not create subnet so due to array it will check subnets one after another till creating...Max array value is 5 but always try with 0
  map_public_ip_on_launch         = var.map_public_ip_on_launch  //giving public ip

  tags = {
   Name = var.public_subnet_tag_1    //subnet name
  }
}
resource "aws_subnet" "public_subnet_2" {
  vpc_id                          = aws_vpc.myVPC.id
  cidr_block                      = var.public_subnets_cidr_2
  availability_zone               = data.aws_availability_zones.available_1.names[1] //give alternate values
  map_public_ip_on_launch         = var.map_public_ip_on_launch

  tags = {
   Name = var.public_subnet_tag_2
  }
}

################################################################################
# Database subnet
################################################################################

resource "aws_subnet" "database_subnet_1" {
  vpc_id                          = aws_vpc.myVPC.id
  cidr_block                      = var.database_subnets_cidr_1
  availability_zone               = data.aws_availability_zones.available_1.names[0]
  map_public_ip_on_launch         = false      //no need to give public ip

  tags = {
    Name = var.database_subnet_tag_1
  }
}
resource "aws_subnet" "database_subnet_2" {
  vpc_id                          = aws_vpc.myVPC.id
  cidr_block                      = var.database_subnets_cidr_2
  availability_zone               = data.aws_availability_zones.available_1.names[1]
  map_public_ip_on_launch         = false

  tags = {
    Name = var.database_subnet_tag_2
  }
}

################################################################################
# Publiс routes
################################################################################

resource "aws_route_table" "public_route_table" {     //api name aws_route_table
  vpc_id = aws_vpc.myVPC.id                           //connect to vpc
  tags = {
    Name = var.public_route_table_tag       //route_table_name
  }
}
resource "aws_route" "public_internet_gateway" {            //attach route table to internet
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.myIGW.id
}

################################################################################
# Database route table
################################################################################

resource "aws_route_table" "database_route_table" {
  vpc_id = aws_vpc.myVPC.id      //create in that vpc

  tags = {
    Name = var.database_route_table_tag      //route table name
  }
}

################################################################################
# Route table association with subnets
################################################################################

resource "aws_route_table_association" "public_route_table_association_1" {    //api name aws_route_table_association
  subnet_id      = aws_subnet.public_subnet_1.id             //add subnet association with routes table
  route_table_id = aws_route_table.public_route_table.id     
}
resource "aws_route_table_association" "public_route_table_association_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_route_table_association" "database_route_table_association_1" {
  subnet_id      = aws_subnet.database_subnet_1.id
  route_table_id = aws_route_table.database_route_table.id
}
resource "aws_route_table_association" "database_route_table_association_2" {
  subnet_id      = aws_subnet.database_subnet_2.id
  route_table_id = aws_route_table.database_route_table.id
}

###############################################################################
# Security Group
###############################################################################

resource "aws_security_group" "sg" {      //api name aws_security_group
  name        = "tcw_security_group"      //here we give hardcore value we can store it in variable file
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.myVPC.id          //creating in that vpc

  ingress = [                       //inbound rules
    {
      description      = "All traffic"
      from_port        = 0    # All ports
      to_port          = 0    # All Ports
      protocol         = "-1" # All traffic
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    }
  ]

  egress = [                 //outbound_rules
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      description      = "Outbound rule"
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    }
  ]

  tags = {
    Name = "tcw_security_group"        //sg name
  }
}
