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
#import "ORServerCommunicator.h"
#import "CallbackResponder.h"
#import "ORArrowButton.h"
#import "ORCameraViewer.h"
#import "ORViewController.h"
#import "OREventOrientation.h"

#import "robot.pb.h"
#import "controller.pb.h"


#pragma mark Interface begin
@interface InputGameScene() <CallbackResponder>
@property (strong, nonatomic) ORTextField *playerTextField;
@property (strong, nonatomic) ORTextField *feedbackTextField;
@property (weak, nonatomic) ORServerCommunicator *serverCommunicator;

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
- (void)onOrientationChanged:(SPEvent *)event;
- (void)replaceObjectsInStage:(UIInterfaceOrientation)forOrientation;

@end

#pragma mark Implementation begin
@implementation InputGameScene
{
    BOOL _selectorsConfigured;
	BOOL _running;
	float _left;
	float _right;
}

#pragma mark Init methods
- (id)init
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
    
    // Tell the controller I'm a good guy.
    ORViewController *viewController = (ORViewController *)[Sparrow currentController];
    viewController.supportedOrientations = UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscape;
    _selectorsConfigured = NO;
    
	return self;
}

- (void)replaceObjectsInStage:(UIInterfaceOrientation)forOrientation
{
    DDLogVerbose(@"Organizing objects for orientation: %d", [[Sparrow currentController] interfaceOrientation]);

    [self removeChild:_playerTextField];
    [self removeChild:_feedbackTextField];
    [self removeChild:_downButton];
    [self removeChild:_upButton];
    [self removeChild:_leftButton];
    [self removeChild:_rightButton];
    [self removeBackButton];
    
    [self addChild:_mjpegViewer];

    switch (forOrientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            DDLogInfo(@"Portrait - %f x %f", Sparrow.stage.width, Sparrow.stage.height);
            
            _playerTextField.text = [NSString stringWithFormat:@"%@ @ %@", self.playerName, self.robotName];
            _playerTextField.x = 0.0f;
            _playerTextField.y = 0.0f;
            
            _mjpegViewer.x = 0.0f;
            _mjpegViewer.y = 70.0f;
            _mjpegViewer.width = 320.0f;
            _mjpegViewer.height = 240.0f;
            
            _downButton.width = 240.0f;
            _downButton.height = 40.0f;
            _downButton.x = 40.0f;
            _downButton.y = 270.0f;
            
            _upButton.width = 240.0f;
            _upButton.height = 40.0f;
            _upButton.x = 40.0f;
            _upButton.y = 70.0f;
            
            _leftButton.width = 40.0f;
            _leftButton.height = 160.0f;
            _leftButton.x = 0.0f;
            _leftButton.y = 110.0f;
            
            _rightButton.width = 40.0f;
            _rightButton.height = 160.0f;
            _rightButton.x = 280.0f;
            _rightButton.y = 110.0f;
            
            _feedbackTextField.x = 0.0f;
            _feedbackTextField.y = 330.0f;
            
            [self addChild:_playerTextField];
            [self addChild:_feedbackTextField];
            [self addChild:_downButton];
            [self addChild:_upButton];
            [self addChild:_leftButton];
            [self addChild:_rightButton];
            [self addBackButton];
            
            _mjpegViewer.rotation = 0;

            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            DDLogInfo(@"Landscape - %f x %f", Sparrow.stage.width, Sparrow.stage.height);

            // It is completely stupid, but width and height in Sparrow don't change, so
            // we have to think as if we were in portrait, with the exception that what
            // is now called 'width' it is 'height' in Landscape, and viceversa.
            _mjpegViewer.width = 320.0f;
            _mjpegViewer.height = 480.0f;
            
            // While x and y coordinates do change, as they are relative to the status bar.
            _mjpegViewer.x = 0.0f;
            _mjpegViewer.y = 0.0f;

            // I give up.
            break;
    }
}

- (void)placeObjectInStage
{  
    [self replaceObjectsInStage:[[Sparrow currentController] interfaceOrientation]];

    if (!_selectorsConfigured) {
        [_rightButton addEventListener:@selector(onRightButtonClicked:) atObject:self forType:SP_EVENT_TYPE_TOUCH];
        [_leftButton addEventListener:@selector(onLeftButtonClicked:) atObject:self forType:SP_EVENT_TYPE_TOUCH];
        [_upButton addEventListener:@selector(onUpButtonClicked:) atObject:self forType:SP_EVENT_TYPE_TOUCH];
        [_downButton addEventListener:@selector(onDownButtonClicked:) atObject:self forType:SP_EVENT_TYPE_TOUCH];
        _selectorsConfigured = YES;
    }
}

- (void)startObjects
{
	// This is active already
	_serverCommunicator = [ORServerCommunicator singleton];
	[_serverCommunicator registerResponder:self forMessage:@"GameState"];
    [_mjpegViewer play];
	
	[self registerSelector:@selector(onBackButton:)];
    [self addEventListener:@selector(onOrientationChanged:)
                  atObject:self
                   forType:OR_EVENT_ORIENTATION_ANIMATION_CHANGED];
	
#pragma mark Background thread for Input messages
	// Background thread handling the logic of constantly sending a message
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		while (_running) {
            using namespace orwell::messages;
            Input input;
            input.mutable_move()->set_left(_left);
            input.mutable_move()->set_right(_right);

            ORServerMessage *message = [[ORServerMessage alloc] init];
            message.tag = @"Input ";
            message.receiver = @"targetrobot ";
            message.payload = [NSData dataWithBytes:input.SerializeAsString().c_str()
                                             length:input.SerializeAsString().length()];
            [_serverCommunicator pushMessage:message];
		}
		
		DDLogInfo(@"Leaving background thread");
	});
}


#pragma mark Callback responder
- (BOOL)messageReceived:(NSDictionary *)message
{
	static int count = 0;
	NSNumber *playing = [message objectForKey:CB_GAMESTATE_KEY_PLAYING];

	if (playing != nil) {
		_feedbackTextField.text = [NSString stringWithFormat:@"GameState received (%d)", count++];
	}

	return YES;
}

#pragma mark Events methods
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

- (void)onBackButton:(SPEvent *)event
{
	[self unregisterSelector:@selector(onBackButton:)];
    [self unregisterSelector:@selector(onOrientationChanged:)];
	[self dispatchEventWithType:EVENT_TYPE_INPUT_SCENE_CLOSING bubbles:YES];
	[_serverCommunicator deleteResponder:self forMessage:@"GameState"];
	_running = NO;
    
    ORViewController *viewController = (ORViewController *)[Sparrow currentController];
    viewController.supportedOrientations = UIInterfaceOrientationPortrait;
}

- (void)onOrientationChanged:(SPEvent *)event
{
    DDLogInfo(@"Orientation changed");
    OREventOrientation *eventOrientation = (OREventOrientation *)event;
    
    [self replaceObjectsInStage:eventOrientation.orientation];
}

@end
