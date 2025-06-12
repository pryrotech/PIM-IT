Function UpdatePIMRole{

    Import-Module Microsoft.Graph.Beta.Identity.Governance
    Import-Module Microsoft.Graph.Authentication
    Import-Module Microsoft.Graph.Users

    Connect-MgGraph -Scopes "User.Read.All, RoleManagement.ReadWrite.Directory, RoleAssignmentSchedule.Read.Directory, RoleEligibilitySchedule.Read.Directory " -NoWelcome | Format-List userPrincipalName


    $currentUser = Get-MgUser -UserId (Get-MgUser -Filter "userPrincipalName eq '$env:USERNAME@$env:USERDNSDOMAIN'").Id

    $activatedRoles = Get-MgRoleManagementDirectoryRoleAssignment -Filter "principalId eq '$($currentUser.Id)'"
    Write-Output "Select an active role to update:"
    for ($i = 0; $i -lt $activatedRoles.Count; $i++) {
        $roleName = Get-RoleNameById($activatedRoles[$i].RoleDefinitionId)
        Write-Output "$($i + 1). $roleName"
    }
    $roleUpdateSelection = Read-Host "Enter the number of the role to update (NOTE: the role must be active for at least five minutes prior to updating!)"


    if ($roleUpdateSelection -ge 1 -and $roleUpdateSelection -le $activatedRoles.Count) {
        $updateRoleHours = Read-Host "Enter the new duration (in hours) for this role"
        
        $roleDeactivationRequest = @{
            Action = "selfDeactivate"
            PrincipalId = $currentUser.Id
            RoleDefinitionId = $roleDefinitionId
            DirectoryScopeId = "/"
            Justification = "Deactivating role via PIM-IT CLI Tool"
        }

        New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $roleDeactivationRequest
        Write-Output "Role deactivated successfully."
        
        # Create a new role assignment with the updated parameters
        $roleDefinitionId = ($roleDefinitions | Where-Object { $_.DisplayName -eq $selectedRole }).Id
                        $directoryScopeId = "/"  
                        $roleAssignmentRequest = @{
                            Action = "selfActivate"
                            PrincipalId = $currentUser.Id
                            RoleDefinitionId = $roleDefinitionId
                            DirectoryScopeId = $directoryScopeId
                            AssignmentType = "Eligible"
                            Justification = "Assigning role via PIM-IT CLI Tool"
                            ScheduleInfo = @{
                                StartDateTime = Get-Date
                                Expiration = @{
                                    Type = "AfterDuration"
                                    Duration = "PT"+$setRoleHours+"H"
                                }
                            }
                        }

                        New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $roleAssignmentRequest
                        Write-Output "Role '$selectedRole' has been assigned."
    }
}