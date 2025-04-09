jcu_id="jd144026"

vpc_id=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text)
aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value=$jcu_id-vpc

pub_sub_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.0.0/24 --availability-zone us-east-1a --query Subnet.SubnetId --output text)
aws ec2 create-tags --resources $pub_sub_id --tags Key=Name,Value=$jcu_id-subnet-public

pri_sub_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --query Subnet.SubnetId --output text)
aws ec2 create-tags --resources $pri_sub_id --tags Key=Name,Value=$jcu_id-subnet-private

igw_id=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)
aws ec2 create-tags --resources $igw_id --tags Key=Name,Value=$jcu_id-igw

aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $igw_id

pub_route_tab_id=$(aws ec2 create-route-table --vpc-id $vpc_id --query RouteTable.RouteTableId --output text)
aws ec2 create-tags --resources $pub_route_tab_id --tags Key=Name,Value=$jcu_id-rtb-public
aws ec2 create-route --route-table-id $pub_route_tab_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id
aws ec2 associate-route-table --route-table-id $pub_route_tab_id --subnet-id $pub_sub_id

elas_ip_id=$(aws ec2 allocate-address --domain vpc --query AllocationId --output text)

nat_id=$(aws ec2 create-nat-gateway --subnet-id $pub_sub_id --allocation-id $elas_ip_id --query NatGateway.NatGatewayId --output text)
aws ec2 create-tags --resources $nat_id --tags Key=Name,Value=$jcu_id-nat

pri_route_tab_id=$(aws ec2 create-route-table --vpc-id $vpc_id --query RouteTable.RouteTableId --output text)
aws ec2 create-tags --resources $pri_route_tab_id --tags Key=Name,Value=$jcu_id-rtb-private
aws ec2 create-route --route-table-id $pri_route_tab_id --destination-cidr-block 0.0.0.0/0 --gateway-id $nat_id
aws ec2 associate-route-table --route-table-id $pri_route_tab_id --subnet-id $pri_sub_id

aws ec2 import-key-pair --key-name webpair --public-key-material fileb://~/.ssh/id_aweb.pub

sec_group_id=$(aws ec2 create-security-group --group-name "webserver group" --description "new security group" --vpc-id $vpc_id --query 'GroupId' --output text)
aws ec2 create-tags --resources $sec_group_id --tags Key=Name,Value=$jcu_id-web-server-group

aws ec2 authorize-security-group-ingress --group-id $sec_group_id --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sec_group_id --protocol tcp --port 22 --cidr 0.0.0.0/0

ami_id="ami-0655cec52acf2717b"
ec2_id=$(aws ec2 run-instances --image-id $ami_id --count 1 --instance-type t2.micro --security-group-ids $sec_group_id --subnet-id $pub_sub_id --associate-public-ip-address --key-name webpair --query "Instances[0].InstanceId" --output text)
aws ec2 create-tags --resources $ec2_id --tags Key=Name,Value=$jcu_id-web-server

ec2_ip=$(aws ec2 describe-instances --instance-ids "$ec2_id" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
ssh -i ~/.ssh/id_aweb.pem ubuntu@$ec2_ip
