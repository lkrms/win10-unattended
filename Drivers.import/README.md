# Drivers.import

Device drivers added to this directory are installed during the `specialize`
configuration pass. There's no need to flatten directory structures, but `.inf`
files and their dependencies must be unpacked.

> [!IMPORTANT]
>
> Boot-critical drivers must be added to the [Drivers] directory. Others may be
> added here.

Here's a possible directory layout for an ASUS laptop and two Brother printers:

```
./brother-HL-L3230CDW
./brother-HL-L3230CDW/amd64
./brother-HL-L3230CDW/i386
./brother-HL-L3230CDW/x86
./brother-HL-5450DN
./asus-E203MA
./asus-E203MA/CardReader
./asus-E203MA/WLAN
./asus-E203MA/WLAN/PIE
./asus-E203MA/Bluetooth
./asus-E203MA/Bluetooth/SFP
./asus-E203MA/Bluetooth/ibtsiva
./asus-E203MA/Bluetooth/WSP
./asus-E203MA/Touchpad
./asus-E203MA/Touchpad/Touchpad
./asus-E203MA/Touchpad/Touchpad/x64
./asus-E203MA/Chipset
./asus-E203MA/Audio
./asus-E203MA/Audio/Realtek
./asus-E203MA/Audio/Realtek/RealtekINTAPO_700
./asus-E203MA/Audio/Realtek/RealtekService_179
./asus-E203MA/Audio/Realtek/RealtekSstPpDll_21
./asus-E203MA/Audio/Realtek/AlexaCfgExt_8734.1
./asus-E203MA/Audio/Realtek/RealtekHSA_183
./asus-E203MA/Audio/Realtek/RealtekASIO_4
./asus-E203MA/Audio/Realtek/ExtRtk_8734.1
./asus-E203MA/Audio/Realtek/Codec_8734.1
./asus-E203MA/Audio/Realtek/RealtekAPO_700
```

[Drivers]: ../Drivers
