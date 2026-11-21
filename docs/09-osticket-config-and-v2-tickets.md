# 09 — Configuring osTicket Like a Real Help Desk + New Ticket Types

**Dates:** November 8–20, 2026

## Situation
osTicket was running with its default settings: one generic department, no response-time targets, and default categories that didn't match my lab. The ticket generator had also gained six new scenario types (write-up 07) that I hadn't practiced yet.

## Task
Configure osTicket so tickets are routed, prioritized, and timed automatically, like a real help desk, then work the new scenario types end to end.

## Part 1: osTicket configuration

| Setting | What I configured | Why |
|---|---|---|
| Departments | `Help Desk (Tier 1)` and `Systems (Tier 2)`; disabled the unused defaults | In osTicket, departments are IT teams, not company departments. Tier 2 handles escalations |
| SLA plans | `Urgent - 4 hours` (can't log in / locked out) and `Standard - 24 hours` (default) | Priority based on how blocked the user is. A user who can't log in can't do any work |
| Help topics | Can't Log In / Locked Out, Password Reset, Shared Drive / File Access, New User / Account Request, Computer / Domain Error (routes to Tier 2), Other; disabled the defaults | Each topic sets department, priority, and SLA automatically |
| Organizations | Sales, HR, IT, with users assigned | Shows which company department a ticket comes from, so team-wide outages are easier to spot |

**Testing it:** I submitted a ticket from CLIENT01 as an HR user through the web portal, choosing "Can't Log In / Locked Out." Department, priority (High), SLA (4 hours), due date, and organization (HR) were all set automatically. osTicket also logged the source IP of the client.

**Things I learned from testing:**
- **Changing the help topic after a ticket is created does not update the SLA or due date.** osTicket only applies topic settings at creation. Tickets from my generator arrive through the API with no topic, so I triage them by hand: set the topic, SLA, and priority, and use Transfer to escalate. A future improvement is to have the generator send the topic when it creates the ticket.
- **SLAs count business hours.** A 4-hour ticket opened on a Friday night was due Monday at noon, because the clock starts when the business day starts.
- **One default topic routed to a department I had disabled.** A ticket filed under it would have gone to a team that no longer existed. I disabled the topic.

## Part 2: New ticket types worked

| Date | User | Reported symptom | Actual cause(s) | Fix |
|---|---|---|---|---|
| Nov 8 | Kevin Tran | "Account is locked" | Locked out (too many bad passwords) | Unlocked in ADUC |
| Nov 8 | Dana Lopez | "Where did my shared drive go?" | Wrong OU (HR) **and** logon hours set to all zeros (blocked at every hour) | Moved back to Sales OU; set logon hours to permitted in ADUC |
| Nov 8 | Kevin Tran | "S drive is not there. Is the server down?" | `Sales - Drive Map` GPO **link** disabled on the Sales OU; affected all Sales users | Re-enabled the link in Group Policy Management |
| Nov 9 | Dana Lopez | "I can see S: but it says I don't have permission" | SG-Sales removed from the Sales share's permissions; affected all Sales users | Re-added SG-Sales (Change) in Advanced Sharing; verified with `Get-SmbShareAccess` |
| Nov 20 | Priya Shah | "Not allowed to sign in to this computer" | Account restricted to `SALES-PC07`, a PC that doesn't exist, for an HR user | Removed the restriction (Log On To: All computers) |

## Problems I ran into
- **A stale `gpresult`.** On the GPO link ticket, `gpresult /r` first showed the drive map GPO as applied. Its timestamp was from before the issue (and from when DC01's clock was still wrong). After `gpupdate /force` and a fresh login, the GPO was missing, which pointed to the link.
- **A test that didn't test the problem.** On the share permission ticket, I first verified by checking that S: was visible, but the user could already see it. The real test was opening the drive and creating a file.
- **A partial fix.** On the workstation ticket, I first added CLIENT01 to the user's allowed list. She could log on, but the mistaken `SALES-PC07` restriction was still there. I removed the restriction completely and corrected the ticket.

## Result
- osTicket routes, prioritizes, and times tickets automatically for portal tickets, with a documented triage process for API tickets
- Five more tickets worked end to end, covering four of the six new scenario types (logon hours, GPO link, share permission, workstation restriction) plus a lockout

## What I learned
- **A clean account means look at shared settings.** When `Get-ADUser` shows nothing wrong, check the share, the GPO link, and the computer account.
- **Same symptom, different causes.** A missing S: drive came from a wrong OU, a disabled GPO link, and removed group membership on different tickets.
- **"Access denied" and "missing" point to different layers.** Missing drive = drive mapping (GPO or OU). Visible but denied = permissions.
- **Check timestamps on diagnostic output.** A report from before the problem tells you nothing about the problem.
- **The test has to repeat the exact action that failed.**
- **Fix the cause, not just the symptom.** Run `Reset-Lab -Check` before closing, not after.
- **Restrictions can be intentional.** Workstation and logon-hour limits are real security controls, so confirm with the manager before removing one.
- **Use each tool for its job:** ADUC for accounts, Group Policy Management for GPOs and links, the folder's sharing settings for share permissions.

## Next
Practice the last new scenario type (trust relationship), and have the generator send a help topic with each ticket.
