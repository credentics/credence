<INSTRUCTIONS>
# Pass Docs Manager Agent Safety

## iPhone Release Safety

- Never use `flutter install`, `xcrun devicectl device install app`, or any alternate iOS install path for this project.
- Only run the project-approved release command when explicitly requested: `make release`.
- If `make release` builds but fails during install or launch, stop and report the failure. Do not retry with an install-only workaround.
- Reason: install-only fallback can uninstall the existing iOS app first, which can remove the local app container and wipe local vault data.
- Before any sync/release recovery work, preserve cloud data: do not trigger backup/upload/synchronize from a fresh or empty local install unless the user explicitly confirms after being warned.
</INSTRUCTIONS>
