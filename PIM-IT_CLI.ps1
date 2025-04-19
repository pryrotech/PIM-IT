###########################################
#         PIM-IT PowerShell Tool          #
#        By Colby Pryor (PryroTech)       #
###########################################

# Imports
Import-Module Microsoft.Graph.Beta.Identity.Governance

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All", "RoleAssignmentSchedule.ReadWrite.Directory" -UseDeviceAuthentication -NoWelcome

# Get current user ID (CHANGE BEFORE RUNNING SCRIPT)
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

Write-Output "**********************************************"
Write-Output "***       Welcome to PIM-IT CLI Tool       ***"
Write-Output "**********************************************"
Start-Sleep -Seconds 3
Clear-Host

$searchingForRoles = $True

while ($searchingForRoles -eq $True) {
    if ($eligibleRoleNames.Count -ge 1) {
        Write-Output "Welcome to PIM-IT! Please select the role you require below:"
        for ($i = 0; $i -lt $eligibleRoleNames.Count; $i++) {
            Write-Output "$($i + 1). $($eligibleRoleNames[$i])"
        }
        $roleSelection = Read-Host "Please select a number and press ENTER"
        $selectedRoleIndex = $roleSelection - 1
        if ($selectedRoleIndex -ge 0 -and $selectedRoleIndex -lt $eligibleRoleNames.Count) {
            $selectedRole = $eligibleRoleNames[$selectedRoleIndex]
            Write-Output "You have selected the role: $selectedRole"
            $searchingForRoles = $False
        } else {
            Write-Output "Invalid selection. Please try again."
        }
    } else {
        Write-Output "No roles found. Would you like to try again? (Y/N)"
        $retry = Read-Host "Enter Y to retry or N to exit"
        if ($retry -eq "Y") {
            $eligibleRoles = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -Filter "principalId eq '$($currentUser.Id)'"
            $eligibleRoleNames = @()
            foreach ($role in $eligibleRoles) {
                $roleDefinition = $roleDefinitions | Where-Object { $_.Id -eq $role.RoleDefinitionId }
                $eligibleRoleNames += $roleDefinition.DisplayName
            }
        } else {
            $searchingForRoles = $False
            Write-Output "Exiting the tool. No roles found."
        }
    }
}

# Prompt user to assign the selected role
if ($selectedRole) {
    $assignRole = Read-Host "Do you want to assign the role '$selectedRole'? (Y/N)"
    $setRoleHours = Read-Host "Specify the number of hours you wish to have the role and press ENTER"
    if ($assignRole -eq "Y") {
        $roleDefinitionId = ($roleDefinitions | Where-Object { $_.DisplayName -eq $selectedRole }).Id
        $directoryScopeId = "/"  # The scope of the role assignment ("/" for tenant-wide)

        # Create the role assignment request
        $roleAssignmentRequest = @{
            Action = "selfActivate"
            PrincipalId = "5ca7e804-9c8e-40b4-8e03-556ce0aa93cd"
            RoleDefinitionId = $roleDefinitionId
            DirectoryScopeId = "/"
            AssignmentType = "Eligible"  # Can be "Eligible" or "Active"  
            Justification = "Assigning role via PIM-IT CLI Tool"
            ScheduleInfo = @{
                StartDateTime = Get-Date
                Expiration = @{
                    Type = "AfterDuration"
                    Duration = "PT"+$setRoleHours+"H"
                }
            }
        }

        # Submit the role assignment request
        New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $roleAssignmentRequest
        Write-Output "Role '$selectedRole' has been assigned."
    } else {
        Write-Output "Role assignment cancelled."
    }
}
