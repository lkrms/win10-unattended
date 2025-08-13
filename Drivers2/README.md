# Drivers2

> [!IMPORTANT]
>
> Boot-critical drivers must be added to the [Drivers] directory and should not
> be duplicated here.

Device drivers added to this directory are installed during the `auditUser`
configuration pass. There's no need to flatten directory structures, but `.inf`
files and their dependencies must be unpacked.

After drivers are installed, `.msi` packages and `.cmd` files found at the top
of the directory are installed or called via `CMD /C` respectively.

`.cmd` exit codes are interpreted as follows:

- **0**: installation completed successfully
- **3010**: reboot required to complete installation
- **other**: installation failed

[Drivers]: ../Drivers
