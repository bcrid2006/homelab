# Reset-Lab.ps1
# Puts every lab user and shared lab setting back to a known-good state.
#   .\Reset-Lab.ps1 -Check   : only report problems, change nothing
#   .\Reset-Lab.ps1          : report and fix everything

param([switch]$Check)

. "$PSScriptRoot\LabConfig.ps1"

# ---------- Users ----------
foreach ($sam in $LabUsers.Keys) {
    $problems = Get-UserProblems $sam
    if (-not $problems) { Write-Host "OK       $sam"; continue }

    Write-Host "PROBLEM  $sam : $($problems -join ', ')"
    if ($Check) { continue }

    $dept = $Depts[$LabUsers[$sam]]
    Enable-ADAccount $sam
    Unlock-ADAccount $sam
    Clear-ADAccountExpiration $sam
    Set-ADUser $sam -ChangePasswordAtLogon $false -Clear logonHours, userWorkstations

    $dn = (Get-ADUser $sam).DistinguishedName
    if ($dn -notlike "*,$($dept.OU)") { Move-ADObject $dn -TargetPath $dept.OU }
    Add-ADGroupMember $dept.Group -Members $sam

    $left = Get-UserProblems $sam
    if ($left) { Write-Host "  STILL WRONG: $($left -join ', ')" } else { Write-Host "  fixed" }
}

# ---------- Shared settings ----------
$envProblems = Get-EnvironmentProblems
if (-not $envProblems) {
    Write-Host "OK       environment"
}
else {
    Write-Host "PROBLEM  environment : $($envProblems -join ', ')"
    if (-not $Check) {
        if (-not (Get-SmbShareAccess -Name $ShareName | Where-Object AccountName -eq "BJLAB\$($Depts.Sales.Group)")) {
            Grant-SmbShareAccess -Name $ShareName -AccountName "BJLAB\$($Depts.Sales.Group)" -AccessRight Change -Force | Out-Null
        }
        Set-GPLink -Name $SalesGpo -Target $Depts.Sales.OU -LinkEnabled Yes | Out-Null
        Get-ADComputer $Computer | Enable-ADAccount
        $left = Get-EnvironmentProblems
        if ($left) { Write-Host "  STILL WRONG: $($left -join ', ')" } else { Write-Host "  fixed" }
    }
}

if (-not $Check) {
    Write-Host ""
    Write-Host "Done. Users who were logged in should sign out and back in."
    Write-Host "Close any leftover open tickets in osTicket by hand."
}
