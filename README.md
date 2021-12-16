### install config


1. install terraform
2. setup google service account, download sa json file and setup $GOOGLE_APPLICATION_CREDENTIALS
3. config the main.tf, change the project id and region to yours
4. run terraform command
```
terraform init
terraform apply
```

### comments

- nlb-udp * nlb-tcp use the same ip
- open all ports in the sample config, if you want to reduce the port number, use the ports argument in the front end terraform resource.

### reference docs

[terraform docs for gcp](https://registry.terraform.io/providers/hashicorp/google/latest/docs)