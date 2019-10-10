package test

import (
	"context"
	"errors"
	"encoding/base64"
	"fmt"
	"testing"
	"net/http"
	"crypto/tls"
	"time"
	"os"
	"github.com/hashicorp/go-retryablehttp"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/aws/aws-sdk-go/service/secretsmanager"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/session"
)

// AWS Code snippit to obtain secret
func getSecret(secretName string, region string) (password string, err error) {
	// Create a session
	sess:= session.Must(session.NewSession(&aws.Config{
		Region : aws.String(region),
	}))

	//Create a Secrets Manager client
	svc := secretsmanager.New(sess)
	input := &secretsmanager.GetSecretValueInput{
		SecretId:     aws.String(secretName),
		VersionStage: aws.String("AWSCURRENT"), // VersionStage defaults to AWSCURRENT if unspecified
	}

	// In this sample we only handle the specific exceptions for the 'GetSecretValue' API.
	// See https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html

	result, err := svc.GetSecretValue(input)
	if err != nil {
		if aerr, ok := err.(awserr.Error); ok {
			switch aerr.Code() {
				case secretsmanager.ErrCodeDecryptionFailure:
				// Secrets Manager can't decrypt the protected secret text using the provided KMS key.
				fmt.Println(secretsmanager.ErrCodeDecryptionFailure, aerr.Error())

				case secretsmanager.ErrCodeInternalServiceError:
				// An error occurred on the server side.
				fmt.Println(secretsmanager.ErrCodeInternalServiceError, aerr.Error())

				case secretsmanager.ErrCodeInvalidParameterException:
				// You provided an invalid value for a parameter.
				fmt.Println(secretsmanager.ErrCodeInvalidParameterException, aerr.Error())

				case secretsmanager.ErrCodeInvalidRequestException:
				// You provided a parameter value that is not valid for the current state of the resource.
				fmt.Println(secretsmanager.ErrCodeInvalidRequestException, aerr.Error())

				case secretsmanager.ErrCodeResourceNotFoundException:
				// We can't find the resource that you asked for.
				fmt.Println(secretsmanager.ErrCodeResourceNotFoundException, aerr.Error())
			}
		} else {
			// Print the error, cast err to awserr.Error to get the Code and
			// Message from an error.
			fmt.Println(err.Error())
		}
		return "", err
	}

	// Decrypts secret using the associated KMS CMK.
	// Depending on whether the secret is a string or binary, one of these fields will be populated.
	var secretString, decodedBinarySecret string
	if result.SecretString != nil {
		secretString = *result.SecretString
		return secretString, nil
	} else {
		decodedBinarySecretBytes := make([]byte, base64.StdEncoding.DecodedLen(len(result.SecretBinary)))
		len, err := base64.StdEncoding.Decode(decodedBinarySecretBytes, result.SecretBinary)
		if err != nil {
			fmt.Println("Base64 Decode Error:", err)
			return "", err
		}
		decodedBinarySecret = string(decodedBinarySecretBytes[:len])
		return decodedBinarySecret, nil
	}
}

func testAnOToolchain(url string, pwd string, client *retryablehttp.Client) (int, error) {
	req, err := retryablehttp.NewRequest("GET", url, nil)
	req.SetBasicAuth("admin", pwd)
	resp, err := client.Do(req)
	if err != nil || resp.StatusCode != 200 {
		return 0,  errors.New("Request Failed")
	}
	defer resp.Body.Close()
	return resp.StatusCode, nil
}

// Test the BIG-IP 1 NIC example
// Ensure your AWS credentials are set to the following environment vars:
//		AWS_ACCESS_KEY_ID
//      AWS_SECRET_ACCESS_KEY
// Ensure you have defined the default AWS region in the following environment var:
//      AWS_DEFAULT_REGION
func Test1NicExample(t *testing.T) {
	opts := &terraform.Options{
		TerraformDir: "../examples/1_nic_with_new_vpc",
		Vars: map[string]interface{} {
			"ec2_key_name": os.Getenv("ec2_key_name"),
		},
	}

	// Clean up everything at the end of the test
	defer terraform.Destroy(t, opts)

	// Deploy BIG-IP
	terraform.InitAndApply(t, opts)

	// Get the BIG-IP management IP address
	bigipMgmtDNS := terraform.OutputList(t, opts, "bigip_mgmt_dns")
	bigipMgmtPort := terraform.OutputRequired(t, opts, "bigip_mgmt_port")
	awsSecretmanagerSecretName := terraform.OutputRequired(t, opts, "aws_secretmanager_secret_name")
	bigipPwd, err := getSecret(awsSecretmanagerSecretName, os.Getenv("AWS_DEFAULT_REGION")) 

	if err != nil || bigipPwd == "" {
		t.Errorf("CAN NOT OBTAIN BIG-IP PASSWORD FROM SECRET MANAGER")
	}

	// Sleep for 5 minutes (time to boot BIG-IP) so we do not overwhelm restnoded while installing A&O Toolchain
	fmt.Println("Sleeping for 5 minutes so A&O Toolchain can be installed")
	time.Sleep(300 * time.Second)

	const minRetryTime = 1   // seconds
	const maxRetryTime = 120 // seconds
	const maxRetryCount = 5
	const attemptTimeoutInit = 2 // seconds
	const doInfoURL = "/mgmt/shared/declarative-onboarding/info"
	const as3InfoURL = "/mgmt/shared/appsvcs/info"

	// since the BIG-IP is deployed with a self-signed cert, we need to ignore validation
	tr := &http.Transport{
		TLSClientConfig: &tls.Config {
			InsecureSkipVerify: true,
		},
	}

	// build an http client with our custom transport
	client := &http.Client{
		Transport: tr,
	}

	// configure the Hashcorp retryablehttp client
	rclient := &retryablehttp.Client{
		HTTPClient: client,
		RetryWaitMin: minRetryTime * time.Second,
		RetryWaitMax: maxRetryTime * time.Second,
		RetryMax: maxRetryCount,
		Backoff: retryablehttp.DefaultBackoff,
	}

	// AnO Toolchain returns a 400 if the rpm is not installed, retry if a 400 is returned
	rclient.CheckRetry = func (_ context.Context, resp *http.Response, err error) (bool, error) {
		if err != nil {
			return true, err
		}
		if resp.StatusCode == 0 || resp.StatusCode >= 400 {
			fmt.Println(resp.StatusCode)
			return true, nil
		}
		return false, nil
	}

	// Check the A&O Toolchain for each BIG-IP
	// TODO: bigips is still not in the right format
	for _, bigip := range bigipMgmtDNS {
		// Check DO info page
		fmt.Printf("CHECK DO FOR %s\n", bigip)
		DOurl := fmt.Sprintf("https://%s:%s%s", bigip, bigipMgmtPort, doInfoURL)
		doresp, err := testAnOToolchain(DOurl, bigipPwd, rclient)
		if err != nil {
			t.Errorf("DO REQUEST FAILED")
		}
		fmt.Println(doresp)

		// Check AS3 info page
		fmt.Printf("CHECK AS3 FOR %s\n", bigip)
		AS3url := fmt.Sprintf("https://%s:%s%s", bigip, bigipMgmtPort, as3InfoURL)
		as3resp, err := testAnOToolchain(AS3url, bigipPwd, rclient)
		if err != nil {
			t.Errorf("DO REQUEST FAILED")
		}
		fmt.Println(as3resp)
	}
}
