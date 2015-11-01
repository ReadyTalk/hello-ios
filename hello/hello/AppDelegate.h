//
//  AppDelegate.h
//  hello
//
//  Created by Benjamin Stadin on 01.11.15.
//  Copyright © 2015 HDM. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VMContext.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong) VMContext *vmContext;

@end

