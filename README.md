Avian on iOS example
====================

[![Build Status](https://travis-ci.org/ReadyTalk/hello-ios.png?branch=master)](https://travis-ci.org/ReadyTalk/hello-ios)

This is a simple example of how to use Avian on iOS.  These are the
steps required to build it:

__1.__ Get Avian:  

    $ git clone https://github.com/ReadyTalk/avian

__2.__ Get ProGuard:

    $ curl -Of http://oss.readytalk.com/avian-web/proguard4.11.tar.gz
    $ tar xzf proguard4.11.tar.gz

__3.__ Get this example, if you don't already have it:

    $ git clone https://github.com/ReadyTalk/hello-ios

__4.__ Build the example.  The default target is an iPhoneOS 64 bit simulator. Uncomment related lines to build for another target.

    $ cd hello-ios && ./build-hello.sh

When building for an iPhoneOS device, the codesign step may fail with the message "User interaction is not
allowed."  To fix this, you'll need to unlock your keychain and try
again:  

    $ security unlock-keychain ~/Library/Keychains/login.keychain

Please send an email to avian@googlegroups.com if you have any
questions or comments.
