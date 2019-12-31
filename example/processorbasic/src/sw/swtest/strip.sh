rm test.bin
objdump -h test | grep "\." |  awk '{print "dd if=test bs=1 count=$[0x" $3 "] skip=$[0x" $6 "] >> test.bin";}' | bash
