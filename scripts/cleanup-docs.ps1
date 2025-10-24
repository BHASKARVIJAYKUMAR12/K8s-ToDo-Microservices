# Documentation Cleanup Script
# This script helps identify and optionally remove redundant documentation

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Documentation Cleanup Utility" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

$projectRoot = "c:\Learnings\K8s-ToDo-Microservices\K8s-ToDo-Microservices"
cd $projectRoot

Write-Host "📋 Current Documentation Structure:" -ForegroundColor Yellow
Write-Host ""

Write-Host "Essential Root Documents (KEEP):" -ForegroundColor Green
$keepDocs = @(
    "README.md",
    "DOCUMENTATION-INDEX.md",
    "PROJECT-STRUCTURE-GUIDE.md",
    "KUBERNETES-DEPLOYMENT.md",
    "KUBERNETES-DEPLOYMENT-SUCCESS.md",
    "DEPLOYMENT-READY.md",
    "LOCAL-TESTING-GUIDE.md",
    "TESTING-INSTRUCTIONS.md",
    "QUICK-START.md",
    "QUICK-ACCESS.md",
    "SECURITY.md"
)

foreach ($doc in $keepDocs) {
    if (Test-Path $doc) {
        $size = (Get-Item $doc).Length / 1KB
        $sizeStr = [math]::Round($size, 1)
        Write-Host "  [KEEP] $doc ($sizeStr KB)" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $doc" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Potentially Redundant Documents:" -ForegroundColor Yellow
$redundantDocs = @(
    "PROJECT-STRUCTURE.md",  # Superseded by PROJECT-STRUCTURE-GUIDE.md
    "CORS-FIXED-K8S.md",     # Moved to troubleshooting guide
    "CORS-FIX-APPLIED.md",   # Moved to troubleshooting guide
    "CORS-SOLUTION-FINAL.md", # Moved to troubleshooting guide
    "CORS-FIXED-FINAL.md",   # Moved to troubleshooting guide
    "PORT-8080-CONFLICT-FIX.md", # Moved to troubleshooting guide
    "KUBERNETES-POD-CHECK-GUIDE.md", # Moved to troubleshooting guide
    "DASHBOARD-QUICK-START.md", # Specific feature, can keep or move
    "KUBERNETES-DASHBOARD-ACCESS.md", # Specific feature
    "HOW-TO-VIEW-KUBERNETES.md", # Merged into main guides
    "LOCAL-DEPLOYMENT-SUCCESS.md", # Merged into KUBERNETES-DEPLOYMENT-SUCCESS.md
    "REORGANIZATION-SUMMARY.md", # Historical, can remove
    "CLEAR-BROWSER-CACHE.md" # Moved to troubleshooting guide
)

$foundRedundant = @()
foreach ($doc in $redundantDocs) {
    if (Test-Path $doc) {
        $size = (Get-Item $doc).Length / 1KB
        $sizeStr = [math]::Round($size, 1)
        Write-Host "  [REDUNDANT] $doc ($sizeStr KB)" -ForegroundColor Yellow
        $foundRedundant += $doc
    }
}

if ($foundRedundant.Count -eq 0) {
    Write-Host "  [OK] No redundant files found!" -ForegroundColor Green
}

Write-Host ""
Write-Host "Organized Documentation:" -ForegroundColor Green
Write-Host "  [OK] docs/troubleshooting/ - All troubleshooting guides" -ForegroundColor Green
Write-Host "  [OK] docs/deployment/ - All deployment guides" -ForegroundColor Green
Write-Host "  [OK] docs/operations/ - Operations and maintenance" -ForegroundColor Green
Write-Host "  [OK] docs/architecture/ - Architecture documentation" -ForegroundColor Green

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Recommendations:" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

if ($foundRedundant.Count -gt 0) {
    Write-Host ""
    Write-Host "Found $($foundRedundant.Count) potentially redundant files." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "These files have been superseded by:" -ForegroundColor White
    Write-Host "  • COMPREHENSIVE-TROUBLESHOOTING-GUIDE.md (in docs/troubleshooting/)" -ForegroundColor Cyan
    Write-Host "  • PROJECT-STRUCTURE-GUIDE.md (consolidated structure)" -ForegroundColor Cyan
    Write-Host "  • KUBERNETES-DEPLOYMENT.md (consolidated K8s guide)" -ForegroundColor Cyan
    Write-Host ""
    
    $response = Read-Host "Would you like to ARCHIVE these files to docs/archive/? (y/n)"
    
    if ($response -eq 'y' -or $response -eq 'Y') {
        # Create archive directory
        $archiveDir = "docs/archive"
        if (!(Test-Path $archiveDir)) {
            New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
            Write-Host "Created archive directory: $archiveDir" -ForegroundColor Green
        }
        
        # Move files to archive
        foreach ($doc in $foundRedundant) {
            Move-Item $doc $archiveDir -Force
            Write-Host "  [ARCHIVED] $doc -> $archiveDir/" -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "[SUCCESS] Files archived successfully!" -ForegroundColor Green
        Write-Host "You can safely delete docs/archive/ if you don't need these files." -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "No files moved. You can manually review and remove them later." -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "[OK] Documentation is already clean and organized!" -ForegroundColor Green
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Documentation Quality Check:" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

# Check for broken links (basic check)
Write-Host ""
Write-Host "Checking documentation structure..." -ForegroundColor Yellow

$checks = @{
    "Documentation Index exists" = (Test-Path "DOCUMENTATION-INDEX.md")
    "Troubleshooting guide exists" = (Test-Path "docs/troubleshooting/COMPREHENSIVE-TROUBLESHOOTING-GUIDE.md")
    "Main K8s guide exists" = (Test-Path "KUBERNETES-DEPLOYMENT.md")
    "Project structure guide exists" = (Test-Path "PROJECT-STRUCTURE-GUIDE.md")
    "README exists" = (Test-Path "README.md")
}

foreach ($check in $checks.GetEnumerator()) {
    if ($check.Value) {
        Write-Host "  [OK] $($check.Key)" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $($check.Key)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Review DOCUMENTATION-INDEX.md for the complete documentation map" -ForegroundColor White
Write-Host "2. All troubleshooting is now in docs/troubleshooting/COMPREHENSIVE-TROUBLESHOOTING-GUIDE.md" -ForegroundColor White
Write-Host "3. Use PROJECT-STRUCTURE-GUIDE.md to understand the entire project" -ForegroundColor White
Write-Host "4. Follow KUBERNETES-DEPLOYMENT.md for deployment" -ForegroundColor White
Write-Host ""
Write-Host "[SUCCESS] Your documentation is now clean and organized!" -ForegroundColor Green
Write-Host ""
