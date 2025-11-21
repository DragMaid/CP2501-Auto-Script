#!/bin/bash

source utils.sh
ami_id="ami-0655cec52acf2717b"
sec_group_name="webserver group"
sec_group_description="Security rules specifically for web server"
install_file="websetup-simple.sh"
key_pair_name="webpair"
instance_type="t2.micro"
vpc_cidr="10.0.0.0/16"
pub_subnet_cidr="10.0.0.0/24"
pri_subnet_cidr="10.0.1.0/24"
availability_zone="us-east-1a"

# Tag values for consistent naming
vpc_tag="$jcu_id-vpc"
pub_subnet_tag="$jcu_id-subnet-public"
pri_subnet_tag="$jcu_id-subnet-private"
igw_tag="$jcu_id-igw"
nat_tag="$jcu_id-nat"
pub_rtb_tag="$jcu_id-rtb-public"
pri_rtb_tag="$jcu_id-rtb-private"
sec_group_tag="$jcu_id-web-server-group"
instance_tag="$jcu_id-web-server"

if [ "$1" == "custom" ]; then
    install_file="websetup.sh"
fi

mkdir -p $HOME/.aws/
iconv -f WINDOWS-1252 -t UTF-8 credentials > credentials.utf8
sed -i 's/\xE2\x80\x93//g' credentials.utf8
mv credentials.utf8 credentials
cp credentials $HOME/.aws/credentials

var="vpc_id"
prompt="$(get_log_format) Creating a new VPC (cidr: $vpc_cidr)"
command="aws ec2 create-vpc --cidr-block $vpc_cidr --query Vpc.VpcId --output text"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Tagging the new VPC name ($vpc_tag)"
command="aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value=$vpc_tag"
async_task "$var" "$command" "$prompt"

var="pub_sub_id"
prompt="$(get_log_format) Creating a new public subnet (AZ: $availability_zone)"
command="aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $pub_subnet_cidr --availability-zone $availability_zone --query Subnet.SubnetId --output text"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Tagging the public subnet name ($pub_subnet_tag)"
command="aws ec2 create-tags --resources $pub_sub_id --tags Key=Name,Value=$pub_subnet_tag"
async_task "$var" "$command" "$prompt"

var="pri_sub_id"
prompt="$(get_log_format) Creating a new private subnet (AZ: $availability_zone)"
command="aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $pri_subnet_cidr --availability-zone $availability_zone --query Subnet.SubnetId --output text"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Tagging the private subnet name ($pri_subnet_tag)"
command="aws ec2 create-tags --resources $pri_sub_id --tags Key=Name,Value=$pri_subnet_tag"
async_task "$var" "$command" "$prompt"

var="igw_id"
prompt="$(get_log_format) Creating a new internet gateway"
command="aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Tagging internet gateway ($igw_tag)"
command="aws ec2 create-tags --resources $igw_id --tags Key=Name,Value=$igw_tag"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Attaching internet gateway to VPC"
command="aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $igw_id"
async_task "$var" "$command" "$prompt"

var="pub_route_tab_id"
prompt="$(get_log_format) Creating route table for public subnet"
command="aws ec2 create-route-table --vpc-id $vpc_id --query RouteTable.RouteTableId --output text"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Tagging public subnet route table ($pub_rtb_tag)"
command="aws ec2 create-tags --resources $pub_route_tab_id --tags Key=Name,Value=$pub_rtb_tag"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Creating route on public route table (redirect traffic to internet gateway)"
command="aws ec2 create-route --route-table-id $pub_route_tab_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Associating public route table with public subnet"
command="aws ec2 associate-route-table --route-table-id $pub_route_tab_id --subnet-id $pub_sub_id"
async_task "$var" "$command" "$prompt"

var="elas_ip_id"
prompt="$(get_log_format) Allocating Elastic IP for NAT gateway"
command="aws ec2 allocate-address --domain vpc --query AllocationId --output text"
async_task "$var" "$command" "$prompt"

