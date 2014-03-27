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

#import "InputGameScene.h"
#import "ORButton.h"
#import "ORTextField.h"
#import "ServerCommunicator.h"
#import "CallbackResponder.h"
#import "ORArrowButton.h"
#import "ORCameraViewer.h"

#import "robot.pb.h"
#import "controller.pb.h"

@interface InputGameScene() <CallbackResponder>
@property (strong, nonatomic) ORTextField *playerTextField;
@property (strong, nonatomic) ORTextField *feedbackTextField;
@property (weak, nonatomic) ServerCommunicator *serverCommunicator;

@property (strong, nonatomic) ORArrowButton *leftButton;
@property (strong, nonatomic) ORArrowButton *downButton;
@property (strong, nonatomic) ORArrowButton *rightButton;
@property (strong, nonatomic) ORArrowButton *upButton;
@property (strong, nonatomic) NSMutableArray *buttonsArray;
@property (strong, nonatomic) ORCameraViewer *mjpegViewer;

- (void)onDownButtonClicked:(SPTouchEvent *)event;
- (void)onUpButtonClicked:(SPTouchEvent *)event;
- (void)onLeftButtonClicked:(SPTouchEvent *)event;
- (void)onRightButtonClicked:(SPTouchEvent *)event;

@end

@implementation InputGameScene
{
	BOOL _running;
	float _left;
	float _right;
}

-(id)init
{
	self = [super init];
	[self addBackButton];
	_left = 0;
	_right = 0;
	_running = YES;
	
	DDLogDebug(@"Usable screen size, w = %f - h = %f",
			   [self getUsableScreenSize].size.width, [self getUsableScreenSize].size.height);
	
	_playerTextField = [ORTextField textFieldWithWidth:320.0f height:60.0f text:@""];
	_feedbackTextField = [ORTextField textFieldWithWidth:320.0f height:60.0f text:@"Feedback area"];
	
	_buttonsArray = [NSMutableArray array];

	_leftButton = [[ORArrowButton alloc] initWithRotation:LEFT];
	_leftButton.name = @"left";
	[_buttonsArray addObject:_leftButton];
	
	_rightButton = [[ORArrowButton alloc] initWithRotation:RIGHT];
	_rightButton.name = @"right";
	[_buttonsArray addObject:_rightButton];

	_downButton = [[ORArrowButton alloc] initWithRotation:DOWN];
	_downButton.name = @"down";
	[_buttonsArray addObject:_downButton];

	_upButton = [[ORArrowButton alloc] initWithRotation:UP];
	_upButton.name = @"up";
	[_buttonsArray addObject:_upButton];

	DDLogDebug(@"Initing _mjpegViewer");
	_mjpegViewer = [ORCameraViewer cameraViewerFromURL:[NSURL URLWithString:@"http://mail.bluegreendiamond.net:8084/cgi-bin/faststream.jpg?stream=full&fps=24"]];

	return self;
}

-(void)onBackButton:(SPEvent *)event
{
	[self unregisterSelector:@selector(onBackButton:)];
	[self dispatchEventWithType:EVENT_TYPE_INPUT_SCENE_CLOSING bubbles:YES];
	[_serverCommunicator deleteResponder:self forMessage:@"GameState"];
	_running = NO;
}

-(void)placeObjectInStage
{
	DDLogDebug(@"Inited with robot name: %@", self.robotName);
	DDLogDebug(@"Inited with player name: %@", self.playerName);

	DDLogDebug(@"Placed mjpegViewer in screen %@", [_mjpegViewer debugDescription]);

	_playerTextField.text = [NSString stringWithFormat:@"%@ @ %@", self.playerName, self.robotName];
	_playerTextField.x = 0.0f;
	_playerTextField.y = 0.0f;
	[self addChild:_playerTextField];
	
	_mjpegViewer.x = 0.0f;
	_mjpegViewer.y = 70.0f;
	[self addChild:_mjpegViewer];
	
	_downButton.width = 240.0f;
	_downButton.height = 40.0f;
	_downButton.x = 40.0f;
	_downButton.y = 270.0f;
    [_downButton addEventListener:@selector(onDownButtonClicked:) atObject:self forType:SP_EVENT_TYPE_TOUCH];

	_upButton.width = 240.0f;
	_upButton.height = 40.0f;
	_upButton.x = 40.0f;
	_upButton.y = 70.0f;
    [_upButton addEventListener:@selector(onUpButtonClicked:) atObject:self forType:SP_EVENT_TYPE_TOUCH];
	
	_leftButton.width = 40.0f;
	_leftButton.height = 160.0f;
	_leftButton.x = 0.0f;
	_leftButton.y = 110.0f;
    [_leftButton addEventListener:@selector(onLeftButtonClicked:) atObject:self forType:SP_EVENT_TYPE_TOUCH];
	
	_rightButton.width = 40.0f;
	_rightButton.height = 160.0f;
	_rightButton.x = 280.0f;
	_rightButton.y = 110.0f;
    [_rightButton addEventListener:@selector(onRightButtonClicked:) atObject:self forType:SP_EVENT_TYPE_TOUCH];
	
	_feedbackTextField.x = 0.0f;
	_feedbackTextField.y = 330.0f;
	[self addChild:_feedbackTextField];
	
	[self addChild:_downButton];
	[self addChild:_upButton];
	[self addChild:_leftButton];
	[self addChild:_rightButton];
}

