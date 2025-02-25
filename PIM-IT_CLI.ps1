###########################################
#         PIM-IT PowerShell Tool          #
#        By Colby Pryor (PryroTech)       #
###########################################

# Install packages if required
Install-Module Microsoft.Graph

# Connect to Microsoft Graph with the required scopes
Connect-MgGraph -Scopes "User.Read", "RoleManagement.ReadWrite.Directory" -NoWelcome

# Set variable for program and menu
$programStatus = 1

# Retrieve the user ID for a specific UPN
$user = Get-MgUser -UserId 'cpryor@pryrotechsandbox.onmicrosoft.com'
$userId = $user.Id

# Get the eligible roles for the user based on the user ID
$eligibleRoles = Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -Filter "principalId eq '$userId'"


while($programStatus -eq 1){
    # Output welcome message and eligible roles
Write-Output "******************************"
Write-Output "* Welcome to PIM-IT CLI Tool *"
Write-Output "******************************"

if ($eligibleRoles -eq $null -or $eligibleRoles.Count -eq 0) {
    $eligibleRoles = Read-Host "No roles found. Scan for new roles? (Y/N)"

    if($eligibleRoles -eq "y"){
        Write-Output "Scanning..."
        $eligibleRoles = Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -Filter "principalId eq '$userId'"
    }

    if($eligibleRoles -eq "n"){
        $programStatus = 0
    }
}

if ($eligibleRoles -ne $null -or $eligibleRoles.Count -gt 0) {
    Write-Output "`nHello $($user.UserPrincipalName), please select one of your eligible roles below:"
    Write-Output $eligibleRoles
}

}
Write-Output "Have a good day! Exiting."