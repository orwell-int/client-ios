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

#import "ORSubmenu.h"

@implementation ORSubmenu {
	SPImage *_background;
	SPButton *_firstButton;
	SPButton *_secondButton;
	SPButton *_thirdButton;
	float _originalWidth;
	float _originalHeight;

	float _originalX;
	float _originalY;
	float _destinationX;
	float _destinationY;
}

- (id)init
{
	if (self = [super init]) {
		__weak id wself = self;
		_background = [SPImage imageWithContentsOfFile:@"Submenu.png"];
		_originalWidth = _background.width;
		_originalHeight = _background.height;
		_originalX = 0;
		_originalY = 0;

		_firstButton = [[SPButton alloc] initWithUpState:[SPTexture textureWithWidth:195 height:48 draw:^(CGContextRef contextRef){
			CGRect rect = CGRectMake(0, 0, 200, 49);
			CGContextClearRect(contextRef, rect);
		}]];
		_firstButton.text = @"First button";
		_firstButton.fontColor = 0xffffff;
		_firstButton.fontName = @"Helvetica Neue";
		_firstButton.fontSize = 19;
		_firstButton.x = 15.0f;
		_firstButton.y = 0.0f;
		[_firstButton addEventListenerForType:SP_EVENT_TYPE_TRIGGERED block:^(id event) {
			[wself broadcastEventWithType:OR_EVENT_SUBMENU_FIRST_BUTTON_TRIGGERED];
		}];

		_secondButton = [[SPButton alloc] initWithUpState:[SPTexture textureWithWidth:195 height:48 draw:^(CGContextRef contextRef){
			CGRect rect = CGRectMake(0, 0, 200, 49);
			CGContextClearRect(contextRef, rect);
		}]];
		_secondButton.text = @"Second button";
		_secondButton.fontColor = 0xffffff;
		_secondButton.fontName = @"Helvetica Neue";
		_secondButton.fontSize = 19;
		_secondButton.x = 15.0f;
		_secondButton.y = 47.0f;
		[_secondButton addEventListenerForType:SP_EVENT_TYPE_TRIGGERED block:^(id event) {
			[wself broadcastEventWithType:OR_EVENT_SUBMENU_SECOND_BUTTON_TRIGGERED];
		}];

		_thirdButton = [[SPButton alloc] initWithUpState:[SPTexture textureWithWidth:195 height:48 draw:^(CGContextRef contextRef){
			CGRect rect = CGRectMake(0, 0, 200, 49);
			CGContextClearRect(contextRef, rect);
		}]];
		_thirdButton.text = @"Third button";
		_thirdButton.fontColor = 0xffffff;
		_thirdButton.fontName = @"Helvetica Neue";
		_thirdButton.fontSize = 19;
		_thirdButton.x = 15.0f;
		_thirdButton.y = 94.0f;
		[_thirdButton addEventListenerForType:SP_EVENT_TYPE_TRIGGERED block:^(id event) {
			[wself broadcastEventWithType:OR_EVENT_SUBMENU_THIRD_BUTTON_TRIGGERED];
		}];

		[self addChild:_background atIndex:0];
		[self addChild:_firstButton];
		[self addChild:_secondButton];
		[self addChild:_thirdButton];
	}

	return self;
}

- (NSString *)firstButtonText
{
	return _firstButton.text;
}

- (void)setFirstButtonText:(NSString *)firstButtonText
{
	_firstButton.text = firstButtonText;
}

- (NSString *)secondButtonText
{
	return _secondButton.text;
}

- (void)setSecondButtonText:(NSString *)secondButtonText
{
	_secondButton.text = secondButtonText;
}

- (NSString *)thirdButtonText
{
	return _thirdButton.text;
}

- (void)setThirdButtonText:(NSString *)thirdButtonText
{
	_thirdButton.text = thirdButtonText;
}

- (void)animateAppear:(float)duration
{
	self.scaleX = 0;
	self.scaleY = 0;
	self.x = _destinationX;
	self.y = _destinationY;
	DDLogVerbose(@"Starting from x: %.2f - y: %.2f", self.x, self.y);
	DDLogVerbose(@"Going to      x: %.2f - y: %.2f", _originalX, _originalY);

	self.visible = YES;
	SPTween *tween = [SPTween tweenWithTarget:self time:duration transition:SP_TRANSITION_EASE_OUT_BACK];
	[tween scaleTo:1];
	[tween moveToX:_originalX y:_originalY];
	[Sparrow.juggler addObject:tween];
}

- (void)animateDisappear:(float)duration
{
	SPTween *tween = [SPTween tweenWithTarget:self time:duration transition:SP_TRANSITION_EASE_IN_BACK];
	DDLogVerbose(@"Starting from x: %.2f - y: %.2f", self.x, self.y);
	DDLogVerbose(@"Going to      x: %.2f - y: %.2f", _originalX + (self.width * 0.5), _originalY + (self.height * 0.5));

	[tween scaleTo:0];
	[tween moveToX:_destinationX
				 y:_destinationY];
	[Sparrow.juggler addObject:tween];

	tween.onComplete = ^{
		DDLogVerbose(@"Tween is over");
		self.visible = NO;
	};
}

- (void)setX:(float)x
{
	super.x = x;
	if (_originalX == 0) {
		_originalX = x;
		_destinationX = _originalX + (self.width * 0.5);
	}
}

- (void)setY:(float)y
{
	super.y = y;
	if (_originalY == 0) {
		_originalY = y;
		_destinationY = _originalY + (self.height * 0.5);
	}
}

- (void)recalibrateX:(float)x andY:(float)y
{
	_originalY = 0;
	_originalX = 0;
	self.x = x;
	self.y = y;
}

@end
