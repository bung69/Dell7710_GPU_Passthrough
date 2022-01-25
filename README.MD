Dell Precision 7710 with Nvidia Quadro m5000m VFIO GPU passthrough using Kubnuntu / probably other Debian based distros.

Should also be posible with non Quadro GPUs either without looking glass and using an external display or using a dummy HDMI device and not using external displays.  Please let me know if it is posible to load EEID for non Quadro GPU's or if its posible to spoof the device id of the equivlent quadro card to allow installing quadro drivers in to the VM and get around these limitations. 


Steps:

1. Boot in to windows and use Nvida control panel to save the EEID of the laptop screen and any external moniters that may be used. Alternativly use the EEID file in this repo if sutable.
2. Enable switchable graphics, direct output mode and virtualisation features in bios.
3. Boot in to fresh install of kubuntu 21.04 or simmiler.
4. Use ```lspci -nnk``` to find the pci bus number, sub-Vendor ID and  sub-device ID of your dGPU and assosiated hardware. For the Dell 7710 the GPU pci bus number is 01:00.0 and its assostiated Audio device is 01:00.1.   The sub Vendor and sub model ID's are inside the square brackets, on the second line for each device  [1028:06da] and [1028:06da]. If there are more devices assosiated with the dGPU such as a usb controler, note the vendor and model IDs also.

```
$ lspci -nnnk

01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GM204GLM [Quadro M5000M / M5000 SE] [10de:13f8] (rev a1)
        Subsystem: Dell GM204GLM [Quadro M5000M / M5000 SE] **[1028:06da]**
        Kernel driver in use: vfio-pci
        Kernel modules: nvidiafb, nouveau
01:00.1 Audio device [0403]: NVIDIA Corporation GM204 High Definition Audio Controller [10de:0fbb] (rev a1)
        Subsystem: Dell GM204 High Definition Audio Controller **[1028:06da]**
        Kernel driver in use: vfio-pci
        Kernel modules: snd_hda_intel
```      
x-pci-sub-vendor-id=0x1028,x-pci-sub-device-id=0x06da
          
5. Add kernel parameters "intel_iommu=on kvm.ignore_msrs=1 vfio_pci.ids=10de:13f8,10de:0fbb" added to GRUB_CMDLINE_LINUX_DEFAULT in /etc/default/gub, replacing the vfio_pci.ids with your ID's from step 4

```
       $ sudo nano /etc/default/grub

       # If you change this file, run 'update-grub' afterwards to update
       # /boot/grub/grub.cfg.
       # For full documentation of the options in this file, see:
       #   info -f grub -n 'Simple configuration'

       GRUB_DEFAULT=0
       GRUB_TIMEOUT_STYLE=hidden
       GRUB_TIMEOUT=10
       GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
       GRUB_CMDLINE_LINUX_DEFAULT="quiet splash intel_iommu=on kvm.ignore_msrs=1 vfio-pci.ids=10de:13f8,10de:0fbb"
       GRUB_CMDLINE_LINUX=""
```

6. Update Grub:

       sudo update-grub
          
7. Install packages used for virtualisation:

       sudo apt install libvirt-daemon-system libvirt-clients qemu-kvm qemu-utils qemu-efi virt-manager ovmf

8. Enable kernal modules for virtualisation and VFIO:

       sudo nano /etc/initramfs-tools/modules
          
       kvm
       kvm_intel
       vfio
       vfio_iommu_type1
       vfio_pci
       vfio_virqfd
       vhost-net


9. Update initramfs 

       sudo update-initramfs -u
          
10. Install proprietary nvidia drivers and then run prime-select intel and reboot

       sudo prime-select intel
          
11. Dump nvidia GPU Vbios to a location accesible by libvirt:

       sudo -i
       mkdir /usr/share/vgabios
       echo 1 > /sys/bus/pci/devices/0000:01:00.0/rom
       cat /sys/bus/pci/devices/0000:01:00.0/rom > /usr/share/vgabios/dgpu_vbios.rom
       echo 0 > /sys/bus/pci/devices/0000:01:00.0/rom

12. Copy SSDT_BAT.dat to /usr/share/vgabios/ ( good location as libvirt can allready access this location)

13. If the Nvidia GPU will also be used with the host, remove any nvida and nouveau driver blacklists inside /etc/modprobe.d/ and /usr/lib/modprobe.d/ 

15. Create VM using virtmanger,  with usual recomended settings for high performance VM ( cpu pinning virtio network, disks etc )
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

At the bottom before </domain> replacing the vfio_pci.ids with your ID's from step 4, but proceded with "0X"

       <qemu:commandline>
         <qemu:arg value="-set"/>
         <qemu:arg value="device.hostdev0.x-pci-sub-vendor-id=0x1028"/>
         <qemu:arg value="-set"/>
         <qemu:arg value="device.hostdev0.x-pci-sub-device-id=0x06da"/ 
         <qemu:arg value="-acpitable"/>
         <qemu:arg value="file=/usr/share/vgabios/SSDT_BAT.dat"/>
       </qemu:commandline>
        
        
        
19. The PCI address of the GPU inside the VM must match the real hardware, assuming the the real hardware address is 0000:01:00.0,  Click PCI 0000:01:00.0 on the left, then XML and replace with: 


        <hostdev mode="subsystem" type="pci" managed="yes">
          <driver name="vfio"/>
          <source>
            <address domain="0x0000" bus="0x01" slot="0x00" function="0x0"/>
          </source>
          <rom bar="on" file="/usr/share/vgabios/dgpu_vbios.rom"/>
          <address type="pci" domain="0x0000" bus="0x01" slot="0x00" function="0x0" multifunction="on"/>
        </hostdev>
    
    
23. Start the VM, install windows, install propritory nvidia drivers. Load EEID
26. Set up looking glass, test rebooting VM without display attached.  looking glass should still work**
27.If using a Quadro Reboot to bios,  disable direct output mode
31. start VM and looking glass**
32.  TADA! 

  

Enable Dynamic Hugepages, dynamic GPU binding and CPU performance Govener
 1. sudo apt install libhugetlbfs-bin ( ?? ) 
 2. Add Hooks Directory to /etc/libvert/ and edit /etc/libbirt/hooks/kvm.conf  pci address if needed.    
 3. Change default Hugepage size to 1G if supported. Add default_hugepagesz=1G to GRUB_CMDLINE_LINUX_DEFAULT in /etc/default/grub


          $ sudo nano /etc/default/grub
          
          GRUB_CMDLINE_LINUX_DEFAULT="quiet splash intel_iommu=on kvm.ignore_msrs=1 vfio_pci.ids=10de:13f8,10de:0fbb default_hugepagesz=1G"

                  
 5.Update Grub:

          $ sudo update-grub
          
 6. Add to VM XML
 
          <memoryBacking>
            <hugepages>
              <page size="1048576" unit="KiB"/>
            </hugepages>
          </memoryBacking>

   

