![banner](.github/assets/banner.png)
<div align="center" style="font-size: 1.25rem;">
    <strong>
        <em>
        This project is not affiliated with LineageOS.
        </em>
    </strong>
</div>

<br>

<div align="center">

[![Downloads](https://img.shields.io/github/downloads/riarumoda/perf_neon-builder/total?label=Downloads&logo=icloud&logoColor=white)](https://github.com/riarumoda/perf_neon-builder/releases)
[![Telegram](https://img.shields.io/badge/Follow-Telegram-blue?logo=telegram)](https://t.me/trrflexgroup)
[![CI Status](https://img.shields.io/github/actions/workflow/status/riarumoda/perf_neon-builder/normal.yml?label=Status&logo=github-actions&logoColor=white)](https://github.com/riarumoda/perf_neon-builder/actions/workflows/normal.yml)

</div>

# Disclaimer
***Your warranty is now void. I am not responsible for bricked devices, dead SD cards, or you getting fired because an alarm failed to work. Please do some research if you have any concerns about features included before flashing it! YOU are choosing to make these modifications, and if you point the finger at me for messing up your device, I will laugh at you.***   
<p align="right">Your typical XDA Forum Disclaimer.<p>   

# Background
The naming, Perf Neon, is inspired by a Linux Distribution called KDE Neon, where KDE take latest Ubuntu LTS as a base system and then put Latest KDE on top of it. Same thing as Perf Neon, where i take whatever the world the LineageOS team put under their kernel source and then put minimal patches on top of it.

# What is it for?
While it's mostly used for another kernel developers to compare their work with a literal close-to-stock kernel, it's also fulfill the dream of a purists, where they want everything stable but also wanted extra spices on top of it.

# Release schedules
This kernel follows weekly builds of LineageOS, you will get a new kernel build every sunday. You might need to check out the GitHub repo for new releases.

# Features
Currently added features:
- KernelSU support (ReSukiSU) & SUSFS support
- Baseband Guard support
- NoMount Meta Module support
- Droidspaces container support
- ReKernel tombstones support
- Compiled with -O3, LTO, LLVM=1

# Compatibility
Currently supported device   
- Redmi K20/Mi 9T ([davinci](https://download.lineageos.org/devices/davinci/builds)) 
- Redmi Note 10 Pro/Pro Max ([sweet](https://download.lineageos.org/devices/sweet/builds))   
- Xiaomi Mi Note 10/Note 10 Pro/CC9 Pro ([tucana](https://download.lineageos.org/devices/tucana/builds))   
- Redmi Note 7 Pro ([violet](https://download.lineageos.org/devices/violet/builds))   
- Redmi Note 8/8T ([ginkgo/willow](https://download.lineageos.org/devices/ginkgo/builds))   
- Xiaomi Mi A3 ([laurel_sprout](https://download.lineageos.org/devices/laurel_sprout/builds))   
- Xiaomi Mi 10 ([umi](https://download.lineageos.org/devices/umi/builds))   
- Xiaomi Mi 10 Pro ([cmi](https://download.lineageos.org/devices/cmi/builds))   
- Samsung Tab A7 10.4 2020 ([gta4l](https://download.lineageos.org/devices/gta4l/builds))   

Externally compiled kernels   
- Samsung A52 4G ([a52q](https://download.lineageos.org/devices/a52q/builds)) from LineageOS   
- Samsung A72 ([a72q](https://download.lineageos.org/devices/a72q/builds)) from LineageOS   
- Samsung Note 10+ ([d2s](https://download.lineageos.org/devices/d2s/builds)) from LineageOS   
- Samsung Note 10+ 5G ([d2x](https://download.lineageos.org/devices/d2x/builds)) from LineageOS   
- Redmi Note 10 Pro/Pro Max ([sweet](https://pixelos.net/download/sweet)) from PixelOS   
- Redmi 4A/5A/Note 5A Lite/Y1 Lite ([mi8917](https://download.lineageos.org/devices/Mi8917/builds)) from Mi-Thorium   
- Redmi 3/3S/4/4X/Note 5A Prime/Y1 Prime ([mi8937](https://download.lineageos.org/devices/Mi8937/builds)) from Mi-Thorium   

# Installation
On Recovery   
- Download both the flashable zip and the original boot image for your device as a backup.   
- Flash or Sideload the flashable zip with `adb sideload <package.zip>`  
- Allow to continue if you see Error 21 signature invalid.   
- Reboot to system and pray everything works.   
- Profit.   

On ReSukiSU Manager
- On ReSukiSU Manager, click the "Working" card on the ReSukiSU Manager Home Screen.
- You'll see flash AnyKernel3, click it, and select the flashable zip.   
- Click next and the flashable will be installed. If you see KPM option, just choose follow kernel.   
- Reboot and pray everything works.   
- Profit.   

Restore to default kernel
- You'll need to remove everything inside `/data/adb`. You can do this with `su -c rm -rf /data/adb/*`.
- Then immediately reboot to bootloader/fastbootd.   
- Flash the stock boot image with `fastboot flash boot <theoriginalbootimage.img>`
- Reboot with `fastboot reboot` and pray everything works.   
- Profit.   

# Credits
Patches & buildscript
- [TBYOOL](https://github.com/tbyool) for the buildscripts & kernel patches.   
- [xiaomi-sm6150](https://github.com/xiaomi-sm6150) for the ln8000 patches.   
- [JackA1ltMan](https://github.com/JackA1ltman) for ReSukiSU hook scripts, ReKernel scripts & SUSFS patches.   
- [TheSillyOk](https://github.com/TheSillyOk) for LTO & kpatch fixup for 4.14 devices.   

Projects   
- [ReSukiSU](https://github.com/ReSukiSU) for ReSukiSU.   
- [vc-teahouse](https://github.com/vc-teahouse) for Baseband Guard.   
- [maxsteeel](https://github.com/maxsteeel) for NoMount.   
- [ravindu644](https://github.com/ravindu644) for Droidspaces.   
- [Sakion-Team](https://github.com/Sakion-Team/Re-Kernel) for ReKernel.   
- [LineageOS](https://github.com/LineageOS) for kernel sources.   
- [PixelOS-Devices](https://github.com/PixelOS-Devices) for kernel sources.   
- [Mi-Thorium](https://github.com/Mi-Thorium) for kernel sources.   