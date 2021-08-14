#!/bin/bash

# =================================================================
#
# Work of the U.S. Department of Defense, Defense Digital Service.
# Released as open source under the MIT License.  See LICENSE file.
#
# =================================================================

# User data script written for use with an Amazon Linux 2 EC2 instance

set -euxo pipefail

# Create and initialize log
touch /var/log/startup.log
chmod 664 /var/log/startup.log
echo "* Starting provisioning" >> /var/log/startup.log 2>&1
echo "* $(date)" >> /var/log/startup.log 2>&1
# Update YUM
yum -y update >> /var/log/startup.log 2>&1
# Install jq
yum -y install jq
# Update shell
echo "export AWS_DEFAULT_REGION=${region}" >> /home/ec2-user/.bash_profile
# Run DNS queries
for service in "${endpoints}"; do
  log_events=$(dig A "${service}.${region}.amazonaws.com" +nocomments +noquestion +noauthority +noadditional +nostats  | awk '{if (NR>3){print}}'| tr -s '\t' | jq -R 'split("\t") | .[2]' | jq --arg s "${service}" --arg ts "$(echo $(($(date +%s%N)/1000000)))" --slurp '[{service:$s, timestamp:($ts|tonumber), message:(.|@json)}]')
  aws logs put-log-events --log-group-name "${log_group_name}" --log-stream-name "${log_stream_name}" --log-events "${log_events}"
done
# Mark that user data script finished execution
echo "Done" >> /var/log/startup.log 2>&1
