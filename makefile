platform = darwin
mode = fast
process = compile
run-proguard = true

ifeq ($(sim),true)
	target = iPhoneSimulator
	sdk = iphonesimulator$(ios-version)
	arch = i386
	arch-flag = -arch i386
	release = Release-iphonesimulator
else
	target = iPhoneOS
	sdk = iphoneos$(ios-version)
	arch = arm
	arch-flag = -arch armv7
	release = Release-iphoneos
endif

developer-dir := $(shell if test -d /Developer; then echo /Developer; \
	else echo /Applications/Xcode.app/Contents/Developer; fi)

sdk-dir = $(developer-dir)/Platforms/$(target).platform/Developer/SDKs

ios-version := $(shell \
		if test -d $(sdk-dir)/$(target)7.1.sdk; then echo 7.1; \
	elif test -d $(sdk-dir)/$(target)7.0.sdk; then echo 7.0; \
	elif test -d $(sdk-dir)/$(target)6.1.sdk; then echo 6.1; \
	elif test -d $(sdk-dir)/$(target)6.0.sdk; then echo 6.0; \
	else echo; fi)

ifeq ($(ios-version),)
	x := $(error "couldn't find SDK")
endif

cc = cc

javac = "$(JAVA_HOME)/bin/javac"
java = "$(JAVA_HOME)/bin/java"
jar = "$(JAVA_HOME)/bin/jar"

flags = -isysroot $(sdk-dir)/$(target)$(ios-version).sdk \
	$(arch-flag)

cflags = $(flags) -D__IPHONE_OS_VERSION_MIN_REQUIRED=30202 -DRESOURCES \
	-fobjc-abi-version=2 -fobjc-legacy-dispatch \
	-I/System/Library/Frameworks/JavaVM.framework/Headers

ifeq ($(mode),debug)
	cflags += -O0 -g3
endif
ifeq ($(mode),debug-fast)
	cflags += -O0 -g3 -DNDEBUG
endif
ifeq ($(mode),fast)
	cflags += -O3 -g3 -DNDEBUG
endif
ifeq ($(mode),small)
	cflags += -Os -g3 -DNDEBUG
endif

lflags = $(flags) -Xlinker -objc_abi_version -Xlinker 2 \
	-framework Carbon -framework Foundation -lz

objects = \
	build/boot.o \
	build/hello.o

ifneq ($(mode),fast)
	options := -$(mode)
endif

ifeq ($(process),compile)
	options := $(options)-bootimage
	bootimage = bootimage=true
	cflags += -DBOOT_IMAGE
	objects += \
		build/bootimage-bin.o \
		build/codeimage-bin.o
else
	options := $(options)-interpret
	objects += \
		build/boot-jar.o
endif

ifneq ($(openjdk),)
	ifneq ($(openjdk-src),)
		options := $(options)-openjdk-src
	else
		options := $(options)-openjdk
	endif

	proguard-flags += -include $(vm)/openjdk.pro
else
	proguard-flags += -overloadaggressively	
endif

ifneq ($(android),)
	options := $(options)-android

	android-archives = \
		$(android)/external/icu4c/lib/libicui18n.a \
		$(android)/external/icu4c/lib/libicuuc.a \
		$(android)/external/icu4c/lib/libicudata.a \
		$(android)/external/fdlibm/libfdm.a \
		$(android)/external/expat/.libs/libexpat.a \
		$(android)/openssl-upstream/libssl.a \
		$(android)/openssl-upstream/libcrypto.a

	classpath-lflags = $(android-archives) -lstdc++

	proguard-flags += -include $(vm)/android.pro -dontoptimize -dontobfuscate
endif

ifeq ($(process),compile)
	vm-targets = \
		build/$(platform)-$(arch)$(options)/bootimage-generator \
		build/$(platform)-$(arch)$(options)/binaryToObject/binaryToObject \
		build/$(platform)-$(arch)$(options)/classpath.jar \
		build/$(platform)-$(arch)$(options)/libavian.a
endif

xcode-build = hello/build
build = build
src = src
stage1 = $(build)/stage1
stage2 = $(build)/stage2
resources = $(build)/resources
vm = ../avian
vm-build = $(vm)/build/$(platform)-$(arch)$(options)
converter = $(vm-build)/binaryToObject/binaryToObject
bootimage-generator = $(vm-build)/bootimage-generator
proguard = ../proguard4.11/lib/proguard.jar

resources-object = $(build)/resources-jar.o

vm-objects-dep = $(build)/vm-objects.d
vm-classes-dep = $(build)/vm-classes.d

java-classes = $(foreach x,$(1),$(patsubst $(2)/%.java,$(3)/%.class,$(x)))

