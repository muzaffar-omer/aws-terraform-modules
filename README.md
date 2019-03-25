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

# Part3 : A simple web server

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

