# ✅ ONE-SHOT SYSTEM DIAGNOSTIC SCRIPT

### Save this as `system-dump.sh` on your ASUS and run it with `sudo bash system-dump.sh > asus-specs.txt`

```bash
#!/bin/bash

echo "========== BASIC SYSTEM INFO =========="
hostnamectl
echo

echo "========== CPU INFO =========="
lscpu
echo

echo "========== MEMORY INFO =========="
free -h
echo "--- dmidecode RAM modules ---"
dmidecode --type 17 | grep -A16 "Memory Device"
echo

echo "========== STORAGE DEVICES =========="
lsblk -o NAME,SIZE,ROTA,RO,MOUNTPOINT,TYPE,MODEL
echo "--- Disk Speeds ---"
/usr/bin/time -f "\n%U user\n%S system\n%E elapsed\n%P CPU" dd if=/dev/zero of=tempfile bs=1M count=1024 conv=fdatasync
rm -f tempfile
echo

echo "========== PCI DEVICES (GPU, etc) =========="
lspci -nnk | grep -A4 VGA
echo

echo "========== USB Devices =========="
lsusb
echo

echo "========== GPU INFO =========="
if command -v nvidia-smi &> /dev/null; then
  nvidia-smi -q
elif command -v glxinfo &> /dev/null; then
  glxinfo | grep -i "OpenGL"
else
  echo "No NVIDIA GPU or glxinfo found."
fi
echo

echo "========== BIOS / UEFI INFO =========="
dmidecode -t bios
echo

echo "========== CURRENT KERNEL =========="
uname -a
echo

echo "========== MODULES LOADED =========="
lsmod
echo

echo "========== SYSTEMD TARGETS =========="
systemctl list-units --type=target --all
echo

echo "========== POWER MANAGEMENT =========="
cat /etc/systemd/logind.conf | grep -v '^#'
echo "--- CPUfreq Governors ---"
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo

echo "========== ZRAM CONFIGURATION =========="
if [[ -d /sys/block/zram0 ]]; then
  zramctl
  echo "--- Kernel ZRAM params ---"
  cat /sys/block/zram0/disksize
else
  echo "No ZRAM configured yet."
fi

echo
echo "========== NETWORK INTERFACES =========="
ip link show
echo
tailscale status 2>/dev/null || echo "No tailscale active."

echo
echo "========== DONE =========="
```

---

## 📦 Dependencies:

You’ll need these installed before running the script:

```bash
sudo pacman -S dmidecode usbutils mesa-demos pciutils time --noconfirm
```

If you want disk I/O benchmarking:

```bash
sudo pacman -S hdparm --noconfirm
```

---

## ✅ Result:

You'll get a **`asus-specs.txt`** file with:

* CPU name, threads, cache, features
* RAM slots, speeds, module names
* GPU chipset + VRAM
* Disk size, model, speed
* BIOS version, manufacturer, date
* Kernel + loaded modules
* ZRAM status
* Power management settings
* Tailscale info

[output]
~/scripts took 3s
❯ ./one-and-done.sh
========== BASIC SYSTEM INFO ==========
 Static hostname: trainr-asus
       Icon name: computer-laptop
         Chassis: laptop 💻
      Machine ID: 30a3c3b81f3a481b8e26902f797ce9ef
         Boot ID: e57d97f1a35b4ee3963ec81b5f2b1eee
Operating System: Arch Linux
          Kernel: Linux 6.15.2-arch1-1
    Architecture: x86-64
 Hardware Vendor: ASUSTeK COMPUTER INC.
  Hardware Model: TUF Gaming FX505DT_FX505DT
Firmware Version: FX505DT.316
   Firmware Date: Thu 2021-01-28
    Firmware Age: 4y 5month 2w 4d

========== CPU INFO ==========
Architecture:                x86_64
  CPU op-mode(s):            32-bit, 64-bit
  Address sizes:             43 bits physical, 48 bits virtual
  Byte Order:                Little Endian
CPU(s):                      8
  On-line CPU(s) list:       0-7
