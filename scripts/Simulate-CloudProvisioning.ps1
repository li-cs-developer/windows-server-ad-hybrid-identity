Import-Module ActiveDirectory

# Define paths
$exportPath = "$env:USERPROFILE\Desktop\CloudProvisioning_Export.json"
$logPath = "$env:USERPROFILE\Desktop\CloudSync_Audit.log"

Write-Host "=== Starting Hybrid Identity Cloud Export ===" -ForegroundColor Cyan

# 1. Fetch users from Active Directory OUs
$targetOUs = @("IT_Dept", "HR_Dept", "Finance_Dept")
$hybridUsers = @()

foreach ($ou in $targetOUs) {
    $ouPath = "OU=$ou,DC=hybridenterprise,DC=local"
    $adUsers = Get-ADUser -Filter * -SearchBase $ouPath -Properties Department, Title, UserPrincipalName
    
    foreach ($u in $adUsers) {
        $cloudObject = [PSCustomObject]@{
            OnPremisesSamAccountName = $u.SamAccountName
            UserPrincipalName        = "$($u.SamAccountName)@hybridenterprise.onmicrosoft.com"
            DisplayName              = $u.Name
            Department               = $u.Department
            Title                    = $u.Title
            ImmutableId              = [Convert]::ToBase64String($u.ObjectGUID.ToByteArray())
            SyncStatus               = "StagedForCloudProvisioning"
            ProvisionedTimestamp     = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        }
        $hybridUsers += $cloudObject
    }
}

# 2. Export staging schema to JSON
$hybridUsers | ConvertTo-Json -Depth 3 | Out-File -FilePath $exportPath -Encoding utf8
Write-Host "Successfully exported $($hybridUsers.Count) staged identity records to: $exportPath" -ForegroundColor Green

# 3. Generate Audit Log
$logHeader = "HYBRID IDENTITY SYNCHRONIZATION AUDIT REPORT`nGenerated: $(Get-Date)`n" + ("=" * 50) + "`n"
$logHeader | Out-File -FilePath $logPath

foreach ($user in $hybridUsers) {
    $logEntry = "SUCCESS: Mapped [$($user.OnPremisesSamAccountName)] -> UPN: [$($user.UserPrincipalName)] | ImmutableID: [$($user.ImmutableId)]"
    Add-Content -Path $logPath -Value $logEntry
    Write-Host $logEntry -ForegroundColor Cyan
}

Write-Host "`nSimulation completed successfully!" -ForegroundColor Green