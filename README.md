# Hackintosh Gigabyte Gaming A16 (i7-13620H + RTX 5050)

EFI OpenCore cho **Gigabyte Gaming A16 CTH**: chạy được **macOS Tahoe 26.7.1** và **Sequoia 15.8.1**, có tăng tốc đồ hoạ
NVIDIA nhờ driver [NullMoth](https://github.com/nullmoth/nvidia-macos-driver).

> ⚠️ **Phần SMBIOS đã bị xoá.** `MLB`, `SystemSerialNumber`, `SystemUUID`, `ROM` trong `config.plist` chỉ là số 0.
> Bạn phải tự tạo bộ của mình (GenSMBIOS hoặc OCAT, model **MacBookPro16,2**) trước khi boot, nếu không iMessage/FaceTime/
> App Store sẽ không chạy. Không dùng chung serial của người khác.

## Phần cứng

| Linh kiện | Chi tiết | Trạng thái |
|---|---|---|
| CPU | Intel Core i7-13620H (6P + 4E, 16 luồng, Raptor Lake) | ✅ đủ xung (CPUFriend, xem bên dưới) |
| GPU rời | NVIDIA RTX 5050 Laptop 8GB (10DE:2D98) | ✅ Metal 3 qua NullMoth 1.14.7 |
| GPU tích hợp | Intel UHD | ❌ tắt (`disable-gpu`) |
| Màn hình | 1920×1200 nối với GPU NVIDIA (BIOS: **Discrete**) | ✅ chỉnh được độ sáng (`nvrmacpibl=1`) |
| Wi-Fi | Intel AX211 CNVi (8086:51F1) | ✅ Wi-Fi gốc (nút Wi-Fi hệ thống) qua AirportItlwm + OCLP |
| Bluetooth | Intel AX211 USB (8087:0033) | ✅ |
| LAN | Realtek RTL8168 | ✅ |
| Âm thanh | Realtek ALC245 | ✅ VoodooHDA (cài vào `/Library/Extensions`, không nằm trong EFI) |
| Touchpad | I2C ELAN0A05 | ✅ có cử chỉ |
| Bàn phím | PS/2 | ✅ |
| Pin | | ✅ hiển thị % (xem phần Hạn chế) |
| Sleep | | ⚠️ chưa kiểm tra kỹ |

## Kết quả đo (Geekbench 6)

| | Sequoia 15.8.1 | Tahoe 26.7.1 |
|---|---|---|
| CPU đơn nhân | 2525 | 2525 |
| CPU đa nhân | 11187 | 11247 |
| OpenCL | 25547 | 27062 |
| Metal | 58198 | ❌ Geekbench bị crash (lỗi MPSGraph của driver) |

## Thiết lập chính

- **OpenCore 1.0.9 (DEBUG)**, SMBIOS `MacBookPro16,2`, `SecureBootModel` = Disabled, SIP `csr-active-config` = `430A0000`
  (cần cho OCLP root patch và driver NullMoth).
- **BIOS**: Switchable Graphics = **Discrete** (để MSHybrid sẽ treo ở màn hình đăng nhập).
- **boot-args**: `-v debug=0x100 keepsyms=1 -vi2c-force-polling ... nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth
  amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 nvrmacpibl=1`
  (`-dbgenh*`, `-btlfxallowanyaddr` chỉ để gỡ lỗi, bỏ được).

### Touchpad (ELAN0A05)
- `DSDT.aml` là bảng DSDT thay thế. **OpenCore không áp ACPI Patch lên bảng thay thế**, nên DSDT đã được **vá trực tiếp
  từng byte**: trong `TPAD._CRS`, điều kiện `OSYS < 0x07DC` thành `OSYS < 0` (nếu không `_CRS` không trả về bus I2C);
  checksum đã tính lại.
- VoodooI2C 2.9.1: thêm PCI ID `0x51e88086` vào personality của bộ điều khiển Lake.
- VoodooGPIO **tự build từ nhánh master** (có TigerLakeLP cho `INTC1055`).

### CPU (vượt trần 3,8 GHz)
- Trên chip lai Intel (Alder Lake trở về sau), 1 đơn vị HWP của P-core = **78,741 MHz** (theo Linux `intel_pstate`), còn
  XCPM của macOS coi là 100 MHz. Kết quả: macOS đặt tối đa 49, phần cứng chỉ chạy 49 × 78,74 ≈ 3,86 GHz.
- Cách sửa: **CPUFriend 1.3.0 + CPUFriendDataProvider tự tạo (v3)**. Lấy bảng FrequencyVectors của MacBookPro16,1 (45 W),
  `Frequencies {'4900':0}`, `lpm_ratio` 24, EPP 0x40, và biến **`hwp = "off"`** để XCPM dùng `IA32_PERF_CTL` (đơn vị 100 MHz thật).
- Kết quả: Geekbench 6 CPU 1191/6396 → **2525/11187**. Khi nghỉ ~9–11 W (gói CPU).
- ⚠️ CPUFriendDataProvider này làm riêng cho i7-13620H. CPU khác nên tự tạo lại.

### Wi-Fi gốc (Intel AX211)
- AirportItlwm 2.3.0 (bản Ventura) + IOSkywalkFamily + IO80211FamilyLegacy (+ AirPortBrcmNIC) + AMFIPass 1.4.1.
- Chặn `com.apple.iokit.IOSkywalkFamily` gốc. Giả IOName `pci14e4,43a0` cho `PciRoot(0x0)/Pci(0x14,0x3)`.
- Root patch bằng OpenCore Legacy Patcher: **Post-Install Root Patch → "Networking: Modern Wireless"**
  (Sequoia: OCLP 2.5.1; Tahoe: **OCLP 3.0.0-rc.3**). **Mỗi lần cập nhật macOS phải root patch lại** (cắm LAN trước).
- AirDrop / iPhone Mirroring / Sidecar **không chạy** (card Intel không có AWDL).

### Bluetooth (Intel AX211)
- IntelBluetoothFirmware + IntelBTPatcher **2.5.1 (bản fork của lshbluesky)**; bản 2.5.0 gốc bị lỗi ở `LE_Read_BufferSize_V2`.
- BlueToolFixup 2.7.3.
- NVRAM: `bluetoothExternalDongleFailed` = `00`, `bluetoothInternalControllerInfo` = 14 byte 0 (cả ở Add lẫn Delete).

### Âm thanh
- AppleALC tắt (ALC245 không có layout chạy được). Dùng **VoodooHDA 3.6.8** cài vào `/Library/Extensions`.

### NVIDIA (NullMoth)
- Cài driver bằng app **1401** của NullMoth. App này tự sửa `config.plist` (boot-args, chặn `IONDRVSupport`, `ResizeGpuBars`...).
- `nvrmacpibl=1`: bật chỉnh độ sáng màn laptop (có thể làm treo lúc boot trên một số máy).
- Không cài bản 1.14.0. Khi lên Tahoe nên dùng ≥ 1.14.2 (bản 1.13 làm WindowServer crash).

## Khôi phục EFI từ menu OpenCore

`extras/startup.nsh` chép vào **gốc** phân vùng chứa EFI, kèm file đánh dấu `HACKINTOSH-1GB-TARGET.txt` và thư mục
`RESTORE/GOOD/{OC,BOOT}` (bản EFI chạy tốt). Mục **"KHOI PHUC EFI (Restore backup)"** (OpenShell) sẽ chép `RESTORE\GOOD`
đè lên `EFI\OC` rồi khởi động lại. Hữu ích khi một lần sửa config làm máy không boot được.

## Hạn chế đã biết

- **Pin tụt nhanh hơn Windows**: đo khi nghỉ ~36–45 W. GPU NVIDIA luôn bật (chế độ Discrete), và thư viện Vulkan của NullMoth
  gửi `PERF_BOOST` (BOOST_TO_MAX, thời hạn INFINITE). Có thể tắt thử bằng dòng `BOOST=0` trong
  `/Library/GPUBundles/nvmtl/nvrm610.conf` (**chưa kiểm chứng**).
- Sạc dừng khoảng 83%: có thể do giới hạn sạc của Gigabyte Control Center (lưu ở EC), chỉnh trong Windows.
- Geekbench Metal crash trên Tahoe (MPSGraph Depthwise Conv) → lỗi driver.
- Không có AirDrop, iPhone Mirroring, Sidecar.
- Màn hình không tắt hẳn khi ngủ với driver 1.13 (đã sửa ở 1.14.x).

## Ghi công

[Acidanthera](https://github.com/acidanthera) (OpenCore, Lilu, VirtualSMC, WhateverGreen, AppleALC, CPUFriend, RestrictEvents, NVMeFix, BrightnessKeys, DebugEnhancer),
[OpenIntelWireless](https://github.com/OpenIntelWireless) (AirportItlwm, IntelBluetoothFirmware), [lshbluesky](https://github.com/lshbluesky) (fork IntelBluetoothFirmware),
[VoodooI2C](https://github.com/VoodooI2C), [Dortania](https://github.com/dortania) (OpenCore Legacy Patcher, IOSkywalkFamily, IO80211FamilyLegacy, AMFIPass),
[USBToolBox](https://github.com/USBToolBox), [Mieze](https://github.com/Mieze) (RealtekRTL8111),
[b00t0x](https://github.com/b00t0x) (CpuTopologyRebuild), [NullMoth](https://github.com/nullmoth/nvidia-macos-driver) (driver NVIDIA, NullMothLogo.efi, NullMothSafe.efi).

Dùng với rủi ro của bạn. Luôn có USB boot dự phòng trước khi thay EFI.
