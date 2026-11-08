# 08 — Domain Controller Clock 6 Hours Off

**Date:** November 8, 2026

## Situation
File timestamps on DC01 were hours ahead of real time, and the daily 9 AM ticket generator task was firing at the wrong time. In a domain, every computer takes its time from the domain controller, and Kerberos logins fail when clocks drift more than 5 minutes apart, so a wrong DC clock can eventually break logins for everyone.

## Task
Find out why DC01's clock was wrong and fix it at the source, without breaking the domain.

## Actions
1. **Gathered facts before changing anything:**
   - `Get-Date` showed 10:54 PM when it was 4:55 PM, exactly 6 hours ahead (the gap between Central time and UTC).
   - `tzutil /g` showed `Central Standard Time`, so the time zone was not the problem.
   - `w32tm /query /source` showed `Local CMOS Clock`. DC01 was not syncing with any real time source, and `w32tm /query /status` showed it advertising itself as Stratum 1 (a perfect source) to the domain.
2. **Identified the cause of the 6 hours:** the Ubuntu host runs on UTC, KVM passes that clock to the VM, and Windows read it as local time.
3. **Took a snapshot** (`before-ntp`), then configured DC01 as the domain's reliable time source, syncing from internet NTP servers:
   `w32tm /config /manualpeerlist:"time.windows.com,0x8 0.pool.ntp.org,0x8" /syncfromflags:manual /reliable:yes /update`
4. **The sync failed:** "no time data was available." I tested one layer at a time:

| Layer | Test | Result |
|---|---|---|
| DNS | `Resolve-DnsName time.windows.com` | Worked (likely a cached answer) |
| Network | `Test-NetConnection 8.8.8.8` | Failed |
| NTP | `w32tm /stripchart` | Timed out (`0x800705B4`) |
| Web | `Test-NetConnection www.google.com -Port 443` | Failed |
| Routing | `Get-NetIPConfiguration` | **Default gateway was `182.168.122.1`**, should be `192.168.122.1` |

5. **Fixed the gateway** with `Remove-NetRoute` and `New-NetRoute`, then resynced. DC01's time source changed to the internet time server and the clock matched real time.
6. **Verified the whole chain:** on CLIENT01, `w32tm /query /source` showed `DC01.bjlab.local` and its clock was correct.

## Root cause
The gateway typo was first found on October 19 (write-up 05). I believed it was fixed, but the change never took effect. DC01 had no route to the internet for three weeks without it being noticed, because everything inside the lab still worked.

## Result
- DC01 syncs from internet time servers and serves correct time to the domain
- CLIENT01 syncs from DC01
- DC01 can reach the internet again
- The scheduled ticket task now runs at the real 9 AM
- Write-up 05 corrected

## What I learned
- **Rule out causes one layer at a time.** The time zone looked right and DNS looked guilty. Neither was the problem.
- **Configuration that looks odd can be correct.** A DC using `127.0.0.1` for DNS is normal.
- **Verify a fix took effect, not just that the command ran.** An unverified fix from three weeks earlier was the real cause.
- **Read error messages.** A typo in a parameter name was spelled out exactly in the error.
- **The DC is the top of the domain's time chain** and should sync from an external source.
