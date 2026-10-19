# 04 — Users, OUs, and Groups

**Date:** October 19, 2026

## Situation
The domain had a server and a workstation but no people. Help desk work is mostly about user accounts, so the lab needed a realistic small company to support.

## Task
Build an organized structure of departments, users, and security groups in Active Directory, then test it the way end users and help desk would.

## Actions
1. **Designed the OU structure:**
   - BJLab
     - Staff → IT, Sales, HR
     - Workstations
     - Groups

   Departments get separate OUs so Group Policy can target them individually later.
2. **Created 7 user accounts** in Active Directory Users and Computers (ADUC) across IT, Sales, and HR, using a first-initial + last-name naming convention (e.g. `dlopez`).
3. **Separated my admin access:** a regular account (`bcrid`) for everyday use and a separate admin account (`bcrid-adm`) in Domain Admins, following the practice of not doing daily work with admin rights.
4. **Created Global Security groups** (`SG-IT`, `SG-Sales`, `SG-HR`) and added users by department. Permissions will be granted to groups, not to individual users.
5. **Moved CLIENT01** from the default Computers container into the Workstations OU, because Group Policy can't be linked to the default container.
6. **Tested every account** by logging into CLIENT01 as each user. New accounts were set to "must change password at next logon," so each user set their own password on first login.
7. **Handled a simulated ticket:** "Dana Lopez forgot her password." Reset it from ADUC on DC01 with "must change password at next logon" checked, then confirmed she could log in and set a new password.
8. **Took a snapshot** of DC01 (`users-created`) to save this configuration.

## Decisions I made
- **Naming convention:** first initial + last name. It's short and common in real environments. Name collisions would get a number appended (e.g. `dlopez2`).
- **Admin naming:** `bcrid-adm`, so the account's admin rights are obvious anywhere it appears,

## Result
- 7 users in 3 departments, 3 security groups, and an organized OU structure
- All accounts tested with a real login
- First help desk ticket (password reset) handled start to finish

## What I learned
- OUs are for organizing and applying policy. Groups are for granting permissions.
- "Must change password at next logon" means help desk never knows a user's real password.
- Keeping admin and regular accounts separate limits the damage if an everyday account is compromised.

## Next
Group Policy: password policy, account lockout, mapped drives, and desktop restrictions.
