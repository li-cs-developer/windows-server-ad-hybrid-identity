Import-Module ActiveDirectory

$reportPath = "$env:USERPROFILE\Desktop\AD_Security_Audit.log"

Write-Host "=== Active Directory Security Audit ===" -ForegroundColor Cyan

# 1. Accounts with passwords that never expire
$noExpireUsers = Get-ADUser -Filter {PasswordNeverExpires -eq $true} -Properties PasswordNeverExpires | Select-Object -ExpandProperty SamAccountName

# 2. Disabled user accounts
$disabledUsers = Get-ADUser -Filter {Enabled -eq $false} | Select-Object -ExpandProperty SamAccountName

# 3. Empty Security Groups
$emptyGroups = Get-ADGroup -Filter * | Where-Object { @(Get-ADGroupMember -Identity $_.DistinguishedName).Count -eq 0 } | Select-Object -ExpandProperty Name

# Generate Output
$output = @"
ACTIVE DIRECTORY SECURITY COMPLIANCE AUDIT REPORT
Generated: $(Get-Date)
Domain: hybridenterprise.local
=========================================================

1. Users with PasswordNeverExpires Flag:
$($noExpireUsers -join "`n")

2. Disabled User Accounts:
$($disabledUsers -join "`n")

3. Empty AD Security Groups:
$($emptyGroups -join "`n")
"@

$output | Out-File -FilePath $reportPath -Encoding utf8
Write-Host "Security audit complete. Saved to: $reportPath" -ForegroundColor Green