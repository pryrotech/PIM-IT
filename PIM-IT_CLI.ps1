###########################################
#         PIM-IT PowerShell Tool          #
#        By Colby Pryor (PryroTech)       #
###########################################

# Imports
Import-Module Microsoft.Graph.Beta.Identity.Governance
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Users

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

Write-Output "**********************************************"
Write-Output "***       Welcome to PIM-IT CLI Tool       ***"
Write-Output "**********************************************"
Start-Sleep -Seconds 3

$searchingForRoles = $True

while ($searchingForRoles -eq $True) {
    Write-Output "Welcome to PIM-IT! Please select an action:"
    Write-Output "1. Activate a role"
    Write-Output "A. Activation Packages"
    Write-Output "D. Deactivate a role"
    Write-Output "U. Update an active role"
    Write-Output "X. Exit"
    $actionSelection = Read-Host "Enter your choice"

    if ($actionSelection -eq "1") {
        # Activation process
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

                # Prompt user to assign the role
                $assignRole = Read-Host "Do you want to assign the role '$selectedRole'? (Y/N)"
                if ($assignRole -eq "Y") {
                    do {
                        $setRoleHours = Read-Host "Specify the number of hours you wish to have the role and press ENTER"
                        $setRoleMinutes = [int]$setRoleHours * 60

                        if ($setRoleMinutes -lt 5) {
                            Write-Output "Error: The minimum required active duration is 5 minutes. Please enter a valid duration."
                        }
                    } while ($setRoleMinutes -lt 5)

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
                    New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $roleDeactivationRequest
                    Write-Output "Role activated successfully." 

                } else {
                    Write-Output "Role assignment cancelled."
                }
            } else {
                Write-Output "Invalid selection."
            }
        } else {
            Write-Output "No eligible roles found."
        }
    } elseif ($actionSelection -eq "D") {
        # Deactivation process
        $activatedRoles = Get-MgRoleManagementDirectoryRoleAssignment -Filter "principalId eq '$($currentUser.Id)'"
        $activeRoleDefinitions = Get-MgRoleManagementDirectoryRoleDefinition
        $activatedRoleNames = @()

        foreach($role in $activatedRoles){
            $roleDefinition = $activeRoleDefinitions | Where-Object { $_.Id -eq $role.RoleDefinitionId }
            $activatedRoleNames += $roleDefinition.DisplayName
        }

        if ($activatedRoleNames.Count -gt 0) {
            Write-Output "Select an active role to deactivate:"
            for ($i = 0; $i -lt $activatedRoleNames.Count; $i++) {
                Write-Output "$($i + 1). $($activatedRoleNames[$i])"
            }
            $roleSelection = Read-Host "Enter the number of the role to deactivate"

            if ($roleSelection -ge 1 -and $roleSelection -le $activatedRoleNames.Count) {
                $roleDefinitionId = ($activeRoleDefinitions | Where-Object { $_.DisplayName -eq $activatedRoleNames[$roleSelection - 1] }).Id
                Write-Output "You have selected: $($activatedRoleNames[$roleSelection - 1]). Deactivating..."

                $roleDeactivationRequest = @{
                    Action = "selfDeactivate"
                    PrincipalId = $currentUser.Id
                    RoleDefinitionId = $roleDefinitionId
                    DirectoryScopeId = "/"
                    Justification = "Deactivating role via PIM-IT CLI Tool"
                }

                New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $roleDeactivationRequest
                Write-Output "Role deactivated successfully."
            } else {
                Write-Output "Invalid selection."
            }
        } else {
            Write-Output "No active roles found."
        }
    } elseif ($actionSelection -eq "U") {

        # Retrieve all role definitions
$roleDefinitions = Get-MgRoleManagementDirectoryRoleDefinition

# Function to get role name by role definition ID
function Get-RoleNameById($roleDefinitionId) {
    $roleDefinition = $roleDefinitions | Where-Object { $_.Id -eq $roleDefinitionId }
    return $roleDefinition.DisplayName
}

# Update active role
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

 else {
            Write-Output "Invalid selection."
        }
    } elseif ($actionSelection -eq "X") {
        Write-Output "Exiting the tool."
        Disconnect-MgGraph
        $searchingForRoles = $False
    } elseif($actionSelection -eq "A"){
        Write-Output "Welcome to activation packages. This section will allow you to activate roles with pre-filled parameters and create your own activation package."
        Write-Output "1. Use an activation package"
        Write-Output "2. Create an activation package"
        $actionSelection = Read-Host "Select an option and press ENTER"

        if($actionSelection -eq 1){
            $packageName = Read-Host "Please enter the package name and press ENTER"
            $packageContents = Get-Content -Path "C:\Users\$env:USERNAME\$($packageName).json"
            New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $packageContents
        }

        elseif($actionSelection -eq 2){
            $RoleName = Read-Host "Please enter the role name and press ENTER"
            $RoleDuration = Read-Host "Please enter number of hours required"
            $RoleJustification = Read-Host "Please enter the justification"
            $PackageName = Read-Host "Please enter in the name of the package and press ENTER"

            $rolesAvailable = Get-MgRoleManagementDirectoryRoleDefinition -All

            if($RoleName -in $rolesAvailable.DisplayName){
                $roleDefinitionId = ($roleDefinitions | Where-Object { $_.DisplayName -eq $selectedRole }).Id
                    $directoryScopeId = "/"  
                    $roleCreation = [PSCustomObject]@{
                        Action = "selfActivate"
                        PrincipalId = $currentUser.Id
                        RoleDefinitionId = $roleDefinitionId = ($roleDefinitions | Where-Object { $_.DisplayName -eq $RoleName }).Id
                        DirectoryScopeId = $directoryScopeId
                        AssignmentType = "Eligible"
                        Justification = $RoleJustification
                        ScheduleInfo = @{
                            StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                            Expiration = @{
                                Type = "AfterDuration"
                                Duration = "PT$RoleDuration`H"
                            }
                        }
                }
                $roleCreationJson = $roleCreation | ConvertTo-Json -Depth 3 -Compress
                $roleCreationJson | Out-File "C:\Users\$env:USERNAME\$($PackageName).json"
            }
            }
            }
            
        }
        
    
    else {
        Write-Output "Invalid selection. Please try again."
    }

