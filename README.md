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

# Background
The naming, Perf Neon, is inspired by a Linux Distribution called KDE Neon, where KDE take latest Ubuntu LTS as a base system and then put Latest KDE on top of it. Same thing as Perf Neon, where i take whatever the world the LineageOS team put under their kernel source and then put minimal patches on top of it.

# What is it for?
While it's mostly used for another kernel developers to compare their work with a literal close-to-stock kernel, it's also fulfill the dream of a purists, where they want everything stable but also wanted extra spices on top of it.

# Release schedules
This kernel follows weekly builds of LineageOS, you will get a new kernel build every sunday. You might need to check out the GitHub repo for new releases.

# Features
Currently added features:
- KernelSU support (ReSukiSU) & SUSFS support (separate build)
- Baseband Guard support
- NoMount Meta Module support
- ReKernel net support
- Droidspaces container support on select kernels
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

Externally supported device   
- Redmi Note 10 Pro/Pro Max ([sweet](https://pixelos.net/download/sweet)) from PixelOS   
- Redmi 4A/5A/Note 5A Lite/Y1 Lite ([mi8917](https://download.lineageos.org/devices/Mi8917/builds)) from Mi-Thorium   
- Redmi 3/3S/4/4X/Note 5A Prime/Y1 Prime ([mi8937](https://download.lineageos.org/devices/Mi8937/builds)) from Mi-Thorium   

# Credits
Patches & buildscript
- [TBYOOL](https://github.com/tbyool) for the buildscripts & kernel patches.   
- [xiaomi-sm6150](https://github.com/xiaomi-sm6150) for the dtbo patches.   
- [crdroidandroid](https://github.com/crdroidandroid) for the ln8000 patches.   
- [JackA1ltMan](https://github.com/JackA1ltman) for syscall hook script, susfs inline hook script, ReKernel hook script, SUSFS patches & ReKernel patches.   
- [TheSillyOk](https://github.com/TheSillyOk) for LTO & kpatch fixup for 4.14 devices.   

Projects   
- [ReSukiSU](https://github.com/ReSukiSU) for ReSukiSU.
- [vc-teahouse](https://github.com/vc-teahouse) for Baseband Guard.   
- [maxsteeel](https://github.com/maxsteeel) for NoMount.   
- [Sakion-Team](https://github.com/Sakion-Team) for ReKernel.
- [ravindu644](https://github.com/ravindu644) for Droidspaces.   
- [LineageOS](https://github.com/LineageOS) for kernel sources.   
- [PixelOS-Devices](https://github.com/PixelOS-Devices) for kernel sources.   
- [Mi-Thorium](https://github.com/Mi-Thorium) for kernel sources.   