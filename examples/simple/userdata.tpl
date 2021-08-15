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
n=$(echo "${services}" | jq -r ". | length")
echo "Services" >> /var/log/startup.log 2>&1
echo "${services}" >> /var/log/startup.log 2>&1
echo "Private DNS Names" >> /var/log/startup.log 2>&1
echo "${private_dns_names}" >> /var/log/startup.log 2>&1
# Run DNS queries
for i in $(seq 1 $${n}); do
  service_name=$(echo "${services}" | jq --arg i -r "$${i}" ".[$$i|tonumber]")
  private_dns_name=$(echo "${private_dns_names}" | jq --arg i -r "$${i}" ".[$$i|tonumber]")
  log_events=$(dig A "$${private_dns_name}" +nocomments +noquestion +noauthority +noadditional +nostats  | awk '{if (NR>3){print}}'| tr -s '\t' | jq -R 'split("\t") | .[2]' | jq --arg s "$${service_name}" --arg ts --arg d "$${private_dns_name}" "$(echo $(($(date +%s%N)/1000000)))" --slurp '[{timestamp:($$ts|tonumber), message:{service_name: $$s, private_dns_name: $$d, results:(.|@json)}}]')
  aws logs put-log-events --log-group-name "${log_group_name}" --log-stream-name "${log_stream_name}" --log-events "$${log_events}" >> /var/log/startup.log 2>&1
done
# Mark that user data script finished execution
echo "Done" >> /var/log/startup.log 2>&1
