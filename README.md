# win10-unattended

Automatic deployment of Windows 10 or 11 from standard install media. For
non-enterprise use.

## What it does

See [Unattended.cmd] and [UnattendedFirstBoot.cmd].

## How to use it

> [!CAUTION]
>
> If deployed, the local `admin` account will not appear in the user list during
> sign-in, but it will be available for authentication in other contexts and
> **has no password by default**. Setting a strong default password for this
> account is highly recommended, otherwise it should be removed from your
> `Autounattend.xml` file.

> [!NOTE]
>
> If not installing Office 365, OneDrive or Teams, skip steps that mention them
> and exclude the `Office365` folder from your removable media.

1. Clone this repo to your system

1. Personalise [Autounattend.xml] and [Audit.xml]

   - Check language settings

     - `UILanguage` values must correspond to your install media

   - Check the product key is correct for your version of Windows

     - Generic keys for Windows Home and Windows Pro are provided
     - For other versions, search online for "generic Windows RTM key"
     - **Don't use a real product key here**; generic keys are replaced with OEM
       keys [during deployment][InstallOriginalProductKey.ps1]

   - Check the image description matches your install media and is correct for
     your version of Windows

   - Configure local user accounts

     - Use Windows SIM or the [password encoder][] below to apply non-empty
       passwords if required

   - See [Windows Unattended Setup Reference] if needed

1. Personalise or remove [Wi-Fi.xml]

   - For example, to replace `Wi-Fi.xml` on a Windows system where your Wi-Fi
     network is already connected:

     ```bat
     :: List configured Wi-Fi profiles
     netsh wlan show profiles

     :: Export the relevant profile without passphrase encryption
     netsh wlan export profile key=clear name="MySSID"

     :: Rename the generated XML file to Wi-Fi.xml
     move "Wi-Fi-MySSID.xml" "Wi-Fi.xml" /Y
     ```

1. Personalise or remove files in the [Optional] folder

   - [ConfigurePrinting.ps1][]: add any printer drivers you reference to
     [Drivers.import]

   - [MapNetworkDrives.cmd]

   - [RemoveBloatware.ps1]

1. Download the latest [OneDriveSetup.exe], [teamsbootstrapper.exe] and
   [MSTeams-x64.msix] files to the [Office365] folder

   - Included because the versions bundled with Windows and Office don't support
     machine-wide installation

1. Download and install the latest [Office Deployment Tool] from Microsoft's
   website to the [Office365] folder

   - The file [Office365/setup.exe] must exist after this step

1. Edit or replace the Office 365 configuration file at
   [Office365/Configuration.xml]

   - Use the [Office 365 Client Configuration Service] to generate a new
     `Configuration.xml` file if necessary

   - See [Office Deployment Tool configuration options] if needed

1. Run [download.cmd] to download Office 365 install files to the location
   specified in [Office365/Configuration.xml]

   - Install files are downloaded to a subdirectory of [Office365] by default,
     otherwise a network share with read-only guest access is required

   - The user running [download.cmd] must have write access to the install files

1. Add system drivers to [Drivers] and [Drivers.import]

   - Boot-critical drivers must be added to [Drivers], otherwise drivers should
     generally be added to [Drivers.import]

   - `.inf` files must be unpacked for recursive discovery

   - `.msi` packages in [Drivers.import] are silently installed after drivers in
     the same directory

1. Add standalone `.msi` packages to the [MSI] directory for silent installation
   after Chocolatey packages

1. Add troubleshooting tools to the [Tools] directory

1. Copy the following files and directories to the root of a USB flash drive and
   connect it to the target system when booting into Windows Setup
   (alternatively, if installing Windows from a USB drive with sufficient
   capacity, you can copy everything to the root of the same drive rather than
   using two flash drives):

   - [Audit.xml]
   - [Autounattend.xml]
   - [Wi-Fi.xml] - _optional for targets connected via Ethernet_
   - [Unattended] - _contents required except:_
     - [Optional] - _may be excluded if no files remain after personalisation_
     - [install.ps1] - _may be downloaded to speed up Chocolatey installation_
   - [Drivers] - _optional_
   - [Drivers.import] - _optional_
   - [MSI] - _optional_
   - [Office365] - _optional_
   - [Tools] - _optional_

1. Choose an install partition, then leave the USB flash drive connected until
   the login screen appears

### How to encode a local account password for `Autounattend.xml`

In Bash:

```bash
(
    while :; do
        read -rsp "Password: " PW && echo &&
            read -rsp "Password (again): " PW2 && echo || exit
        [[ $PW != "$PW2" ]] || break
        echo "Passwords did not match"
    done
    PW=$(printf '%sPassword' "$PW" | perl -pe 's/(.)/\1\0/g' | base64) &&
        cat <<XML

<Password>
   <Value>$PW</Value>
   <PlainText>false</PlainText>
</Password>
XML
)
```

## Links

- You may find [@cschneegans]' [online autounattend.xml generator] easier to
  work with than this project. I won't take it personally 😉

[@cschneegans]: https://github.com/cschneegans
[Audit.xml]: Audit.xml
[Autounattend.xml]: Autounattend.xml
[ConfigurePrinting.ps1]: Unattended/Optional/ConfigurePrinting.ps1
[download.cmd]: Office365/download.cmd
[Drivers]: Drivers/
[Drivers.import]: Drivers.import/
[install.ps1]: https://community.chocolatey.org/install.ps1
[InstallOriginalProductKey.ps1]:
  Unattended/Optional/InstallOriginalProductKey.ps1
[MapNetworkDrives.cmd]: Unattended/Optional/MapNetworkDrives.cmd
[MSI]: MSI/
[MSTeams-x64.msix]: https://go.microsoft.com/fwlink/?linkid=2196106
[Office 365 Client Configuration Service]: https://config.office.com/
[Office Deployment Tool configuration options]:
  https://learn.microsoft.com/en-us/microsoft-365-apps/deploy/office-deployment-tool-configuration-options
[Office Deployment Tool]:
  https://www.microsoft.com/en-au/download/details.aspx?id=49117
[Office365]: Office365/
[Office365/Configuration.xml]: Office365/Configuration.xml
[Office365/setup.exe]: Office365/setup.exe
[OneDriveSetup.exe]: https://go.microsoft.com/fwlink/?linkid=844652
[online autounattend.xml generator]:
  https://schneegans.de/windows/unattend-generator/
[Optional]: Unattended/Optional/
[password encoder]: #how-to-encode-a-local-account-password-for-autounattendxml
[RemoveBloatware.ps1]: Unattended/Optional/RemoveBloatware.ps1
[teamsbootstrapper.exe]:
  https://go.microsoft.com/fwlink/?linkid=2243204&clcid=0x409
[Tools]: Tools/
[Unattended.cmd]: Unattended/Unattended.cmd
[Unattended]: Unattended/
[UnattendedFirstBoot.cmd]: Unattended/UnattendedFirstBoot.cmd
[Wi-Fi.xml]: Wi-Fi.xml
[Windows Unattended Setup Reference]:
  https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/
