target = iPhoneSimulator

platform = darwin
arch = i386
mode = fast
run-proguard = true

cc = /Developer/Platforms/$(target).platform/Developer/usr/bin/llvm-gcc-4.2

javac = "$(JAVA_HOME)/bin/javac"
jar = "$(JAVA_HOME)/bin/jar"

flags = -isysroot \
	/Developer/Platforms/$(target).platform/Developer/SDKs/$(target)4.3.sdk \
	-arch i386

cflags = $(flags) -D__IPHONE_OS_VERSION_MIN_REQUIRED=30202 \
	-fobjc-abi-version=2 -fobjc-legacy-dispatch \
	-I/System/Library/Frameworks/JavaVM.framework/Headers

lflags = $(flags) -Xlinker -objc_abi_version -Xlinker 2 -framework UIKit \
	-framework Foundation -framework CoreGraphics

objects = \
	build/boot.o \
	build/hello.o \
	build/bootimage-bin.o \
	build/codeimage-bin.o

ifneq ($(mode),fast)
	options := -$(mode)
endif

options := $(options)-bootimage

build = build
src = src
stage1 = $(build)/stage1
stage2 = $(build)/stage2
vm = ../avian
vm-build = $(vm)/build/$(platform)-$(arch)$(options)
converter = $(vm-build)/binaryToObject
bootimage-generator = $(vm-build)/bootimage-generator
proguard = ../proguard4.6beta1/lib/proguard.jar

vm-objects-dep = $(build)/vm-objects.d
vm-classes-dep = $(build)/vm-classes.d

java-classes = $(foreach x,$(1),$(patsubst $(2)/%.java,$(3)/%.class,$(x)))

main-class = Hello
all-javas := $(shell find $(src) -name '*.java')
javas = $(src)/$(main-class).java
classes = $(call java-classes,$(javas),$(src),$(stage1))

bootimage-bin = $(build)/bootimage.bin
bootimage-object = $(build)/bootimage-bin.o

codeimage-bin = $(build)/codeimage.bin
codeimage-object = $(build)/codeimage-bin.o

.PHONY: build
build: make-vm $(build)/hello.ipa

.PHONY: run
run: build
	/Developer/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone\ Simulator.app/Contents/MacOS/iPhone\ Simulator -SimulateApplication $(build)/Release-iphonesimulator/hello.app

.PHONY: make-vm
make-vm:
	(cd $(vm) && \
	 make mode=$(mode) arch=$(arch) platform=$(platform) bootimage=true)

$(classes): $(all-javas)
	@rm -rf $(stage1)
	@mkdir -p $(stage1)
	$(javac) -d $(stage1) -sourcepath $(src) \
		-bootclasspath $(vm-build)/classpath $(javas)

$(vm-objects-dep):
	@mkdir -p $(build)/vm-objects
	(wd=$$(pwd) && cd $(build)/vm-objects \
		&& ar x  $${wd}/$(vm-build)/libavian.a)
	@touch $(@)

$(vm-classes-dep): $(classes)
	cp -r $(vm-build)/classpath/* $(stage1)
	@touch $(@)

$(build)/hello.ipa: hello/build/Release-iphonesimulator/hello.app/hello
	#xcrun -sdk iphoneos PackageApplication -v $(build)/hello.app -o $(@)
	touch $(@)

hello/build/Release-iphonesimulator/hello.app/hello: hello/build/libhello.a
	(cd hello && xcodebuild -sdk iphonesimulator4.3 build)

$(build)/%.o: $(src)/%.m
	@mkdir -p $(dir $(@))
	$(cc) $(cflags) -c $(<) -o $(@)

$(build)/%.o: $(src)/%.c
	@mkdir -p $(dir $(@))
	$(cc) $(cflags) -c $(<) -o $(@)

$(stage2).d: $(classes) $(vm-classes-dep)
	@mkdir -p $(dir $(@))
ifeq ($(run-proguard),true)
	rm -rf $(stage2)
	java -jar $(proguard) \
		-injars $(stage1) \
		-outjars $(stage2) \
		-dontusemixedcaseclassnames \
		@$(vm)/vm.pro \
		@hello.pro
endif
	@touch $(@)

$(bootimage-bin): $(stage2).d
	$(bootimage-generator) $(stage2) $(@) $(codeimage-bin)

$(bootimage-object): $(bootimage-bin) $(converter)
	@echo "creating $(@)"
	$(converter) $(<) $(@) _binary_bootimage_bin_start \
		_binary_bootimage_bin_end $(platform) $(arch) 8 \
		writable

$(codeimage-object): $(bootimage-bin) $(converter)
	@echo "creating $(@)"
	$(converter) $(codeimage-bin) $(@) _binary_codeimage_bin_start \
		_binary_codeimage_bin_end $(platform) $(arch) 8 \
		executable

hello/build/libhello.a: $(objects) $(vm-objects-dep)
	@mkdir -p $(dir $(@))
	rm -rf $(@)
	mkdir -p $(build)/libhello
	cp $(objects) $(build)/vm-objects/*.o $(build)/libhello
	(cd $(build)/libhello && ar cru ../../$(@) *)
	ranlib $(@)

.PHONY: clean
clean:
	rm -rf $(build)
