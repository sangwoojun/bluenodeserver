rm binary.bin
#objdump -h binary.elf
objdump -h binary.elf | grep " \." |  awk '{print "dd if=binary.elf bs=1 count=$[0x" $3 "] skip=$[0x" $6 "] seek=$[0x" $4 "] of=binary.bin";}' | bash