Vendor ID:                   AuthenticAMD
  Model name:                AMD Ryzen 5 3550H with Radeon Vega Mobile Gfx
    CPU family:              23
    Model:                   24
    Thread(s) per core:      2
    Core(s) per socket:      4
    Socket(s):               1
    Stepping:                1
    Frequency boost:         enabled
    CPU(s) scaling MHz:      97%
    CPU max MHz:             2100.0000
    CPU min MHz:             1400.0000
    BogoMIPS:                4191.96
    Flags:                   fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clfl
                             ush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm consta
                             nt_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmu
                             lqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rd
                             rand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowpr
                             efetch osvw skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc
                              mwaitx cpb hw_pstate ssbd ibpb vmmcall fsgsbase bmi1 avx2 smep bmi2 rdseed
                             adx smap clflushopt sha_ni xsaveopt xsavec xgetbv1 clzero xsaveerptr arat np
                             t lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pau
                             sefilter pfthreshold avic v_vmsave_vmload vgif overflow_recov succor smca se
                             v sev_es
Virtualization features:
  Virtualization:            AMD-V
Caches (sum of all):
  L1d:                       128 KiB (4 instances)
  L1i:                       256 KiB (4 instances)
  L2:                        2 MiB (4 instances)
  L3:                        4 MiB (1 instance)
NUMA:
  NUMA node(s):              1
  NUMA node0 CPU(s):         0-7
Vulnerabilities:
  Gather data sampling:      Not affected
  Ghostwrite:                Not affected
  Indirect target selection: Not affected
  Itlb multihit:             Not affected
  L1tf:                      Not affected
  Mds:                       Not affected
  Meltdown:                  Not affected
  Mmio stale data:           Not affected
  Reg file data sampling:    Not affected
  Retbleed:                  Mitigation; untrained return thunk; SMT vulnerable
  Spec rstack overflow:      Mitigation; Safe RET
  Spec store bypass:         Mitigation; Speculative Store Bypass disabled via prctl
  Spectre v1:                Mitigation; usercopy/swapgs barriers and __user pointer sanitization
  Spectre v2:                Mitigation; Retpolines; IBPB conditional; STIBP disabled; RSB filling; PBRSB
                             -eIBRS Not affected; BHI Not affected
  Srbds:                     Not affected
  Tsx async abort:           Not affected

========== MEMORY INFO ==========
               total        used        free      shared  buff/cache   available
Mem:            29Gi       2.4Gi        25Gi        30Mi       1.6Gi        26Gi
Swap:           14Gi          0B        14Gi
--- dmidecode RAM modules ---
./one-and-done.sh: line 14: dmidecode: command not found

========== STORAGE DEVICES ==========
NAME          SIZE ROTA RO MOUNTPOINT TYPE MODEL
zram0        14.7G    0  0 [SWAP]     disk
nvme0n1     931.5G    0  0            disk CT1000P3SSD8
├─nvme0n1p1     1G    0  0 /boot      part
├─nvme0n1p2    50G    0  0 /          part
├─nvme0n1p3   100G    0  0 /var       part
├─nvme0n1p4   200G    0  0 /home      part
└─nvme0n1p5 580.5G    0  0 /data      part
--- Disk Speeds ---
./one-and-done.sh: line 20: /usr/bin/time: No such file or directory

========== PCI DEVICES (GPU, etc) ==========
01:00.0 VGA compatible controller [0300]: NVIDIA Corporation TU117M [GeForce GTX 1650 Mobile / Max-Q] [10de:1f91] (rev a1)
	Subsystem: ASUSTeK Computer Inc. Device [1043:109f]
	Kernel driver in use: nvidia
	Kernel modules: nouveau, nvidia_drm, nvidia
01:00.1 Audio device [0403]: NVIDIA Corporation Device [10de:10fa] (rev a1)
--
05:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Picasso/Raven 2 [Radeon Vega Series / Radeon Vega Mobile Series] [1002:15d8] (rev c2)
	Subsystem: ASUSTeK Computer Inc. Device [1043:18f1]
	Kernel driver in use: amdgpu
	Kernel modules: amdgpu
05:00.2 Encryption controller [1080]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 10h-1fh) Platform Security Processor [1022:15df]

========== USB Devices ==========
./one-and-done.sh: line 29: lsusb: command not found

========== GPU INFO ==========

==============NVSMI LOG==============

Timestamp                                 : Thu Jul 17 13:57:03 2025
Driver Version                            : 575.57.08
CUDA Version                              : 12.9

