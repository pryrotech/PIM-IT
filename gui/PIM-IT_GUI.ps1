###########################################
#               PIM-IT GUI                #
#        By Colby Pryor (PryroTech)       #
###########################################

# Imports
Import-Module Microsoft.Graph.Beta.Identity.Governance
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Users
Add-Type -assembly System.Windows.Forms

# Initializers
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = 'PIM-IT GUI Tool'
$mainForm.Width = 600
$mainForm.Height = 400
$mainForm.StartPosition = "CenterScreen"

#Variables
$authentication = $False

# Create a label and apply properties
$label = New-Object System.Windows.Forms.Label
$label.Text = "PIM-IT: User Portal"
$label.Font = New-Object System.Drawing.Font("Arial", 30)
$label.ForeColor = [System.Drawing.Color]::Black
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(110, 50)
$mainForm.Controls.Add($label)

# Create a button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Continue"
$button.Size = New-Object System.Drawing.Size(200, 50)
$button.Location = New-Object System.Drawing.Point(180, 120)
$mainForm.Controls.Add($button)

# Button click event
$button.Add_Click({
    $mainForm.Controls.Remove($label)
    $mainForm.Controls.Remove($button)
    $mainForm.Refresh()
})

while($authentication -eq $False){
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Attempting to authenticate..."
    $label.Font = New-Object System.Drawing.Font("Arial", 15)
    $label.ForeColor = [System.Drawing.Color]::Black
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(110, 50)
    $mainForm.Controls.Add($label)
}

$mainForm.ShowDialog()



