log_events=$(dig A "cloudtrail.us-west-2.amazonaws.com" +nocomments +noquestion +noauthority +noadditional +nostats | awk '{if (NR>3){print}}'| tr -s '\t' | jq -R 'split("\t") | .[1]' | jq -r --arg d "cloudtrail.us-west-2.amazonaws.com" --arg n "cloudtrail" --arg ts "$(echo $(($(date +%s)000)))" --slurp '[{timestamp:($ts|tonumber), message:({name: $n, private_dns_name: $d, results:.}|@json)}]|@json')
aws logs put-log-events \
  --sequence-token "49620842493507902171291562258949225203621174984459681874" \
  --log-group-name "terratest-vpc-endpoints-simple-r0q7mg" \
  --log-stream-name "results" \
  --log-events "${log_events}"
