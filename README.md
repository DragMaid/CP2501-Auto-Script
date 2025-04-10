# Introduction
A custom script that can build the following AWS architecture in 1 line, with variables for easy customization.
The project is used to quickly setup a working aws ec2 instance with ssh pre-configured so students can start
experiencing the most of AWS EC2 features without having to re-install all the components every 1.5 hours when
the lab is terminated due to time limit.

# Architecture Overview
![General Architecture for AWS](/assets/architecture.png)

# Pre-Installation
## Windows
+ Option 1: Just use windows Powershell to run the script (do be aware of the dependencies since you'll need git, ssh and you'll need to edit the ssh key location in the script, hence I preferably recommend option 2)
+ Option 2: Download and install WSL on your machine [instructions](https://learn.microsoft.com/en-us/windows/wsl/install) then download your desired distro on the Microsoft Store
## Linux
+ Install "aws-cli-v2" via your distro package manager. For the arch users out there:
```
sudo pacman -S aws-cli-v2
```

# Instructions
1. Open the aws lab environment from the practical no.5 of the subject
2. Clone the repository back to your local machine
3. Start the aws lab session and wait for it to start
4. Click on "AWS details" on the top right of the screen
5. Click show in the AWS-CLI section and copy the code block
6. Run aws configure (skip most prompts except region - insert us-east-1 (the only region available))
7. Open the file ~/.aws/credentials with a code editor and paste the previously copied code block
8. Run "bash setup.sh" in the project directory
9. Sit back and enjoy the show

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
- [ ] Change final website display
- [ ] Change ami image (make sure to keep it a linux environment)
