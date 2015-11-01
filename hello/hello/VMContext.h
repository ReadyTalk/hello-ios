//
//  VMContext.h
//  hello
//
//  Created by Benjamin Stadin on 01.11.15.
//  Copyright © 2015 HDM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#include <jni.h>

@interface VMContext : NSObject

@property JavaVM* vm;
@property (readonly) JNIEnv* env;
@property jobject peer;
@property jmethodID draw;
@property jmethodID dispose;

@property (readonly) BOOL loaded;


// we say hello to java, and get a greet "hello ios" greeting back to our screen (via hello.m)
-(void)helloJava:(CGRect)rect;

@end
