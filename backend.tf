#
terraform {
    backend "remote" {
        hostname = "app.terraform.io"
        organization = "DigitalTech"
        workspaces {
          name = "gitaction_aws_container"
        }
    }
}

#