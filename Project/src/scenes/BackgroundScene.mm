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

#import "BackgroundScene.h"
#import "ORButton.h"

@interface BackgroundScene()
@property (strong, nonatomic) SPImage *topBar;
@property (strong, nonatomic) SPButton *nbackButton;
@property (strong, nonatomic) SPTextField *topBarTextField; // x50 y20

@property (strong, nonatomic) SPImage *background;
@property (strong, nonatomic) ORButton *backButton;
@end

@implementation BackgroundScene

- (id)init
{
	self = [super init];
	_backButtonVisible = YES;
	_topBarVisible = YES;

	_background = [SPImage imageWithContentsOfFile:@"StageBackground.png"];
	_background.touchable = NO;

	// Init Top Bar
	_topBar = [SPImage imageWithContentsOfFile:@"TopBar.png"];
	_topBar.x = 0;
	_topBar.y = 0;

	// Init back button
	_nbackButton = [SPButton buttonWithUpState:[SPTexture textureWithContentsOfFile:@"BackButton.png"]];
	_nbackButton.x = 12.0f;
	_nbackButton.y = 17.0f;
	_nbackButton.width = 23.0f;
	_nbackButton.height = 23.0f;
	[_nbackButton addEventListener:@selector(onBackButtonPressed:)
						  atObject:self
						   forType:SP_EVENT_TYPE_TRIGGERED];

	// Init TextField
	_topBarTextField = [SPTextField textFieldWithWidth:218.0f
												height:18.0f
												  text:@"iOrwell"];

	_topBarTextField.fontName = @"HelveticaNeue-Light";
	_topBarTextField.fontSize = 17;
	_topBarTextField.color = 0xffffff;
	_topBarTextField.x = 50.0f;
	_topBarTextField.y = 20.0f;

	[self addChild:_background atIndex:0];
	[self addChild:_topBar];
	[self addChild:_nbackButton];
	[self addChild:_topBarTextField];

	return self;
}

- (void)willGoBack
{

}

- (void)onBackButtonPressed:(SPEvent *)event
{
	[self willGoBack];
	[self dispatchEventWithType:EVENT_TYPE_SCENE_CLOSING bubbles:YES];
}

- (void)addBackButton
{
//	_backButton = [[ORButton alloc] initWithText:@"Back"];;
//	_backButton.name = @"Back";

//	_backButton.x = 90.0f;
//	_backButton.y = 400.0f;

//	[self addChild:_backButton];
}

- (void)removeBackButton
{
//	[self removeChild:_backButton];
}

- (void)registerSelector:(SEL)selector
{
//	if (_backButton)
//		[_backButton addEventListener:selector
//							 atObject:self
//							  forType:SP_EVENT_TYPE_TRIGGERED];
}

- (void)unregisterSelector:(SEL)selector
{
//	[_backButton removeEventListener:selector
//							atObject:self
//							 forType:SP_EVENT_TYPE_TRIGGERED];
}

- (float)getBackButtonY
{
	return _backButton.y;
}

- (float)getBackButtonHeight
{
	return _backButton.height;
}

- (void)placeObjectInStage
{

}

- (void)startObjects
{

}

- (CGRect)getUsableScreenSize
{
	CGRect screenSize;

	screenSize.size.width = Sparrow.stage.width;
	screenSize.size.height = Sparrow.stage.height - (Sparrow.stage.height - _backButton.y - 5.0f);

	screenSize.origin.x = 0.0f;
	screenSize.origin.y = 0.0f;

	return screenSize;
}

- (void)resetBackground
{
//	_background = [SPImage imageWithContentsOfFile:@"game-bg.png"];
//	_background.touchable = NO;
}

- (void)setBlackBackground
{
//	_background = [[SPImage alloc] initWithWidth:320.0f height:480.0f color:0];
//	_background.touchable = NO;
}

- (void)setTopBarText:(NSString *)topBarText
{
	_topBarText = topBarText;
	_topBarTextField.text = topBarText;
}

- (void)setTopBarVisible:(BOOL)topBarVisible
{
	_topBarVisible = topBarVisible;
	_topBar.visible = topBarVisible;
	_topBarTextField.visible = topBarVisible;
	self.backButtonVisible = topBarVisible;
}

- (void)setBackButtonVisible:(BOOL)backButtonVisible
{
	_backButtonVisible = backButtonVisible;
	_nbackButton.visible = backButtonVisible;
}

@end
