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
#import "ORTopBar.h"

@interface BackgroundScene()
@property (strong, nonatomic) SPImage *background;
@end

@implementation BackgroundScene

- (id)init
{
	self = [super init];

	_background = [SPImage imageWithContentsOfFile:@"StageBackground.png"];
	_background.touchable = NO;

	// Init Top Bar
	_topBar = [[ORTopBar alloc] init];
	[_topBar addEventListener:@selector(onBackButtonPressed:)
					 atObject:self
					  forType:OR_EVENT_BACKBUTTON_TRIGGERED];

	[self addChild:_background atIndex:0];
	[self addChild:_topBar];

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

- (void)placeObjectInStage
{

}

- (void)startObjects
{

}

- (void)animateTransitionWithTime:(double)time
{
	SPTween *transition = [SPTween tweenWithTarget:self time:time transition:SP_TRANSITION_EASE_IN];
	[transition moveToX:0 y:0];

	transition.onComplete = ^{
		[self animationDidFinish];
	};

	[Sparrow.juggler addObject:transition];
}

- (void)animateTransitionOutWithTime:(double)time andCompletionBlock:(void (^)())block
{
	SPTween *transition = [SPTween tweenWithTarget:self time:time transition:SP_TRANSITION_EASE_OUT];
	[transition moveToX:Sparrow.stage.width y:0];

	transition.onComplete = ^{
		block();
	};

	[Sparrow.juggler addObject:transition];
}

- (void)animationDidFinish
{

}

@end
