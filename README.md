# Hackintosh Gigabyte Gaming A16 (i7-13620H + RTX 5050)

**Language:** English | [Tiếng Việt](README.vi.md)

OpenCore EFI for the **Gigabyte Gaming A16 CTH**. Runs **macOS Tahoe 26.7.1** and **Sequoia 15.8.1** with NVIDIA graphics
acceleration (Metal 3) through the [NullMoth](https://github.com/nullmoth/nvidia-macos-driver) driver, native Wi-Fi, Bluetooth,
touchpad, audio, full CPU clocks and working screen brightness.

> ⚠️ **SMBIOS has been removed.** `MLB`, `SystemSerialNumber`, `SystemUUID` and `ROM` in `config.plist` are all zeros.
> Generate your own with [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) (model **MacBookPro16,2**) and fill in
> `PlatformInfo > Generic`, otherwise iMessage/FaceTime/App Store will not work. Never reuse someone else's serial.

## Contents
1. [Hardware and status](#hardware-and-status)
2. [Benchmarks](#benchmarks-geekbench-6)
3. [BIOS and setup](#bios-and-setup)
4. [Kexts, drivers and download sources](#kexts-drivers-and-download-sources)
5. [How each part was fixed](#how-each-part-was-fixed)
6. [Restoring the EFI from the OpenCore menu](#restoring-the-efi-from-the-opencore-menu)
7. [Known limitations](#known-limitations)
8. [Credits](#credits)

## Hardware and status

| Component | Details | Status |
|---|---|---|
| CPU | Intel Core i7-13620H (6P + 4E, 16 threads, Raptor Lake) | ✅ full 4.9 GHz (CPUFriend) |
| Discrete GPU | NVIDIA RTX 5050 Laptop 8GB (10DE:2D98) | ✅ Metal 3 (NullMoth 2.3.7) |
| Integrated GPU | Intel UHD | ❌ disabled (`disable-gpu`) |
| Display | 1920×1200, wired to the NVIDIA GPU | ✅ brightness control (`nvrmacpibl=1`) |
| Wi-Fi | Intel AX211 CNVi (8086:51F1) | ✅ native Wi-Fi, system Wi-Fi toggle |
| Bluetooth | Intel AX211 USB (8087:0033) | ✅ |
| Ethernet | Realtek RTL8168 | ✅ |
| Audio | Realtek ALC245 | ✅ VoodooHDA |
| Touchpad | I2C ELAN0A05 | ✅ with gestures |
| Keyboard | PS/2 | ✅ |
| Battery | 4890 mAh | ✅ percentage shown, ⚠️ drains fast (see limitations) |
| AirDrop / iPhone Mirroring / Sidecar | | ❌ Intel card has no AWDL |

## Benchmarks (Geekbench 6)

| | Sequoia 15.8.1 | Tahoe 26.7.1 |
|---|---|---|
| CPU single-core | 2525 | 2525 |
| CPU multi-core | 11187 | 11247 |
| OpenCL | 25547 | 27091 (driver 2.3.1) |
| Metal | 58198 (driver 1.13) | **68553** (driver 2.3.7) |

Before the CPU fix: 1191 / 6396.

### GPU score by NullMoth driver version (Geekbench 6, same laptop)

| Driver | macOS | Metal | OpenCL | Notes |
|---|---|---|---|---|
| 1.13.0 | Sequoia 15.8.1 | 58198 | 25547 | first working setup |
| 1.15.0 | Tahoe 26.7.1 | ❌ crash | 27062 | MPSGraph pipeline fails |
| 2.0.1 | Tahoe 26.7.1 | 63794 / 65611 | 26275 / 26229 | first official Tahoe support |
| 2.1.0 | Tahoe 26.7.1 | 67288 | 27112 | desktop no longer waits for the GPU every frame |
| 2.3.1 | Tahoe 26.7.1 | 68316 | 27091 | |
| 2.3.7 | Tahoe 26.7.1 | 67312 / 68553 | 26592 (on battery) | security release; ~5 min pipeline build before each Metal run |

Two numbers = two runs. Differences under ~3% are run-to-run noise.

## BIOS and setup

- **Switchable Graphics = Discrete** (required). MSHybrid hangs at the login window.
- Secure Boot off.
- OpenCore **1.0.9 DEBUG**, `SecureBootModel` = Disabled, SIP `csr-active-config` = `430A0000`
  (needed for the OCLP root patch and the NullMoth driver), `DisableIoMapper` = true.
- Booting from the NVMe shared with Windows: if the BIOS only lists "Windows Boot Manager", add an OpenCore entry from
  Windows (Command Prompt as Administrator):
  ```
  bcdedit /copy {bootmgr} /d "OpenCore"
  bcdedit /set {id-printed-above} path \EFI\OC\OpenCore.efi
  bcdedit /set {fwbootmgr} displayorder {id-printed-above} /addfirst
  ```
- Current **boot-args**:
  ```
  debug=0x100 keepsyms=1 -vi2c-force-polling -dbgenhdbg -dbgenhiolog -dbgenhbeta ctrsmt=full
  nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80
  -btlfxallowanyaddr ipc_control_port_options=0 nvrmacpibl=1
  ```
  `-dbgenh*` (DebugEnhancer) and `-btlfxallowanyaddr` are for debugging only and can be removed. Add `-v` if you want to see the boot log (removed here for a clean boot).

## Kexts, drivers and download sources

### Kexts in `EFI/OC/Kexts`

| Kext | Version | Purpose | Download |
|---|---|---|---|
| Lilu | 1.7.3 | base for other kexts | [acidanthera/Lilu](https://github.com/acidanthera/Lilu/releases) |
| VirtualSMC + SMCBatteryManager, SMCProcessor, SMCSuperIO, SMCLightSensor | 1.3.9 | SMC emulation, battery, sensors | [acidanthera/VirtualSMC](https://github.com/acidanthera/VirtualSMC/releases) |
| WhateverGreen | 1.7.2 | disables iGPU, graphics fixes | [acidanthera/WhateverGreen](https://github.com/acidanthera/WhateverGreen/releases) |
| RestrictEvents | 1.1.7 | CPU name, event fixes | [acidanthera/RestrictEvents](https://github.com/acidanthera/RestrictEvents/releases) |
| NVMeFix | 1.1.4 | NVMe power management | [acidanthera/NVMeFix](https://github.com/acidanthera/NVMeFix/releases) |
| BrightnessKeys | | brightness keys | [acidanthera/BrightnessKeys](https://github.com/acidanthera/BrightnessKeys/releases) |
| CPUFriend | 1.3.0 | injects the CPU power profile | [acidanthera/CPUFriend](https://github.com/acidanthera/CPUFriend/releases) |
| CPUFriendDataProvider | v3 (custom) | power profile made for the i7-13620H | custom, see [CPU fix](#cpu-breaking-the-38-ghz-cap) |
| CpuTopologyRebuild | 2.0.2 | P/E core topology for hybrid CPUs | [b00t0x/CpuTopologyRebuild](https://github.com/b00t0x/CpuTopologyRebuild/releases) |
| VoodooPS2Controller | 2.3.8 | keyboard | [acidanthera/VoodooPS2](https://github.com/acidanthera/VoodooPS2/releases) |
| VoodooI2C + VoodooI2CHID | 2.9.1 | I2C touchpad | [VoodooI2C/VoodooI2C](https://github.com/VoodooI2C/VoodooI2C/releases) (modified, see below) |
| VoodooGPIO (plugin inside VoodooI2C) | master | TigerLakeLP GPIO (INTC1055) | built from [VoodooI2C/VoodooGPIO](https://github.com/VoodooI2C/VoodooGPIO) master |
| AirportItlwm | 2.3.0 (**Ventura** build) | Apple-style Intel Wi-Fi | [OpenIntelWireless/itlwm](https://github.com/OpenIntelWireless/itlwm/releases/tag/v2.3.0) → `AirportItlwm_v2.3.0_stable_Ventura.kext.zip` |
| IOSkywalkFamily | 1.2.0 | legacy Skywalk for Wi-Fi | [OCLP payloads/Kexts/Wifi](https://github.com/dortania/OpenCore-Legacy-Patcher/tree/main/payloads/Kexts/Wifi) |
| IO80211FamilyLegacy (+ AirPortBrcmNIC) | 1.0.0 | legacy IO80211 for Wi-Fi | [OCLP payloads/Kexts/Wifi](https://github.com/dortania/OpenCore-Legacy-Patcher/tree/main/payloads/Kexts/Wifi) |
| AMFIPass | 1.4.1 | allows root patches with AMFI enabled | [OCLP payloads/Kexts/Acidanthera](https://github.com/dortania/OpenCore-Legacy-Patcher/tree/main/payloads/Kexts/Acidanthera) |
| IntelBluetoothFirmware + IntelBTPatcher | 2.5.1 (fork) | Intel Bluetooth | [lshbluesky/IntelBluetoothFirmware](https://github.com/lshbluesky/IntelBluetoothFirmware/releases/tag/v2.5.1) |
| BlueToolFixup | 2.7.3 | third-party Bluetooth on macOS 12+ | [acidanthera/BrcmPatchRAM](https://github.com/acidanthera/BrcmPatchRAM/releases) |
| RealtekRTL8111 | 2.4.2 | Ethernet | [Mieze/RTL8111_driver_for_OS_X](https://github.com/Mieze/RTL8111_driver_for_OS_X/releases) |
| USBToolBox + UTBDefault | | USB port map | [USBToolBox/kext](https://github.com/USBToolBox/kext/releases) |
| XHCI-unsupported | 0.9.2 | USB controller | [RehabMan/OS-X-USB-Inject-All](https://github.com/RehabMan/OS-X-USB-Inject-All) |
| DebugEnhancer | 1.1.1 | debugging only (DEBUG kext logs) | [acidanthera/DebugEnhancer](https://github.com/acidanthera/DebugEnhancer/releases) |
| AppleALC | 1.9.9 | **disabled** (no working ALC245 layout) | [acidanthera/AppleALC](https://github.com/acidanthera/AppleALC/releases) |

### UEFI drivers and tools

| File | Source |
|---|---|
| OpenCore.efi, BOOTx64.efi, OpenRuntime.efi, ResetNvramEntry.efi, OpenShell.efi | [acidanthera/OpenCorePkg 1.0.9](https://github.com/acidanthera/OpenCorePkg/releases) |
| HfsPlus.efi | [acidanthera/OcBinaryData](https://github.com/acidanthera/OcBinaryData) |
| NullMothSafe.efi (NullMothLogo.efi was removed in 2.2.0) | added by the [1401 / NullMoth](https://github.com/nullmoth/1401/releases) app when installing the driver |

### Installed inside macOS (not in the EFI)

| Item | Version | Source |
|---|---|---|
| NVIDIA driver (**1401** app) | 2.3.7 (Tahoe supported since 2.0.0) | [nullmoth/nvidia-macos-driver](https://github.com/nullmoth/nvidia-macos-driver/releases) (app: [nullmoth/1401](https://github.com/nullmoth/1401/releases)) |
| VoodooHDA (audio) | 3.6.8 | [CloverHackyColor/VoodooHDA Release368](https://github.com/CloverHackyColor/VoodooHDA/releases) → install to `/Library/Extensions` |
| OpenCore Legacy Patcher (Wi-Fi root patch) | Sequoia: 2.5.1, Tahoe: **3.0.0-rc.3** | [dortania/OpenCore-Legacy-Patcher](https://github.com/dortania/OpenCore-Legacy-Patcher/releases) |
| Vietnamese input method (optional) | Gõ Nhanh 1.0.165 | [khaphanspace/gonhanh.org](https://github.com/khaphanspace/gonhanh.org/releases) |

## How each part was fixed

### NVIDIA graphics (NullMoth)
1. Install macOS and get it booting first (use `-nvoff` or no driver at that point).
2. Download the **1401** app from [nullmoth/1401](https://github.com/nullmoth/1401/releases), open it and install the driver.
   The app edits the `config.plist` of the OpenCore you booted from: boot-args `nvfb=1 nvaccel=1 nvfbheads=4 ...`,
   blocks `IONDRVSupport`, sets `ResizeGpuBars`, etc.
3. Reboot. Check System Information → Graphics shows "Metal 3".
- **Tahoe**: use 2.0.0 or newer (official Tahoe support + security fixes). 1.13 crashes WindowServer (`CoreDisplay::Assert`). Avoid 1.14.0.
- If boot freezes: pick **"1401: Start once without NVIDIA driver"** in the OpenCore menu, or add `-nvoff`.
- Keep `NullMothLogo.efi` disabled if the machine hangs before the OpenCore picker (1.14.7+ disables it automatically).

### Screen brightness
- Add boot-arg **`nvrmacpibl=1`** (available since NullMoth 1.14.1). After boot macOS sees `AppleBacklightDisplay` and
  brightness works.
- Warning: on some machines this option hangs the boot. Always keep a backup EFI.

### I2C touchpad (ELAN0A05)
1. `DSDT.aml` in this repo replaces the firmware DSDT. **OpenCore does not apply `ACPI > Patch` to replacement tables**, so the
   table was **byte-patched directly**: in `TPAD._CRS`, `If (OSYS < 0x07DC)` → `If (OSYS < 0)` (otherwise `_CRS` returns no
   I2C bus and the touchpad is never attached). After patching, **recompute the table checksum** (byte 9).
2. VoodooI2C 2.9.1: add PCI ID **`0x51e88086`** (Raptor Lake I2C controller) to the "Lake" personality in
   `VoodooI2C.kext/Contents/Info.plist`.
3. VoodooGPIO: build from master (the release lacks `TigerLakeLP` for `INTC1055`) and replace it in `VoodooI2C.kext/Contents/PlugIns`.
4. Boot-arg `-vi2c-force-polling`.
- Debugging: DEBUG builds + DebugEnhancer + `-dbgenhdbg -dbgenhiolog -dbgenhbeta`, then `sudo dmesg | grep -i voodoo`.

### CPU (breaking the 3.8 GHz cap)
- **Cause**: on Intel hybrid CPUs (Alder Lake and newer) one HWP unit on a P-core = **78.741 MHz** (see the "hybrid scaling
  factor" in Linux `intel_pstate`), but macOS XCPM assumes 100 MHz. macOS requests a max of 49, so the hardware only runs
  49 × 78.74 ≈ **3.86 GHz**.
- **Fix**: CPUFriend 1.3.0 + a custom CPUFriendDataProvider (v3):
  - Base: the **MacBookPro16,1** FrequencyVectors (same 45 W class).
  - `Frequencies` → only `{'4900': 0}`, `lpm_ratio` 26 → 24, default EPP 0x80 → 0x40.
  - Added variable **`hwp = "off"`** so XCPM controls clocks through `IA32_PERF_CTL` (real 100 MHz units).
  - FrequencyVectors decoded/encoded following acidanthera/CPUFriend's `FrequencyVectors.bt` template.
- Result: Geekbench 6 CPU 1191/6396 → **2525/11187**. CPU package ~9–11 W at idle, 45–55 W under load (runs hotter).
- ⚠️ The CPUFriendDataProvider in this repo is made for the i7-13620H. Rebuild it for other CPUs
  (see [CPUFriendFriend](https://github.com/corpnewt/CPUFriendFriend)).

### Native Wi-Fi (Intel AX211, system Wi-Fi toggle)
1. Kexts: **AirportItlwm 2.3.0 Ventura build** + IOSkywalkFamily + IO80211FamilyLegacy (+ AirPortBrcmNIC) + AMFIPass,
   `MinKernel` = `24.0.0`. Remove `itlwm.kext` (it conflicts with AirportItlwm).
2. `Kernel > Block`: block the stock `com.apple.iokit.IOSkywalkFamily`.
3. `DeviceProperties`: `PciRoot(0x0)/Pci(0x14,0x3)` → `IOName` = `pci14e4,43a0` (spoofs a Broadcom card so OCLP detects it).
4. `SecureBootModel` = Disabled, SIP `430A0000`, `DisableIoMapper` = true.
5. On **Tahoe** add boot-arg `-amfipassbeta` if AMFIPass does not load, and use **OCLP 3.0.0-rc.3** or newer
   (OCLP 2.5.1 does not support Tahoe). Based on [itlwm issue #1062](https://github.com/OpenIntelWireless/itlwm/issues/1062).
6. Boot macOS, **plug in Ethernet**, open OCLP → **Post-Install Root Patch** → it must list **"Networking: Modern Wireless"** →
   Start Root Patching → reboot.
- **Re-run the root patch after every macOS update.**
- HeliPort is no longer needed.

### Bluetooth (Intel AX211)
1. Use **IntelBluetoothFirmware + IntelBTPatcher 2.5.1 by [lshbluesky](https://github.com/lshbluesky/IntelBluetoothFirmware/releases/tag/v2.5.1)**
   (newer firmware). The original OpenIntelWireless 2.5.0 stops at `LE_Read_BufferSize_V2`.
2. BlueToolFixup 2.7.3.
3. NVRAM (`7C436110-AB2A-4BBB-A880-FE41995C9F82`), set in **both Add and Delete**:
   - `bluetoothExternalDongleFailed` = `00`
   - `bluetoothInternalControllerInfo` = 14 bytes of `00`
   This makes `bluetoothd` accept the card.
4. Tahoe: add `-ibtcompatbeta` if the kexts do not load.

### Audio (Realtek ALC245)
- AppleALC has no working layout for the ALC245 → **AppleALC disabled**.
- Install **VoodooHDA 3.6.8** into `/Library/Extensions` (`sudo cp -R VoodooHDA.kext /Library/Extensions/`,
  `sudo chown -R root:wheel`, then allow it in System Settings → Privacy & Security) and reboot.

## Restoring the EFI from the OpenCore menu

Copy `extras/startup.nsh` to the **root** of the partition holding the EFI, together with:
- the marker file `HACKINTOSH-1GB-TARGET.txt` (lets the script find the right partition; rename it in the script if needed),
- the folders `RESTORE/GOOD/OC` and `RESTORE/GOOD/BOOT` = a known-good copy of the EFI.

Add a `Misc > Tools` entry that runs `OpenShell.efi`, named "KHOI PHUC EFI (Restore backup)". Selecting it makes OpenShell run
`startup.nsh`, which copies `RESTORE\GOOD` over `EFI\OC` and reboots. Useful when a config change leaves the machine unbootable.

## Known limitations

- **Battery drains faster than on Windows**: ~36–45 W at idle. The NVIDIA GPU is always on (Discrete mode), and NullMoth's
  Vulkan library sends `PERF_BOOST` (BOOST_TO_MAX, duration INFINITE). It may be disabled with a `BOOST=0` line in
  `/Library/GPUBundles/nvmtl/nvrm610.conf` (**untested**).
- Charging stops around 83%: probably the Gigabyte Control Center charge limit (stored in the EC); change it from Windows.
- Some MPSGraph depthwise-convolution workloads still hang in the shader translator (Geekbench Metal works since 2.0.0).
- Driver 2.3.7: every Geekbench Metal run spends ~5 minutes building pipelines before scoring (score unchanged, 67–68k).
- Hot-plugging an HDMI monitor: the driver lights the port but macOS never adds the display (2.3.x). Workaround: connect it before booting.
- No GPU utilization, clock or temperature is reported to macOS (Activity Monitor, TMOG, Stats show nothing for the GPU).
- Internal speakers are quieter than on Windows with VoodooHDA; eqMac (volume above 100%) helps.
- OpenGL is broken: Unigine Heaven 4.0 renders corrupted at ~2 fps.
- iOS Simulator flickers while scrolling: fixed by `NVMTL_SCHEDULE_AFTER_SURFACE_WRITES=1` in `/Library/GPUBundles/nvmtl/nvrm610.conf`. Put it between `# --- my settings, kept on update ---` and `# --- end my settings ---` (2.1.0+) or driver updates remove it.
- Rare kernel panic `decmpfs_pagein_compressed: couldn't ubc_upl_map a single page` (seen with ReportCrash, sample, FaceTime). `-nvrmsmallbar` is untested.
- No AirDrop, iPhone Mirroring or Sidecar (Intel card has no AWDL).
- The Intel iGPU cannot be used (the display is wired to the NVIDIA GPU).

## Credits

[Acidanthera](https://github.com/acidanthera) (OpenCore and most kexts), [OpenIntelWireless](https://github.com/OpenIntelWireless)
(AirportItlwm, IntelBluetoothFirmware), [lshbluesky](https://github.com/lshbluesky) (IntelBluetoothFirmware fork),
[VoodooI2C](https://github.com/VoodooI2C), [Dortania](https://github.com/dortania) (OpenCore Legacy Patcher, IOSkywalkFamily,
IO80211FamilyLegacy, AMFIPass), [USBToolBox](https://github.com/USBToolBox), [Mieze](https://github.com/Mieze) (RealtekRTL8111),
[b00t0x](https://github.com/b00t0x) (CpuTopologyRebuild), [RehabMan](https://github.com/RehabMan) (XHCI-unsupported),
[CloverHackyColor](https://github.com/CloverHackyColor) (VoodooHDA), [NullMoth](https://github.com/nullmoth/nvidia-macos-driver) (NVIDIA driver).

Use at your own risk. Always keep a bootable USB backup before replacing your EFI.
