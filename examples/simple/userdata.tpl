#!/bin/bash

# =================================================================
#
# Work of the U.S. Department of Defense, Defense Digital Service.
# Released as open source under the MIT License.  See LICENSE file.
#
# =================================================================

# User data script written for use with an Amazon Linux 2 EC2 instance

set -euxo pipefail

# Update current shell
export AWS_DEFAULT_REGION=${region}
# Create and initialize log
touch /var/log/startup.log
chmod 664 /var/log/startup.log
echo "* Starting provisioning" >> /var/log/startup.log 2>&1
echo "* $(date)" >> /var/log/startup.log 2>&1
# Update YUM
yum -y update >> /var/log/startup.log 2>&1
# Install jq
yum -y install jq >> /var/log/startup.log 2>&1
# Update shell configuration
echo "export AWS_DEFAULT_REGION=${region}" >> /root/.bash_profile
all_endpoints=$(aws s3 cp "s3://${bucket}/endpoints.json" -)
gateway_endpoints=$(echo "$${all_endpoints}" | jq -r '.gateway')
gateway_endpoints_length=$(echo "$${gateway_endpoints}" | jq -r ". | length")
interface_endpoints=$(echo "$${all_endpoints}" | jq -r '.interface')
interface_endpoints_length=$(echo "$${interface_endpoints}" | jq -r ". | length")
echo "Gateway Endpoints" >> /var/log/startup.log 2>&1
echo "$${gateway_endpoints}" >> /var/log/startup.log 2>&1
echo "Interface Endpoints" >> /var/log/startup.log 2>&1
echo "$${interface_endpoints}" >> /var/log/startup.log 2>&1
# Run DNS queries for interface endpoints
sequence_token=""
for i in $(seq 0 $((interface_endpoints_length-1))); do
  name=$(echo "$${interface_endpoints}" | jq -r --arg i "$${i}" '.[$i|tonumber].name')
  private_dns_name=$(echo "$${interface_endpoints}" | jq -r --arg i "$${i}" '.[$i|tonumber].private_dns_name')
  log_events=$(dig A "$${private_dns_name}" +nocomments +noquestion +noauthority +noadditional +nostats | awk '{if (NR>3){print}}'| tr -s '\t' | jq -R 'split("\t") | .[-1]' | jq -r --arg d "$${private_dns_name}" --arg n "$${name}" --arg ts "$(echo $(($(date +%s%N)/1000000)))" --slurp '[{timestamp:($ts|tonumber), message:({name: $n, query: $d, answers:.}|@json)}]|@json')
  if [[ -z "$${sequence_token:-}" ]]; then
    sequence_token=$(aws logs put-log-events \
    --log-group-name "${log_group_name}" \
    --log-stream-name "${log_stream_name}" \
    --log-events "$${log_events}" | jq -r '.nextSequenceToken')
  else
    sequence_token=$(aws logs put-log-events \
    --log-group-name "${log_group_name}" \
    --log-stream-name "${log_stream_name}" \
    --sequence-token "$${sequence_token:-}" \
    --log-events "$${log_events}" | jq -r '.nextSequenceToken')
  fi
done
# Mark that user data script finished execution
echo "Done" | aws s3 cp --acl bucket-owner-full-control --sse AES256 - "s3://${bucket}/done.txt"
echo "Done" >> /var/log/startup.log 2>&1
