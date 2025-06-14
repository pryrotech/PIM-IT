Function DeactivatePIMRole {
  
    Connect-MgGraph -Scopes "User.Read.All, RoleManagement.ReadWrite.Directory, RoleAssignmentSchedule.Read.Directory, RoleEligibilitySchedule.Read.Directory " -NoWelcome | Format-List userPrincipalName


    $currentUser = Get-MgUser -UserId (Get-MgUser -Filter "userPrincipalName eq '$env:USERNAME@$env:USERDNSDOMAIN'").Id


    $eligibleRoles = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -Filter "principalId eq '$($currentUser.Id)'"
    $roleDefinitions = Get-MgRoleManagementDirectoryRoleDefinition


    $eligibleRoleNames = @()
    foreach ($role in $eligibleRoles) {
        $roleDefinition = $roleDefinitions | Where-Object { $_.Id -eq $role.RoleDefinitionId }
        $eligibleRoleNames += $roleDefinition.DisplayName
    }


        if ($eligibleRoleNames.Count -ge 1) {
            Write-Output "Please select the role you wish to deactivate below:"
            for ($i = 0; $i -lt $eligibleRoleNames.Count; $i++) {
                Write-Output "$($i + 1). $($eligibleRoleNames[$i])"
            }
            $roleSelection = Read-Host "Please select a number and press ENTER"

            $selectedRoleIndex = $roleSelection - 1
            if ($selectedRoleIndex -ge 0 -and $selectedRoleIndex -lt $eligibleRoleNames.Count) {
                $selectedRole = $eligibleRoleNames[$selectedRoleIndex]
                Write-Output "You have selected the role: $selectedRole"

                $assignRole = Read-Host "Do you want to deactivate the role '$selectedRole'? (Y/N)"
                if ($assignRole -eq "Y") {
                    
                    $roleDefinitionId = ($roleDefinitions | Where-Object { $_.DisplayName -eq $selectedRole }).Id

                        $roleDeactivationRequest = @{
                        Action = "selfDeactivate"
                        PrincipalId = $currentUser.Id
                        RoleDefinitionId = $roleDefinitionId
                        DirectoryScopeId = "/"
                        Justification = "Deactivating role via PIM-IT CLI Tool"
                    }
                        New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $roleDeactivationRequest
                        Write-Output "Role deactivated successfully." 

            }
            else{
                Write-Output "Role was not deactivated."
            }
        else{
            Write-Output "Role was not deactivated."
        }
        }
    else{
        Write-Output "Role was not deactivated."
    }
    }
    else{
        Write-Output "Role was not deactivated."
    }
}
