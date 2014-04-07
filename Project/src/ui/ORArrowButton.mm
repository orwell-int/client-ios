/* Copyright (c) 2014, Massimo Gengarelli, orwell-int members
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *  - Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * - Neither the name of the orwell-int organization nor the
 * names of its contributors may be used to endorse or promote products
 * derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL MASSIMO GENGARELLI BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ORArrowButton.h"
#import <CoreGraphics/CoreGraphics.h>

@interface ORArrowButton()
@property (strong, nonatomic) SPImage *backgroundImage;
@end

@implementation ORArrowButton
@synthesize rotation = _rotation;
@synthesize backgroundAlpha = _backgroundAlpha;

- (id)init
{
	self = [super initWithUpState:[SPTexture textureWithContentsOfFile:@"button-arrow-down.png"]];
	_backgroundAlpha = 0.0f;
	return self;
}

- (id)initWithRotation:(Rotation)rotation
{
	SPTexture *texture;
	DDLogInfo(@"Calling ORArrowButton with rotation: %d", rotation);
	
	_rotation = rotation;
	
	switch (_rotation) {
		case DOWN:
			DDLogInfo(@"Using new ButtonDown.png texture");
			texture = [SPTexture textureWithContentsOfFile:@"ButtonDown.png"];
			break;
		case UP:
			texture = [SPTexture textureWithContentsOfFile:@"ButtonUp.png"];
			break;
		case LEFT:
			texture = [SPTexture textureWithContentsOfFile:@"ButtonLeft.png"];
			break;
		case RIGHT:
			texture = [SPTexture textureWithContentsOfFile:@"ButtonRight.png"];
			break;

		default:
			DDLogError(@"Something wrong happened, we have been called with: %d", rotation);
			texture = [SPTexture textureWithContentsOfFile:@"button-arrow-down.png"];
			break;
	}
	
	self = [super initWithUpState:texture];
	DDLogInfo(@"Beginning draw with width: %f - height: %f", self.width, self.height);
	SPTexture *backgroundTexture = [[SPTexture alloc] initWithWidth:self.width/2 height:self.height/2 draw:^(CGContextRef contextRef) {
		UIColor * redColor = [UIColor colorWithRed:1.0f green:0.0 blue:0.0 alpha:0.5f];
		
		CGContextSetFillColorWithColor(contextRef, redColor.CGColor);
		CGContextFillRect(contextRef, CGRectMake(self.x, self.y, self.width/2, self.height/2));
	}];

	_backgroundImage = [SPImage imageWithTexture:backgroundTexture];
	_backgroundImage.alpha = _backgroundAlpha; // background invisible
	[self addChild:_backgroundImage atIndex:0];
	return self;
}

- (void)setBackgroundAlpha:(float)backgroundAlpha
{
	_backgroundAlpha = backgroundAlpha;
	_backgroundImage.alpha = _backgroundAlpha;
}

- (float)backgroundAlpha
{
	return _backgroundImage.alpha;
}

- (NSString *)debugDescription
{
	return [NSString stringWithFormat:@"ORArrowButton with rotation: %d", _rotation];
}

@end
