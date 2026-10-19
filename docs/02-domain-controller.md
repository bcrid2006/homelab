# 02 — Building the Domain Controller

**Date:** October 19, 2026

## Situation
To practice help desk work (user accounts, password resets, Group Policy), my lab needs an Active Directory domain like a small company would have. Active Directory runs on a domain controller.

## Task
Build a Windows Server 2025 VM on my Ubuntu KVM host and promote it to the domain controller for a new domain, `bjlab.local`.

## Actions
1. **Prepared the host.** Moved the Windows ISOs from my home folder to `/var/lib/libvirt/images`, because the VM software couldn't read files in my home directory. Started the default virtual network, a private subnet (192.168.122.0/24) with internet access that stays separate from my home network.
2. **Created the VM with `virt-install`:** 4 GB RAM, 2 vCPUs, and a 60 GB disk. I used SATA disk and e1000e network hardware so the Windows installer would detect them without extra drivers.
3. **Installed Windows Server 2025 Standard (Desktop Experience)** through the Cockpit web console.
4. **Configured the basics with `sconfig`:** set a static IP (192.168.122.10), since computers on the domain need to find the domain controller at an address that never changes, and renamed the server to `DC01`.
5. **Installed Active Directory Domain Services** and promoted the server to a domain controller in a new forest, `bjlab.local`. DNS was installed as part of the promotion.
6. **Took a snapshot** (`fresh-dc`) so I can roll back to a clean domain controller if I break something later.

## Problems I ran into
- **Memory bar showed 4.1 / 4 GiB in red.** I checked what it meant before changing anything. It shows the VM using the RAM it was given (Windows uses all available memory for caching), not the host running out. I kept the setting as is.
- **Cockpit showed "Disconnected."** I checked `uptime` (host had not rebooted) and `virsh list --all` (VM still running), which narrowed it to the Cockpit web session dropping. Restarting the `cockpit` service fixed it, and the VM was never affected.

## Result
- Working domain `bjlab.local`, with DC01 as the domain controller and DNS server
- Logged in as `BJLAB\Administrator` and confirmed the domain in Active Directory Users and Computers
- Restore point saved

## What I learned
- A domain controller needs a static IP, because clients find the domain through it.
- Check before acting. Confirming the host and VM state first showed that only the dashboard had a problem.
- Snapshots before big changes make mistakes cheap to undo.

## Next
Create a Windows 11 client VM and join it to the domain.