-(void)startObjects
{
	// This is active already
	_serverCommunicator = [ServerCommunicator initSingleton];
	[_serverCommunicator registerResponder:self forMessage:@"GameState"];
	
	[self registerSelector:@selector(onBackButton:)];
	
	// Background thread handling the logic of constantly sending a message
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		while (_running) {
            using namespace orwell::messages;
            Input input;
            input.mutable_move()->set_left(_left);
            input.mutable_move()->set_right(_right);

            ServerMessage *message = [[ServerMessage alloc] init];
            message.tag = @"Input ";
            message.receiver = @"targetrobot ";
            message.payload = [NSData dataWithBytes:input.SerializeAsString().c_str()
                                             length:input.SerializeAsString().length()];
            [_serverCommunicator pushMessage:message];
		}
		
		DDLogInfo(@"Leaving background thread");
	});
}

-(BOOL)messageReceived:(NSDictionary *)message
{
	static int count = 0;
	NSNumber *playing = [message objectForKey:CB_GAMESTATE_KEY_PLAYING];

	if (playing != nil) {
		_feedbackTextField.text = [NSString stringWithFormat:@"GameState received (%d)", count++];
	}

	return YES;
}

- (void)onDownButtonClicked:(SPTouchEvent *)event
{
    SPTween *alphaAnimator = [SPTween tweenWithTarget:_downButton time:0.5f];
    
    if ([[event touchesWithTarget:_downButton andPhase:SPTouchPhaseBegan] allObjects].count) {
        DDLogInfo(@"Down button started");
        _left = -1;
        _right = -1;
        [alphaAnimator animateProperty:@"backgroundAlpha" targetValue:1.0f];
    }
    else {
        DDLogInfo(@"Down button finished");
        _left = 0;
        _right = 0;
        [alphaAnimator animateProperty:@"backgroundAlpha" targetValue:0.0f];
    }
    
    [Sparrow.juggler addObject:alphaAnimator];
}

- (void)onUpButtonClicked:(SPTouchEvent *)event
{
    SPTween *alphaAnimator = [SPTween tweenWithTarget:_upButton time:0.5f];
    
    if ([[event touchesWithTarget:_upButton andPhase:SPTouchPhaseBegan] allObjects].count) {
        DDLogInfo(@"Up button started");
        _left = 1;
        _right = 1;
        [alphaAnimator animateProperty:@"backgroundAlpha" targetValue:1.0f];
    }
    else {
        DDLogInfo(@"Up button finished");
        _left = 0;
        _right = 0;
        [alphaAnimator animateProperty:@"backgroundAlpha" targetValue:0.0f];
    }
    
    [Sparrow.juggler addObject:alphaAnimator];
}

- (void)onLeftButtonClicked:(SPTouchEvent *)event
{
    SPTween *alphaAnimator = [SPTween tweenWithTarget:_leftButton time:0.5f];
    
    if ([[event touchesWithTarget:_leftButton andPhase:SPTouchPhaseBegan] allObjects].count) {
        DDLogInfo(@"Left button started");
        _left = 1;
        _right = -1;
        [alphaAnimator animateProperty:@"backgroundAlpha" targetValue:1.0f];
    }
    else {
        DDLogInfo(@"Left button finished");
        _left = 0;
        _right = 0;
        [alphaAnimator animateProperty:@"backgroundAlpha" targetValue:0.0f];
    }
    
    [Sparrow.juggler addObject:alphaAnimator];
}

- (void)onRightButtonClicked:(SPTouchEvent *)event
{
    SPTween *alphaAnimator = [SPTween tweenWithTarget:_rightButton time:0.5f];
    
    if ([[event touchesWithTarget:_rightButton andPhase:SPTouchPhaseBegan] allObjects].count) {
        DDLogInfo(@"Right button started");
        _left = -1;
        _right = 1;
        [alphaAnimator animateProperty:@"backgroundAlpha" targetValue:1.0f];
    }
    else {
        DDLogInfo(@"Right button finished");
        _left = 0;
        _right = 0;
        [alphaAnimator animateProperty:@"backgroundAlpha" targetValue:0.0f];
    }
    
    [Sparrow.juggler addObject:alphaAnimator];
}

@end
