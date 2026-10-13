@echo -off
echo " "
echo "================================================================"
echo "  KHOI PHUC EFI (phan vung 1GB NVMe) TU \RESTORE\GOOD"
echo "  Bam ESC trong vai giay dau de HUY."
echo "================================================================"
set TGT ""
for %a run (0 20)
  if exist fs%a:\HACKINTOSH-1GB-TARGET.txt then
    set TGT fs%a:
  endif
endfor
if "%TGT%" == "" then
  echo "KHONG tim thay phan vung 1GB (file HACKINTOSH-1GB-TARGET.txt). Dung lai."
  goto END
endif
if not exist %TGT%\RESTORE\GOOD\OC\config.plist then
  echo "KHONG co ban backup %TGT%\RESTORE\GOOD. Dung lai."
  goto END
endif
echo "Chep %TGT%\RESTORE\GOOD -> %TGT%\EFI ..."
cp -r -q %TGT%\RESTORE\GOOD\OC\* %TGT%\EFI\OC
cp -q %TGT%\RESTORE\GOOD\BOOT\BOOTx64.efi %TGT%\EFI\BOOT\BOOTx64.efi
echo " "
echo "XONG. Khoi dong lai sau 5 giay..."
stall 5000000
reset
:END
echo "Go: map -r  de xem cac o. Go: reset  de khoi dong lai."
