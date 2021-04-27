place Holder / Note to self with all the information i used to Passthrough a Nvidia Quadro m5000m on a Dell Precision 7710.
i plan to update this in to a proper guide one day


Steps:
Enable switchable graphics and direct output mode (and virtualisation features) in bios
boot in to fresh install of ubuntu 21.04 with kernel parameters "intel_iommu=on kvm.ignore_msrs=1" added to GRUB_CMDLINE_LINUX_DEFAULT in /etc/default/gub
bind GPU and HDMI audio to VFIO using bind-gpu-vfio.sh
unbind GPU and HDMI audio from VFIO and rescan using remove-rescan.sh
bind HDMI audio to VFIO using bind-HDMI_audio-vfio.sh

