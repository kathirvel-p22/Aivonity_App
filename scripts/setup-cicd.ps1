# AIVONITY CI/CD Setup Script (PowerShell)
param(
    [string]$GitHubRepo = "",
    [switch]$SetupSecrets,
    [switch]$ValidateConfig
)

Write-Host "🚀 AIVONITY CI/CD Setup Script" -ForegroundColor Green

# Check prerequisites
function Test-Prerequisites {
    Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow
    
    $missing = @()
    
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        $missing += "git"
    }
    
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        $missing += "gh (GitHub CLI)"
    }
    
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        $missing += "kubectl"
    }
    
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        $missing += "docker"
    }
    
    if ($missing.Count -gt 0) {
        Write-Host "❌ Missing prerequisites: $($missing -join ', ')" -ForegroundColor Red
        Write-Host "Please install the missing tools and try again." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ All prerequisites found" -ForegroundColor Green
}

# Validate GitHub repository
function Test-GitHubRepo {
    param([string]$repo)
    
    if ([string]::IsNullOrEmpty($repo)) {
        Write-Host "❌ GitHub repository not specified" -ForegroundColor Red
        Write-Host "Usage: .\setup-cicd.ps1 -GitHubRepo 'owner/repo'" -ForegroundColor Yellow
        exit 1
    }
    
    try {
        gh repo view $repo | Out-Null
        Write-Host "✅ GitHub repository '$repo' found" -ForegroundColor Green
    } catch {
        Write-Host "❌ GitHub repository '$repo' not found or not accessible" -ForegroundColor Red
        exit 1
    }
}

# Setup GitHub secrets
function Set-GitHubSecrets {
    param([string]$repo)
    
    Write-Host "🔐 Setting up GitHub secrets..." -ForegroundColor Yellow
    
    $secrets = @{
        "OPENAI_API_KEY" = "Enter your OpenAI API key"
        "ANTHROPIC_API_KEY" = "Enter your Anthropic API key"
        "SENDGRID_API_KEY" = "Enter your SendGrid API key"
        "TWILIO_ACCOUNT_SID" = "Enter your Twilio Account SID"
        "TWILIO_AUTH_TOKEN" = "Enter your Twilio Auth Token"
        "SLACK_WEBHOOK_URL" = "Enter your Slack webhook URL"
        "SNYK_TOKEN" = "Enter your Snyk token (optional)"
        "ANDROID_KEY_ALIAS" = "Enter your Android key alias"
        "ANDROID_STORE_PASSWORD" = "Enter your Android store password"
        "ANDROID_KEY_PASSWORD" = "Enter your Android key password"
        "APPLE_ID_EMAIL" = "Enter your Apple ID email"
        "GOOGLE_PLAY_SERVICE_ACCOUNT" = "Enter your Google Play service account JSON (base64 encoded)"
    }
    
    foreach ($secret in $secrets.GetEnumerator()) {
        $value = Read-Host -Prompt $secret.Value -AsSecureString
        if ($value.Length -gt 0) {
            $plainValue = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($value))
            try {
                gh secret set $secret.Key --body $plainValue --repo $repo
                Write-Host "✅ Set secret: $($secret.Key)" -ForegroundColor Green
            } catch {
                Write-Host "❌ Failed to set secret: $($secret.Key)" -ForegroundColor Red
            }
        } else {
            Write-Host "⏭️ Skipped secret: $($secret.Key)" -ForegroundColor Yellow
        }
    }
    
    Write-Host "📁 File-based secrets (upload manually):" -ForegroundColor Cyan
    Write-Host "- ANDROID_KEYSTORE: Base64 encoded Android keystore file" -ForegroundColor White
    Write-Host "- IOS_CERTIFICATE: Base64 encoded iOS certificate" -ForegroundColor White
    Write-Host "- IOS_PROVISIONING_PROFILE: Base64 encoded provisioning profile" -ForegroundColor White
    Write-Host "- KUBE_CONFIG_STAGING: Base64 encoded kubeconfig for staging" -ForegroundColor White
    Write-Host "- KUBE_CONFIG_PRODUCTION: Base64 encoded kubeconfig for production" -ForegroundColor White
}

