# 05 — Group Policy and Troubleshooting a Mapped Drive

**Date:** October 19, 2026

## Situation
The fake company had users and departments but no policies. Real environments use Group Policy to enforce security settings, give departments access to shared folders, and restrict what users can change.

## Task
Configure an account lockout policy, give the Sales department a mapped S: drive, and block Control Panel for Sales and HR without affecting IT. Then test everything as real users.

## Actions
1. **Account lockout policy:** edited the Default Domain Policy to lock an account for 15 minutes after 5 failed logins. It went in the domain-level policy because account policies apply to the whole domain.
2. **Sales file share:** created `C:\Shares\Sales` on DC01, shared as `Sales`, with SG-Sales set to Change and Domain Admins to Full Control. Permissions are granted to the group, not to individual users.
3. **Drive map GPO** (`Sales - Drive Map`), linked to the Sales OU: maps `\\DC01\Sales` as S: at login.
4. **Control Panel restriction GPO** (`Staff - Restrict Control Panel`), linked to the Sales and HR OUs only. I didn't link it to the parent Staff OU, because that would also lock out IT.
5. **Tested as users:** Dana (Sales) got S: and a blocked Control Panel. Marcus (IT) got neither restriction. Confirmed with `gpresult /r`.
6. **Simulated ticket, "my account is locked":** entered the wrong password for Kevin Tran 5 times to trigger the lockout, confirmed it with `Search-ADAccount -LockedOut`, unlocked him with `Unlock-ADAccount`, and verified he could log in.
7. **Took a snapshot** (`gpo-baseline`) once everything worked.

## Troubleshooting: the S: drive didn't appear
This turned out to be four separate problems. I worked through them one layer at a time.

| Layer | What I checked | What I found | Fix |
|---|---|---|---|
| Policy | `gpresult /r` as Dana | Both GPOs applied, so the policy wasn't the problem | — |
| Group membership | Security groups in `gpresult /r` | SG-Sales was missing | Added Dana and Kevin to SG-Sales, then signed out and back in |
| Share | `Get-SmbShare` on DC01 | The parent folder `C:\Shares` was shared as `Shares`, not `Sales` | Removed it, recreated the share on the right folder with `New-SmbShare`, verified with `Get-SmbShareAccess` |
| Name resolution | `net use` (error 67), `net view` (error 53), `nslookup`, `Resolve-DnsName` | The server was named `DCO1` (letter O) instead of `DC01` (zero), so `DC01` never existed in DNS | Renamed the server with `Rename-Computer`, re-registered DNS (`ipconfig /registerdns`, restarted Netlogon) |

While checking `ipconfig /all`, I also found the default gateway was typed as `182.168.122.1` instead of `192.168.122.1`, and fixed it.

After the fixes, Dana's S: drive mapped automatically at login, and `net use` showed `\\DC01\Sales` with status OK.

## Result
- Account lockout enforced domain-wide and tested
- Sales gets its drive automatically; other departments don't
- Control Panel blocked for Sales and HR, open for IT
- Two help desk tickets handled: locked account and missing mapped drive

## What I learned
- Check each layer separately: policy, group membership, share, and name resolution. One symptom can have several causes.
- Group membership and drive maps only update at login, so sign out and back in after changes.
- Error messages narrow things down. "Access denied" means permissions; "network name cannot be found" means the share or name doesn't exist.
- Typos in names and IPs cause real outages. Verify settings after typing them.
- Take a snapshot before risky changes. I renamed a domain controller without one, and it worked, but it shouldn't have been a gamble.

## Next
Install osTicket and start working simulated help desk tickets.
