terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
}

variable "github_owner" {
  description = "GitHub username or organization"
  type        = string
}

variable "repository_name" {
  description = "GitHub repository name"
  type        = string
}

variable "deploy_key_public" {
  description = "SSH public key to be used as deploy key"
  type        = string
}

resource "github_repository_deploy_key" "deploy" {
  title      = "Terraform Deploy Key"
  repository = var.repository_name
  key        = var.deploy_key_public
  read_only  = false
}
