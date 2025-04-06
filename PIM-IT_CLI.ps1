###########################################
#         PIM-IT PowerShell Tool          #
#        By Colby Pryor (PryroTech)       #
###########################################

# Imports
Import-Module Microsoft.Graph.Beta.Identity.Governance
Import-Module Microsoft.Graph.Authentication

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory"

# Get current user ID
$currentUser = 'cpryor@pryrotechsandbox.onmicrosoft.com'

# Get all eligible PIM role assignments
$roles = Get-MgRoleManagementDirectoryRoleDefinition -All

# Filter roles based on the connected user
$eligibleRoles = $roles | Where-Object { $_.PrincipalId -eq $currentUser }

Write-Output $eligibleRoles
