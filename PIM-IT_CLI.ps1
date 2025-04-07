###########################################
#         PIM-IT PowerShell Tool          #
#        By Colby Pryor (PryroTech)       #
###########################################

# Imports
Import-Module Microsoft.Graph.Beta.Identity.Governance
Import-Module Microsoft.Graph

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All" -NoWelcome

# Get current user ID
$currentUser = Get-MgUser -UserId -Filter 'UserPrincipalName eq "cpryor@pryrotechsandbox.onmicrosoft.com"'

#Get eligible PIM roles

$eligibleRoles = Get-MgBetaPrivilegedRoleRoleAssignment -Filter "principalId eq '$($currentUser.Id)' and assignmentState eq 'Eligible'"

Write-Output $eligibleRoles
