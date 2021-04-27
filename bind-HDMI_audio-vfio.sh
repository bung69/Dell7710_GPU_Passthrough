#!/bin/bash
echo "10de 0fbb" > /sys/bus/pci/drivers/vfio-pci/new_id
echo "0000:01:00.1" > /sys/bus/pci/devices/0000:01:00.1/driver/unbind
echo "0000:01:00.1" > /sys/bus/pci/drivers/vfio-pci/bind
echo "10de 0fbb" > /sys/bus/pci/drivers/vfio-pci/remove_id
