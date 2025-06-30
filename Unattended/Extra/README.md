# Extra

Scripts and registry settings in this directory aren't used during deployment
but may be useful afterwards.

- `AddGroupPolicyPackages.cmd`: run as administrator to enable `gpedit.msc` on
  Windows Home.
- `AllowLoginWithoutPassword.reg`: apply, reboot, run `netplwiz` and configure
  automatic logon without third-party tools.
- `DisableChromeDefaultBrowserReminders.reg`: apply to stop Chrome begging to be
  your favourite browser when you only want to spend a little time with it.
- `DisableFastUserSwitching.reg`: apply to prevent multiple users logging on
  simultaneously.
- `DisableRealtimeMonitoring.reg`: apply to disable Microsoft Defender's
  real-time monitoring (if your build of Windows honours the relevant policies).
- `DoNotLock.reg`: apply to prevent screen locking after user inactivity.
  (You'll also need to comment out `DisableAutomaticRestartSignOn` and
  `InactivityTimeoutSecs` in `Unattended.reg`, or their values will be restored
  on every boot.)
- `EnableFastUserSwitching.reg`: apply to allow multiple users to log on
  simultaneously.
- `SetTargetRelease.reg`: edit and apply to prevent--or accelerate--the
  installation of feature updates by Windows Update.
- `UpdateImageOffline.cmd`: pre-apply updates to your install media (if it's
  writable).
