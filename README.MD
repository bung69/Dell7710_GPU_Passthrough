place Holder / Note to self with all the information i used to Passthrough a Nvidia Quadro m5000m on a Dell Precision 7710.
i plan to update this in to a proper guide one day


Steps for Kubnuntu / probably other Debian based distros:

1. Enable switchable graphics and direct output mode (and virtualisation features) in bios**
2. boot in to fresh install of ubuntu 21.04 with kernel parameters "intel_iommu=on kvm.ignore_msrs=1" added to GRUB_CMDLINE_LINUX_DEFAULT in /etc/default/gub**
3. sudo update-grub**
4. sudo apt install libvirt-daemon-system libvirt-clients qemu-kvm qemu-utils qemu-efi virt-manager ovmf libhugetlbfs-bin**
5. sudo nano /etc/initramfs-tools/modules  and add**

          kvm
          kvm_intel
          vfio
          vfio_iommu_type1
          vfio_pci
          vfio_virqfd
          vhost-net


6. sudo update-initramfs -u**
7. install propriotory nvidia drivers and then do sudo prime-select intel and reboot**
8. use iommu.sh to get device ID's  and edit IDs in bind-gpu-vfio.sh and bind-HDMI_audio-vfio.sh**
9. do the folowing to get nvidia GPU Vbios:**

          sudo -i
          mkdir /usr/share/vgabios
          echo 1 > /sys/bus/pci/devices/0000:01:00.0/rom
          cat /sys/bus/pci/devices/0000:01:00.0/rom > /usr/share/vgabios/dgpu_vbios.rom
          echo 0 > /sys/bus/pci/devices/0000:01:00.0/rom

11. copy SSDT_BAT.dat to /usr/share/vgabios/ ( good location as libvirt can access this location) **
12. bind GPU and HDMI audio to VFIO using bind-gpu-vfio.sh**
15. create VM using virtmanger,  with usual recomended settings for high performance VN ( cpu pinning virtio network, disks etc ) **
16. add PCI device for nvidia GPU**
17. allow edit xml preference and select overview > XML to editand add the folowing**

At the top
  
    <domain xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0" type="kvm">
        
Before </hyperv>

    <vendor_id state="on" value="kvm hyperv"/>

After </hyperv>

    <kvm>
      <hidden state="on"/>
    </kvm>

Before </features>
      
    <ioapic driver="kvm"/>

At the bottom before </domain>

    <qemu:commandline>
      <qemu:arg value="-set"/>
      <qemu:arg value="device.hostdev0.x-pci-sub-vendor-id=0x1028"/>
      <qemu:arg value="-set"/>
      <qemu:arg value="device.hostdev0.x-pci-sub-device-id=0x06da"/>
      <qemu:arg value="-acpitable"/>
      <qemu:arg value="file=/usr/share/vgabios/SSDT_BAT.dat"/>
    </qemu:commandline>
        
        
        
19. Click PCI 0000:01:00.0 on the left,  then XML**

Replace with 

      <hostdev mode="subsystem" type="pci" managed="yes">
        <driver name="vfio"/>
        <source>
          <address domain="0x0000" bus="0x01" slot="0x00" function="0x0"/>
        </source>
        <rom bar="on" file="/usr/share/vgabios/dgpu_vbios.rom"/>
        <address type="pci" domain="0x0000" bus="0x01" slot="0x00" function="0x0" multifunction="on"/>
      </hostdev>
    
    
21. unbind GPU and HDMI audio from VFIO and rescan using remove-rescan.sh**
22. bind HDMI audio to VFIO using bind-HDMI_audio-vfio.sh**
23. Start the VM, install windows etc install propritory nvidia drivers. connect external display,  use nvida control pannel to copy EEID information,  alternativly boot in to windows baremetal without gpu switching bios option and copy laptop displays EEID**
24. Load EEID file again ( works kind of like a dummy HDMI plug?) **
25. set up looking glass,  test rebooting VM withougt display attached.  looking glass should still work**
26. reboot to bios,  disable direct output mode**
27. bind GPU and HDMI audio to VFIO using bind-gpu-vfio.sh**
28. unbind GPU and HDMI audio from VFIO and rescan using remove-rescan.sh**
29. bind HDMI audio to VFIO using bind-HDMI_audio-vfio.sh**
30. start VM and looking glass**
31.  TADA! 

  
