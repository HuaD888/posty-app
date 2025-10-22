param(
  [string]$RepoName = "posty-app",
  [switch]$Public = $true
)

# Move to project root (script is in scripts/)
Set-Location -Path (Join-Path $PSScriptRoot "..")

Write-Host "Working in: $(Get-Location)"

# Check for git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Host "git is not installed or not on PATH. Please install Git for Windows: https://git-scm.com/download/win" -ForegroundColor Red
  exit 2
}

# Initialize repo if needed
if (-not (Test-Path .git)) {
  git init
  Write-Host "Initialized empty git repository"
}

# Stage and commit
git add -A
try {
  git commit -m "Initial commit" -q
  Write-Host "Committed files"
} catch {
  Write-Host "No changes to commit or commit failed (maybe already committed)"
}

# Ensure branch is main
try { git branch -M main } catch { }

# If gh (GitHub CLI) is available, create repo and push
if (Get-Command gh -ErrorAction SilentlyContinue) {
  # Ensure gh auth
  $auth = gh auth status 2>$null
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Please authenticate with GitHub CLI first: gh auth login" -ForegroundColor Yellow
    exit 3
  }

  $vis = $Public.IsPresent ? "public" : "private"
  Write-Host "Creating GitHub repo '$RepoName' ($vis) and pushing..."
  gh repo create $RepoName --$vis --source . --remote origin --push
  exit $LASTEXITCODE
} else {
  Write-Host "GitHub CLI (gh) not found. Create a remote manually and push with these commands:" -ForegroundColor Yellow
  Write-Host "git remote add origin https://github.com/<your-username>/$RepoName.git"
  Write-Host "git push -u origin main"
  exit 0
}
