# win10-unattended

> Automatic deployment of Windows 10 or 11 from standard install media. Intended
> for personal, non-enterprise use.

The aim of this project is to make it relatively painless to provision "clean"
Windows Home or Pro machines by using enterprise features like unattended
installation and group policy to minimise the bloat, unnecessary notifications,
unsolicited content, covert data collection, invasive advertising, coercive app
provisioning and other horrors Microsoft enables by default.

It provides a template you can download and customise as much or as little as
you like (although I do recommend replacing my particulars with your own 😉).
Then, copy everything you need to a USB flash drive, connect it to your target
system, and boot into Windows Setup from standard install media. If it works as
intended, you will be asked for an install location for Windows, then no further
questions until provisioning is complete.

> [!TIP]
>
> If you're Git-savvy, I suggest cloning the repository and creating a private
> branch so you can easily rebase your changes onto `main` as needed.

## What it does

Most of the actions taken by `win10-unattended` are optional, and if files are
not provided for an action that requires them, the action is silently skipped.

1.  **Skips all Windows Setup and OOBE (out-of-box experience) prompts** except
    install location selection
2.  **Disables Windows 11 eligibility checks** for secure boot support, TPM 2.0
    and 4 GB RAM
3.  **Installs system drivers** in two passes:
    - `windowsPE` for [boot-critical drivers][Drivers]
    - `auditUser` for [other drivers][Drivers2], including any provided as
      `.msi` packages
4.  **Installs `.cab` and `.msu` update packages** downloaded from [Windows
    Update][Microsoft Update Catalog]
5.  **Silences Cortana's OOBE voice-over** because there is never a good time to
    hear "a little sign-in here, a touch of Wi-Fi there..."
6.  **Sets computer name** _(if enabled by uncommenting `<ComputerName>` in
    [Autounattend.xml])_
7.  **Installs the system's OEM product key** for activation once online
8.  **Adds a Wi-Fi profile** and waits for Internet connectivity
9.  **Installs [Chocolatey]** with the following packages:
    - 7-Zip
    - Firefox
    - Google Chrome
    - Notepad++
    - Sumatra PDF
    - VLC media player
    - O&O ShutUp10++ _(optional)_
    - KeePassXC _(optional)_
10. **Installs standalone `.msi` packages**
11. **Deploys Microsoft Office 365, OneDrive and Teams** via their offline
    installers
12. **Applies policies and registry settings** to improve UX and mitigate the
    worst of Microsoft's built-in privacy and autonomy travesties
13. **Removes bloatware** installed by Microsoft
14. **Reapplies policies, registry settings and bloatware removal on boot** to
    restore order after updates
15. **Deploys TightVNC Server** for remote desktop access _(if enabled by
    uncommenting the relevant `<RunSynchronousCommand>` in [Autounattend.xml])_
16. **Creates local user accounts**, bypassing "Sign in with Microsoft" prompts
17. **Deletes cached answer files** for security

## How to use it

> [!TIP]
>
> Architecture-specific answer files in [Build] can be used as drop-in
> replacements for [Autounattend.xml] and [Audit.xml].

> [!NOTE]
>
> If not deploying Microsoft Office 365, OneDrive or Teams, skip steps that
> mention them and exclude the `Office365` directory from your removable media.

> [!CAUTION]
>
> If deployed, the local `admin` account will not appear in the user list during
> sign-in, but it will be available for authentication in other contexts and
> **has no password by default**. Please set a strong default password for this
> account or remove it from your `Audit.xml` file.

1. Clone this repository to your system

