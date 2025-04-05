###########################################
#         PIM-IT PowerShell Tool          #
#        By Colby Pryor (PryroTech)       #
###########################################

#Imports
Import-Module Microsoft.Graph.Beta.Identity.Governance

#Connect to Mg-Graph
Connect-MgGraph -Scopes "PrivilegedAccess.ReadWrite.AzureADGroup"
$user = "//"

#Get all eligible PIM roles
$roles = Get-MgBetaRoleManagementDirectoryRoleAssignmentSchedule -All  -Filter "PrincipalId eq '$($user.Id)'"

Write-Output $roles.RoleDefinition.DisplayName