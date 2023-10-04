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
Write-Output "Connecting to Exchange Online..."
Connect-ExchangeOnline -ShowProgress $true

# Retrieve accepted domains
$domains = Get-AcceptedDomain
Connect-AzureAD

# Retrieve all active user mailboxes by filtering with Azure AD
$activeUsers = Get-AzureADUser -Filter "accountEnabled eq true"
$activeMailboxes = $activeUsers | 
    ForEach-Object { 
        Get-Mailbox -Identity $_.UserPrincipalName -ErrorAction SilentlyContinue 
    }

# Check forwarding rules for each active mailbox
foreach ($mailbox in $activeMailboxes) {
    Write-Host ("Checking rules for " + $mailbox.DisplayName + " - " + $mailbox.PrimarySmtpAddress) -ForegroundColor Green
    $rules = Get-InboxRule -Mailbox $mailbox.PrimarySmtpAddress
    
    foreach ($rule in $rules) {
        $recipients = ($rule.ForwardTo + $rule.ForwardAsAttachmentTo) | Where-Object { $_ -match "SMTP" }
        
        $externalRecipients = $recipients | 
            Where-Object {
                $email = ($_ -split "SMTP:")[1].Trim("]")
                $domain = ($email -split "@")[1]
                return $domains.DomainName -notcontains $domain
            } | 
            ForEach-Object { ($_ -split "SMTP:")[1].Trim("]") }

        $extRecString = $externalRecipients -join ", "

        if ($externalRecipients) {
            Write-Host ("    $($rule.Name) forwards to $extRecString") -ForegroundColor Yellow
        } else {
            Write-Host ("    $($rule.Name) has internal forwarding") -ForegroundColor Gray
        }
    }
}
