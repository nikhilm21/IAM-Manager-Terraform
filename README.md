# IAMManger via Terraform

To deploy the code on your AWS via Terraform:

1. Ensure that the AWS CLI is set-up.
2. Run the commands below to set-up Terraform and deploy it. 
      ```
      terraform init
      terraform apply
      ```
 Note: The default config file is already there, so you can skip through the process of selecting server and DBName.

Note: In order to delete your resources run the following command:
```
    terraform destroy
```
