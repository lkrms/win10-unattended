# Drivers2

> [!IMPORTANT]
>
> Boot-critical drivers must be added to the [Drivers] directory. Others should
> generally be added here.

Device drivers added to this directory are installed during the `auditUser`
configuration pass. There's no need to flatten directory structures, but `.inf`
files and their dependencies must be unpacked.

If any `.msi` packages are found at the top of this directory, they are
installed after drivers.

[Drivers]: ../Drivers
