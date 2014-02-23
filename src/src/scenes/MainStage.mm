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

#import "MainStage.h"
#import "SPImage.h"
#import "Sparrow.h"

#import "BroadcastScene.h"
#import "FlowScene.h"
#import "PlayGameScene.h"

#import "ORButton.h"

#pragma mark Private Interface
@interface MainStage()

// Init functions
-(void) initWelcomeMessage;
-(void) initBackground;
-(void) initButtons;

// Events
-(void) onButtonTriggered:(SPEvent *)event;
@end

#pragma mark Implementation
@implementation MainStage
{
	SPImage *_background;
	SPImage *_marvin;
	
	SPTextField *_welcomeMessage;

	ORButton *_testBroadcastButton;
	ORButton *_testHelloMessageButton;
	ORButton *_playGameButton;
	
	BackgroundScene *_activeScene;
}

#pragma mark Functions
- (id)initMainStage
{
	self = [super init];
	
	// Init welcome message
	[self initWelcomeMessage];
	[self addChild:_welcomeMessage];
	
	// Init buttons
	[self initButtons];
	[self addChild:_testBroadcastButton];
	[self addChild:_testHelloMessageButton];
	[self addChild:_playGameButton];
	
	_marvin = [SPImage imageWithContentsOfFile:@"marvin.png"];
	_marvin.x = (Sparrow.stage.width / 2) - (_marvin.width / 2);
	_marvin.y = Sparrow.stage.height - _marvin.height - 10.0f;
	[self addChild:_marvin];
	
	[self addEventListener:@selector(onSceneClosing:)
				  atObject:self
				   forType:EVENT_TYPE_SCENE_CLOSING];

	return self;
}

- (void)initBackground
{
	_background = [[SPImage alloc] initWithContentsOfFile:@"background.jpg"];
}

- (void)initWelcomeMessage
{
	_welcomeMessage = [SPTextField textFieldWithWidth:(Sparrow.stage.width - 30) height:80 text:@"iOrwellcome to you!"];
	_welcomeMessage.fontName = [SPTextField registerBitmapFontFromFile:@"dodger_condensed_condensed_20.fnt"];
	_welcomeMessage.fontSize = 12;
	_welcomeMessage.color = 0xffffff;;
	
	_welcomeMessage.x = (Sparrow.stage.width / 2) - (_welcomeMessage.width / 2);
	_welcomeMessage.y = 5;
}

- (void)initButtons
{	
	// Test Broadcast Button
	_testBroadcastButton = [[ORButton alloc] initWithText:@"Test Broadcast"];
	_testBroadcastButton.name = @"BroadcastButton";
	
	_testBroadcastButton.x = (Sparrow.stage.width / 2) - (_testBroadcastButton.width / 2);
	_testBroadcastButton.y = _welcomeMessage.y + _welcomeMessage.height + 5;
	
	[_testBroadcastButton addEventListener:@selector(onButtonTriggered:)
								  atObject:self
								   forType:SP_EVENT_TYPE_TRIGGERED];
	
	_testHelloMessageButton = [[ORButton alloc] initWithText:@"Test Flow"];
	_testHelloMessageButton.name = @"HelloButton";
	
	_testHelloMessageButton.x = (Sparrow.stage.width / 2) - (_testHelloMessageButton.width / 2);
	_testHelloMessageButton.y = _testBroadcastButton.y + _testBroadcastButton.height + 5;
	
	[_testHelloMessageButton addEventListener:@selector(onButtonTriggered:)
									 atObject:self
									  forType:SP_EVENT_TYPE_TRIGGERED];
	
	_playGameButton = [[ORButton alloc] initWithText:@"Play"];
	_playGameButton.name = @"PlayButton";
	
	_playGameButton.x = (Sparrow.stage.width / 2) - (_playGameButton.width / 2);
	_playGameButton.y = _testHelloMessageButton.y + _testHelloMessageButton.height + 5;
	
	[_playGameButton addEventListener:@selector(onButtonTriggered:)
							 atObject:self
							  forType:SP_EVENT_TYPE_TRIGGERED];
	
}

- (void)onButtonTriggered:(SPEvent *)event
{
	SPButton *button = (SPButton *)event.target;
	NSLog(@"Clicked button: %@", button.name);
	
	SPTween *animator = [SPTween tweenWithTarget:_marvin time:1.0f];
	[animator animateProperty:@"alpha" targetValue:0];
	animator.reverse = YES;
	animator.repeatCount = 0;
	[Sparrow.juggler addObject:animator];
	
	if (_activeScene) return;

	else if ([button.name isEqualToString:@"BroadcastButton"])
	{
		_activeScene = [[BroadcastScene alloc] init];
	}
	
	else if ([button.name isEqualToString:@"HelloButton"])
	{
		_activeScene = [[FlowScene alloc] init];
	}
	
	else
	{
		_activeScene = [[PlayGameScene alloc] init];
	}
	
	[self addChild:_activeScene];
}

- (void)onSceneClosing:(SPEvent *)event
{
	if (_activeScene)
	{
		[_activeScene removeFromParent];
		_activeScene = nil;
	}
}

@end
