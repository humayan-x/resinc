# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Privacy & Security Guarantees

- **Zero Network Permissions:** ReSinc does not request `android.permission.INTERNET` in its manifest. By platform design, it is incapable of communicating with remote servers or leaking image data.
- **On-Device Only Processing:** All image downscaling, compression passes, EXIF metadata stripping, and file caching occur exclusively in native local memory and the application's private sandbox storage.
- **Automatic EXIF & GPS Scrubbing:** High-risk metadata (precise geographic latitude/longitude, altitude, camera serial numbers, user comments) is systematically purged on export.

## Reporting a Vulnerability

If you discover a potential security issue or vulnerability in ReSinc:

1. Please **do not** open a public GitHub issue.
2. Report the vulnerability privately via GitHub's [Security Advisories](https://github.com/humayan-x/resinc/security/advisories) feature.
3. You will receive an acknowledgment within 48 hours, followed by a remediation timeline.
