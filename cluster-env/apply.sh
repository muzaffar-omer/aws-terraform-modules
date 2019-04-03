#!/bin/bash

terraform apply -target aws_vpc.vpc
terraform apply -target aws_subnet.public_sn
terraform apply