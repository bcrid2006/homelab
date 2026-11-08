# New-LabTicket.ps1
# Picks a random help desk scenario, breaks it for real, and files a vague
# ticket in osTicket as the affected user. Only picks users and settings that
# are currently healthy, so problems don't pile up on top of each other.
#
#   -DryRun     : show what it would do; changes nothing, files nothing
#   -TestApi    : file one harmless test ticket; breaks nothing
#   -Issues 1|2 : force one or two problems on the same user
#                 (default: one, with a 1-in-4 chance of two)

param(
    [switch]$TestApi,
    [switch]$DryRun,
    [ValidateSet(1, 2)][int]$Issues
)

. "$PSScriptRoot\LabConfig.ps1"

$ApiUrl  = 'http://192.168.122.1/osticket/api/http.php/tickets.json'
$ApiKey  = (Get-Content "$PSScriptRoot\apikey.txt" -Raw).Trim()
$LogFile = "$PSScriptRoot\answers.log"

# ---------- Send a ticket to osTicket ----------
function Send-Ticket($Name, $Email, $Subject, $Message) {
    $Body = @{
        alert       = $false
        autorespond = $false
        source      = 'API'
        name        = $Name
        email       = $Email
        subject     = $Subject
        message     = "data:text/plain,$Message"
    } | ConvertTo-Json

    Invoke-RestMethod -Uri $ApiUrl -Method Post `
        -Headers @{ 'X-API-Key' = $ApiKey } `
        -Body $Body -ContentType 'application/json'
}

if ($TestApi) {
    $Num = Send-Ticket 'API Test' 'test@bjlab.local' 'API test ticket' 'If you can read this, the generator can reach osTicket.'
    Write-Host "Test ticket created: $Num"
    return
}

# ---------- Scenarios ----------
# Scope User = breaks one account.  Scope Env = breaks a shared setting
# (the ticket comes from one affected user, but others are hit too).
# Secondary = allowed as the hidden second problem in a two-issue ticket.
$All = @('Sales', 'HR')
$Scenarios = @(
    @{ Name = 'Account disabled'; Scope = 'User'; Depts = $All; Secondary = $true
       Break = { param($u) Disable-ADAccount $u }
       Subject = 'Cannot log in'
       Message = 'Hi, I tried to log in this morning and it will not let me in. I did not change anything. Can you help?' },

    @{ Name = 'Must change password at next logon'; Scope = 'User'; Depts = $All; Secondary = $true
       Break = { param($u) Set-ADUser $u -ChangePasswordAtLogon $true }
       Subject = 'Weird password message'
       Message = 'My computer says I have to change my password. Is this a scam? I did not ask for this.' },

    @{ Name = 'Account expired'; Scope = 'User'; Depts = $All; Secondary = $true
       Break = { param($u) Set-ADAccountExpiration $u -DateTime (Get-Date).AddDays(-1) }
       Subject = 'Locked out?'
       Message = 'I cannot sign in, it says something about my account. Please help ASAP.' },

    @{ Name = 'Locked out (too many bad passwords)'; Scope = 'User'; Depts = $All; Secondary = $false
       Break = { param($u)
           Add-Type -AssemblyName System.DirectoryServices.AccountManagement
           $ctx = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('Domain', 'bjlab.local')
           1..6 | ForEach-Object { $null = $ctx.ValidateCredentials($u, "Wrong-$(Get-Random)") } }
       Subject = 'Account locked'
       Message = 'I think I typed my password wrong a few times and now it says my account is locked. I have a call in 10 minutes.' },

    @{ Name = 'Logon hours restricted'; Scope = 'User'; Depts = $All; Secondary = $true
       Break = { param($u) Set-ADUser $u -Replace @{ logonHours = [byte[]]::new(21) } }
       Subject = 'Cannot sign in today'
       Message = 'It says something about time restrictions and will not let me sign in. I am supposed to be working today!' },

    @{ Name = 'Workstation restricted'; Scope = 'User'; Depts = $All; Secondary = $true
       Break = { param($u) Set-ADUser $u -LogonWorkstations 'SALES-PC07' }
       Subject = 'Not allowed on my PC?'
       Message = 'It says I am not allowed to sign in to this computer. I have used this PC for months.' },

    @{ Name = 'Removed from SG-Sales'; Scope = 'User'; Depts = @('Sales'); Secondary = $true
       Break = { param($u) Remove-ADGroupMember 'SG-Sales' -Members $u -Confirm:$false }
       Subject = 'S drive is gone'
       Message = 'My S drive disappeared and I need the files on it for a meeting today.' },

    @{ Name = 'Moved to the wrong OU (HR)'; Scope = 'User'; Depts = @('Sales'); Secondary = $true
       Break = { param($u) Move-ADObject (Get-ADUser $u).DistinguishedName -TargetPath $Depts.HR.OU }
       Subject = 'Missing drive'
       Message = 'Where did my shared drive go? It was there yesterday.' },

    @{ Name = 'SG-Sales removed from the Sales share'; Scope = 'Env'; Depts = @('Sales'); Secondary = $false
       Break = { param($u) Revoke-SmbShareAccess -Name $ShareName -AccountName "BJLAB\$($Depts.Sales.Group)" -Force | Out-Null }
       Subject = 'S drive access denied'
       Message = 'I can see the S drive but when I open it, it says I do not have permission. It worked last week.' },

    @{ Name = "'Sales - Drive Map' GPO link disabled"; Scope = 'Env'; Depts = @('Sales'); Secondary = $false
       Break = { param($u) Set-GPLink -Name $SalesGpo -Target $Depts.Sales.OU -LinkEnabled No | Out-Null }
       Subject = 'No S drive'
       Message = 'My S drive is not there anymore. Is the server down?' },

    @{ Name = 'CLIENT01 computer account disabled'; Scope = 'Env'; Depts = $All; Secondary = $false
       Break = { param($u) Get-ADComputer $Computer | Disable-ADAccount }
       Subject = 'Weird error at login'
       Message = 'When I try to sign in it says something about a trust relationship with the domain. I have no idea what that means.' }
)

