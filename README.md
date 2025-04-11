# Introduction
A custom script that can build the following AWS architecture in 1 line, with variables for easy customization.
The project is used to quickly setup a working aws ec2 instance with ssh pre-configured so students can start
experiencing the most of AWS EC2 features without having to re-install all the components every 1.5 hours when
the lab is terminated due to time limit.

# Architecture Overview
![General Architecture for AWS](/assets/architecture.png)

# Pre-Installation
## Windows
- Download and Install git bash from [here](https://git-scm.com/downloads)
- Launch "Git Bash" program on your machine
- Run this command in git bash to install  aws-cli (v2) using msiexec
 ```
 powershell -Command "msiexec /i https://awscli.amazonaws.com/AWSCLIV2.msi /norestart"
 ```

## MacOS
- Open up the terminal on your machine
- Run the following command to install aws-cli (v2)
```
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```


## Linux
+ Open up the terminal on your machine
+ Use your distro package manager to install aws-cli (v2) or just run the following commands:
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```


# Instructions
1. Open the aws lab environment from the practical no.5 of the subject
2. Start the aws lab session and wait for it to start
3. Click on "AWS details" on the top right of the screen
![General Instructon 1 for AWS](/assets/instructions1.png)

4. Click "show" in the AWS-CLI section and copy the credential
![General Instructon 2 for AWS](/assets/instructions2.png)
   
5. Open terminal (or git bash) and run aws configure (skip most prompts except "region") (insert "east-us-1)
![General Instructon 2 for AWS](/assets/configure.png)

6. Clone the repository back to your local machine
```
git clone https://github.com/DragMaid/CP2501-Auto-Script.git
```
7. Change directory into the project
```
cd CP2501-Auto-Script
```
8. Open the "credentials" file in that directory and paste in the "<credential>" you copied before
9. Set the jcu_id variable so it dynamically assign your id to the project
```
export jcu_id="your_jcu_id"
```
11. Finally run the setup script in the same directory
```
bash ./setup.sh
```
10. Sit back and enjoy the show

# Requirements
- [x] Rename VPC (id-vcp)
- [x] Rename private subnet (id-subnet-private)
- [x] Rename public subnet (id-subnet-public)
- [x] Rename public route table (id-rtb-public)
- [x] Renme private route table (id-rtb-private)
- [x] Rename internet gateway (id-igw)
- [x] Rename nat gateway (id-nat)
- [x] Rename security group

# Modifications
- [ ] Change name of variables
- [ ] Change final website display (there's an example of a custom nodejs website being ran if you add the "custom argument after "setup.sh")
- [ ] Change ami image (make sure to keep it a linux environment)
