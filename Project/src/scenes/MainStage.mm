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
#import "PlayGameScene.h"
#import "ServerConnectionScene.h"
#import "ORAlternativeButton.h"
#import "ORDialogBox.h"
#import "ORDialogBoxDelegate.h"

#pragma mark Private Interface
@interface MainStage() <ORDialogBoxDelegate>

@property (strong, nonatomic) SPImage *logo;
@property (strong, nonatomic) SPTextField *versionNumber;
@property (strong, nonatomic) ORAlternativeButton *playButton;
@property (strong, nonatomic) ORAlternativeButton *informationButton;
@property (strong, nonatomic) ORAlternativeButton *creditsButton;
@property (strong, nonatomic) BackgroundScene *activeScene;

// Events
- (void)onButtonTriggered:(SPEvent *)event;
@end

#pragma mark Implementation
@implementation MainStage {
	ORDialogBox *_dialogBox;
	float _deltaX;
	float _deltaY;
}

#pragma mark Initialization
- (id)init
{
	self = [super init];

	NSString *softwareVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	_versionNumber = [SPTextField textFieldWithWidth:Sparrow.stage.width - 30
											  height:20
												text:[NSString stringWithFormat:@"Version %@", softwareVersion]];
	_versionNumber.fontName = @"HelveticaNeue-Light";
	_versionNumber.fontSize = 17;
	_versionNumber.color = 0xffffff;
	_versionNumber.x = 15.0f;
	_versionNumber.y = 440.0f;
	[self addChild:_versionNumber];

	_logo = [[SPImage alloc] initWithContentsOfFile:@"LogoBig.png"];
	_logo.x = 10.0f;
	_logo.y = 55.0f;
	[self addChild:_logo];

	_playButton = [[ORAlternativeButton alloc] initWithType:OR_BUTTON_PLAY];
	_playButton.name = @"PlayButton";
	_playButton.x = 70.0f;
	_playButton.y = 270.0f;
	[_playButton addEventListener:@selector(onButtonTriggered:)
						 atObject:self
						  forType:SP_EVENT_TYPE_TRIGGERED];

	_informationButton = [[ORAlternativeButton alloc] initWithType:OR_BUTTON_INFORMATIONS];
	_informationButton.name = @"InformationButton";
	_informationButton.x = 70.0f;
	_informationButton.y = 325.0f;
	[_informationButton addEventListener:@selector(onButtonTriggered:)
								atObject:self
								 forType:SP_EVENT_TYPE_TRIGGERED];

	_creditsButton = [[ORAlternativeButton alloc] initWithType:OR_BUTTON_CREDITS];
	_creditsButton.name = @"CreditsButton";
	_creditsButton.x = 70.0f;
	_creditsButton.y = 380.0f;
	[_creditsButton addEventListener:@selector(onButtonTriggered:)
							atObject:self
							 forType:SP_EVENT_TYPE_TRIGGERED];

	[self addChild:_playButton];
	[self addChild:_informationButton];
	[self addChild:_creditsButton];

	[self addEventListener:@selector(onSceneClosing:)
				  atObject:self
				   forType:EVENT_TYPE_SCENE_CLOSING];

	self.backButtonVisible = NO;
	self.topBarText = @"Welcome to iOrwell!";

	return self;
}

#pragma mark Events
- (void)onButtonTriggered:(SPEvent *)event
{
	SPButton *button = (SPButton *)event.target;
	DDLogDebug(@"Clicked button: %@", button.name);

	if (_dialogBox) {
		[self removeChild:_dialogBox];
		_dialogBox = nil;
	}

	if ([button.name isEqualToString:@"PlayButton"]) {
		if (!_activeScene) {
			_activeScene = [[ServerConnectionScene alloc] init];
			[_activeScene placeObjectInStage];

			[self addChild:_activeScene];
			[_activeScene startObjects];
		}
	}
	else if ([button.name isEqualToString:@"InformationButton"]) {
		_dialogBox = [[ORDialogBox alloc] initWithHeader:@"Information"
												 andBody:@"Very long body\n"
					  " with a lot of text that is actually even spanning on multiple \n"
					  "lines, hence creating something that should be scrollable...."];
		_dialogBox.x = 15.0f;
		_dialogBox.y = 45.0f;
		_dialogBox.delegate = self;
		[self addChild:_dialogBox];
	}
	else if ([button.name isEqualToString:@"CreditsButton"]) {
		_dialogBox = [[ORDialogBox alloc] initWithHeader:@"Credits"
												 andBody:@"Very long body\n"
					  " with a lot of text that is actually even spanning on multiple \n"
					  "lines, hence creating something that should be scrollable...."];
		_dialogBox.x = 15.0f;
		_dialogBox.y = 45.0f;
		_dialogBox.delegate = self;
		[self addChild:_dialogBox];
	}
}

- (void)dialogBox:(ORDialogBox *)dialogBox didMoveAtX:(float)x andY:(float)y
{
	_deltaX = 0;
	_deltaY = 0;
}

- (void)dialogBox:(ORDialogBox *)dialogBox startedMoveAtX:(float)x andY:(float)y
{
	_deltaX = x;
	_deltaY = y;
}

- (void)dialogBox:(ORDialogBox *)dialogBox continuedMovingAtX:(float)x andY:(float)y
{
	_deltaX -= x;
	dialogBox.x -= _deltaX;

	_deltaY -= y;
	dialogBox.y -= _deltaY;

	_deltaX = x;
	_deltaY = y;
}

- (void)onSceneClosing:(SPEvent *)event
{
	if (_activeScene) {
		[_activeScene removeFromParent];
		_activeScene = nil;
	}
}

@end
