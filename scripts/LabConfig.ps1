# LabConfig.ps1
# Shared settings and health checks for the BJLab scripts.
# The other scripts load this file with:  . "$PSScriptRoot\LabConfig.ps1"

Import-Module ActiveDirectory
Import-Module GroupPolicy

$DomainDN = 'DC=bjlab,DC=local'

# Where each department lives and which group it uses
$Depts = @{
    Sales = @{ OU = "OU=Sales,OU=Staff,OU=BJLab,$DomainDN"; Group = 'SG-Sales' }
    HR    = @{ OU = "OU=HR,OU=Staff,OU=BJLab,$DomainDN";    Group = 'SG-HR' }
}

# Users the scripts are allowed to break, and the department each belongs in.
# IT and admin accounts are never touched.
$LabUsers = [ordered]@{
    dlopez = 'Sales'; ktran = 'Sales'; akim = 'Sales'
    pshah  = 'HR';    twalsh = 'HR'
}

$SalesGpo  = 'Sales - Drive Map'
$ShareName = 'Sales'
$Computer  = 'CLIENT01'

# Returns a list of everything wrong with one user. Empty list = healthy.
function Get-UserProblems($Sam) {
    $dept = $Depts[$LabUsers[$Sam]]
    $u = Get-ADUser $Sam -Properties Enabled, LockedOut, AccountExpirationDate, pwdLastSet, MemberOf, logonHours, userWorkstations
    $p = @()
    if (-not $u.Enabled)            { $p += 'disabled' }
    if ($u.LockedOut)               { $p += 'locked out' }
    if ($u.AccountExpirationDate)   { $p += 'expiration set' }
    if ($u.pwdLastSet -eq 0)        { $p += 'must change password at next logon' }
    if ($u.DistinguishedName -notlike "*,$($dept.OU)") { $p += 'wrong OU' }
    $groupDN = (Get-ADGroup $dept.Group).DistinguishedName
    if ($u.MemberOf -notcontains $groupDN) { $p += "not in $($dept.Group)" }
    if ($u.logonHours -and ($u.logonHours | Where-Object { $_ -ne 255 })) { $p += 'logon hours restricted' }
    if ($u.userWorkstations)        { $p += 'workstation restricted' }
    return $p
}

# Returns a list of everything wrong with shared lab settings. Empty list = healthy.
function Get-EnvironmentProblems {
    $p = @()
    $access = Get-SmbShareAccess -Name $ShareName | Where-Object AccountName -eq "BJLAB\$($Depts.Sales.Group)"
    if (-not $access) { $p += "$($Depts.Sales.Group) missing from the $ShareName share" }
    $link = (Get-GPInheritance -Target $Depts.Sales.OU).GpoLinks | Where-Object DisplayName -eq $SalesGpo
    if (-not $link -or -not $link.Enabled) { $p += "'$SalesGpo' link disabled" }
    if (-not (Get-ADComputer $Computer).Enabled) { $p += "$Computer computer account disabled" }
    return $p
}
