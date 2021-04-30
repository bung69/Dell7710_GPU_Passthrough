#!/bin/bash

# A script to aid binding an Nvidia GPU to various drivers or power on/off


#varables
GPUpci="01:00.0"
GPUid="10de 13f8"
AUDIOpci="01:00.1"
AUDIOid="10de 0fbb"

GPUdriver=$(lspci -nnk -s $GPUpci |grep "Kernel driver in use:" | awk '{ print $5 }')


################################################################################
# Help                                                                         #
################################################################################
hlp()  {
   # Display Help
   echo "GPU.sh help"
   echo ""
   echo "Options:"
   echo ""
   echo "help       -       Displays this help"
   echo "vfio       -       Binds GPU to vfio"
   echo "nouveau    -       Binds GPU to nouveau "
   echo "nvidia     -       Binds GPU to nvidia"
   echo "unbind     -       Unbinds GPU"
   echo "on         -       Power GPU on"
   echo "off        -       Power GPU off"

}

if [ -z "$1" ]
then
 hlp
fi

################################################################################
# Functions                                                                    #
################################################################################

vfio() {
	if ! $(lspci -H1 | grep --quiet NVIDIA)
	then
		on
		sleep 1
	fi
	unbind
	echo "$GPUid" > /sys/bus/pci/drivers/vfio-pci/new_id
    GPUdriver=$(lspci -nnk -s $GPUpci |grep "Kernel driver in use:" | awk '{ print $5 }')
    if  [ -z "$GPUdriver" ]
		then
		    echo 0000:$GPUpci > /sys/bus/pci/drivers/vfio-pci/bind
        fi
    GPUdriver=$(lspci -nnk -s $GPUpci |grep "Kernel driver in use:" | awk '{ print $5 }')
    if ! [ "vfio-pci" == "$GPUdriver" ]
    then
        echo "Cant bind $GPUdriver driver"
        exit
    fi
    echo "$GPUid" > /sys/bus/pci/drivers/vfio-pci/remove_id
    echo "$GPUdriver Bound"


}

nouveau() {
	if ! $(lspci -H1 | grep --quiet NVIDIA)
	then
		on
		sleep 1
	fi
	unbind
	modprobe nouveau
	echo "$GPUid" > /sys/bus/pci/drivers/nouveau/new_id
    GPUdriver=$(lspci -nnk -s $GPUpci |grep "Kernel driver in use:" | awk '{ print $5 }')
    if  [ -z "$GPUdriver" ]
		then
		    echo 0000:$GPUpci > /sys/bus/pci/drivers/nouveau/bind
        fi
    GPUdriver=$(lspci -nnk -s $GPUpci |grep "Kernel driver in use:" | awk '{ print $5 }')
    if ! [ "nouveau" == "$GPUdriver" ]
    then
        echo "Cant bind $GPUdriver driver"
        exit
    fi
    echo "$GPUid" > /sys/bus/pci/drivers/nouveau/remove_id
    echo "$GPUdriver Bound"

}

nvidia() {
	if ! $(lspci -H1 | grep --quiet NVIDIA)
	then
		on
		sleep 1
	fi
	unbind
	modprobe nvidia
	echo "$GPUid" > /sys/bus/pci/drivers/nvidia/new_id
	sleep 1
    GPUdriver=$(lspci -nnk -s $GPUpci |grep "Kernel driver in use:" | awk '{ print $5 }')
    if  [ -z "$GPUdriver" ]
		then
		    echo 0000:$GPUpci > /sys/bus/pci/drivers/nvidia/bind
        fi
    GPUdriver=$(lspci -nnk -s $GPUpci |grep "Kernel driver in use:" | awk '{ print $5 }')
    if ! [ "nvidia" == "$GPUdriver" ]
    then
        echo "Cant bind $GPUdriver driver"
        exit
    fi
    echo "$GPUid" > /sys/bus/pci/drivers/nvidia/remove_id
    echo "$GPUdriver Bound"


}

unbind() {
# Checks if nvidia modual is loaded and unloads it as it can cause a crash when unbinding vfio-pci
    if ! [ -z "$(lsmod | grep nvidia)" ]
    then
        if [ "nvidia" == "$GPUdriver" ]
        then
            echo 0000:$GPUpci > /sys/bus/pci/devices/0000\:01\:00.0/driver/unbind
            sleep 1
            GPUdriver=$(lspci -nnk -s $GPUpci |grep "Kernel driver in use:" | awk '{ print $5 }')
            if [ "nvidia" == "$GPUdriver" ]
            then
                echo "cant unbind $GPUdriver driver,  is something using it?"
                exit
            fi
        fi
        modprobe -r nvidia_drm
        modprobe -r nvidia_uvm
        modprobe -r nvidia
        sleep 1
        if  ! [ -z "$(lsmod | grep nvidia)" ]
        then
            echo "Cant unload nvidia modules,  is something using them?"
            exit
        fi
    fi


    # Try to unbind attached driver
	if [ -f /sys/bus/pci/devices/0000\:01\:00.0/driver/unbind ]
	then
		echo 0000:$GPUpci > /sys/bus/pci/devices/0000\:01\:00.0/driver/unbind
		GPUdriver=$(lspci -nnk -s $GPUpci |grep "Kernel driver in use:" | awk '{ print $5 }')
		if ! [ -z "$GPUdriver" ]
		then
		    echo "Cant unbind $GPUdriver driver,  is something using it?"
            exit
        fi
        echo "GPU Driver Unbound"

	fi

}

on() {
	echo '\_SB_.PCI0.PEG0.PEGP._ON' > /proc/acpi/call
	if [ -f /sys/bus/pci/devices/0000\:01\:00.0/remove ]
	then
		echo 1 > /sys/bus/pci/devices/0000\:01\:00.0/remove
	fi
	if [ -f /sys/bus/pci/devices/0000\:01\:00.1/remove ]
	then
		echo 1 > /sys/bus/pci/devices/0000\:01\:00.1/remove
	fi
	echo 1 > /sys/bus/pci/rescan

}

off() {
	unbind
	echo '\_SB_.PCI0.PEG0.PEGP._OFF' > /proc/acpi/call

}

case "$1" in
	vfio)
		vfio
		;;
	nouveau)
		nouveau
		;;
	nvidia)
		nvidia
		;;
	unbind)
		unbind
		;;
	on)
		on
		;;
	off)
		off
		;;
    help)
        hlp
		;;
esac
