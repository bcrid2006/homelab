# 06 — osTicket Install and First Ticket: New Hire Account

**Date:** October 19, 2026

## Situation
The lab had a working domain but no way to track requests. Real help desks log every request in a ticketing system so work is assigned, documented, and closed properly.

## Task
Install osTicket, then handle a realistic request start to finish: a manager asks IT to set up an account for a new hire.

## Actions

### Installing osTicket
1. Installed Apache, MariaDB, and PHP with the extensions osTicket needs on the Ubuntu host.
2. Ran `mysql_secure_installation`, then created a dedicated `osticket` database and database user with access only to that database (least privilege).
3. Downloaded osTicket v1.18.4 from the official GitHub release, deployed it to `/var/www/html/osticket`, and ran the web installer.
4. After install, set the config file to read-only (`chmod 0644`) and deleted the `setup` directory so the installer can't be rerun.

### Working the ticket
1. **Ticket submitted** from CLIENT01 as Dana Lopez (Sales): "New hire Alex Kim starts tomorrow; needs a login and access to the Sales S: drive."
2. **Assigned the ticket to myself** and posted an internal note confirming the request came from Sales and what I planned to do.
3. **Created the account** in ADUC: `akim` in the Sales OU, with a temporary password and "must change password at next logon."
4. **Granted access** by adding him to `SG-Sales`, so he gets the S: drive through the existing Group Policy instead of an individual permission.
5. **Tested before closing:** logged into CLIENT01 as `akim`, set a new password, and confirmed the S: drive mapped.
6. **Replied to Dana and closed the ticket.** The reply confirmed the username and S: access and said the temporary password would be given to Alex in person.

## Problems I ran into
- **The ticket form rejected `dlopez@bjlab.local` as invalid.** osTicket checks that email domains exist on the internet, and `.local` is a private lab domain. I turned off the email address verification setting in the Admin Panel (Settings → Emails), and the ticket went through.

## Result
- osTicket running on the host and reachable from the lab VMs
- First ticket handled end to end: logged, assigned, documented, completed, tested, and closed
- New user `akim` working with the correct access

## What I learned
- **Never put a password in a ticket.** Tickets are stored and seen by many people, so passwords go to the user separately.
- **Test before closing.** Confirming the login and S: drive myself meant the user wouldn't have to report it was broken.
- **Group-based access scales.** Adding Alex to one group gave him everything Sales needs, with no extra setup.
- **Internal notes vs replies:** notes are for staff, replies go to the user.

## Next
Configure osTicket departments and help topics to match the company, then work more ticket types.