main-class = Hello
all-javas := $(shell find $(src) -name '*.java')
all-properties := $(shell find $(src) -name '*.properties')
javas = $(src)/$(main-class).java
classes = $(call java-classes,$(javas),$(src),$(stage1))

bootimage-object = $(build)/bootimage-bin.o

codeimage-object = $(build)/codeimage-bin.o

boot-jar = $(build)/boot.jar
boot-object = $(build)/boot-jar.o

.PHONY: build
build: make-vm $(xcode-build)/$(release)/hello.app/hello

.PHONY: run
run: build
	/Developer/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone\ Simulator.app/Contents/MacOS/iPhone\ Simulator -SimulateApplication $(xcode-build)/Release-iphonesimulator/hello.app

.PHONY: make-vm
make-vm:
	(cd $(vm) && make arch=$(arch) platform=$(platform) process=$(process) \
		"openjdk=$(openjdk)" "openjdk-src=$(openjdk-src)" $(bootimage) ios=true \
		android=$(android) $(vm-targets))

.PHONY: xcode-build
xcode-build:
	(cd hello && xcodebuild -sdk $(sdk) build)

$(classes): $(all-javas) $(all-properties)
	@rm -rf $(stage1)
	@mkdir -p $(stage1)
	$(javac) -d $(stage1) -sourcepath $(src) \
		-bootclasspath $(vm-build)/classpath $(javas)
	cp $(all-properties) $(stage1)/

$(vm-objects-dep):
	@mkdir -p $(build)/vm-objects
	(wd=$$(pwd) && cd $(build)/vm-objects \
		&& ar x $${wd}/$(vm-build)/libavian.a)
	@touch $(@)

$(vm-classes-dep): $(classes)
	cp -r $(vm-build)/classpath/* $(stage1)
	@touch $(@)

$(build)/resources.jar: $(resources).d
	wd=$$(pwd); cd $(resources) && jar cf $${wd}/$(build)/resources.jar *

$(build)/resources-jar.o: $(build)/resources.jar
	$(converter) $(<) $(@) _binary_resources_jar_start \
		_binary_resources_jar_end $(platform) $(arch) 1

$(xcode-build)/$(release)/hello.app/hello: $(build)/libhello.list xcode-build

$(build)/%.o: $(src)/%.m
	@mkdir -p $(dir $(@))
	$(cc) $(cflags) -c $(<) -o $(@)

$(build)/%.o: $(src)/%.c
	@mkdir -p $(dir $(@))
	$(cc) $(cflags) -c $(<) -o $(@)

$(stage2).d: $(classes) $(vm-classes-dep)
	@mkdir -p $(dir $(@))
	rm -rf $(stage2)
ifeq ($(run-proguard),true)
	$(java) -jar $(proguard) \
		-injars $(stage1) \
		-outjars $(stage2) \
		-dontusemixedcaseclassnames \
		-dontwarn \
		-dontoptimize \
		-dontobfuscate \
		@$(vm)/vm.pro \
		$(proguard-flags) \
		@hello.pro
else
	mkdir -p $(stage2)
	cp -r $(stage1)/* $(stage2)
endif
	@touch $(@)

$(resources).d: $(stage2).d
	@mkdir -p $(dir $(@))
	rm -rf $(resources)
	mkdir -p $(resources)
	wd=$$(pwd); cd $(stage2) && find . -type f -not -name '*.class' \
		| xargs tar cf - | tar xf - -C $${wd}/$(resources)
	@touch $(@)

$(bootimage-object): $(stage2).d
	$(bootimage-generator) -cp $(stage2) -bootimage $(@) \
		-codeimage $(codeimage-object)

$(boot-jar): $(stage2).d
	wd=$$(pwd); cd $(stage2) && jar cf $${wd}/$(boot-jar) *

$(boot-object): $(boot-jar)
	$(converter) $(<) $(@) _binary_boot_jar_start \
		_binary_boot_jar_end $(platform) $(arch) 1

$(build)/libhello.list: $(objects) $(vm-objects-dep) $(resources-object) \
		$(android-archives)
	@mkdir -p $(dir $(@))
	rm -rf $(@)
	mkdir -p $(build)/libhello
	cp $(objects) $(build)/vm-objects/*.o $(resources-object) $(build)/libhello
	(cd $(build)/libhello \
		&& for x in $(android-archives); do ar x $${x}; done)
	for x in $(build)/libhello/*; do echo ../$${x}; done > $(@)

$(build)/main: $(build)/main.o $(objects) $(vm-objects-dep)
	$(cc) $(lflags) $(build)/main.o $(objects) $(build)/vm-objects/*.o -o $(@)

.PHONY: clean
clean:
	rm -rf $(build) $(xcode-build)
