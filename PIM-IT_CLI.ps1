###########################################
#         PIM-IT PowerShell Tool          #
#        By Colby Pryor (PryroTech)       #
###########################################

# Imports
Import-Module Microsoft.Graph.Beta.Identity.Governance

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All" -NoWelcome

# Get current user ID
$currentUser = Get-MgUser -userid '//' | Format-List

# Get eligible PIM roles
$eligibleRoles = Get-MgDirectoryRole -Filter "UserId eq '$currentUser'"

# Output results
Write-Output $eligibleRoles