Attached GPUs                             : 1
GPU 00000000:01:00.0
    Product Name                          : NVIDIA GeForce GTX 1650
    Product Brand                         : GeForce
    Product Architecture                  : Turing
    Display Mode                          : Requested functionality has been deprecated
    Display Attached                      : No
    Display Active                        : Disabled
    Persistence Mode                      : Disabled
    Addressing Mode                       : None
    MIG Mode
        Current                           : N/A
        Pending                           : N/A
    Accounting Mode                       : Disabled
    Accounting Mode Buffer Size           : 4000
    Driver Model
        Current                           : N/A
        Pending                           : N/A
    Serial Number                         : N/A
    GPU UUID                              : GPU-8eca225f-bc43-11b3-b5f1-f4e61ee30d05
    Minor Number                          : 0
    VBIOS Version                         : 90.17.4C.00.23
    MultiGPU Board                        : No
    Board ID                              : 0x100
    Board Part Number                     : N/A
    GPU Part Number                       : 1F91-750-A1
    FRU Part Number                       : N/A
    Platform Info
        Chassis Serial Number             : N/A
        Slot Number                       : N/A
        Tray Index                        : N/A
        Host ID                           : N/A
        Peer Type                         : N/A
        Module Id                         : 1
        GPU Fabric GUID                   : N/A
    Inforom Version
        Image Version                     : G001.0000.02.04
        OEM Object                        : 1.1
        ECC Object                        : N/A
        Power Management Object           : N/A
    Inforom BBX Object Flush
        Latest Timestamp                  : N/A
        Latest Duration                   : N/A
    GPU Operation Mode
        Current                           : N/A
        Pending                           : N/A
    GPU C2C Mode                          : N/A
    GPU Virtualization Mode
        Virtualization Mode               : None
        Host VGPU Mode                    : N/A
        vGPU Heterogeneous Mode           : N/A
    GPU Reset Status
        Reset Required                    : Requested functionality has been deprecated
        Drain and Reset Recommended       : Requested functionality has been deprecated
    GPU Recovery Action                   : None
    GSP Firmware Version                  : 575.57.08
    IBMNPU
        Relaxed Ordering Mode             : N/A
    PCI
        Bus                               : 0x01
        Device                            : 0x00
        Domain                            : 0x0000
        Base Classcode                    : 0x3
        Sub Classcode                     : 0x0
        Device Id                         : 0x1F9110DE
        Bus Id                            : 00000000:01:00.0
        Sub System Id                     : 0x109F1043
        GPU Link Info
            PCIe Generation
                Max                       : 3
                Current                   : 1
                Device Current            : 1
                Device Max                : 3
                Host Max                  : 3
            Link Width
                Max                       : 16x
                Current                   : 8x
        Bridge Chip
            Type                          : N/A
            Firmware                      : N/A
        Replays Since Reset               : 0
        Replay Number Rollovers           : 0
        Tx Throughput                     : 350 KB/s
        Rx Throughput                     : 350 KB/s
        Atomic Caps Outbound              : N/A
        Atomic Caps Inbound               : N/A
    Fan Speed                             : N/A
    Performance State                     : P8
    Clocks Event Reasons
        Idle                              : Active
        Applications Clocks Setting       : Not Active
        SW Power Cap                      : Not Active
        HW Slowdown                       : Not Active
            HW Thermal Slowdown           : Not Active
            HW Power Brake Slowdown       : Not Active
        Sync Boost                        : Not Active
        SW Thermal Slowdown               : Not Active
        Display Clock Setting             : Not Active
    Clocks Event Reasons Counters
        SW Power Capping                  : 4957032508 us
        Sync Boost                        : 0 us
        SW Thermal Slowdown               : 3893592 us
        HW Thermal Slowdown               : 0 us
        HW Power Braking                  : 0 us
    Sparse Operation Mode                 : N/A
    FB Memory Usage
        Total                             : 4096 MiB
        Reserved                          : 381 MiB
        Used                              : 4 MiB
        Free                              : 3713 MiB
    BAR1 Memory Usage
        Total                             : 256 MiB
        Used                              : 4 MiB
        Free                              : 252 MiB
    Conf Compute Protected Memory Usage
        Total                             : 0 MiB
        Used                              : 0 MiB
        Free                              : 0 MiB
    Compute Mode                          : Default
    Utilization
        GPU                               : 0 %
        Memory                            : 0 %
        Encoder                           : 0 %
        Decoder                           : 0 %
        JPEG                              : 0 %
        OFA                               : 0 %
    Encoder Stats
        Active Sessions                   : 0
        Average FPS                       : 0
        Average Latency                   : 0
    FBC Stats
        Active Sessions                   : 0
        Average FPS                       : 0
        Average Latency                   : 0
    DRAM Encryption Mode
        Current                           : N/A
        Pending                           : N/A
    ECC Mode
        Current                           : N/A
        Pending                           : N/A
    ECC Errors
        Volatile
            SRAM Correctable              : N/A
            SRAM Uncorrectable            : N/A
            DRAM Correctable              : N/A
            DRAM Uncorrectable            : N/A
        Aggregate
            SRAM Correctable              : N/A
            SRAM Uncorrectable            : N/A
            DRAM Correctable              : N/A
            DRAM Uncorrectable            : N/A
    Retired Pages
        Single Bit ECC                    : N/A
        Double Bit ECC                    : N/A
        Pending Page Blacklist            : N/A
    Remapped Rows                         : N/A
    Temperature
        GPU Current Temp                  : 39 C
        GPU T.Limit Temp                  : N/A
        GPU Shutdown Temp                 : 102 C
        GPU Slowdown Temp                 : 97 C
        GPU Max Operating Temp            : 102 C
        GPU Target Temperature            : 87 C
        Memory Current Temp               : N/A
        Memory Max Operating Temp         : N/A
    GPU Power Readings
        Average Power Draw                : N/A
        Instantaneous Power Draw          : 2.66 W
        Current Power Limit               : 50.00 W
        Requested Power Limit             : 50.00 W
        Default Power Limit               : 50.00 W
        Min Power Limit                   : 1.00 W
        Max Power Limit                   : 50.00 W
    GPU Memory Power Readings
        Average Power Draw                : N/A
        Instantaneous Power Draw          : N/A
    Module Power Readings
        Average Power Draw                : N/A
        Instantaneous Power Draw          : N/A
        Current Power Limit               : N/A
        Requested Power Limit             : N/A
        Default Power Limit               : N/A
        Min Power Limit                   : N/A
        Max Power Limit                   : N/A
    Power Smoothing                       : N/A
    Workload Power Profiles
        Requested Profiles                : N/A
        Enforced Profiles                 : N/A
    Clocks
        Graphics                          : 300 MHz
        SM                                : 300 MHz
        Memory                            : 405 MHz
        Video                             : 540 MHz
    Applications Clocks
        Graphics                          : N/A
        Memory                            : N/A
    Default Applications Clocks
        Graphics                          : N/A
        Memory                            : N/A
    Deferred Clocks
        Memory                            : N/A
    Max Clocks
        Graphics                          : 2100 MHz
        SM                                : 2100 MHz
        Memory                            : 4001 MHz
        Video                             : 1950 MHz
    Max Customer Boost Clocks
        Graphics                          : N/A
    Clock Policy
        Auto Boost                        : N/A
        Auto Boost Default                : N/A
    Voltage
        Graphics                          : Requested functionality has been deprecated
    Fabric
        State                             : N/A
        Status                            : N/A
        CliqueId                          : N/A
        ClusterUUID                       : N/A
        Health
            Bandwidth                     : N/A
            Route Recovery in progress    : N/A
            Route Unhealthy               : N/A
            Access Timeout Recovery       : N/A
    Processes
        GPU instance ID                   : N/A
        Compute instance ID               : N/A
        Process ID                        : 2023
            Type                          : G
            Name                          : /usr/bin/gnome-shell
            Used GPU Memory               : 1 MiB
    Capabilities
        EGM                               : disabled


