//
//  PlayGameScene.m
//  iOrwell2
//
//  Created by Massimo Gengarelli on 23/02/14.
//
//

#import "PlayGameScene.h"

@implementation PlayGameScene

- (id)init
{
	self = [super init];
	[self addBackButton];
	
	[self registerSelector:@selector(onBackButton:)];
	
	return self;
}

- (void)onBackButton:(SPEvent *)event
{
	[self unregisterSelector:@selector(onBackButton:)];
	[self dispatchEventWithType:EVENT_TYPE_SCENE_CLOSING bubbles:YES];
}

@end
