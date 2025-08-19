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
  type        = string
  description = "Token_TF"
  sensitive   = true
}

variable "github_owner" {
  type        = string
  description = "NagiosT"
}

variable "repository_name" {
  type        = string
  description = "github-terraform-task-NagiosT"
}

variable "collaborator" {
  type    = string
  default = "softservedata"
}

variable "deploy_key_public" {
  type        = string
  description = "Public key for deploy key"
}

resource "github_repository" "repo" {
  name           = var.repository_name
  default_branch = "develop"
}

resource "github_branch" "develop_branch" {
  repository = github_repository.repo.name
  branch     = "develop"

  depends_on = [github_repository.repo]
}

resource "github_repository_collaborator" "collaborator" {
  repository = github_repository.repo.name
  username   = var.collaborator
  permission = "push"
}

resource "github_branch_protection" "main" {
  repository_id = github_repository.repo.node_id
  pattern       = "main"

  required_pull_request_reviews {
    dismiss_stale_reviews            = true
    require_code_owner_reviews       = true
    required_approving_review_count  = 1
  }

  enforce_admins = true
}

resource "github_branch_protection" "develop" {
  repository_id = github_repository.repo.node_id
  pattern       = "develop"

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    required_approving_review_count = 2
  }

  enforce_admins = true
}

resource "github_repository_file" "codeowners" {
  repository     = github_repository.repo.name
  file           = "CODEOWNERS"
  branch         = "main"
  content        = "* @softservedata\n"
  commit_message = "Add CODEOWNERS file assigning softservedata"
}

resource "github_repository_file" "pr_template" {
  repository     = github_repository.repo.name
  file           = ".github/pull_request_template.md"
  branch         = github_repository.repo.default_branch != "" ? github_repository.repo.default_branch : "develop"

  content = <<-EOF
Describe your changes

Issue ticket number and link

Checklist before requesting a review
- I have performed a self-review of my code
- If it is a core feature, I have added thorough tests
- Do we need to implement analytics?
- Will this be part of a product update? If yes, please write one phrase about this update
EOF

  commit_message = "Add pull request template"
}

resource "github_repository_deploy_key" "deploy_key" {
  repository = github_repository.repo.name
  title      = "DEPLOY_KEY"
  key        = var.deploy_key_public
  read_only  = false
}

# Note: Discord notifications and PAT secrets management are not supported directly in Terraform GitHub provider.

output "repo_clone_url" {
  value = github_repository.repo.clone_url
}
