package test

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"net/http"
	"crypto/tls"
	"time"
	"github.com/hashicorp/go-retryablehttp"
	// "github.com/gruntwork-io/terratest/modules/terraform"
)

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


func Test1NicExample(t *testing.T) {
	// opts := &terraform.Options{
	// 	TerraformDir: "../examples/1_nic_with_new_vpc",
	// }

	// Clean up everything at the end of the test
	// defer terraform.Destroy(t, opts)

	// // Deploy BIG-IP
	// terraform.InitAndApply(t, opts)

	// // Get the BIG-IP management IP address
	// bigipMgmtDNS := terraform.OutputRequired(t, opts, "bigip_mgmt_dns")
	// bigipMgmtPort := terraform.OutputRequired(t, opts, "bigip_mgmt_port")
	// bigipMgmtDNS := "ec2-18-223-69-232.us-east-2.compute.amazonaws.com"
	bigipMgmtDNS := [2]string{
		"ec2-18-223-69-232.us-east-2.compute.amazonaws.com",
		"ec2-3-130-27-98.us-east-2.compute.amazonaws.com",
	}
	bigipMgmtPort := "8443"
	bigipPwd := "W14cgviThPNri2B2"

	const minRetryTime = 1   // seconds
	const maxRetryTime = 120 // seconds
	const maxRetryCount = 10
	const attemptTimeoutInit = 2 // seconds
	const doInfoURL = "/mgmt/shared/declarative-onboarding/info"
	const as3InfoURL = "/mgmt/shared/appsvcs/info"

	// DOurl := fmt.Sprintf("https://%s:%s/mgmt/shared/declarative-onboarding/info", bigipMgmtDNS, bigipMgmtPort)
	// AS3url := fmt.Sprintf("https://%s:%s/mgmt/shared/appsvcs/info", bigipMgmtDNS, bigipMgmtPort)

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
	for _, bigip := range bigipMgmtDNS {
		// Check DO info page
		DOurl := fmt.Sprintf("https://%s:%s%s", bigip, bigipMgmtPort, doInfoURL)
		doresp, err := testAnOToolchain(DOurl, bigipPwd, rclient)
		if err != nil {
			t.Errorf("DO REQUEST FAILED")
		}
		fmt.Println(doresp)

		// Check AS3 info page
		AS3url := fmt.Sprintf("https://%s:%s%s", bigip, bigipMgmtPort, as3InfoURL)
		as3resp, err := testAnOToolchain(AS3url, bigipPwd, rclient)
		if err != nil {
			t.Errorf("DO REQUEST FAILED")
		}
		fmt.Println(as3resp)
	}
}
