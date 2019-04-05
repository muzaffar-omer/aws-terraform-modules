#!/bin/bash

echo "${private_key_pem}" > ~/${private_key_file_name}
chmod 400 ~/${private_key_file_name}