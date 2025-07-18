# Extra

Scripts and registry settings in this directory aren't used during deployment
but may be useful afterwards.

- **`AddGroupPolicyPackages.cmd`**: run as administrator to enable `gpedit.msc`
  on Windows Home.
- **`AllowLogonWithoutPassword.reg`**: apply, reboot, and run `netplwiz` to
  configure automatic logon. Usually combined with `DoNotLock.reg`.
- **`DisableChromeDefaultBrowserReminders.reg`**: apply to stop Chrome asking to
  be your default browser when you only want to use it occasionally.
- **`DisableFastUserSwitching.reg`**: apply to prevent multiple users logging on
  simultaneously.
- **`DisableRealtimeMonitoring.reg`**: apply to disable Microsoft Defender's
  real-time monitoring (if your system honours the relevant policies).
- **`DoNotLock.reg`**: apply to prevent screen locking after user inactivity,
  then add `DoNotLock-HKLM.reg` to `Unattended.reg.d` so changes survive reboot.
- **`EnableFastUserSwitching.reg`**: apply to allow multiple users to log on
  simultaneously.
- **`SetTargetRelease.reg`**: edit and apply to prevent--or accelerate--the
  installation of feature updates by Windows Update.
- **`UpdateImageOffline.cmd`**: pre-apply updates to your install media (if it's
  writable).
