# 03 — Joining a Windows 11 Client to the Domain

**Date:** October 19, 2026

## Situation
A domain needs computers in it. To practice the work help desk does on user machines (logins, policies, troubleshooting), I needed a Windows 11 workstation joined to `bjlab.local`.

## Task
Build a Windows 11 Enterprise VM and join it to the domain run by DC01.

## Actions
1. **Created the VM with `virt-install`:** 4 GB RAM, 2 vCPUs, a 64 GB disk, UEFI firmware, and an emulated TPM 2.0. Windows 11 won't install without UEFI and a TPM.
2. **Installed Windows 11 Enterprise** and created a local admin account during setup.
3. **Pointed the client's DNS at the domain controller (192.168.122.10).** Clients find the domain through DNS. The VM network's default DNS doesn't know `bjlab.local`, so without this change the join would fail. Verified with `nslookup bjlab.local`.
4. **Renamed the computer to `CLIENT01` and joined it to `bjlab.local`** through System Properties (`sysdm.cpl`), using domain admin credentials.
5. **Logged in as a domain user** (`BJLAB\Administrator`).
6. **Verified from the server side:** CLIENT01 appeared in the Computers container in Active Directory Users and Computers on DC01.

## Problems I ran into
- **Missed the "Press any key to boot from CD" prompt.** UEFI shows it for only a few seconds, so the VM went to the firmware menu instead. I used Boot Manager to pick the DVD drive, and when the VM powered off, I started it again from the command line and caught the prompt.
- **CLIENT01 didn't show up in ADUC at first.** The console doesn't refresh on its own. Refreshing the Computers container showed it, with no restart needed.

## Result
- CLIENT01 is a member of `bjlab.local`
- Domain logins work from the client
- The lab now has a domain controller and a workstation, the base for user and Group Policy practice

## What I learned
- DNS is the most common reason a domain join fails. The client has to use the domain controller for DNS.
- Windows 11 needs UEFI and a TPM, and both can be emulated in KVM.
- Check whether a tool shows live data before assuming something failed.

## Next
Create OUs, users, and security groups for a fake company.