# ---------- Only pick from healthy users and settings ----------
$HealthyUsers = @($LabUsers.Keys | Where-Object { -not (Get-UserProblems $_) })
$EnvHealthy   = -not (Get-EnvironmentProblems)

if (-not $HealthyUsers) {
    $msg = 'No healthy lab users left. Run .\Reset-Lab.ps1 first.'
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm') | SKIPPED | $msg" | Add-Content $LogFile
    Write-Host $msg
    return
}

if (-not $Issues) { $Issues = if ((Get-Random -Maximum 4) -eq 0) { 2 } else { 1 } }

$Candidates = @($Scenarios | Where-Object {
    $s = $_
    ($s.Scope -eq 'User' -or $EnvHealthy) -and
    ($HealthyUsers | Where-Object { $s.Depts -contains $LabUsers[$_] })
})
$Primary = Get-Random -InputObject $Candidates
$User    = Get-Random -InputObject @($HealthyUsers | Where-Object { $Primary.Depts -contains $LabUsers[$_] })
$Chosen  = @($Primary)

if ($Issues -eq 2) {
    $Extra = @($Scenarios | Where-Object {
        $_.Scope -eq 'User' -and $_.Secondary -and $_.Name -ne $Primary.Name -and $_.Depts -contains $LabUsers[$User]
    })
    if ($Extra) { $Chosen += Get-Random -InputObject $Extra }
}

$Names = ($Chosen | ForEach-Object { $_.Name }) -join ' + '

if ($DryRun) {
    Write-Host "DRY RUN: would apply '$Names' to $User. Nothing changed."
    return
}

# ---------- File the ticket, then break things ----------
$ADUser  = Get-ADUser $User
$Message = "$($Primary.Message)`n`n- $($ADUser.GivenName)"

try {
    $Num = Send-Ticket $ADUser.Name "$User@bjlab.local" $Primary.Subject $Message
    foreach ($s in $Chosen) { & $s.Break $User }
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm') | Ticket $Num | $User | $Names" | Add-Content $LogFile
    Write-Host "Ticket $Num created. Good luck."
}
catch {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm') | ERROR | $($_.Exception.Message)" | Add-Content $LogFile
    Write-Host "Something failed: $($_.Exception.Message)"
}
