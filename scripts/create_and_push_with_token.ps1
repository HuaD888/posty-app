param(
  [string]$RepoName = "posty-app",
  [switch]$Public = $true
)

# Usage:
# $env:GITHUB_TOKEN = '<your-token>'
# .\scripts\create_and_push_with_token.ps1 -RepoName posty-app -Public

Set-Location -Path (Join-Path $PSScriptRoot "..")

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Error "git is not installed or not on PATH. Install Git: https://git-scm.com/download/win"
  exit 2
}

$token = $env:GITHUB_TOKEN
if (-not $token) {
  Write-Host "No GITHUB_TOKEN environment variable detected. You can generate a token at https://github.com/settings/tokens (scope: repo)." -ForegroundColor Yellow
  $token = Read-Host -AsSecureString "Enter GitHub PAT (will not be stored)"
  $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($token)
  $token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
  [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}

# Ensure repo is initialized and committed
if (-not (Test-Path .git)) {
  git init
}

git add -A
try { git commit -m "Initial commit" -q } catch { Write-Host "No commit created (maybe nothing to commit)" }
try { git branch -M main } catch {}

$visibility = $Public.IsPresent ? 'false' : 'true' # JSON private field: false => public

$headers = @{
  Authorization = "token $token"
  Accept = 'application/vnd.github+json'
  'User-Agent' = 'posty-app-script'
}

$body = @{ name = $RepoName; private = $visibility } | ConvertTo-Json

try {
  $resp = Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Method Post -Headers $headers -Body $body
} catch {
  Write-Error "Failed to create repository via API: $_"
  exit 3
}

if ($resp -and $resp.clone_url) {
  $remote = $resp.clone_url
  git remote remove origin 2>$null
  git remote add origin $remote
  git push -u origin main
  Write-Host "Repository created and pushed: $($resp.html_url)"
} else {
  Write-Error "Unexpected API response. Repository may not have been created."
  exit 4
}
