Dell Precision 7710 with Nvidia Quadro m500m VFIO GPU passthrough using Kubnuntu / probably other Debian based distros.

Should also be posible with non Quadro GPUs either without looking glass and using an external display or using a dummy HDMI device and not using external displays.  Please let me know if it is posible to load EEID for non Quadro GPU's or if its posible to spoof the device id of the equivlent quadro card to allow installing quadro drivers in to the VM and get around these limitations. 


Steps:

1. Boot in to windows and use Nvida control panel to save the EEID of the laptop screen and any external moniters that may be used. Alternativly use the EEID file in this repo if sutable.
2. Enable switchable graphics, direct output mode and virtualisation features in bios.
3. Boot in to fresh install of ubuntu 21.04 or simmiler.
4. Use "lspci -nn | grep 01:00." to find the pci bus number Vendor ID and model ID of your dGPU and assosiated hardware. For the Dell 7710 the GPU pci bus number is 01:00.0 and its assostiated Audio device is 01:00.1.   The Vendor and model ID's are inside the square brackets, [10de:13f8] and [10de:0fbb]. If there are more devices assosiated with the dGPU such as a usb controler, note the vendor and model IDs also.

          $ lspci -nnk
          
          01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GM204GLM [Quadro M5000M / M5000 SE] [10de:13f8] (rev a1)
          01:00.1 Audio device [0403]: NVIDIA Corporation GM204 High Definition Audio Controller [10de:0fbb] (rev a1)
          
          
5. Add kernel parameters "intel_iommu=on kvm.ignore_msrs=1 vfio_pci.ids=10de:13f8,10de:0fbb" added to GRUB_CMDLINE_LINUX_DEFAULT in /etc/default/gub, replacing the vfio_pci.ids with your ID's from step 4

          $ sudo nano /etc/default/grub
          
          # If you change this file, run 'update-grub' afterwards to update
          # /boot/grub/grub.cfg.
          # For full documentation of the options in this file, see:
          #   info -f grub -n 'Simple configuration'

          GRUB_DEFAULT=0
          GRUB_TIMEOUT_STYLE=hidden
          GRUB_TIMEOUT=10
          GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
          GRUB_CMDLINE_LINUX_DEFAULT="quiet splash intel_iommu=on kvm.ignore_msrs=1 vfio_pci.ids=10de:13f8,10de:0fbb"
          GRUB_CMDLINE_LINUX=""



6. Update Grub:

          $ sudo update-grub
          
7. Install packages used for virtualisation:

          $ sudo apt install libvirt-daemon-system libvirt-clients qemu-kvm qemu-utils qemu-efi virt-manager ovmf

8. Enable kernal modules for virtualisation and VFIO:

          $ sudo nano /etc/initramfs-tools/modules
          
          kvm
          kvm_intel
          vfio
          vfio_iommu_type1
          vfio_pci
          vfio_virqfd
          vhost-net


9. Update initramfs 

          $ sudo update-initramfs -u**
          
10. Install propriotory nvidia drivers and then prime-select intel and reboot.

          $ sudo prime-select intel
          
11. Dump nvidia GPU Vbios to a location accesible by libvirt:

          sudo -i
          mkdir /usr/share/vgabios
          echo 1 > /sys/bus/pci/devices/0000:01:00.0/rom
          cat /sys/bus/pci/devices/0000:01:00.0/rom > /usr/share/vgabios/dgpu_vbios.rom
          echo 0 > /sys/bus/pci/devices/0000:01:00.0/rom

12. Copy SSDT_BAT.dat to /usr/share/vgabios/ ( good location as libvirt can access this location)

13. If the Nvidia GPU will also be used with the host, remove any nvida and nouveau driver blacklists inside /etc/modprobe.d/ and /usr/lib/modprobe.d/ 

15. Create VM using virtmanger,  with usual recomended settings for high performance VN ( cpu pinning virtio network, disks etc )
16. add PCI device for nvidia GPU
17. allow edit xml preference and select overview > XML to editand add the folowing

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
    
    
23. Start the VM, install windows etc install propritory nvidia drivers. connect external display,  use nvida control pannel to copy EEID information,  alternativly boot in to windows baremetal without gpu switching bios option and copy laptop displays EEID**
24. Load EEID file again ( works kind of like a dummy HDMI plug?) **
25. set up looking glass,  test rebooting VM withougt display attached.  looking glass should still work**
26. reboot to bios,  disable direct output mode**
27. bind GPU and HDMI audio to VFIO using bind-gpu-vfio.sh**
28. unbind GPU and HDMI audio from VFIO and rescan using remove-rescan.sh**
29. bind HDMI audio to VFIO using bind-HDMI_audio-vfio.sh**
30. start VM and looking glass**
31.  TADA! 

  

Enableing Hugepages ( From bryansteiner)
 1. sudo apt install libhugetlbfs-bin**
 2. Add VFIO-Tools Hook Helper**

                   $ mkdir /etc/libvirt/hooks
                   $ sudo wget 'https://raw.githubusercontent.com/PassthroughPOST/VFIO-Tools/master/libvirt_hooks/qemu' \
                     -O /etc/libvirt/hooks/qemu
                   $ sudo chmod +x /etc/libvirt/hooks/qemu
                   $ sudo service libvirtd restart