========== BIOS / UEFI INFO ==========
./one-and-done.sh: line 43: dmidecode: command not found

========== CURRENT KERNEL ==========
Linux trainr-asus 6.15.2-arch1-1 #1 SMP PREEMPT_DYNAMIC Tue, 10 Jun 2025 21:32:33 +0000 x86_64 GNU/Linux

========== MODULES LOADED ==========
Module                  Size  Used by
hid_samsung            32768  0
uhid                   28672  2
xt_conntrack           12288  1
xt_MASQUERADE          16384  1
bridge                450560  0
stp                    12288  1 bridge
llc                    16384  2 bridge,stp
xt_set                 24576  0
ip_set                 69632  1 xt_set
xt_addrtype            12288  4
xfrm_user              69632  1
xfrm_algo              16384  1 xfrm_user
ccm                    20480  3
snd_seq_dummy          12288  0
snd_hrtimer            12288  1
rfcomm                102400  16
snd_seq               135168  7 snd_seq_dummy
snd_seq_device         16384  1 snd_seq
nf_tables             385024  0
ip6table_nat           12288  1
ip6table_filter        12288  1
ip6_tables             36864  2 ip6table_filter,ip6table_nat
iptable_nat            12288  1
nf_nat                 61440  3 ip6table_nat,iptable_nat,xt_MASQUERADE
nf_conntrack          204800  3 xt_conntrack,nf_nat,xt_MASQUERADE
nf_defrag_ipv6         24576  1 nf_conntrack
nf_defrag_ipv4         12288  1 nf_conntrack
iptable_filter         12288  1
overlay               237568  0
cmac                   12288  3
algif_hash             16384  1
algif_skcipher         12288  1
af_alg                 32768  6 algif_hash,algif_skcipher
bnep                   36864  2
amd_atl                57344  1
intel_rapl_msr         20480  0
intel_rapl_common      53248  1 intel_rapl_msr
iwlmvm                741376  0
kvm_amd               237568  0
snd_hda_codec_realtek   221184  1
mac80211             1646592  1 iwlmvm
snd_hda_codec_generic   114688  1 snd_hda_codec_realtek
libarc4                12288  1 mac80211
snd_hda_scodec_component    20480  1 snd_hda_codec_realtek
snd_hda_codec_hdmi     90112  1
ptp                    49152  1 iwlmvm
kvm                  1388544  1 kvm_amd
pps_core               32768  1 ptp
btusb                  81920  0
snd_hda_intel          69632  2
btrtl                  32768  1 btusb
snd_intel_dspcfg       40960  1 snd_hda_intel
snd_intel_sdw_acpi     16384  1 snd_intel_dspcfg
irqbypass              12288  1 kvm
btintel                73728  1 btusb
iwlwifi               622592  1 iwlmvm
btbcm                  24576  1 btusb
pkcs8_key_parser       12288  0
polyval_clmulni        12288  0
snd_hda_codec         217088  4 snd_hda_codec_generic,snd_hda_codec_hdmi,snd_hda_intel,snd_hda_codec_realtek
polyval_generic        12288  1 polyval_clmulni
nvidia_drm            143360  3
uvcvideo              184320  0
ghash_clmulni_intel    16384  0
btmtk                  32768  1 btusb
videobuf2_vmalloc      20480  1 uvcvideo
nvidia_uvm           3874816  0
uvc                    12288  1 uvcvideo
snd_hda_core          143360  5 snd_hda_codec_generic,snd_hda_codec_hdmi,snd_hda_intel,snd_hda_codec,snd_hda_codec_realtek
nvidia_modeset       1843200  3 nvidia_drm
sha512_ssse3           53248  0
joydev                 24576  0
asus_nb_wmi            32768  0
videobuf2_memops       16384  1 videobuf2_vmalloc
snd_hwdep              24576  1 snd_hda_codec
cfg80211             1400832  3 iwlmvm,iwlwifi,mac80211
bluetooth            1101824  48 btrtl,btmtk,btintel,btbcm,bnep,btusb,rfcomm
sha256_ssse3           36864  0
videobuf2_v4l2         40960  1 uvcvideo
jc42                   12288  0
asus_wmi              110592  1 asus_nb_wmi
mousedev               28672  0
sha1_ssse3             32768  0
videobuf2_common       94208  4 videobuf2_vmalloc,videobuf2_v4l2,uvcvideo,videobuf2_memops
snd_pcm               212992  4 snd_hda_codec_hdmi,snd_hda_intel,snd_hda_codec,snd_hda_core
platform_profile       16384  1 asus_wmi
aesni_intel           106496  6
r8169                 131072  0
ee1004                 16384  0
vfat                   24576  1
snd_timer              57344  3 snd_seq,snd_hrtimer,snd_pcm
crypto_simd            16384  1 aesni_intel
videodev              397312  2 videobuf2_v4l2,uvcvideo
fat                   110592  1 vfat
snd                   155648  16 snd_hda_codec_generic,snd_seq,snd_seq_device,snd_hda_codec_hdmi,snd_hwdep,snd_hda_intel,snd_hda_codec,snd_hda_codec_realtek,snd_timer,snd_pcm
realtek                49152  1
sp5100_tco             20480  0
cryptd                 28672  3 crypto_simd,ghash_clmulni_intel
hid_multitouch         36864  0
i2c_piix4              36864  0
mdio_devres            12288  1 r8169
mc                     90112  4 videodev,videobuf2_v4l2,uvcvideo,videobuf2_common
rapl                   20480  0
sparse_keymap          12288  1 asus_wmi
wmi_bmof               12288  0
pcspkr                 12288  0
acpi_cpufreq           32768  0
soundcore              16384  1 snd
ccp                   184320  1 kvm_amd
rfkill                 45056  11 iwlmvm,asus_wmi,bluetooth,cfg80211
libphy                233472  3 r8169,mdio_devres,realtek
i2c_smbus              20480  1 i2c_piix4
k10temp                16384  0
i2c_hid_acpi           12288  0
i2c_hid                45056  1 i2c_hid_acpi
asus_wireless          16384  0
nvidia              112218112  37 nvidia_uvm,nvidia_modeset
mac_hid                12288  0
sg                     53248  0
crypto_user            12288  0
loop                   40960  0
dm_mod                229376  0
nfnetlink              20480  4 nf_tables,ip_set
zram                   65536  1
842_decompress         16384  1 zram
842_compress           24576  1 zram
lz4hc_compress         20480  1 zram
lz4_compress           24576  1 zram
ip_tables              36864  2 iptable_filter,iptable_nat
x_tables               65536  10 ip6table_filter,xt_conntrack,iptable_filter,ip6table_nat,xt_addrtype,xt_set,ip6_tables,ip_tables,iptable_nat,xt_MASQUERADE
xfs                  4165632  4
amdgpu              15548416  12
amdxcp                 12288  1 amdgpu
i2c_algo_bit           24576  1 amdgpu
drm_ttm_helper         16384  3 amdgpu,nvidia_drm
ttm                   118784  2 amdgpu,drm_ttm_helper
drm_exec               12288  1 amdgpu
gpu_sched              65536  1 amdgpu
drm_suballoc_helper    16384  1 amdgpu
nvme                   65536  5
drm_panel_backlight_quirks    12288  1 amdgpu
drm_buddy              24576  1 amdgpu
nvme_core             266240  6 nvme
drm_display_helper    270336  1 amdgpu
serio_raw              20480  0
nvme_keyring           20480  1 nvme_core
video                  81920  4 asus_wmi,amdgpu,asus_nb_wmi,nvidia_modeset
cec                    90112  2 drm_display_helper,amdgpu
nvme_auth              32768  1 nvme_core
wmi                    32768  3 video,asus_wmi,wmi_bmof

