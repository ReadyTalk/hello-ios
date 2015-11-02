#import "VMContext.h"

extern int hello_ios_use_lzma;

static JNIEnv*
getEnv(JavaVM* vm)
{
    void* env;
    if ((*vm)->GetEnv(vm, &env, JNI_VERSION_1_2) == JNI_OK) {
        return (JNIEnv*) env;
    } else {
        return 0;
    }
}

@interface VMContext ()

@property (assign) BOOL loaded;
@property (readwrite) JNIEnv* env;

@end

@implementation VMContext

- (instancetype)init
{
    self = [super init];
    if (self) {
        BOOL res = [self loadVM];
        NSAssert(res, @"Failed to init virtual machine context");
    }
    return self;
}

-(BOOL)loadVM
{
    JavaVMInitArgs vmArgs;
    vmArgs.version = JNI_VERSION_1_2;
    vmArgs.nOptions = 5;
    vmArgs.ignoreUnrecognized = JNI_TRUE;
    
    JavaVMOption options[vmArgs.nOptions];
    vmArgs.options = options;
    
    if (hello_ios_use_lzma) {
        options[0].optionString = (char*) "-Davian.bootimage=lzma:bootimageBin";
    } else {
        options[0].optionString = (char*) "-Davian.bootimage=bootimageBin";
    }
    options[1].optionString = (char*) "-Davian.codeimage=codeimageBin";
    options[2].optionString = (char*) "-Xbootclasspath:[bootJar]:[resourcesJar]";
    options[3].optionString = (char*) "-Davian.aotonly=true";
    // prevent OpenJDK reflection from generating code at runtime:
    options[4].optionString = (char*) "-Dsun.reflect.inflationThreshold=2147483647";
    
    JavaVM* vm = NULL;
    void* env = NULL;
    JNI_CreateJavaVM(&vm, &env, &vmArgs);
    JNIEnv* e = (JNIEnv*) env;
    
    jclass hello = (*e)->FindClass(e, "Hello");
    if (! (*e)->ExceptionCheck(e)) {
        jmethodID constructor = (*e)->GetMethodID(e, hello, "<init>", "(J)V");
        if (! (*e)->ExceptionCheck(e)) {
            jobject peer = (*e)->NewObject
            (e, hello, constructor, (jlong) (uintptr_t) self);
            if (! (*e)->ExceptionCheck(e)) {
                jmethodID draw = (*e)->GetMethodID(e, hello, "draw", "(II)V");
                if (! (*e)->ExceptionCheck(e)) {
                    self.dispose = (*e)->GetMethodID(e, hello, "dispose", "()V");
                    self.peer = (*e)->NewGlobalRef(e, peer);
                    self.draw = draw;
                }
            }
        }
    }
    
    if ((*e)->ExceptionCheck(e)) {
        (*e)->ExceptionDescribe(e);
    }
    
    self.vm = vm;
    self.env = getEnv(self.vm);
    
    BOOL res = (*e)->ExceptionCheck(e) ? NO : YES;
    
    if (res) {
        self.loaded = YES;
    }
    
    return res;
}

-(void)helloJava:(CGRect)rect
{
    JNIEnv* e = self.env;
    if (e) {
        int x = (int) floor(rect.size.width / 2.0);
        int y = (int) floor(rect.size.height / 2.0);
        (*e)->CallVoidMethod
        (e, self.peer, self.draw, x, y);
    }
}

- (void)dealloc
{
    JNIEnv* e = getEnv(self.vm);
    if (e) {
        (*e)->CallVoidMethod(e, self.peer, self.dispose);
        (*e)->DeleteGlobalRef(e, self.peer);
    }
    (*self.vm)->DestroyJavaVM(self.vm);
}

@end
