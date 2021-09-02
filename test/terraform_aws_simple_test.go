// =================================================================
//
// Work of the U.S. Department of Defense, Defense Digital Service.
// Released as open source under the MIT License.  See LICENSE file.
//
// =================================================================

package test

import (
	"encoding/json"
	"fmt"
	"net"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/cloudwatchlogs"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

type Message struct {
	Name    string   `json:"name"`
	Query   string   `json:"query"`
	Answers []string `json:"answers"`
}

func TestTerraformSimpleExample(t *testing.T) {

	// Allow test to run in parallel with other tests
	t.Parallel()

	region := os.Getenv("AWS_DEFAULT_REGION")

	// If AWS_DEFAULT_REGION environment variable is not set, then fail the test.
	require.NotEmpty(t, region, "missing environment variable AWS_DEFAULT_REGION")

	// Append a random suffix to the test name, so individual test runs are unique.
	// When the test runs again, it will use the existing terraform state,
	// so it should override the existing infrastructure.
	testName := fmt.Sprintf("terratest-vpc-endpoints-simple-%s", strings.ToLower(random.UniqueId()))

	tags := map[string]interface{}{
		"Automation": "Terraform",
		"Terratest":  "yes",
		"Test":       "TestTerraformSimpleExample",
	}

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// TerraformDir is where the terraform state is found.
		TerraformDir: "../examples/simple",
		// Set the variables passed to terraform
		Vars: map[string]interface{}{
			"public_key":   "../../temp/id_rsa.pub",
			"ec2_image_id": "ami-083ac7c7ecf9bb9b0",
			"test_name":    testName,
			"tags":         tags,
		},
		// Set the environment variables passed to terraform.
		// AWS_DEFAULT_REGION is the only environment variable strictly required,
		// when using the AWS provider.
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": region,
		},
	})

	// If TT_SKIP_DESTROY is set to "1" then do not destroy the intrastructure,
	// at the end of the test run
	if os.Getenv("TT_SKIP_DESTROY") != "1" {
		defer terraform.Destroy(t, terraformOptions)
	}

	// Init runs "terraform init"
	terraform.Init(t, terraformOptions)

	// Due to unmanaged peer dependencies, destroy the infrastructure first.
	// Destroy runs "terraform destroy"
	terraform.Destroy(t, terraformOptions)

	// Apply runs "terraform apply"
	terraform.Apply(t, terraformOptions)

	s := session.Must(session.NewSession())

	s3Client := s3.New(s, aws.NewConfig().WithRegion(region))

	bucketName := terraform.Output(t, terraformOptions, "bucket_name")

	t.Logf("Waiting for cloud init script to finish")
	for i := 0; true; i++ {
		_, headObjectError := s3Client.HeadObject(&s3.HeadObjectInput{
			Bucket: aws.String(bucketName),
			Key:    aws.String("done.txt"),
		})
		if headObjectError == nil {
			break
		}
		time.Sleep(1 * time.Second)
		if i == 30 {
			require.Fail(t, "Cloud init script had not finished after 30 seconds")
		}
	}

	cloudwatchlogsClient := cloudwatchlogs.New(s, aws.NewConfig().WithRegion(region))

	vpcCIDRBlock := terraform.Output(t, terraformOptions, "vpc_cidr_block")

	_, network, parseCIDRError := net.ParseCIDR(vpcCIDRBlock)

	require.NoError(t, parseCIDRError, "invalid CIDR block: %s", vpcCIDRBlock)

	cloudwatchLogGroupName := terraform.Output(t, terraformOptions, "cloudwatch_log_group_name")

	t.Logf("Sleeping for 5 seconds to wait for Cloudwatch log group to catch up")

	time.Sleep(5 * time.Second)

	t.Logf("Filtering cloudwatch logs")

	filterLogEventsOutput, filterLogEventsError := cloudwatchlogsClient.FilterLogEvents(&cloudwatchlogs.FilterLogEventsInput{
		LogGroupName: aws.String(cloudwatchLogGroupName),
	})
	require.NoError(t, filterLogEventsError)

	for _, event := range filterLogEventsOutput.Events {
		message := &Message{}
		err := json.Unmarshal([]byte(aws.StringValue(event.Message)), message)
		require.NoError(t, err)
		t.Logf("Checking results for %s (%s)", message.Name, message.Query)
		for _, answer := range message.Answers {
			a := net.ParseIP(answer)
			require.NotNil(t, a, "answer is not valid ip address: %s", answer)
			assert.True(t, network.Contains(a), "network %q does not contain answer %q", network, a)
		}
	}
}
