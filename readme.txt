This is a simple example of how to use Avian on iOS.  These are the
steps required to build it:

  1. Get Avian and check out the "ios" branch:

    git clone git://oss.readytalk.com/avian.git
    git checkout ios

  2. Get this example, if you don't already have it:

    git clone git://oss.readytalk.com/hello-ios.git

  3. Build the example.  The default target is an iPhoneOS device,
  which requires that XCode be configured with a valid iOS developer
  certificate. 

    cd hello-ios && make

  The codesign step may fail with the message "User interaction is not
  allowed."  To fix this, you'll need to unlock your keychain and try
  again:

    security unlock-keychain ~/Library/Keychains/login.keychain

  Alternatively, you can target the iPhoneSimulator instead, which
  does not require code signing:

    make sim=true

  You can also run the result in the simulator:
  
    make sim=true run

Please send an email to avian@googlegroups.com if you have any
questions or comments.