2. Personalise answer files [Autounattend.xml] and [Audit.xml]

   - (**_optional_**) Remove components that don't apply to the architecture of
     the target system from both files

     - e.g. for an `amd64` system with a 32-bit UEFI, remove:
       - all `processorArchitecture="arm64"` components
       - `processorArchitecture="amd64"` components in the `windowsPE` pass
       - `processorArchitecture="x86"` components NOT in the `windowsPE` pass
     - Unnecessary if install media is architecture-specific
     - **Changes to settings should be identical for every architecture that
       remains**

   - Check language settings in both files

     - Every `UILanguage` value must correspond to the language of your install
       media

   - Replace my particulars (`Luke Arms`; `LINA Creative`; `lina`) with your own
     in both files

   - Check the product key is correct for your version of Windows in
     [Autounattend.xml]

     - Generic keys for Windows Home and Windows Pro are provided
     - For other versions, search online for "generic Windows RTM key"
     - **Don't use a real product key here**; it will be replaced with an OEM
       key during deployment

   - Check the image description matches your install media and is correct for
     your version of Windows in [Autounattend.xml]

   - Configure local user accounts in [Audit.xml]

     - Use Windows SIM or [EncodeUnattendPassword.sh] to encode passwords if
       required

   > Relevant documentation:
   >
   > - [Windows Unattended Setup Reference]

3. Personalise or remove [Wi-Fi.xml]

   - e.g. to replace `Wi-Fi.xml` on a Windows system connected to Wi-Fi network
     `NoStrings`:

     ```bat
     rem Check profiles
     netsh wlan show profiles
     netsh wlan export profile key=clear name="NoStrings"
     move "Wi-Fi-NoStrings.xml" "\path\to\win10-unattended\Wi-Fi.xml" /Y
     ```

   - If the target system has an Ethernet connection to the Internet,
     `Wi-Fi.xml` can be deleted or excluded from your removable media

4. Personalise or remove files in the [Optional] directory

   - [ConfigurePrinting.ps1][]: add any printer drivers you reference to
     [Drivers2]

   - [InstallOriginalProductKey.ps1]

   - [MapNetworkDrives.cmd]

   - [RemoveBloatware.ps1]

5. Download the latest [OneDriveSetup.exe], [teamsbootstrapper.exe] and
   [MSTeams-x64.msix] files to the [Office365] directory

   - Included because the versions bundled with Windows and Office don't support
     machine-wide installation

6. Download and install the latest [Office Deployment Tool] from Microsoft's
   website to the [Office365] directory

   - The file [Office365/setup.exe] must exist after this step

7. Edit or replace the Office 365 configuration file at
   [Office365/Configuration.xml]

   - Use the [Office 365 Client Configuration Service] to generate a new
     `Configuration.xml` file if necessary

   - See [Office Deployment Tool configuration options] if needed

8. Run [download.cmd] to download Office 365 install files to the location
   specified in [Office365/Configuration.xml]

   - Install files are downloaded to a subdirectory of [Office365] by default,
     otherwise a network share with read-only guest access is required

   - The user running [download.cmd] must have write access to the install files

9. Add system drivers to [Drivers] and [Drivers2]

   - Boot-critical drivers must be added to [Drivers], otherwise drivers should
     generally be added to [Drivers2]

   - `.inf` files must be unpacked for recursive discovery

   - `.msi` packages in [Drivers2] are silently installed after drivers in the
     same directory

10. Add standalone `.msi` packages to the [MSI] directory for silent
    installation after Chocolatey packages

11. Download updates from the [Microsoft Update Catalog] to the [Updates]
    directory for your install media

    - Cumulative updates without "Dynamic" or "Preview" in the title are
      preferred where possible
    - Directories with at least one `.cab` or `.msu` file are passed to
      `DISM /Add-Package`, one directory per run

12. Add troubleshooting tools to the [Tools] directory

13. Copy the following files and directories to the root of a USB flash drive
    and connect it to the target system when booting into Windows Setup
    (alternatively, if installing Windows from a USB drive with sufficient
    capacity, you can copy everything to the root of the same drive rather than
    using two drives):

    - [Audit.xml]
    - [Autounattend.xml]
    - [Wi-Fi.xml] - _optional for targets connected via Ethernet_
    - [Unattended] - _contents required except:_
      - [Optional] - _may be excluded if no files remain after personalisation_
      - [install.ps1] - _may be downloaded to speed up Chocolatey installation_
    - [Drivers] - _optional_
    - [Drivers2] - _optional_
    - [MSI] - _optional_
    - [Office365] - _optional_
    - [Tools] - _optional_
    - [Updates] - _optional_