========== SYSTEMD TARGETS ==========
  UNIT                                                                                 LOAD   ACTIVE   S>
  basic.target                                                                         loaded active   a>
  blockdev@dev-disk-by\x2duuid-11a95024\x2da366\x2d40b5\x2d8022\x2d06e4a49ef8b6.target loaded inactive d>
  blockdev@dev-disk-by\x2duuid-676542e5\x2db5a0\x2d4c04\x2db989\x2d8dbf917cb00c.target loaded inactive d>
  blockdev@dev-disk-by\x2duuid-7376\x2dA4D4.target                                     loaded inactive d>
  blockdev@dev-disk-by\x2duuid-95e10df6\x2d1f10\x2d4eb5\x2da9a7\x2d4cbb0b19de14.target loaded inactive d>
  blockdev@dev-disk-by\x2duuid-f5e29748\x2d50dd\x2d45fc\x2db4dc\x2d613d908ade11.target loaded inactive d>
  blockdev@dev-nvme0n1p1.target                                                        loaded inactive d>
  blockdev@dev-nvme0n1p3.target                                                        loaded inactive d>
  blockdev@dev-nvme0n1p4.target                                                        loaded inactive d>
  blockdev@dev-nvme0n1p5.target                                                        loaded inactive d>
  blockdev@dev-zram0.target                                                            loaded inactive d>
  bluetooth.target                                                                     loaded active   a>
  cryptsetup-pre.target                                                                loaded inactive d>
  cryptsetup.target                                                                    loaded active   a>
  emergency.target                                                                     loaded inactive d>
  final.target                                                                         loaded inactive d>
  first-boot-complete.target                                                           loaded inactive d>
  getty-pre.target                                                                     loaded inactive d>
  getty.target                                                                         loaded active   a>
  graphical.target                                                                     loaded active   a>
  halt.target                                                                          loaded inactive d>
  initrd-fs.target                                                                     loaded inactive d>
  initrd-root-device.target                                                            loaded inactive d>
  initrd-root-fs.target                                                                loaded inactive d>
  initrd-switch-root.target                                                            loaded inactive d>
  initrd-usr-fs.target                                                                 loaded inactive d>
  initrd.target                                                                        loaded inactive d>
  integritysetup.target                                                                loaded active   a>
  kexec.target                                                                         loaded inactive d>
  local-fs-pre.target                                                                  loaded active   a>
  local-fs.target                                                                      loaded active   a>
  multi-user.target                                                                    loaded active   a>
  network-online.target                                                                loaded active   a>
  network-pre.target                                                                   loaded active   a>
  network.target                                                                       loaded active   a>
  nss-lookup.target                                                                    loaded active   a>
  nss-user-lookup.target                                                               loaded active   a>
  paths.target                                                                         loaded active   a>
  poweroff.target                                                                      loaded inactive d>
  reboot.target                                                                        loaded inactive d>
  remote-cryptsetup.target                                                             loaded inactive d>
  remote-fs-pre.target                                                                 loaded inactive d>
  remote-fs.target                                                                     loaded active   a>
  remote-veritysetup.target                                                            loaded inactive d>
  rescue.target                                                                        loaded inactive d>
  shutdown.target                                                                      loaded inactive d>
  slices.target                                                                        loaded active   a>
  sockets.target                                                                       loaded active   a>
  soft-reboot.target                                                                   loaded inactive d>
  sound.target                                                                         loaded active   a>
  swap.target                                                                          loaded active   a>
  sysinit.target                                                                       loaded active   a>
  time-set.target                                                                      loaded active   a>
  time-sync.target                                                                     loaded inactive d>
  timers.target                                                                        loaded active   a>
  tpm2.target                                                                          loaded active   a>
  umount.target                                                                        loaded inactive d>
  veritysetup-pre.target                                                               loaded inactive d>
  veritysetup.target                                                                   loaded active   a>

