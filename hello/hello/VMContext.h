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


// we say hello to java, and get back a "hello ios" greeting, drawn to the screen region (via hello.m)
-(void)helloJava:(CGRect)rect;

@end
