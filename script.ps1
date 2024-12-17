# Script de création de structure AD pour entreprise

# Définition des variables
$domainDN = "DC=entreprise,DC=local"
$ouBase = "OU=ENTREPRISE,$domainDN"

# 1. Création des Unités d'Organisation principales
$mainOUs = @(
    "Direction",
    "Ressources_Humaines",
    "Informatique",
    "Commercial",
    "Production",
    "Finance",
    "Administratif"
)
foreach ($ou in $mainOUs) {
    New-ADOrganizationalUnit -Name $ou -Path $ouBase -ProtectedFromAccidentalDeletion $true
}

# 2. Création des sous-OUs pour chaque département
$subOUs = @(
    "Utilisateurs",
    "Groupes",
    "Ordinateurs"
)
foreach ($mainOU in $mainOUs) {
    foreach ($subOU in $subOUs) {
        New-ADOrganizationalUnit -Name $subOU -Path "OU=$mainOU,$ouBase" -ProtectedFromAccidentalDeletion $true
    }
}

# 3. Création des groupes de sécurité par département
$securityLevels = @("Admin", "User", "ReadOnly")
foreach ($mainOU in $mainOUs) {
    foreach ($level in $securityLevels) {
        $groupName = "GRP_${mainOU}_${level}"
        New-ADGroup -Name $groupName `
            -Path "OU=Groupes,OU=$mainOU,$ouBase" `
            -GroupCategory Security `
            -GroupScope Global
    }
}

# 4. Import et création des utilisateurs depuis un CSV
$users = @(
    @{
        FirstName="Jean"; LastName="Dupont"; Department="Direction"; Title="Directeur Général"; SecurityLevel="Admin"
    },
    @{
        FirstName="Marie"; LastName="Martin"; Department="Ressources_Humaines"; Title="DRH"; SecurityLevel="Admin"
    }
    # ... Ajoutez d'autres utilisateurs ici
)

# Création des utilisateurs
foreach ($user in $users) {
    $username = ($user.FirstName.ToLower() + "." + $user.LastName.ToLower())
    $upn = "$username@entreprise.local"
    $ou = "OU=Utilisateurs,OU=$($user.Department),$ouBase"
    # Création de l'utilisateur
    New-ADUser -Name "$($user.FirstName) $($user.LastName)" `
        -GivenName $user.FirstName `
        -Surname $user.LastName `
        -UserPrincipalName $upn `
        -SamAccountName $username `
        -Path $ou `
        -Title $user.Title `
        -Department $user.Department `
        -Enabled $true `
        -AccountPassword (ConvertTo-SecureString "ChangeMe123!" -AsPlainText -Force) `
        -PasswordNeverExpires $false `
        -ChangePasswordAtLogon $true
    # Ajout au groupe correspondant
    Add-ADGroupMember -Identity "GRP_$($user.Department)_$($user.SecurityLevel)" -Members $username
}

# 5. Script pour générer 30 utilisateurs aléatoires
$departments = $mainOUs
$titles = @("Manager", "Assistant", "Responsable", "Analyste", "Technicien")
$securityLevels = @("User", "ReadOnly", "Admin")
1..30 | ForEach-Object {
    $firstName = "Utilisateur$_"
    $lastName = "Test$_"
    $department = Get-Random -InputObject $departments
    $title = Get-Random -InputObject $titles
    $securityLevel = Get-Random -InputObject $securityLevels
    $username = "$firstName.$lastName".ToLower()
    $upn = "$username@entreprise.local"
    $ou = "OU=Utilisateurs,OU=$department,$ouBase"
    # Création de l'utilisateur
    New-ADUser -Name "$firstName $lastName" `
        -GivenName $firstName `
        -Surname $lastName `
        -UserPrincipalName $upn `
        -SamAccountName $username `
        -Path $ou `
        -Title $title `
        -Department $department `
        -Enabled $true `
        -AccountPassword (ConvertTo-SecureString "ChangeMe123!" -AsPlainText -Force) `
        -PasswordNeverExpires $false `
        -ChangePasswordAtLogon $true
    # Ajout au groupe correspondant
    Add-ADGroupMember -Identity "GRP_${department}_${securityLevel}" -Members $username
}