# 01 — Server Audit and Cleanup

**Date:** October 18, 2026

## Situation
My home server had collected scheduled jobs and leftover files from old automation projects (web scrapers, alert bots, content scripts). Some jobs were still running every 30 minutes, using resources and old API credentials, even though the projects were done.

## Task
Remove everything from those projects without breaking the OS or the game servers that still need to run.

## Actions
1. **Inventory first, no changes.** Ran a read-only audit covering user and root crontabs, `/etc/cron.d`, systemd timers and services, user services, running processes, and the home directory. Saved the output to a file for review.
2. **Sorted everything into keep or remove.**
   - Keep: standard Ubuntu timers and services, SSH, and the AMP game server services (`ampinstmgr`, `amptasks`, `ampfirewall`).
   - Remove: 7 user cron jobs and 11 project folders.
3. **Removed it.** Cleared the user crontab, deleted the project folders by exact name (no wildcards, to avoid deleting the wrong thing), and removed leftover browser automation files.
4. **Checked for leftover secrets.** Searched `.bashrc` for API keys and tokens.
5. **Verified.** Confirmed the crontab was empty and the AMP service and game server were still running.

## Result
- Server now runs only the OS and the game servers
- No more scheduled jobs from old projects
- Server is ready to host VMs for the Active Directory lab

## Still to do
- [ ] Revoke old credentials at the source (API keys, Discord webhooks, app passwords)
- [ ] Remove Webmin, an unused admin panel that adds attack surface; Cockpit replaces it

## What I learned
- Always inventory before deleting. Scheduled jobs can live in several places: cron, systemd timers, and services.
- Deleting a script doesn't deactivate the credentials it used. They have to be revoked where they were issued.
