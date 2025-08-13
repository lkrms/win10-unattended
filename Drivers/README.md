# Drivers

> [!TIP]
>
> Boot-critical drivers must be added to this directory. Others may be added to
> [Drivers2], where non-unique entries don't trigger "Windows installation
> encountered an unexpected error. Error code: 0x80070103 - 0x40031".

[Out-of-box device drivers][DriverPaths] added to this directory are installed
during the `windowsPE` configuration pass. There's no need to flatten directory
structures, but `.inf` files and their dependencies must be unpacked.

[DriverPaths]:
  https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-pnpcustomizationswinpe-driverpaths
[Drivers2]: ../Drivers2
