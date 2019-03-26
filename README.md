# Preparation
In order to start using Terraform and access AWS cloud, I performed the below steps:
* Created a new AWS account with free tier
* Created a separate use with the below permissions:
  *  AmazonEC2FullAccess
  *  AmazonS3FullAccess
  *  AmazonRDSFullAccess
* Generated the access keys (Access key ID, and Secret access key)
* Installed AWS CLI using pip3
* Configured AWS credentials in the laptop using `aws configure`, which stored the credentials in the file `~/.aws/credentials`
* Installed Terraform version `v0.11.13` binary in the laptop and updated the `$PATH` variable to make Terraform binary accessible from anywhere in the CLI 
* Installed Terraform plugin in `Visual Studio Code`

## Repository Creation
Executed the below steps to initialize the repository:
1. Created the `deploy_it` directory
2. Initilized the git repository inside the directory using
   `git init`
1. Created the below files in the directory
   * `deployment.tf` : will include the Terraform code for all the solution
   * `README.md` : documentation file
   * `.gitignore` : to ignore files which should not be included in the git repository, this includes the below files:
     * `.terraform` directory which is used as cache by Terraform
     * `*.tfstate` and `*.tfstate.backup` ignore Terraform local state files

Code generated in exercises 0, 1, 2 is not included in the repository

# Exercise 3 : A simple web server

####Using only Terraform, deploy the latest available Ubuntu 18.04 server AMI in the region of your choice (using the free t2.micro instance type). Document how you found the AMI.** 

By Googling for how to find the latest Ubuntu server AMI, I got the below link:

https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/finding-an-ami.html

Specifically the below command finds the latest Ubuntu 16.04 server AMI

`aws ec2 describe-images --owners 099720109477 --filters 'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-????????' 'Name=state,Values=available' --output json | jq -r '.Images | sort_by(.CreationDate) | last(.[]).ImageId'`

By changing 16.04 into 18.04 and executing the command again without the `--output` option, I found that AMIs are described in the below format:

```
{
            "Architecture": "x86_64",
            "CreationDate": "2018-11-26T17:52:59.000Z",
            "ImageId": "ami-0d2505740b82f7948",
            "ImageLocation": "099720109477/ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-20181124",
            "ImageType": "machine",
            "Public": true,
            "OwnerId": "099720109477",
            "State": "available",
            "BlockDeviceMappings": [
                {
                    "DeviceName": "/dev/sda1",
                    "Ebs": {
                        "DeleteOnTermination": true,
                        "SnapshotId": "snap-099254c67ff32ec51",
                        "VolumeSize": 8,
                        "VolumeType": "gp2",
                        "Encrypted": false
                    }
                },
                {
                    "DeviceName": "/dev/sdb",
                    "VirtualName": "ephemeral0"
                },
                {
                    "DeviceName": "/dev/sdc",
                    "VirtualName": "ephemeral1"
                }
            ],
            "Description": "Canonical, Ubuntu, 18.04 LTS, amd64 bionic image build on 2018-11-24",
            "EnaSupport": true,
            "Hypervisor": "xen",
            "Name": "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-20181124",
            "RootDeviceName": "/dev/sda1",
            "RootDeviceType": "ebs",
            "SriovNetSupport": "simple",
            "VirtualizationType": "hvm"
        }
```
And AMIs names are stored in the below format:

`"Name": "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-20181124",`

In order to search for Ubuntu 18.04, I had to update the `--filters` as below:

`--filters 'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu*18.04-amd64-server-*'`

Executing the updated command generated the below output

```
aws ec2 describe-images --owners 099720109477 --filters 'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu*18.04-amd64-server-*' 'Name=state,Values=available' --output json | jq -r '.Images | sort_by(.CreationDate) | last(.[]).ImageId'
ami-07025b83b4379007e
```

Accordingly, the most recent Ubuntu 18.04 AMI is `ami-07025b83b4379007e`

To search for the AMI in Terraform file, used a Data Source with the below filters:

