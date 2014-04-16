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

#import "ORTopBar.h"

@implementation ORTopBar {
	SPImage *_background;
	SPImage *_busyIndicator;
	SPButton *_backButton;
	SPTextField *_textField;
}

- (id)init
{
	if (self = [super init]) {
		_background = [SPImage imageWithContentsOfFile:@"TopBar.png"];
		_background.x = 0.0f;
		_background.y = 0.0f;
		// Init TextField
		_textField = [SPTextField textFieldWithWidth:218.0f
													height:18.0f
													  text:@"iOrwell"];

		_textField.fontName = @"HelveticaNeue-Light";
		_textField.fontSize = 17;
		_textField.color = 0xffffff;
		_textField.x = 50.0f;
		_textField.y = 20.0f;

		// Init back button
		_backButton = [SPButton buttonWithUpState:[SPTexture textureWithContentsOfFile:@"BackButton.png"]];
		_backButton.x = 12.0f;
		_backButton.y = 22.0f;
		_backButton.width = 23.0f;
		_backButton.height = 23.0f;

		_busyIndicator = [SPImage imageWithContentsOfFile:@"BusyIndicator.png"];
		_busyIndicator.x = _background.width - _busyIndicator.width - 20.0f;
		_busyIndicator.y = 10.0f;
		_busyIndicator.visible = NO;

		__weak ORTopBar *wself = self;
		[_backButton addEventListenerForType:SP_EVENT_TYPE_TRIGGERED block:^(id event) {
			[wself dispatchEventWithType:OR_EVENT_BACKBUTTON_TRIGGERED bubbles:YES];
		}];

		[self addChild:_background atIndex:0];
		[self addChild:_backButton];
		[self addChild:_busyIndicator];
		[self addChild:_textField];
	}

	return self;
}

- (void)setBackButtonVisible:(BOOL)backButtonVisible
{
	_backButton.visible = backButtonVisible;
}

- (BOOL)backButtonVisible
{
	return _backButton.visible;
}

- (void)setText:(NSString *)text
{
	_textField.text = text;
}

- (NSString *)text
{
	return _textField.text;
}

- (BOOL)busyIndicatorVisible
{
	return _busyIndicator.visible;
}

- (void)setBusyIndicatorVisible:(BOOL)busyIndicatorVisible
{
	_busyIndicator.visible = busyIndicatorVisible;
}

- (void)animateBusyIndicatorWithDelay:(float)delay
{
	self.busyIndicatorVisible = YES;
	SPTween *tween = [SPTween tweenWithTarget:_busyIndicator time:delay];
	[tween animateProperty:@"alpha" targetValue:0.2f];
	tween.repeatCount = 0;
	tween.reverse = YES;

	[Sparrow.juggler addObject:tween];
}

- (void)stopBusyIndicator
{
	self.busyIndicatorVisible = NO;
	_busyIndicator.alpha = 1.0f;
}

@end
