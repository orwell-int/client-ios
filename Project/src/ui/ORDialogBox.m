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

#import "ORDialogBox.h"
#import "ORAlternativeButton.h"
#import "ORDialogBoxDelegate.h"

@implementation ORDialogBox {
	SPImage *_background;
	SPTextField *_headerTextField;
	SPTextField *_textMessageTextField;
	SPButton *_dismissButton;
}

- (id)init
{
	if (self = [super init]) {
		_background = [SPImage imageWithContentsOfFile:@"DialogBackground.png"];
		_headerTextField = [SPTextField textFieldWithWidth:_background.width - 10
													height:20
													  text:@""];
		_headerTextField.x = 0.0f;
		_headerTextField.y = 20.0f;
		_headerTextField.color = 0xffffff;
		_headerTextField.fontName = @"HelveticaNeue-Bold";
		_headerTextField.fontSize = 16;


		_textMessageTextField = [SPTextField textFieldWithWidth:_background.width - 40
														 height:_background.height - 30
														   text:@""];
		_textMessageTextField.x = 25.0f;
		_textMessageTextField.y = 55.0f;
		_textMessageTextField.color = 0xffffff;
		_textMessageTextField.fontName = @"Helvetica Neue-Light";
		_textMessageTextField.fontSize = 14;
		_textMessageTextField.vAlign = SPVAlignTop;
		_textMessageTextField.hAlign = SPHAlignLeft;

		_dismissButton = [SPButton buttonWithUpState:[SPTexture textureWithContentsOfFile:@"BackButton.png"]];
		_dismissButton.x = 20.0f;
		_dismissButton.y = 20.0f;
		_dismissButton.height = 20.0f;
		_dismissButton.width = 20.0f;

		[self addChild:_background atIndex:0];
		[self addChild:_headerTextField];
		[self addChild:_textMessageTextField];
		[self addChild:_dismissButton];

		__weak ORDialogBox * wself = self;
		[_dismissButton addEventListenerForType:SP_EVENT_TYPE_TRIGGERED block:^(id event){
			if (wself.delegate) {
				[wself.delegate dialogBoxWantsToLeave:wself];
			}
		}];

		[self addEventListener:@selector(onDragged:)
					  atObject:self
					   forType:SP_EVENT_TYPE_TOUCH];
	}

	return self;
}

- (id)initWithHeader:(NSString *)header andBody:(NSString *)body
{
	if (self = [self init]) {
		self.header = header;
		self.body = body;
	}

	return self;
}

- (void)setHeader:(NSString *)header
{
	_header = [NSString stringWithString:header];
	_headerTextField.text = _header;
}

- (void)setBody:(NSString *)body
{
	_body = [NSString stringWithString:body];
	_textMessageTextField.text = _body;
}

- (void)onDragged:(SPTouchEvent *)event
{
	NSArray *touchPhaseBeganArray = [[event touchesWithTarget:self
											 andPhase:SPTouchPhaseBegan]
							 allObjects];
	for (SPTouch *touch in touchPhaseBeganArray) {
		if (_delegate)
			[_delegate dialogBox:self startedMoveAtX:touch.globalX andY:touch.globalY];
	}

	NSArray *touchPhaseMovedArray = [[event touchesWithTarget:self
													 andPhase:SPTouchPhaseMoved]
									 allObjects];
	for (SPTouch *touch in touchPhaseMovedArray) {
		if (_delegate)
			[_delegate dialogBox:self continuedMovingAtX:touch.globalX andY:touch.globalY];
	}

	NSArray *touchPhaseEndedArray = [[event touchesWithTarget:self
													andPhase:SPTouchPhaseEnded]
									 allObjects];
	for (SPTouch *touch in touchPhaseEndedArray) {
		if (_delegate)
			[_delegate dialogBox:self didMoveAtX:touch.globalX andY:touch.globalY];
	}
}

@end