14. Choose an install partition, then leave the USB flash drive connected until
    the logon screen appears

## FAQ

### Can I use this to deploy Windows to `arm64` and `x86` devices?

Yes, you can. The only difference between settings applied to `amd64`, `arm64`
and `x86` builds by [Autounattend.xml] and [Audit.xml] is that [Compact OS] is
enabled on 32-bit systems because they tend to have limited storage.

### Are two answer files really necessary?

Inelegant as they may be, [Autounattend.xml] and [Audit.xml] are both needed for
Windows OOBE (out-of-box experience) prompts to be skipped.

This is because `oobeSystem` settings in [Autounattend.xml] are applied before
audit mode starts, leaving no pending settings to apply when it concludes and
the OOBE starts for the second time. Copying [Audit.xml] to the system just
before this happens makes it the answer file for the second `oobeSystem` pass
and allows Windows Setup to continue without user interaction.

One answer file would be sufficient if the `specialize` pass were used to
install software instead of audit mode, but some apps - including Microsoft
Office 365 and OneDrive - fail to install without the Network List Service
(`netprofm`), which cannot be started in `specialize`. Deploying these apps on
first boot fails intermittently, and using `<FirstLogonCommands>` for
long-running tasks is discouraged, so unless the problematic installers improve,
two answer files will continue to be necessary.

> Relevant documentation:
>
> - [Reseal]
> - [Implicit Answer File Search Order]
> - [Use Unattend to run scripts]

### Why are system drivers installed in two passes?

There are two reasons for this:

1. Because some drivers (e.g. for storage controllers and input devices) need to
   be installed before Windows Setup can start, and others (usually graphics
   card drivers) need to be installed later or they will crash Windows PE.

2. Because providing multiple drivers for one device via `<DriverPaths>` in
   `windowsPE` or `offlineServicing` triggers the error below, but the same
   drivers can be installed by running `pnputil /add-driver` from a command in
   `auditUser` or `specialize`.

   ```
   Windows installation encountered an unexpected error. Error code: 0x80070103 - 0x40031.
   ```

## Links

- You may find [@cschneegans]' [online autounattend.xml generator] easier to
  work with than this project. I won't take it personally 😉

[@cschneegans]: https://github.com/cschneegans
[Audit.xml]: Audit.xml
[Autounattend.xml]: Autounattend.xml
[Build]: Build/
[Chocolatey]: https://community.chocolatey.org/
[Compact OS]:
  https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/compact-os?view=windows-10
[ConfigurePrinting.ps1]: Unattended/Optional/ConfigurePrinting.ps1
[download.cmd]: Office365/download.cmd
[Drivers]: Drivers/
[Drivers2]: Drivers2/
[EncodeUnattendPassword.sh]: Scripts/EncodeUnattendPassword.sh
[Implicit Answer File Search Order]:
  https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-automation-overview?view=windows-11#implicit-answer-file-search-order
[install.ps1]: https://community.chocolatey.org/install.ps1
[InstallOriginalProductKey.ps1]:
  Unattended/Optional/InstallOriginalProductKey.ps1
[MapNetworkDrives.cmd]: Unattended/Optional/MapNetworkDrives.cmd
[Microsoft Update Catalog]: https://catalog.update.microsoft.com/
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
[RemoveBloatware.ps1]: Unattended/Optional/RemoveBloatware.ps1
[Reseal]:
  https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-deployment-reseal
[teamsbootstrapper.exe]:
  https://go.microsoft.com/fwlink/?linkid=2243204&clcid=0x409
[Tools]: Tools/
[Unattended.cmd]: Unattended/Unattended.cmd
[Unattended]: Unattended/
[UnattendedFirstBoot.cmd]: Unattended/UnattendedFirstBoot.cmd
[Updates]: Updates/
[Use Unattend to run scripts]:
  https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/add-a-custom-script-to-windows-setup?view=windows-11#use-unattend-to-run-scripts
[Wi-Fi.xml]: Wi-Fi.xml
[Windows Unattended Setup Reference]:
  https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/
