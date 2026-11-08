# 07 — Ticket Generator and Help Desk Practice

**Dates:** October 29 and November 7, 2026

## Situation
Writing my own practice tickets didn't work: I already knew the answer to every problem. To practice real troubleshooting, I needed problems I didn't cause on purpose, reported the way real users report them: vaguely.

## Task
Build a tool that breaks something real in Active Directory, files a matching vague ticket in osTicket as the affected user, and keeps an answer key I only check after closing the ticket. Then use it to practice the full ticket workflow.

## Actions

### Building the generator
1. **Created an osTicket API key** locked to DC01's IP address, so the key only works from that one machine.
2. **Wrote `New-LabTicket.ps1`** (PowerShell) on DC01. It picks a random scenario and a random user, files the ticket through osTicket's REST API, applies the break, and logs the answer to `answers.log`.
3. **Built in safety switches:** `-DryRun` shows what it would do without changing anything, and `-TestApi` files a harmless test ticket. IT and admin accounts are never touched.
4. **Scheduled it** as a Windows scheduled task running daily at 9 AM as SYSTEM, set to run at startup if the time was missed.
5. **Version 2 (Nov 7):** moved shared settings into `LabConfig.ps1`, added `Reset-Lab.ps1` to put every account and setting back to a known-good state, added six new scenarios (lockout, logon hours, workstation restriction, share permission, disabled GPO link, disabled computer account), made it skip users that already have a problem, and added a chance of two problems on one user.

The scripts were written with AI assistance. I tested them in the lab and can explain what each section does. Scripts are in [`/scripts`](../scripts). The API key is stored only on DC01 and is not in this repo.

### Working the tickets (Nov 7)
| User | Reported symptom | Actual cause(s) | Fix |
|---|---|---|---|
| Tom Walsh | "Weird password message" | Must change password at next logon **and** account expired (two generator runs) | Cleared both; closed his duplicate ticket |
| Alex Kim | "S drive is gone" | Removed from SG-Sales **and** account disabled | Re-added to group, re-enabled account |
| Kevin Tran | "Where did my shared drive go?" | Moved to the HR OU **and** must change password flag | Moved back to Sales OU, cleared flag |
| Priya Shah | "Cannot sign in, ASAP" | Account expired | Cleared expiration (confirmation with HR simulated) |

## Problems I ran into
- **The same scenario came up three times in a row.** Instead of assuming a bug, I ran the generator 20 times in `-DryRun` mode and counted the results. All five scenarios appeared (7/5/3/3/2), so it was normal randomness.
- **Problems stacked on the same user.** The missed 9 AM run fired on boot, then a manual run hit the same person. Version 2 only picks users that are currently healthy.

## Result
- A repeatable way to practice: a fresh, realistic ticket every day
- Four tickets worked end to end, three of them with a second hidden problem found by testing before closing

## What I learned
- **Check every field, not just the one the symptom points to.** Three of four tickets had a second problem.
- **Same symptom, different cause.** Alex and Kevin both lost the S: drive: one from group membership, one from the wrong OU.
- **Check the queue for other tickets from the same user** before starting, and work the oldest first.
- **Don't re-enable a disabled or expired account without confirming why** it was changed. It could be a terminated employee.
- **Write for the reader:** technical names in internal notes, plain language in replies. Only record checks I actually did.
- **`pwdLastSet = 0` makes `PasswordExpired` show True** even with no expiration policy. That's the "must change password at next logon" flag, not an expired password.

## Next
Practice the new scenario types, then add a file share for HR.