var="nat_id"
prompt="$(get_log_format) Creating NAT gateway in public subnet"
command="aws ec2 create-nat-gateway --subnet-id $pub_sub_id --allocation-id $elas_ip_id --query NatGateway.NatGatewayId --output text"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Tagging NAT gateway ($nat_tag)"
command="aws ec2 create-tags --resources $nat_id --tags Key=Name,Value=$nat_tag"
async_task "$var" "$command" "$prompt"

var="pri_route_tab_id"
prompt="$(get_log_format) Creating route table for private subnet"
command="aws ec2 create-route-table --vpc-id $vpc_id --query RouteTable.RouteTableId --output text"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Tagging private route table ($pri_rtb_tag)"
command="aws ec2 create-tags --resources $pri_route_tab_id --tags Key=Name,Value=$pri_rtb_tag"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Creating route from private subnet to NAT gateway"
command="aws ec2 create-route --route-table-id $pri_route_tab_id --destination-cidr-block 0.0.0.0/0 --gateway-id $nat_id"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Associating private route table with private subnet"
command="aws ec2 associate-route-table --route-table-id $pri_route_tab_id --subnet-id $pri_sub_id"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Generating SSH key pair"
command="bash ./keygen.sh"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Importing SSH public key to AWS"
command="aws ec2 import-key-pair --key-name $key_pair_name --public-key-material fileb://~/.ssh/id_aweb.pub"
async_task "$var" "$command" "$prompt"

var="sec_group_id"
prompt="$(get_log_format) Creating security group for web server"
command="aws ec2 create-security-group --group-name '$sec_group_name' --description '$sec_group_description' --vpc-id $vpc_id --query 'GroupId' --output text"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Tagging security group ($sec_group_tag)"
command="aws ec2 create-tags --resources $sec_group_id --tags Key=Name,Value=$sec_group_tag"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Allowing HTTP (port 80) ingress in security group"
command="aws ec2 authorize-security-group-ingress --group-id $sec_group_id --protocol tcp --port 80 --cidr 0.0.0.0/0"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Allowing SSH (port 22) ingress in security group"
command="aws ec2 authorize-security-group-ingress --group-id $sec_group_id --protocol tcp --port 22 --cidr 0.0.0.0/0"
async_task "$var" "$command" "$prompt"

var="ec2_id"
prompt="$(get_log_format) Launching EC2 instance (ubuntu, $instance_type, public sub)"
command="aws ec2 run-instances --image-id $ami_id --count 1 --instance-type $instance_type --security-group-ids $sec_group_id --subnet-id $pub_sub_id --associate-public-ip-address --key-name $key_pair_name --query \"Instances[0].InstanceId\" --output text"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Tagging EC2 instance ($instance_tag)"
command="aws ec2 create-tags --resources $ec2_id --tags Key=Name,Value=$instance_tag"
async_task "$var" "$command" "$prompt"

var="ec2_ip"
prompt="$(get_log_format) Retrieving EC2 instance public IPv4"
command="aws ec2 describe-instances --instance-ids \"$ec2_id\" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Waiting for EC2 instance to finish initializing"
command="source ./utils.sh; wait_ec2_init 10 $ec2_id"
async_task "$var" "$command" "$prompt"

iconv -f WINDOWS-1252 -t UTF-8 ./$install_file > ./$install_file.utf8
sed -i 's/\xE2\x80\x93//g' ./$install_file.utf8
sed -i 's/\r//g' ./$install_file
mv ./$install_file.utf8 ./$install_file
chmod +x ./$install_file

var=""
prompt="$(get_log_format) Copying web server setup file to EC2 instance"
command="scp -i ~/.ssh/id_aweb.pem -o LogLevel=ERROR -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ./$install_file ubuntu@$ec2_ip:/home/ubuntu/websetup.sh"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Setting up webserver on EC2 instance via SSH"
command="ssh -i ~/.ssh/id_aweb.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@$ec2_ip '~/websetup.sh $jcu_id 2>&1 | tee webserver.log'"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Retrieving web server setup logfile to local machine"
command="scp -i ~/.ssh/id_aweb.pem -o LogLevel=ERROR -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@$ec2_ip:/home/ubuntu/webserver.log ./webserver.log"
async_task "$var" "$command" "$prompt"

