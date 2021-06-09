nano slic-dump

    #!/bin/bash

    set -e

    cat /sys/firmware/acpi/tables/SLIC > slic.bin
    cat /sys/firmware/acpi/tables/MSDM > msdm.bin
    dmidecode -t 0 -u | grep $'^\t\t[^"]' | xargs -n1 | perl -lne 'printf "%c", hex($_)' > smbios_type_0.bin
    dmidecode -t 1 -u | grep $'^\t\t[^"]' | xargs -n1 | perl -lne 'printf "%c", hex($_)' > smbios_type_1.bin



add to xml:


    domain.xml
    <domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
      <!-- ... -->
      <qemu:commandline>
        <qemu:arg value='-acpitable'/>
        <qemu:arg value='file=/some/path/slic.bin'/>
        <qemu:arg value='-acpitable'/>
        <qemu:arg value='file=/some/path/msdm.bin'/>
        <qemu:arg value='-smbios'/>
        <qemu:arg value='file=/some/path/smbios_type_0.bin'/>
        <qemu:arg value='-smbios'/>
        <qemu:arg value='file=/some/path/smbios_type_1.bin'/>
      </qemu:commandline>
    </domain>
