#!/bin/bash

source utils.sh
ami_id="ami-0655cec52acf2717b"
sec_group_name="webserver group"
install_file="websetup-simple.sh"

if [ "$1" == "custom" ]; then
    install_file="websetup.sh"
fi

mkdir -p $HOME/.aws/
iconv -f WINDOWS-1252 -t UTF-8 credentials > credentials.utf8
sed -i 's/\xE2\x80\x93//g' credentials.utf8
mv credentials.utf8 credentials
cp credentials $HOME/.aws/credentials

var="vpc_id"
prompt="$(get_log_format) Creating a new VPC (cidr: 10.0.0.0/16)"
command="aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Tagging the new VPC name ($jcu_id-vpc)"
command="aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value=$jcu_id-vpc"
async_task "$var" "$command" "$prompt"

var="pub_sub_id"
prompt="$(get_log_format) Creating a new public subnet (AZ: us-east-1a)"
command="aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.0.0/24 --availability-zone us-east-1a --query Subnet.SubnetId --output text"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Tagging the public subnet name ($jcu_id-subnet-public)"
command="aws ec2 create-tags --resources $pub_sub_id --tags Key=Name,Value=$jcu_id-subnet-public"
async_task "$var" "$command" "$prompt"

var="pri_sub_id"
prompt="$(get_log_format) Creating a new private subnet (AZ: us-east-1a)"
command="aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --query Subnet.SubnetId --output text"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Tagging the private subnet name ($jcu_id-subnet-private)"
command="aws ec2 create-tags --resources $pri_sub_id --tags Key=Name,Value=$jcu_id-subnet-private"
async_task "$var" "$command" "$prompt"

var="igw_id"
prompt="$(get_log_format) Creating a new internet gateway"
command="aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Tagging internet gateway ($jcu_id-igw)"
command="aws ec2 create-tags --resources $igw_id --tags Key=Name,Value=$jcu_id-igw"
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
prompt="$(get_log_format) Tagging public subnet route table ($jcu_id-rtb-public)"
command="aws ec2 create-tags --resources $pub_route_tab_id --tags Key=Name,Value=$jcu_id-rtb-public"
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
prompt="$(get_log_format) Tagging NAT gateway ($jcu_id-nat)"
command="aws ec2 create-tags --resources $nat_id --tags Key=Name,Value=$jcu_id-nat"
async_task "$var" "$command" "$prompt"

var="pri_route_tab_id"
prompt="$(get_log_format) Creating route table for private subnet"
command="aws ec2 create-route-table --vpc-id $vpc_id --query RouteTable.RouteTableId --output text"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Tagging private route table ($jcu_id-rtb-private)"
command="aws ec2 create-tags --resources $pri_route_tab_id --tags Key=Name,Value=$jcu_id-rtb-private"
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
command="aws ec2 import-key-pair --key-name webpair --public-key-material fileb://~/.ssh/id_aweb.pub"
async_task "$var" "$command" "$prompt"

var="sec_group_id"
prompt="$(get_log_format) Creating security group for web server"
command="aws ec2 create-security-group --group-name '$sec_group_name' --description 'Security rules specifically for web server' --vpc-id $vpc_id --query 'GroupId' --output text"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Tagging security group ($jcu_id-web-server-group)"
command="aws ec2 create-tags --resources $sec_group_id --tags Key=Name,Value=$jcu_id-web-server-group"
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
prompt="$(get_log_format) Launching EC2 instance (ubuntu, t2.micro, public sub)"
command="aws ec2 run-instances --image-id $ami_id --count 1 --instance-type t2.micro --security-group-ids $sec_group_id --subnet-id $pub_sub_id --associate-public-ip-address --key-name webpair --query \"Instances[0].InstanceId\" --output text"
async_task "$var" "$command" "$prompt"

var=""
prompt="$(get_log_format) Tagging EC2 instance ($jcu_id-web-server)"
command="aws ec2 create-tags --resources $ec2_id --tags Key=Name,Value=$jcu_id-web-server"
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

if [ "$install_file" == "websetup.sh" ]; then
    ssh -i ~/.ssh/id_aweb.pem -o LogLevel=ERROR -o 'StrictHostKeyChecking no' -o 'UserKnownHostsFile /dev/null' ubuntu@$ec2_ip "bash -lc 'source ~/.nvm/nvm.sh; pm2 list'"
fi
