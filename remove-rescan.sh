#!/bin/bash
echo 1 > /sys/bus/pci/devices/0000:01:00.0/remove
echo 1 > /sys/bus/pci/devices/0000:01:00.1/remove
echo 1 > /sys/bus/pci/rescan
