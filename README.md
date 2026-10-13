EndpointOps — Windows Endpoint Health & Automation Toolkit
Overview
EndpointOps is a PowerShell-based Windows infrastructure automation project designed to collect endpoint inventory, identify disk-capacity risks, audit selected Windows services, and produce timestamped operational reports.

Engineering objectives
Automate endpoint inventory using Windows CIM.
Identify low-disk-space conditions using configurable thresholds.
Audit selected Windows service states.
Generate CSV reports for operational review.
Maintain timestamped execution logs.
Provide an explicitly enabled, limited service-remediation workflow.
Technologies
Windows 10/11
PowerShell
Windows CIM / WMI
CSV reporting
Windows service management
Validation
Document the Windows version, test date, generated reports, service audit results, and any remediation tests actually completed.

Limitations
This version runs against the local Windows endpoint. Enterprise-wide remote inventory, Microsoft Graph integration, Intune policy deployment, and multi-device orchestration are planned enhancements, not implemented features.

Future enhancements
Microsoft Graph API integration
Intune-managed device reporting
Remote endpoint inventory
Scheduled execution
Centralized reporting and alerting
