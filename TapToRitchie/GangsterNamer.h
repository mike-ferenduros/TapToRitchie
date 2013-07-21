//
//  GangsterNamer.h
//  TapToRitchie
//
//  Created by Michael Ferenduros on 22/07/2013.
//  Copyright (c) 2013 Michael Ferenduros. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GangsterNamer : NSObject

+ (void)loadStrings;
+ (NSString*)randomName:(BOOL)female;

@end
