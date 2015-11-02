#import "HelloView.h"
#import "AppDelegate.h"

@implementation HelloView

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    AppDelegate *appDel = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (!appDel.vmContext.loaded) {
        return;
    }
    
    [appDel.vmContext helloJava:rect];
}

@end
