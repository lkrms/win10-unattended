# Drivers

[Out-of-box device drivers][DriverPaths] added to this directory are installed
during the `windowsPE` configuration pass. There's no need to flatten directory
structures, but `.inf` files and their dependencies must be unpacked.

> [!TIP]
>
> Only add boot-critical drivers to this directory. Others can be added to
> [Drivers.import], where non-unique entries don't trigger "Windows installation
> encountered an unexpected error. Error code: 0x80070103 - 0x40031".

[DriverPaths]:
  https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-pnpcustomizationswinpe-driverpaths
[Drivers.import]: ../Drivers.import
