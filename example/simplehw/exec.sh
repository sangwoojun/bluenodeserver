date
echo "Cleaning..."
make clean
echo ""
date
echo "Building..."
make 
echo ""
date
echo "Running..."
./obj/bsim
