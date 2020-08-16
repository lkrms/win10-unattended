# win10-unattended
Automatic deployment of Windows 10 from standard installation media

## What it does

See [`Unattended.cmd`](./Unattended/Unattended.cmd) and
[`UnattendedFirstBoot.cmd`](./Unattended/UnattendedFirstBoot.cmd) for details.

## How to use it

Skip Office-related steps and exclude the [`Office365`](./Office365/) folder
from your removable media if not installing Microsoft Office 365 or OneDrive.

1. Clone this repo to your system

1. Copy [`Autounattend-home.xml`](./Autounattend-home.xml) or
   [`Autounattend-pro.xml`](./Autounattend-pro.xml) (whichever corresponds to
   your Windows 10 license) to [`Autounattend.xml`](./Autounattend.xml)

1. Customise [`Autounattend.xml`](./Autounattend.xml) as needed
   (`<LocalAccounts>` at minimum)

1. Replace or remove [`Wi-Fi.xml`](./Wi-Fi.xml), e.g. on a system with your
   Wi-Fi network already configured:

    ```bat
    rem List configured Wi-Fi profiles
    netsh wlan show profiles

    rem Export the relevant profile **without passphrase encryption**
    netsh wlan export profile key=clear name="MySSID"

    rem Rename the generated XML file to Wi-Fi.xml
    move "Wi-Fi-MySSID.xml" "Wi-Fi.xml" /Y
    ```

1. Personalise (or remove) files in the [`Unattended`](./Unattended/) folder:

   - [`AddPrinters.ps1`](./Unattended/AddPrinters.ps1): add any printer drivers
     you reference to the [`Drivers`](./Drivers/) folder

   - [`MapNetworkDrives.cmd`](./Unattended/MapNetworkDrives.cmd)

   - [`RemoveProvisionedPackages.ps1`](./Unattended/RemoveProvisionedPackages.ps1):
     use [this
     document](https://docs.microsoft.com/en-us/windows/application-management/apps-in-windows-10)
     as a reference if needed

1. Download the latest
   [OneDriveSetup.exe](https://go.microsoft.com/fwlink/?linkid=844652) to the
   [`Office365`](./Office365/) folder

   - The version of OneDrive packaged with Windows doesn't support machine-wide
     (`/allusers`) installation

1. Download and install the latest [Office Deployment
   Tool](https://www.microsoft.com/en-au/download/details.aspx?id=49117) from
   Microsoft's website to the [`Office365`](./Office365/) folder

   - The file [`Office365/setup.exe`](./Office365/setup.exe) must exist after
     this step

1. Edit or replace the Office 365 configuration file at
   [`Office365/Configuration.xml`](./Office365/Configuration.xml)

   - Generating a new `Configuration.xml` file using Microsoft's [Office 365
     Client Configuration Service](https://config.office.com/) is recommended

1. Run [`download.cmd`](./Office365/download.cmd) to download Office 365 install
   files to the `SourcePath` location specified in
   [`Office365/Configuration.xml`](./Office365/Configuration.xml)

1. Add system drivers to the [`Drivers`](./Drivers/) folder

1. Copy the following files and directories to the root of a USB flash drive and
   connect it to the target system when booting into Windows 10 Setup
   (alternatively, if installing Windows from a USB drive with sufficient
   capacity, you can copy everything to the root of the same drive rather than
   using two flash drives):

   - [`Autounattend.xml`](./Autounattend.xml)
   - [`Wi-Fi.xml`](./Wi-Fi.xml) *(optional)*
   - [`Unattended`](./Unattended/) *(all contents optional except
     [`Unattended.cmd`](./Unattended/Unattended.cmd) and
     [`UnattendedFirstBoot.cmd`](./Unattended/UnattendedFirstBoot.cmd))*
   - [`Drivers`](./Drivers/) *(optional)*
   - [`Office365`](./Office365/) *(optional)*
   - [`Office365\OneDriveSetup.exe`](./Office365/OneDriveSetup.exe) *(optional)*

1. Assuming `<UILanguage>` values in your
   [`Autounattend.xml`](./Autounattend.xml) match your install media language,
   the only manual step will be choosing an install partition

   - Leave the USB flash drive connected until the login screen appears

1. Rinse and repeat
