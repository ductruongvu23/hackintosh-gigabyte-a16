# Hackintosh Gigabyte Gaming A16 (i7-13620H + RTX 5050)

**Ngôn ngữ:** [English](README.md) | Tiếng Việt


EFI OpenCore cho **Gigabyte Gaming A16 CTH**: chạy **macOS Tahoe 26.7.1** và **Sequoia 15.8.1**, có tăng tốc đồ hoạ NVIDIA
(Metal 3) nhờ driver [NullMoth](https://github.com/nullmoth/nvidia-macos-driver), Wi-Fi gốc, Bluetooth, touchpad, âm thanh,
CPU chạy đủ xung và chỉnh được độ sáng màn hình.

> ⚠️ **SMBIOS đã bị xoá.** `MLB`, `SystemSerialNumber`, `SystemUUID`, `ROM` trong `config.plist` chỉ là số 0.
> Bạn phải tự tạo bộ của mình bằng [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) (model **MacBookPro16,2**) rồi điền vào
> `PlatformInfo > Generic`. Nếu không, iMessage/FaceTime/App Store sẽ không chạy. Không dùng chung serial của người khác.

## Mục lục
1. [Phần cứng và trạng thái](#phần-cứng-và-trạng-thái)
2. [Kết quả đo](#kết-quả-đo-geekbench-6)
3. [BIOS và cài đặt](#bios-và-cài-đặt)
4. [Danh sách kext, driver và nguồn tải](#danh-sách-kext-driver-và-nguồn-tải)
5. [Cách fix từng phần](#cách-fix-từng-phần)
6. [Khôi phục EFI từ menu OpenCore](#khôi-phục-efi-từ-menu-opencore)
7. [Hạn chế đã biết](#hạn-chế-đã-biết)
8. [Ghi công](#ghi-công)

## Phần cứng và trạng thái

| Linh kiện | Chi tiết | Trạng thái |
|---|---|---|
| CPU | Intel Core i7-13620H (6P + 4E, 16 luồng, Raptor Lake) | ✅ đủ xung 4,9 GHz (CPUFriend) |
| GPU rời | NVIDIA RTX 5050 Laptop 8GB (10DE:2D98) | ✅ Metal 3 (NullMoth 2.3.7) |
| GPU tích hợp | Intel UHD | ❌ tắt (`disable-gpu`) |
| Màn hình | 1920×1200, nối GPU NVIDIA | ✅ chỉnh độ sáng (`nvrmacpibl=1`) |
| Wi-Fi | Intel AX211 CNVi (8086:51F1) | ✅ Wi-Fi gốc, nút Wi-Fi hệ thống |
| Bluetooth | Intel AX211 USB (8087:0033) | ✅ |
| LAN | Realtek RTL8168 | ✅ |
| Âm thanh | Realtek ALC245 | ✅ VoodooHDA |
| Touchpad | I2C ELAN0A05 | ✅ có cử chỉ |
| Bàn phím | PS/2 | ✅ |
| Pin | 4890 mAh | ✅ hiển thị %, ⚠️ tụt nhanh (xem Hạn chế) |
| AirDrop / iPhone Mirroring / Sidecar | | ❌ card Intel không có AWDL |

## Kết quả đo (Geekbench 6)

| | Sequoia 15.8.1 | Tahoe 26.7.1 |
|---|---|---|
| CPU đơn nhân | 2525 | 2525 |
| CPU đa nhân | 11187 | 11247 |
| OpenCL | 25547 | 27091 (driver 2.3.1) |
| Metal | 58198 (driver 1.13) | **68553** (driver 2.3.7) |

Trước khi sửa CPU: 1191 / 6396.

### Điểm GPU theo từng bản driver NullMoth (Geekbench 6, cùng một máy)

| Driver | macOS | Metal | OpenCL | Ghi chú |
|---|---|---|---|---|
| 1.13.0 | Sequoia 15.8.1 | 58198 | 25547 | lần đầu chạy được |
| 1.15.0 | Tahoe 26.7.1 | ❌ crash | 27062 | lỗi pipeline MPSGraph |
| 2.0.1 | Tahoe 26.7.1 | 63794 / 65611 | 26275 / 26229 | bản đầu tiên hỗ trợ Tahoe chính thức |
| 2.1.0 | Tahoe 26.7.1 | 67288 | 27112 | desktop không còn chờ GPU ở mỗi khung hình |
| 2.3.1 | Tahoe 26.7.1 | 68316 | 27091 | |
| 2.3.7 | Tahoe 26.7.1 | 67312 / 68553 | 26592 (chạy pin) | bản vá bảo mật; mất khoảng 5 phút dựng pipeline trước mỗi lần chạy Metal |

Hai số là hai lần chạy. Chênh lệch dưới khoảng 3% là dao động giữa các lần chạy.

## BIOS và cài đặt

- **Switchable Graphics = Discrete** (bắt buộc). Để MSHybrid sẽ treo ở màn hình đăng nhập.
- Tắt Secure Boot.
- OpenCore **1.0.9 DEBUG**, `SecureBootModel` = Disabled, SIP `csr-active-config` = `430A0000`
  (cần cho OCLP root patch và driver NullMoth), `DisableIoMapper` = true.
- Boot từ ổ NVMe chung với Windows: nếu BIOS chỉ thấy "Windows Boot Manager", thêm mục OpenCore từ Windows
  (Command Prompt quyền Administrator):
  ```
  bcdedit /copy {bootmgr} /d "OpenCore"
  bcdedit /set {mã-vừa-in-ra} path \EFI\OC\OpenCore.efi
  bcdedit /set {fwbootmgr} displayorder {mã-vừa-in-ra} /addfirst
  ```
- **boot-args** đang dùng:
  ```
  debug=0x100 keepsyms=1 -vi2c-force-polling -dbgenhdbg -dbgenhiolog -dbgenhbeta ctrsmt=full
  nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80
  -btlfxallowanyaddr ipc_control_port_options=0 nvrmacpibl=1
  ```
  `-dbgenh*` (DebugEnhancer) và `-btlfxallowanyaddr` chỉ dùng khi gỡ lỗi, bỏ được. Thêm `-v` nếu muốn xem log khi boot (ở đây đã bỏ cho khởi động gọn).

## Danh sách kext, driver và nguồn tải

### Kext trong `EFI/OC/Kexts`

| Kext | Bản | Để làm gì | Tải ở đâu |
|---|---|---|---|
| Lilu | 1.7.3 | nền cho các kext khác | [acidanthera/Lilu](https://github.com/acidanthera/Lilu/releases) |
| VirtualSMC + SMCBatteryManager, SMCProcessor, SMCSuperIO, SMCLightSensor | 1.3.9 | giả SMC, pin, cảm biến | [acidanthera/VirtualSMC](https://github.com/acidanthera/VirtualSMC/releases) |
| WhateverGreen | 1.7.2 | tắt iGPU, sửa đồ hoạ | [acidanthera/WhateverGreen](https://github.com/acidanthera/WhateverGreen/releases) |
| RestrictEvents | 1.1.7 | đổi tên CPU, sửa sự kiện | [acidanthera/RestrictEvents](https://github.com/acidanthera/RestrictEvents/releases) |
| NVMeFix | 1.1.4 | tiết kiệm điện SSD NVMe | [acidanthera/NVMeFix](https://github.com/acidanthera/NVMeFix/releases) |
| BrightnessKeys | | phím độ sáng | [acidanthera/BrightnessKeys](https://github.com/acidanthera/BrightnessKeys/releases) |
| CPUFriend | 1.3.0 | nạp bảng điện năng CPU | [acidanthera/CPUFriend](https://github.com/acidanthera/CPUFriend/releases) |
| CPUFriendDataProvider | v3 (tự làm) | bảng điện năng riêng cho i7-13620H | tự tạo, xem [Cách fix CPU](#cpu-vượt-trần-38-ghz) |
| CpuTopologyRebuild | 2.0.2 | sắp lại nhân P/E của chip lai | [b00t0x/CpuTopologyRebuild](https://github.com/b00t0x/CpuTopologyRebuild/releases) |
| VoodooPS2Controller | 2.3.8 | bàn phím | [acidanthera/VoodooPS2](https://github.com/acidanthera/VoodooPS2/releases) |
| VoodooI2C + VoodooI2CHID | 2.9.1 | touchpad I2C | [VoodooI2C/VoodooI2C](https://github.com/VoodooI2C/VoodooI2C/releases) (đã sửa, xem bên dưới) |
| VoodooGPIO (plugin trong VoodooI2C) | master | GPIO TigerLakeLP (INTC1055) | build từ [VoodooI2C/VoodooGPIO](https://github.com/VoodooI2C/VoodooGPIO) nhánh master |
| AirportItlwm | 2.3.0 (bản **Ventura**) | Wi-Fi Intel kiểu Apple | [OpenIntelWireless/itlwm](https://github.com/OpenIntelWireless/itlwm/releases/tag/v2.3.0) → `AirportItlwm_v2.3.0_stable_Ventura.kext.zip` |
| IOSkywalkFamily | 1.2.0 | Skywalk cũ cho Wi-Fi | [OCLP payloads/Kexts/Wifi](https://github.com/dortania/OpenCore-Legacy-Patcher/tree/main/payloads/Kexts/Wifi) |
| IO80211FamilyLegacy (+ AirPortBrcmNIC) | 1.0.0 | IO80211 cũ cho Wi-Fi | [OCLP payloads/Kexts/Wifi](https://github.com/dortania/OpenCore-Legacy-Patcher/tree/main/payloads/Kexts/Wifi) |
| AMFIPass | 1.4.1 | cho phép root patch khi bật AMFI | [OCLP payloads/Kexts/Acidanthera](https://github.com/dortania/OpenCore-Legacy-Patcher/tree/main/payloads/Kexts/Acidanthera) |
| IntelBluetoothFirmware + IntelBTPatcher | 2.5.1 (fork) | Bluetooth Intel | [lshbluesky/IntelBluetoothFirmware](https://github.com/lshbluesky/IntelBluetoothFirmware/releases/tag/v2.5.1) |
| BlueToolFixup | 2.7.3 | Bluetooth bên thứ ba trên macOS 12+ | [acidanthera/BrcmPatchRAM](https://github.com/acidanthera/BrcmPatchRAM/releases) |
| RealtekRTL8111 | 2.4.2 | LAN | [Mieze/RTL8111_driver_for_OS_X](https://github.com/Mieze/RTL8111_driver_for_OS_X/releases) |
| USBToolBox + UTBDefault | | map cổng USB | [USBToolBox/kext](https://github.com/USBToolBox/kext/releases) |
| XHCI-unsupported | 0.9.2 | bộ điều khiển USB | [RehabMan/OS-X-USB-Inject-All](https://github.com/RehabMan/OS-X-USB-Inject-All) |
| DebugEnhancer | 1.1.1 | chỉ để gỡ lỗi (log kext DEBUG) | [acidanthera/DebugEnhancer](https://github.com/acidanthera/DebugEnhancer/releases) |
| AppleALC | 1.9.9 | **tắt** (ALC245 không có layout chạy) | [acidanthera/AppleALC](https://github.com/acidanthera/AppleALC/releases) |

### Driver UEFI và công cụ

| File | Nguồn |
|---|---|
| OpenCore.efi, BOOTx64.efi, OpenRuntime.efi, ResetNvramEntry.efi, OpenShell.efi | [acidanthera/OpenCorePkg 1.0.9](https://github.com/acidanthera/OpenCorePkg/releases) |
| HfsPlus.efi | [acidanthera/OcBinaryData](https://github.com/acidanthera/OcBinaryData) |
| NullMothSafe.efi (NullMothLogo.efi đã bị bỏ từ 2.2.0) | app [1401 / NullMoth](https://github.com/nullmoth/1401/releases) tự thêm khi cài driver |

### Cài trong macOS (không nằm trong EFI)

| Thứ | Bản | Nguồn |
|---|---|---|
| Driver NVIDIA (app **1401**) | 2.3.7 (hỗ trợ Tahoe từ 2.0.0) | [nullmoth/nvidia-macos-driver](https://github.com/nullmoth/nvidia-macos-driver/releases) (app [nullmoth/1401](https://github.com/nullmoth/1401/releases)) |
| VoodooHDA (âm thanh) | 3.6.8 | [CloverHackyColor/VoodooHDA Release368](https://github.com/CloverHackyColor/VoodooHDA/releases) → cài vào `/Library/Extensions` |
| OpenCore Legacy Patcher (root patch Wi-Fi) | Sequoia: 2.5.1, Tahoe: **3.0.0-rc.3** | [dortania/OpenCore-Legacy-Patcher](https://github.com/dortania/OpenCore-Legacy-Patcher/releases) |
| Bộ gõ tiếng Việt (tuỳ chọn) | Gõ Nhanh 1.0.165 | [khaphanspace/gonhanh.org](https://github.com/khaphanspace/gonhanh.org/releases) |

## Cách fix từng phần

### Đồ hoạ NVIDIA (NullMoth)
1. Cài macOS và boot được trước (lúc đầu dùng `-nvoff` hoặc chưa cài driver).
2. Tải app **1401** từ [nullmoth/1401](https://github.com/nullmoth/1401/releases), mở và bấm cài driver. App tự sửa
   `config.plist` của OpenCore đang boot: boot-args `nvfb=1 nvaccel=1 nvfbheads=4 ...`, chặn `IONDRVSupport`, `ResizeGpuBars`...
3. Khởi động lại. Kiểm tra: System Information → Graphics hiện "Metal 3".
- **Tahoe**: dùng bản ≥ 2.0.0 (hỗ trợ Tahoe chính thức + vá bảo mật). Bản 1.13 làm WindowServer crash (`CoreDisplay::Assert`). Không dùng 1.14.0.
- Nếu boot đơ: trong menu OpenCore chọn **"1401: Start once without NVIDIA driver"**, hoặc thêm `-nvoff`.
- Không để `NullMothLogo.efi` bật nếu máy treo trước menu OpenCore (từ 1.14.7 tự tắt nó).

### Độ sáng màn hình
- Thêm boot-arg **`nvrmacpibl=1`** (có từ NullMoth 1.14.1). Sau khi boot, macOS thấy `AppleBacklightDisplay` và chỉnh được độ sáng.
- Cảnh báo: trên một số máy, tuỳ chọn này làm treo lúc boot. Luôn có bản EFI dự phòng.

### Touchpad I2C (ELAN0A05)
1. `DSDT.aml` trong repo là bảng DSDT thay thế. **OpenCore không áp `ACPI > Patch` lên bảng thay thế**, nên đã **vá trực tiếp
   từng byte**: trong `TPAD._CRS`, `If (OSYS < 0x07DC)` → `If (OSYS < 0)` (nếu không, `_CRS` không trả về bus I2C và touchpad
   không được nhận). Sau khi vá, **tính lại checksum** của bảng (byte thứ 9).
2. VoodooI2C 2.9.1: thêm PCI ID **`0x51e88086`** (bộ điều khiển I2C của Raptor Lake) vào personality "Lake" trong
   `VoodooI2C.kext/Contents/Info.plist`.
3. VoodooGPIO: build từ nhánh master (bản release chưa có `TigerLakeLP` cho `INTC1055`), thay vào `VoodooI2C.kext/Contents/PlugIns`.
4. Boot-arg `-vi2c-force-polling`.
- Gỡ lỗi: dùng bản DEBUG + DebugEnhancer + `-dbgenhdbg -dbgenhiolog -dbgenhbeta`, rồi `sudo dmesg | grep -i voodoo`.

### CPU (vượt trần 3,8 GHz)
- **Nguyên nhân**: trên chip lai Intel (Alder Lake trở về sau), 1 đơn vị HWP của P-core = **78,741 MHz** (xem "hybrid scaling
  factor" trong Linux `intel_pstate`), nhưng XCPM của macOS coi là 100 MHz. macOS đặt tối đa 49, phần cứng chỉ chạy
  49 × 78,74 ≈ **3,86 GHz**.
- **Cách sửa**: CPUFriend 1.3.0 + CPUFriendDataProvider tự tạo (v3):
  - Gốc: bảng FrequencyVectors của **MacBookPro16,1** (cùng hạng 45 W).
  - `Frequencies` → chỉ `{'4900': 0}`, `lpm_ratio` 26 → 24, EPP mặc định 0x80 → 0x40.
  - Thêm biến **`hwp = "off"`** để XCPM điều khiển xung bằng `IA32_PERF_CTL` (đơn vị 100 MHz thật).
  - Giải mã / ghi FrequencyVectors theo template `FrequencyVectors.bt` của acidanthera/CPUFriend.
- Kết quả: Geekbench 6 CPU 1191/6396 → **2525/11187**. Khi nghỉ gói CPU ~9–11 W, chạy nặng 45–55 W (nóng hơn).
- ⚠️ CPUFriendDataProvider trong repo làm riêng cho i7-13620H. CPU khác nên tạo lại
  (tham khảo [CPUFriendFriend](https://github.com/corpnewt/CPUFriendFriend)).

### Wi-Fi gốc (Intel AX211, nút Wi-Fi hệ thống)
1. Kext: **AirportItlwm 2.3.0 bản Ventura** + IOSkywalkFamily + IO80211FamilyLegacy (+ AirPortBrcmNIC) + AMFIPass,
   `MinKernel` = `24.0.0`. Gỡ `itlwm.kext` (không chạy cùng AirportItlwm).
2. `Kernel > Block`: chặn `com.apple.iokit.IOSkywalkFamily` gốc.
3. `DeviceProperties`: `PciRoot(0x0)/Pci(0x14,0x3)` → `IOName` = `pci14e4,43a0` (giả card Broadcom để OCLP nhận).
4. `SecureBootModel` = Disabled, SIP `430A0000`, `DisableIoMapper` = true.
5. Trên **Tahoe** cần thêm boot-arg `-amfipassbeta` nếu AMFIPass không nạp, và phải dùng **OCLP 3.0.0-rc.3** trở lên
   (OCLP 2.5.1 không hỗ trợ Tahoe). Cách làm theo [itlwm issue #1062](https://github.com/OpenIntelWireless/itlwm/issues/1062).
6. Boot vào macOS, **cắm LAN**, mở OCLP → **Post-Install Root Patch** → phải thấy **"Networking: Modern Wireless"** →
   Start Root Patching → khởi động lại.
- **Mỗi lần cập nhật macOS phải root patch lại.**
- Không còn cần HeliPort.

### Bluetooth (Intel AX211)
1. Dùng **IntelBluetoothFirmware + IntelBTPatcher 2.5.1 của [lshbluesky](https://github.com/lshbluesky/IntelBluetoothFirmware/releases/tag/v2.5.1)**
   (firmware mới hơn). Bản 2.5.0 gốc của OpenIntelWireless dừng ở lệnh `LE_Read_BufferSize_V2`.
2. BlueToolFixup 2.7.3.
3. NVRAM (`7C436110-AB2A-4BBB-A880-FE41995C9F82`), đặt ở **cả Add lẫn Delete**:
   - `bluetoothExternalDongleFailed` = `00`
   - `bluetoothInternalControllerInfo` = 14 byte `00`
   Để `bluetoothd` chấp nhận card.
4. Tahoe: thêm `-ibtcompatbeta` nếu kext không nạp.

### Âm thanh (Realtek ALC245)
- AppleALC không có layout chạy được với ALC245 → **tắt AppleALC**.
- Cài **VoodooHDA 3.6.8** vào `/Library/Extensions` (`sudo cp -R VoodooHDA.kext /Library/Extensions/`,
  `sudo chown -R root:wheel`, rồi cho phép trong System Settings → Privacy & Security), khởi động lại.

## Khôi phục EFI từ menu OpenCore

`extras/startup.nsh` chép vào **gốc** phân vùng chứa EFI, kèm:
- file đánh dấu `HACKINTOSH-1GB-TARGET.txt` (để script tìm đúng phân vùng; đổi tên trong script nếu cần),
- thư mục `RESTORE/GOOD/OC` và `RESTORE/GOOD/BOOT` = bản EFI đang chạy tốt.

Thêm vào `Misc > Tools` một mục chạy `OpenShell.efi` tên "KHOI PHUC EFI (Restore backup)". Chọn mục này, OpenShell chạy
`startup.nsh`, chép `RESTORE\GOOD` đè lên `EFI\OC`, rồi tự khởi động lại. Hữu ích khi một lần sửa config làm máy không boot.

## Hạn chế đã biết

- **Pin tụt nhanh hơn Windows**: khi nghỉ máy tiêu ~36–45 W. GPU NVIDIA luôn bật (chế độ Discrete), và thư viện Vulkan của
  NullMoth gửi `PERF_BOOST` (BOOST_TO_MAX, thời hạn INFINITE). Có thể tắt thử bằng dòng `BOOST=0` trong
  `/Library/GPUBundles/nvmtl/nvrm610.conf` (**chưa kiểm chứng**).
- Sạc dừng ~83%: có thể do giới hạn sạc của Gigabyte Control Center (lưu ở EC), chỉnh trong Windows.
- Một số phép depthwise convolution của MPSGraph vẫn treo trong bộ dịch shader (Geekbench Metal đã chạy từ 2.0.0).
- Driver 2.3.7: mỗi lần chạy Geekbench Metal mất khoảng 5 phút dựng pipeline trước khi chấm (điểm không đổi, 67–68k).
- Cắm nóng màn ngoài HDMI: driver bật cổng nhưng macOS không thêm màn hình (2.3.x). Cách tạm: cắm trước khi khởi động.
- Driver không báo % sử dụng, xung nhịp, nhiệt độ GPU cho macOS (Activity Monitor, TMOG, Stats đều trống phần GPU).
- Loa trong nhỏ hơn Windows khi dùng VoodooHDA; dùng eqMac (tăng âm lượng trên 100%) đỡ hơn.
- OpenGL còn lỗi: Unigine Heaven 4.0 vỡ hình, khoảng 2 fps.
- iOS Simulator nháy khi lướt: sửa bằng `NVMTL_SCHEDULE_AFTER_SURFACE_WRITES=1` trong `/Library/GPUBundles/nvmtl/nvrm610.conf`. Đặt giữa `# --- my settings, kept on update ---` và `# --- end my settings ---` (từ 2.1.0), nếu không bản cập nhật driver sẽ xoá mất.
- Thỉnh thoảng kernel panic `decmpfs_pagein_compressed: couldn't ubc_upl_map a single page` (gặp khi ReportCrash, sample, FaceTime chạy). Chưa thử `-nvrmsmallbar`.
- AirDrop, iPhone Mirroring, Sidecar không chạy (card Intel không có AWDL).
- Không dùng được iGPU Intel (màn hình nối với GPU NVIDIA).

## Ghi công

[Acidanthera](https://github.com/acidanthera) (OpenCore và hầu hết kext), [OpenIntelWireless](https://github.com/OpenIntelWireless)
(AirportItlwm, IntelBluetoothFirmware), [lshbluesky](https://github.com/lshbluesky) (fork IntelBluetoothFirmware),
[VoodooI2C](https://github.com/VoodooI2C), [Dortania](https://github.com/dortania) (OpenCore Legacy Patcher, IOSkywalkFamily,
IO80211FamilyLegacy, AMFIPass), [USBToolBox](https://github.com/USBToolBox), [Mieze](https://github.com/Mieze) (RealtekRTL8111),
[b00t0x](https://github.com/b00t0x) (CpuTopologyRebuild), [RehabMan](https://github.com/RehabMan) (XHCI-unsupported),
[CloverHackyColor](https://github.com/CloverHackyColor) (VoodooHDA), [NullMoth](https://github.com/nullmoth/nvidia-macos-driver) (driver NVIDIA).

Dùng với rủi ro của bạn. Luôn có USB boot dự phòng trước khi thay EFI.
