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
  description = "T_key"
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
  type        = string
  default     = "softservedata"
}

variable "deploy_key_public" {
  type        = string
  description = "Public key for deploy key"
}

# Створення репозиторію
resource "github_repository" "repo" {
  name               = var.repository_name
  visibility         = "private"
  auto_init          = true
  has_issues         = true
  has_projects       = true
  has_wiki           = true
}

# Створення develop гілки
resource "github_branch" "develop_branch" {
  repository = github_repository.repo.name
  branch     = "develop"
  depends_on = [github_repository.repo]
}

# Встановлення develop як default
resource "github_branch_default" "default" {
  repository = github_repository.repo.name
  branch     = github_branch.develop_branch.branch
}

# Додавання колаборатора
resource "github_repository_collaborator" "collaborator" {
  repository = github_repository.repo.name
  username   = var.collaborator
  permission = "push"
}

# Захист develop
resource "github_branch_protection" "develop" {
  repository_id = github_repository.repo.node_id
  pattern       = "develop"

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    required_approving_review_count = 2
  }

  enforce_admins = true
}

# Захист main
resource "github_branch_protection" "main" {
  repository_id = github_repository.repo.node_id
  pattern       = "main"

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    required_approving_review_count = 1
  }

  enforce_admins = true
}

# CODEOWNERS файл
resource "github_repository_file" "codeowners" {
  repository      = github_repository.repo.name
  file            = "CODEOWNERS"
  branch          = "main"
  content         = "* @${var.collaborator}"
  commit_message  = "Add CODEOWNERS file assigning softservedata"
}

# Pull Request Template
resource "github_repository_file" "pr_template" {
  repository     = github_repository.repo.name
  file           = ".github/pull_request_template.md"
  branch         = github_branch.develop_branch.branch
  content        = <<EOF
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

# Deploy Key
resource "github_repository_deploy_key" "deploy_key" {
  repository = github_repository.repo.name
  title      = "DEPLOY_KEY"
  key        = var.deploy_key_public
  read_only  = false
}

# Output
output "repo_html_url" {
  value = github_repository.repo.html_url
}
