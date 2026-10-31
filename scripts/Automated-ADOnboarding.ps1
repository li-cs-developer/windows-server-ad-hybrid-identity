Import-Module ActiveDirectory

$csvPath = "C:\Users\admin\Desktop\NewUsers.csv"
Write-Host "Looking for CSV at: $csvPath" -ForegroundColor Yellow

if (-not (Test-Path $csvPath)) {
    Write-Error "CSV file not found!"
    exit
}

$users = Import-Csv -Path $csvPath
Write-Host "Successfully loaded $($users.Count) user(s) from CSV." -ForegroundColor Green

$securePassword = ConvertTo-SecureString "TempPass2026!" -AsPlainText -Force

foreach ($user in $users) {
    $ouName = $user.OU
    $ouPath = "OU=$ouName,DC=hybridenterprise,DC=local"
    
    # Check if OU exists; if not, create it
    $existingOU = Get-ADOrganizationalUnit -Filter "Name -eq '$ouName'" -ErrorAction SilentlyContinue
    if (-not $existingOU) {
        New-ADOrganizationalUnit -Name $ouName -Path "DC=hybridenterprise,DC=local"
        Write-Host "Created OU: $ouName" -ForegroundColor Green
    } else {
        Write-Host "OU already exists: $ouName" -ForegroundColor DarkGray
    }
    
    # Create the AD User with explicit -Name parameter
    New-ADUser -SamAccountName $user.SamAccountName -UserPrincipalName "$($user.SamAccountName)@hybridenterprise.local" -Name "$($user.FirstName) $($user.LastName)" -GivenName $user.FirstName -Surname $user.LastName -DisplayName "$($user.FirstName) $($user.LastName)" -Department $user.Department -Title $user.Title -Path $ouPath -AccountPassword $securePassword -Enabled $true -ChangePasswordAtLogon $true
    
    Write-Host "Successfully created user: $($user.SamAccountName)" -ForegroundColor Cyan
}

Write-Host "All onboarding tasks completed successfully!" -ForegroundColor Green