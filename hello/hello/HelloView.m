//
//  HelloView.m
//  hello
//
//  Created by Benjamin Stadin on 01.11.15.
//  Copyright © 2015 HDM. All rights reserved.
//

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
