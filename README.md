![banner](.github/assets/banner.png)
<div align="center" style="font-size: 1.25rem;">
    <strong>
        <em>
        This project is not affiliated with LineageOS & CrDroid.
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
The naming, Perf Neon, is inspired by a Linux Distribution called KDE Neon, where KDE take latest Ubuntu LTS as a base system and then put Latest KDE on top of it. Same thing as Perf Neon, where i take whatever the world the LineageOS & CrDroid team put under their kernel source and then put minimal patches on top of it.   

# What is it for?
This kernel solely focuses on adding goodies on top of the stock kernel, which fulfill the dream of a purists, where they want everything stable and rock solid from their stock kernels but also wanted extra spices on top of it.   

# Release schedules
This kernel follows weekly builds of LineageOS, you will get a new kernel build every sunday. You might need to check out the GitHub repo for new releases. Emergency rebuilt might happen if services that this builder rely on being broken or kernel source code have massive changes.   

# Features
Currently available features:   
- KernelSU support (ReSukiSU) & SUSFS support   
- Baseband Guard support   
- NoMount Meta Module support   
- Droidspaces container support   
- ReKernel tombstones support   
- Compiled with LTO and latest AOSP clang   

Currently added features into the kernel:   
- Every features is guaranteed available on Weekly release.   
- Redmi Mi89x7 & Mi8953 (mithorium, titanium): KernelSU w/ SUSFS, Baseband Guard, Nomount, ReKernel, -O3, LTO.   
- Redmi sweet (Spiteful): KernelSU w/ SUSFS, Baseband Guard, Nomount, ReKernel, -O3.   
- Redmi sweet (PixelOS): KernelSU w/ SUSFS, Baseband Guard, Nomount, ReKernel, -O3, Clang 12 + Android GCC 4.9.   
- Redmi tissot (Another): KernelSU w/ SUSFS, Baseband Guard, Nomount, Clang 12 + Android GCC 4.9.   

# Compatibility
Currently supported Operating System   
- LineageOS   
- /e/ OS   
- LibreMobileOS   
- CrDroid

Currently supported device (LineageOS & CrDroid)   
- Redmi K20/Mi 9T ([davinci](https://download.lineageos.org/devices/davinci/builds))   
- Redmi Note 10 Pro/Pro Max ([sweet](https://download.lineageos.org/devices/sweet/builds))   
- Xiaomi Mi Note 10/Note 10 Pro/CC9 Pro ([tucana](https://download.lineageos.org/devices/tucana/builds))    

Currently supported device (LineageOS Only)   
- Redmi Note 7 Pro ([violet](https://download.lineageos.org/devices/violet/builds))   
- Redmi Note 8/8T ([ginkgo/willow](https://download.lineageos.org/devices/ginkgo/builds))   
- Xiaomi Mi A3 ([laurel_sprout](https://download.lineageos.org/devices/laurel_sprout/builds))    
- Samsung Tab A7 10.4 2020 ([gta4l](https://download.lineageos.org/devices/gta4l/builds))   

Externally compiled kernels   
- Xiaomi Mi 10 ([umi](https://download.lineageos.org/devices/umi/builds)) from LineageOS   
- Xiaomi Mi 10 Pro ([cmi](https://download.lineageos.org/devices/cmi/builds)) from LineageOS   
- Redmi 4A/5A/Note 5A Lite/Y1 Lite ([mi8917](https://download.lineageos.org/devices/Mi8917/builds)) from Mi-Thorium   
- Redmi 3/3S/4/4X/Note 5A Prime/Y1 Prime ([mi8937](https://download.lineageos.org/devices/Mi8937/builds)) from Mi-Thorium   
- Redmi Note 10 Pro/Pro Max ([sweet](https://pixelos.net/download/sweet)) from PixelOS   
- Redmi A1 ([tissot](https://github.com/romiyusnandar/Another_Kernel_tissot-4.9)) from Another Kernel   
- Redmi S2/Y2/5 Plus/Note 4/Note 4X/Mi 5X ([mi8953](https://github.com/imren0x/msm-4.19)) from Mi-Titanium   
- Redmi Note 10 Pro/Pro Max ([sweet](https://github.com/tbyool/android_kernel_xiaomi_sm6150)) from Spiteful Kernel   

Notes   
- Kernels that released on playground is not restricted with these OS constraints.   
- Your device aren't yet supported? Go to the telegram channel to request your device for support.   

# Installation
On Recovery   
- Download both the flashable zip of the custom kernel and the original boot & dtbo image for your device as a backup.   
- Flash or Sideload the flashable zip with `adb sideload </path/to/flashable.zip>`  
- Allow to continue if you see Error 21 signature invalid.   
- Reboot to system.   
- Profit.   

On ReSukiSU Manager   
- On ReSukiSU Manager, click the "Working" card on the ReSukiSU Manager Home Screen.   
- You'll see flash AnyKernel3, click it, and select the flashable zip.   
- Click next and the flashable will be installed. If you see KPM option, just choose follow kernel.   
- Reboot.   
- Profit.   

Restore to default kernel   
- You'll need to remove everything inside `/data/adb`. You can do this with `su -c rm -rf /data/adb/*`.   
- Then immediately reboot to bootloader/fastbootd.   
- Flash the stock boot image with `fastboot flash boot </path/to/original/boot/image.img>`   
- Also flash the stock dtbo image with `fastboot flash dtbo </path/to/original/dtbo/image.img>`
- Reboot with `fastboot reboot`.   
- Profit.   

# Credits
Patches & buildscript
- [TBYOOL](https://github.com/tbyool) for the buildscripts, kernel sources & kernel patches.   
- [xiaomi-sm6150](https://github.com/xiaomi-sm6150) for the DTB patches.   
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
- [romiyusnandar](https://github.com/romiyusnandar) for kernel sources.
- [imren0x](https://github.com/imren0x) for kernel sources.