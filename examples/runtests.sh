#!/bin/bash
tf_output_file='inspec/bigip-ready/files/terraform.json'

# Save the Terraform data into a JSON file for InSpec to read
terraform output --json > $tf_output_file

# Run InSpect tests from the Jumphost
inspec exec inspec/bigip-ready 