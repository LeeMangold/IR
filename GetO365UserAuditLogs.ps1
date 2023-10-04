<#
.SYNOPSIS
This script retrieves the unified audit logs from Exchange Online for a specific user within the past week.
It extracts relevant audit details, accounts for variations in Client IP naming, and exports the extracted data to a CSV file.

.DESCRIPTION
- The script connects to Exchange Online using modern authentication.
- It prompts the user for the target email address.
- Defines a date range for the past week.
- Retrieves the unified audit logs for the specified email.
- Processes the audit logs to extract key details.
- Considers both "ClientIP" and "ClientIPAddress" naming conventions.
- Exports the processed data to a CSV file.
- Disconnects from Exchange Online.

.NOTES
Ensure the ExchangeOnlineManagement module is installed before executing the script.
#>

# Import required module
Import-Module -Name ExchangeOnlineManagement

# Connect to Exchange Online
Connect-ExchangeOnline -ShowProgress $true

# Prompt for user's email
$userEmail = Read-Host "Enter the user's email address"

# Define the date range for the past 7 days
$startDate = (Get-Date).AddDays(-7)
$endDate = Get-Date

# Retrieve the audit logs
$auditLogs = Search-UnifiedAuditLog -StartDate $startDate -EndDate $endDate -UserIds $userEmail

# Specify the CSV file path
$csvPath = "C:\temp\audit_logs.csv"

# Process and extract data from the audit logs
$extractedData = $auditLogs | ForEach-Object {
    $auditData = $_.AuditData | ConvertFrom-Json
    [PSCustomObject]@{
        CreationDate      = $_.CreationTime
        Operation         = $_.Operation
        ClientIP          = $auditData.ClientIPAddress ?? $auditData.ClientIP
        UserAgent         = $auditData.ClientInfoString
        DisplayName       = $auditData.DisplayName
        CommunicationType = $auditData.CommunicationType
        ResultStatus      = $_.ResultStatus
    }
}

# Export the extracted data
$extractedData | Export-Csv -Path $csvPath -NoTypeInformation

# Feedback and disconnection
Write-Host "Data exported to $csvPath"
$extractedData | Format-Table -AutoSize
Disconnect-ExchangeOnline -Confirm:$false
