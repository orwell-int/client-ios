//
//  ORArrowButton.m
//  iOrwell2
//
//  Created by Massimo Gengarelli on 04/03/14.
//
//

#import "ORArrowButton.h"

@implementation ORArrowButton

- (id)init
{
	self = [super initWithUpState:[SPTexture textureWithContentsOfFile:@"button-arrow.png"]];
	self.width = 15.0f;
	self.height = 15.0f;
	
	return self;
}

@end
