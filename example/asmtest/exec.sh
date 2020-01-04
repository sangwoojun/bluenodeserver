echo "Building..."
cd datagen
make

echo ""
echo ""
echo ""
echo ""
echo "***************************************************************"
echo "** Running Benchmark 'max'"
echo "***************************************************************"

./obj/datagen max 32

mv ./obj/dataset.bin ../obj
mv ./obj/mmap.txt ../

cd ..

make max

echo ""
echo ""
echo "** Emulator starting!"
echo ""
echo ""
./emulator/obj/bsim

echo ""
echo ""
echo ""
echo ""
echo "***************************************************************"
echo "** Running Benchmark 'gcd'"
echo "***************************************************************"

cd datagen

./obj/datagen gcd 2

mv ./obj/dataset.bin ../obj
mv ./obj/mmap.txt ../

cd ..

make gcd

echo ""
echo ""
echo "** Emulator starting!"
echo ""
echo ""
./emulator/obj/bsim

echo ""
echo ""
echo ""
echo ""
echo "***************************************************************"
echo "** Running Benchmark 'sort'"
echo "***************************************************************"

cd datagen

./obj/datagen sort 8

mv ./obj/dataset.bin ../obj
mv ./obj/mmap.txt ../

cd ..

make sort

echo ""
echo ""
echo "** Emulator starting!"
echo ""
echo ""
./emulator/obj/bsim
