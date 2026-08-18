terraform {
    backend "s3" {
        bucket      = "mentis-backend-bucket"
        key         = "devops-code-challenge1/terrafor/terraform.tfstate"
        region      = "us-east-1"
        use_lockfile = true
      
    }
}

# # Terraform stores its state file (terraform.tfstate) locally, right on your laptop — which is exactly the file we just agreed to .gitignore. This block changes that, telling 
# Terraform "instead of keeping state locally, store it remotely in this S3 bucket." That matters for a few real reasons: your state survives even if your laptop dies or you switch 
# machines; if you were working with teammates, everyone would be reading/writing the same shared state instead of separate local copies (avoiding conflicts); and it enables locking 
# (see below), which prevents two apply runs from corrupting state if run at the same time.