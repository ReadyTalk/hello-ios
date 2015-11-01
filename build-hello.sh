make clean
cd ..
cd avian
make clean
cd ..
cd hello-ios

# Note: Set ARCHITECTURES to ARCHS_STANDARD_32_BIT in the Xcode project's build settings 
# (via "others" menu option)to force 32 bit if you want to run 32 bit 
# build on 64 bit devices / simulators.

make arch=x86_64 sim=true
#make arch=arm64
#make arch=arm
#make arch=i386 sim=true