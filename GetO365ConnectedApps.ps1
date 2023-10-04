<#
.SYNOPSIS
    This script checks and displays forwarding rules for all active mailboxes in Exchange Online.

.DESCRIPTION
    1. The script begins by connecting to Exchange Online.
    2. It retrieves the list of accepted domains.
    3. It connects to Azure AD and fetches all active user mailboxes.
    4. For each active mailbox, the script fetches its forwarding rules.
    5. The rules are then checked to see if they forward to external recipients.
       External recipients are those whose domains are not in the accepted domains list.
    6. The script displays each mailbox's name and primary SMTP address.
    7. For each forwarding rule, the script:
       - Displays external forwarding rules in yellow.
       - Displays internal forwarding rules in gray.

.NOTES
    The script only provides a visual representation of the forwarding rules.
    It does not make any changes or generate any CSV outputs.

#>


# Connect to Exchange Online
Connect-ExchangeOnline -ShowProgress $true

# Retrieve accepted domains
$domains = Get-AcceptedDomain

# Connect to AzureAD
Connect-AzureAD

# Retrieve all active user mailboxes by filtering with Azure AD
$activeUsers = Get-AzureADUser -Filter "accountEnabled eq true"

foreach ($user in $activeUsers) {
    Write-Host ("Checking applications for " + $user.DisplayName + " - " + $user.UserPrincipalName) -ForegroundColor Green

    # Fetch OAuth 2.0 permission grants for the user
    $permissions = Get-AzureADUserOAuth2PermissionGrant -ObjectId $user.ObjectId

    foreach ($permission in $permissions) {
        # Retrieve service principal details for the application
        $servicePrincipal = Get-AzureADServicePrincipal -ObjectId $permission.ResourceId

        if ($servicePrincipal) {
            Write-Host ("    Connected Application: " + $servicePrincipal.DisplayName) -ForegroundColor Cyan
            Write-Host ("        Permission ID: " + $permission.Id) -ForegroundColor Gray
            Write-Host ("        Permission Type: " + $permission.Type) -ForegroundColor Gray
            Write-Host ("        Permission Scope: " + $permission.Scope) -ForegroundColor Gray
        }
    }
}