echo "$(get_log_format SUCCESS) EC2 instance successfully created with id: $ec2_id"
echo "$(get_log_format SUCCESS) Server is now up and running on IP: $ec2_ip (port: 80)"
echo "$(get_log_format INFO) You can now access your website at http://$ec2_ip"

if [ "$install_file" == "websetup.sh" ]; then
    ssh -i ~/.ssh/id_aweb.pem -o LogLevel=ERROR -o 'StrictHostKeyChecking no' -o 'UserKnownHostsFile /dev/null' ubuntu@$ec2_ip "bash -lc 'source ~/.nvm/nvm.sh; pm2 list'"
fi

# Generate command list based on template
echo ""
echo "$(get_log_format INFO) Generating command list output..."
cat > aws_commands_list.txt << EOF
# AWS Infrastructure Setup Commands
# Generated on $(date)
# JCU ID: $jcu_id

aws ec2 create-vpc --cidr-block $vpc_cidr
aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value=$vpc_tag
aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $pub_subnet_cidr
aws ec2 create-tags --resources $pub_sub_id --tags Key=Name,Value=$pub_subnet_tag
aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $pri_subnet_cidr
aws ec2 create-tags --resources $pri_sub_id --tags Key=Name,Value=$pri_subnet_tag
aws ec2 create-internet-gateway
aws ec2 create-tags --resources $igw_id --tags Key=Name,Value=$igw_tag
aws ec2 attach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id
aws ec2 allocate-address --domain vpc
aws ec2 create-nat-gateway --subnet-id $pub_sub_id --allocation-id $elas_ip_id
aws ec2 create-tags --resources $nat_id --tags Key=Name,Value=$nat_tag
aws ec2 create-route-table --vpc-id $vpc_id
aws ec2 create-tags --resources $pub_route_tab_id --tags Key=Name,Value=$pub_rtb_tag
aws ec2 create-tags --resources $pri_route_tab_id --tags Key=Name,Value=$pri_rtb_tag
aws ec2 create-route --route-table-id $pub_route_tab_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id
aws ec2 create-route --route-table-id $pri_route_tab_id --destination-cidr-block 0.0.0.0/0 --gateway-id $nat_id
aws ec2 associate-route-table --route-table-id $pub_route_tab_id --subnet-id $pub_sub_id
aws ec2 associate-route-table --route-table-id $pri_route_tab_id --subnet-id $pri_sub_id
aws ec2 create-security-group --group-name "$sec_group_name" --description "$sec_group_description" --vpc-id $vpc_id
aws ec2 create-tags --resources $sec_group_id --tags Key=Name,Value=$sec_group_tag
aws ec2 authorize-security-group-ingress --group-id $sec_group_id --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sec_group_id --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 create-key-pair --key-name cli-keyPair --query 'KeyMaterial' --output text > cli-keyPair.pem
chmod 400 cli-keyPair.pem
aws ec2 run-instances --image-id $ami_id --instance-type $instance_type --count 1 --subnet-id $pub_sub_id --security-group-ids $sec_group_id --associate-public-ip-address --key-name cli-keyPair
aws ec2 create-tags --resources $ec2_id --tags Key=Name,Value=$instance_tag
aws ec2 describe-instances --instance-ids $ec2_id --query 'Reservations[].Instances[].PublicDnsName'
ssh -i "cli-keyPair.pem" ec2-user@$ec2_ip
sudo yum install httpd -y
sudo service httpd start
cd /var/www/html
echo "<h1>Hello from $jcu_id web server</h1>" > index.html
EOF

echo "$(get_log_format SUCCESS) Command list generated: aws_commands_list.txt"