# Validate CI/CD configuration
function Test-CICDConfig {
    Write-Host "🔍 Validating CI/CD configuration..." -ForegroundColor Yellow
    
    $workflows = @(
        ".github/workflows/backend-ci.yml",
        ".github/workflows/mobile-ci.yml",
        ".github/workflows/infrastructure-ci.yml",
        ".github/workflows/security-scan.yml"
    )
    
    $allValid = $true
    
    foreach ($workflow in $workflows) {
        if (Test-Path $workflow) {
            Write-Host "✅ Found: $workflow" -ForegroundColor Green
            
            # Basic YAML validation
            try {
                $content = Get-Content $workflow -Raw
                if ($content -match "on:" -and $content -match "jobs:") {
                    Write-Host "  ✅ Valid YAML structure" -ForegroundColor Green
                } else {
                    Write-Host "  ❌ Invalid YAML structure" -ForegroundColor Red
                    $allValid = $false
                }
            } catch {
                Write-Host "  ❌ Failed to parse YAML" -ForegroundColor Red
                $allValid = $false
            }
        } else {
            Write-Host "❌ Missing: $workflow" -ForegroundColor Red
            $allValid = $false
        }
    }
    
    # Check other required files
    $requiredFiles = @(
        ".github/dependabot.yml",
        ".github/CODEOWNERS",
        ".github/pull_request_template.md",
        "backend/Dockerfile",
        "backend/pytest.ini",
        "backend/.flake8",
        "backend/pyproject.toml",
        "docker-compose.yml"
    )
    
    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Write-Host "✅ Found: $file" -ForegroundColor Green
        } else {
            Write-Host "❌ Missing: $file" -ForegroundColor Red
            $allValid = $false
        }
    }
    
    if ($allValid) {
        Write-Host "✅ All CI/CD configuration files are present and valid" -ForegroundColor Green
    } else {
        Write-Host "❌ Some CI/CD configuration issues found" -ForegroundColor Red
        exit 1
    }
}

# Enable GitHub Actions
function Enable-GitHubActions {
    param([string]$repo)
    
    Write-Host "🔧 Enabling GitHub Actions..." -ForegroundColor Yellow
    
    try {
        gh api repos/$repo/actions/permissions --method PUT --field enabled=true
        Write-Host "✅ GitHub Actions enabled" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to enable GitHub Actions" -ForegroundColor Red
    }
}

# Setup branch protection
function Set-BranchProtection {
    param([string]$repo)
    
    Write-Host "🛡️ Setting up branch protection..." -ForegroundColor Yellow
    
    $protectionRules = @{
        "required_status_checks" = @{
            "strict" = $true
            "contexts" = @("test", "security-scan", "validate-kubernetes")
        }
        "enforce_admins" = $true
        "required_pull_request_reviews" = @{
            "required_approving_review_count" = 2
            "dismiss_stale_reviews" = $true
            "require_code_owner_reviews" = $true
        }
        "restrictions" = $null
    }
    
    try {
        $json = $protectionRules | ConvertTo-Json -Depth 10
        gh api repos/$repo/branches/main/protection --method PUT --input - <<< $json
        Write-Host "✅ Branch protection enabled for main branch" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to set branch protection" -ForegroundColor Red
    }
}

# Main execution
Test-Prerequisites

if (-not [string]::IsNullOrEmpty($GitHubRepo)) {
    Test-GitHubRepo -repo $GitHubRepo
    
    if ($SetupSecrets) {
        Set-GitHubSecrets -repo $GitHubRepo
    }
    
    Enable-GitHubActions -repo $GitHubRepo
    Set-BranchProtection -repo $GitHubRepo
}

if ($ValidateConfig) {
    Test-CICDConfig
}

Write-Host ""
Write-Host "🎉 CI/CD setup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Review and update secrets in GitHub repository settings" -ForegroundColor White
Write-Host "2. Upload file-based secrets (certificates, kubeconfig)" -ForegroundColor White
Write-Host "3. Test the pipeline by creating a pull request" -ForegroundColor White
Write-Host "4. Monitor the first pipeline run for any issues" -ForegroundColor White
Write-Host "5. Set up monitoring and alerting" -ForegroundColor White