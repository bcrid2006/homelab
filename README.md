# Home Lab — bjhomeserver

Hands-on IT lab on an always-on Ubuntu server, built to practice the work of a help desk / IT support technician: Windows administration, Active Directory, ticket handling, and documentation. Security monitoring comes later as I move toward SOC work.

## Infrastructure

| Component | Details |
|-----------|---------|
| Host OS | Ubuntu Server 24.04 LTS (headless, managed over SSH) |
| Hardware | 16 GB RAM, 1 TB NVMe |
| Hypervisor | KVM/QEMU, managed through Cockpit |
| Other services | Game servers managed with AMP |

## Lab Roadmap

### Phase 1 — Hypervisor setup
- [x] Ubuntu server running 24/7
- [x] Audit and clean up unused services and scheduled jobs → [write-up](docs/01-server-audit-cleanup.md)
- [x] Install KVM + Cockpit for VM management
- [x] Download Windows Server 2025 and Windows 11 Enterprise evaluation ISOs

### Phase 2 — Fake company domain (in progress)
- [x] Windows Server 2025 VM promoted to domain controller (AD DS, DNS)
- [ ] Windows 11 client VM joined to the domain
- [ ] OUs, users, and security groups for a small fake company
- [ ] Group Policy: password policy, mapped drives, desktop restrictions

### Phase 3 — Help desk practice
- [ ] osTicket installed and configured
- [ ] Daily simulated tickets (lockouts, password resets, drive mapping, printers)
- [ ] Resolution write-ups for each ticket type

### Phase 4 — Security monitoring (later)
- [ ] Sysmon on Windows endpoints
- [ ] Wazuh SIEM collecting Windows logs
- [ ] Investigate simulated attacks and write incident reports

## Write-ups

| # | Topic | Skills |
|---|-------|--------|
| 01 | [Server audit and cleanup](docs/01-server-audit-cleanup.md) | Linux, cron, systemd, credential hygiene |
| 02 | [Building the domain controller](docs/02-domain-controller.md) | KVM, Windows Server 2025, AD DS, DNS, static IP |

## Skills Used So Far
`Ubuntu Linux` `SSH` `Bash` `cron` `systemd` `KVM` `Windows Server 2025` `Active Directory` `DNS` `AMP game server management`

## Planned
`Group Policy` `osTicket` `PowerShell` `Sysmon` `Wazuh`

## Certifications
- CompTIA A+ — in progress
- CompTIA Security+ — planned
