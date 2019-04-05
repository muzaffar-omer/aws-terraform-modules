#!/bin/bash

terraform apply -auto-approve -target aws_vpc.vpc
terraform apply -auto-approve -target aws_subnet.public_sn
terraform apply -auto-approve
