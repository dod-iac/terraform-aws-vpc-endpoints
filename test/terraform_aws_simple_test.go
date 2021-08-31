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
	"os"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/require"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/cloudwatchlogs"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

type Message struct {
	Name           string   `json:name`
	PrivateDNSName string   `json:private_dns_name`
	Results        []string `json:results`
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

	logs := cloudwatchlogs.New(s, aws.NewConfig().WithRegion(region))

	cloudwatchLogGroupName := terraform.Output(t, terraformOptions, "cloudwatch_log_group_name")

	// Wait for log messages to be saved
	t.Logf("Waiting for log messages to be saved")
	events := make([]*cloudwatchlogs.FilteredLogEvent, 0)
	for i := 0; true; i++ {
		filterLogEventsOutput, filterLogEventsError := logs.FilterLogEvents(&cloudwatchlogs.FilterLogEventsInput{
			LogGroupName: aws.String(cloudwatchLogGroupName),
		})
		require.NoError(t, filterLogEventsError)
		if len(filterLogEventsOutput.Events) > 0 {
			events = filterLogEventsOutput.Events
			break
		}
		time.Sleep(1 * time.Second)
		if i == 30 {
			require.Fail(t, "ECS task had no logs after 30 seconds")
		}
	}

	t.Logf("Checking results")
	for _, event := range events {
		message := &Message{}
		err := json.Unmarshal([]byte(aws.StringValue(event.Message)), message)
		require.NoError(t, err)
		t.Logf("Checking results for %#v", message)
	}
}