```
data "aws_ami" "latest_ubuntu_ami" {
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu*18.04-amd64-server-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  # Return only the most recent image
  most_recent = true
}
```

Created the instance using `aws_instance`, and used the AMI ID retrieved in the `latest_ubuntu_ami` data source 

```
resource "aws_instance" "web_server" {
  ami           = "${data.aws_ami.latest_ubuntu_ami.id}"
  instance_type = "t2.micro"
}
```

####The instance must have a public IP address (OK if dynamic; find out how to ask Terraform about the current value of a dynamic IP address) and a security group that allows inbound connections only to port 80 add 22.

To extract the public ip of the created instance, defined the below variable

```
output "ws_public_ip" {
  description = "Public IP of the web server"
  value       = "${aws_instance.web_server.public_ip}"
}
```

To allow inbound traffic in ports 80 and 22, defined the below security group

```
variable "ws_http_port" {
  description = "Default Web Server HTTP port"
  default     = "80"
}

variable "ws_ssh_port" {
  description = "Default Web Server SSH port"
  default     = "22"
}

variable "ws_cidr" {
  description = "CIDR to receive traffic from all hosts"
  default     = ["0.0.0.0/0"]
}

resource "aws_security_group" "ws_sg" {
  description = "Web server security group"

  # Allow incoming traffic in port 80
  ingress {
    from_port   = "${var.ws_http_port}"
    to_port     = "${var.ws_http_port}"
    cidr_blocks = "${var.ws_cidr}"
    protocol    = "tcp"
  }

  # Allow incoming traffic in port 22
  ingress {
    from_port   = "${var.ws_ssh_port}"
    to_port     = "${var.ws_ssh_port}"
    cidr_blocks = "${var.ws_cidr}"
    protocol    = "tcp"
  }
}
```

At the beginning the ports 80, 22 were defined as static values directly inside the security group definition, but in order to make them configurable, I moved them into separate variablas. The same is done to the CIDR to enable configurable IP ranges.

####Using the ​provisioner​ you are most familiar with, install and configure nginx so that it will serve a custom static web page (that can be specified in the Terraform configuration file or as a Terraform input variable).

In order to use a provisioner, I need to setup an SSH connection with the instance, and provide a key for connection, there are two approaches:
* Either to generate a key pair in AWS and use the `.pem` file to connect the instance
* Or, issue a key pair locally, and create a key in AWS using the public key of the local machine, and use the private key of the local machine to connect to the created instance

For this exercise, I will issue a key pair in AWS and use the `.pem` file to connect to the created instance

Below are the steps used to access the instances using the generated key-pair:
* Generated the key-pair in AWS console `Key Pairs` section with the name `WSKeyPair`
* Saved the generated private key `.pem` file under the `keys/` directory
* Configured the instance to use the AWS key pair using the `key_name` attribute in the `aws_instance` resource as below:
  
    ```
    resource "aws_instance" "web_server" {
        ami           = "${data.aws_ami.latest_ubuntu_ami.id}"
        instance_type = "t2.micro"

        vpc_security_group_ids = ["${aws_security_group.ws_sg.id}"]

        key_name = "WSKeyPair"

        connection {
            type = "ssh"
            user = "ubuntu"
            private_key = "${file("keys/WSKeyPair.pem")}"
        }
    }    
    ```

In order to install nginx in the created instances, I need to use the `remote-exec` provisioner, there are three options to use for the `remote-exec` provisioner:
* Use `inline` and list all the commands needed to install nginx, but in cases of escape character, it will be a mess, and commands will be unclear
* Use `script` and upload the script to the created instance first using the `file` provisioner, then execute the uploaded script
* Use `scripts` which will be the same as using `script` in this case

Personally, I prefer writing a separate script for the installation of nginx, and upload that script to the created instance, then execute the uploaded script in the created instance

Looking at the nginx installation guide https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-open-source/#prebuilt_ubuntu, it could be installed using the below commands:

```
sudo apt-get update -y
sudo apt-get install -y nginx
```

