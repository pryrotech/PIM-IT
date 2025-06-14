Function ActivatePIMRole {
    # Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All, RoleManagement.ReadWrite.Directory, RoleAssignmentSchedule.Read.Directory, RoleEligibilitySchedule.Read.Directory " -NoWelcome | Format-List userPrincipalName

# Get current user ID
$currentUser = Get-MgUser -UserId (Get-MgUser -Filter "userPrincipalName eq '$env:USERNAME@$env:USERDNSDOMAIN'").Id

# Get eligible PIM roles
$eligibleRoles = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -Filter "principalId eq '$($currentUser.Id)'"
$roleDefinitions = Get-MgRoleManagementDirectoryRoleDefinition

# Output results
$eligibleRoleNames = @()
foreach ($role in $eligibleRoles) {
    $roleDefinition = $roleDefinitions | Where-Object { $_.Id -eq $role.RoleDefinitionId }
    $eligibleRoleNames += $roleDefinition.DisplayName
}


    if ($eligibleRoleNames.Count -ge 1) {
        Write-Output "Please select the role you require below:"
        for ($i = 0; $i -lt $eligibleRoleNames.Count; $i++) {
            Write-Output "$($i + 1). $($eligibleRoleNames[$i])"
        }
        $roleSelection = Read-Host "Please select a number and press ENTER"

        $selectedRoleIndex = $roleSelection - 1
        if ($selectedRoleIndex -ge 0 -and $selectedRoleIndex -lt $eligibleRoleNames.Count) {
            $selectedRole = $eligibleRoleNames[$selectedRoleIndex]
            Write-Output "You have selected the role: $selectedRole"

            $assignRole = Read-Host "Do you want to assign the role '$selectedRole'? (Y/N)"
            if ($assignRole -eq "Y") {
                do {
                    $setRoleHours = Read-Host "Specify the number of hours you wish to have the role and press ENTER"
                    $setRoleMinutes = [int]$setRoleHours * 60

                    if ($setRoleMinutes -lt 5) {
                        Write-Output "Error: The minimum required active duration is 5 minutes. Please enter a valid duration."
                    }
                } 
                while ($setRoleMinutes -lt 5)

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
                    Write-Output "Role activated successfully." 

        }
    }
}
    }