Legend: LOAD   → Reflects whether the unit definition was properly loaded.
        ACTIVE → The high-level unit activation state, i.e. generalization of SUB.
        SUB    → The low-level unit activation state, values depend on unit type.

59 loaded units listed.
To show all installed unit files use 'systemctl list-unit-files'.

========== POWER MANAGEMENT ==========

[Login]
--- CPUfreq Governors ---
schedutil
schedutil
schedutil
schedutil
schedutil
schedutil
schedutil
schedutil

========== ZRAM CONFIGURATION ==========
NAME       ALGORITHM DISKSIZE DATA COMPR TOTAL STREAMS MOUNTPOINT
/dev/zram0 zstd         14.7G   4K   64B   20K         [SWAP]
--- Kernel ZRAM params ---
15733882880

========== NETWORK INTERFACES ==========
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: enp2s0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc fq_codel state DOWN mode DEFAULT group default qlen 1000
    link/ether d4:5d:64:5d:6e:19 brd ff:ff:ff:ff:ff:ff
    altname enxd45d645d6e19
3: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DORMANT group default qlen 1000
    link/ether 28:a4:4a:01:7a:bb brd ff:ff:ff:ff:ff:ff
4: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN mode DEFAULT group default
    link/ether 7a:5b:e7:bd:ee:bc brd ff:ff:ff:ff:ff:ff

No tailscale active.

========== DONE ==========

