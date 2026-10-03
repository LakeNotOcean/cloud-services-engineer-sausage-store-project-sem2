package terratest

import (
	"context"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/yandex-cloud/go-genproto/yandex/cloud/vpc/v1"
	ycsdk "github.com/yandex-cloud/go-sdk"
)

func TestProdSecurityGroup(t *testing.T) {
	terraformOptions := &terraform.Options{
		TerraformDir: "..",
	}


	// Инициализация и применение Terraform
   terraform.InitAndApply(t, terraformOptions)

	// Получение имени SG
	prodSGName := terraform.Output(t, terraformOptions, "prod_sg_name")

	// Проверка имени SG
	assert.Equal(t, "prod-sg", prodSGName, "Prod SG name does not match")

	// Инициализация Yandex Cloud SDK
	ctx := context.Background()
	yc, err := ycsdk.Build(ctx, ycsdk.Config{
		Credentials: getYCToken(t),
	})
	if err != nil {
		t.Fatalf("Failed to initialize Yandex Cloud SDK: %v", err)
	}

	folderID := terraform.Output(t, terraformOptions, "folder_id") 

	// Проверка существования SG
	vpcService := yc.VPC().SecurityGroup()
	groups, err := vpcService.List(ctx, &vpc.ListSecurityGroupsRequest{
		FolderId: folderID,
	})
	if err != nil {
		t.Fatalf("Failed to list security groups: %v", err)
	}

	sgFound := false
	for _, group := range groups.SecurityGroups {
		if group.Name == prodSGName {
			sgFound = true
			// смотрим правила
			hasSSH := false
			hasHTTP := false
			for _, rule := range group.Rules {
				if rule.Direction == vpc.SecurityGroupRule_INGRESS {
					if rule.Ports != nil {
						if rule.Ports.FromPort == 22 {
							hasSSH = true
						}
						if rule.Ports.FromPort == 8200 {
							hasHTTP = true
						}
					}
				}
			}
			assert.True(t, hasSSH, "Prod SG should allow SSH (port 22)")
			assert.True(t, hasHTTP, "Prod SG should allow HTTP (port 8200)")
		}
	}
	assert.True(t, sgFound, "Prod Security Group not found in Yandex Cloud")
}