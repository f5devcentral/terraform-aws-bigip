package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func Test3NicExample(t *testing.T) {
	opts := &terraform.Options{
		TerraformDir: "../examples/3_nic_with_new_vpc",
	}

	// Clean up everything at the end of the test
	defer terraform.Destroy(t, opts)

	terraform.InitAndApply(t, opts)
}
