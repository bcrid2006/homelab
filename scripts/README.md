     # Lab scripts

     PowerShell scripts that run on DC01. See [write-up 07](../docs/07-ticket-generator.md).

     | Script | What it does |
     |---|---|
     | `LabConfig.ps1` | Shared settings and health checks used by the other two scripts |
     | `New-LabTicket.ps1` | Breaks something real in AD and files a matching ticket in osTicket |
     | `Reset-Lab.ps1` | Reports (`-Check`) or fixes every broken lab user and setting |

     The osTicket API key is stored only on DC01 and is not in this repo.
