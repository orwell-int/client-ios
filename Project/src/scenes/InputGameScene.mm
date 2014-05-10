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
#import "ORServerCommunicator.h"
#import "CallbackResponder.h"
#import "ORArrowButton.h"
#import "ORCameraViewer.h"
#import "ORViewController.h"
#import "OREventOrientation.h"
#import "ORSubmenu.h"
#import "ORAlternativeButton.h"
#import "ORDialogBox.h"
#import "ORDialogBoxDelegate.h"
#import <LARSBar.h>

#import "robot.pb.h"
#import "controller.pb.h"


#pragma mark - Interface begin
@interface InputGameScene() <CallbackResponder, ORDialogBoxDelegate>

@end

#pragma mark - Implementation begin
@implementation InputGameScene {
    uint64_t _gamestateCounts;
    BOOL _selectorsConfigured;
	BOOL _running;
    BOOL _isLandscape;
	float _left;
	float _right;

    __weak ORServerCommunicator *_serverCommunicator;
    ORArrowButton *_leftButton;
    ORArrowButton *_rightButton;
    ORArrowButton *_downButton;
    ORArrowButton *_upButton;
    NSMutableArray *_buttonsArray;

    ORCameraViewer *_mjpegViewer;
    LARSBar *_lbLeft;
    LARSBar *_lbRight;

    ORAlternativeButton *_starButton;
    ORAlternativeButton *_gamestateButton;
    ORSubmenu *_submenu;

    ORDialogBox *_gamestateDialogBox;
}

#pragma mark - Init methods
- (id)init
{
	self = [super init];
	_left = 0;
	_right = 0;
	_running = YES;
    _gamestateCounts = 0;

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

	_mjpegViewer = [ORCameraViewer cameraViewerFromURL:[NSURL URLWithString:@"http://mail.bluegreendiamond.net:8084/cgi-bin/faststream.jpg?stream=full&fps=24"]];

    // Tell the controller I'm a good guy.
    ORViewController *viewController = (ORViewController *)[Sparrow currentController];
    viewController.supportedOrientations = UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscape;
    _selectorsConfigured = NO;

    _starButton = [[ORAlternativeButton alloc] initWithType:OR_BUTTON_STAR];
    [_starButton addEventListener:@selector(onStarButtonClicked:)
                         atObject:self
                          forType:SP_EVENT_TYPE_TRIGGERED];
    _submenu = [[ORSubmenu alloc] init];
    _submenu.firstButtonText = @"Fire Left";
    _submenu.secondButtonText = @"Fire Right";
    _submenu.thirdButtonText = @"Reset controls";
    [_submenu addEventListener:@selector(onFireLeft:)
                      atObject:self
                       forType:OR_EVENT_SUBMENU_FIRST_BUTTON_TRIGGERED];

    [_submenu addEventListener:@selector(onFireRight:)
                      atObject:self
                       forType:OR_EVENT_SUBMENU_SECOND_BUTTON_TRIGGERED];

    [_submenu addEventListener:@selector(onResetControls:)
                      atObject:self
                       forType:OR_EVENT_SUBMENU_THIRD_BUTTON_TRIGGERED];
    _submenu.visible = NO;

    _gamestateButton = [[ORAlternativeButton alloc] initWithType:OR_BUTTON_GAMESTATE];
    [_gamestateButton addEventListener:@selector(onGamestateButtonClicked:)
                            atObject:self
                             forType:SP_EVENT_TYPE_TRIGGERED];

    _gamestateDialogBox = [[ORDialogBox alloc] initWithHeader:@"Gamestate"
                                                      andBody:@"To be set"];
    _gamestateDialogBox.delegate = self;

    _lbLeft = [[LARSBar alloc] init];
    _lbLeft.transform = CGAffineTransformMakeRotation(M_PI * 1.5);
    _lbLeft.frame = CGRectMake(0, 0, 40, 320);
    _lbLeft.minimumValue = 0.0f;
    _lbLeft.maximumValue = 2.0f;
    _lbLeft.leftChannelLevel = 2.0f;
    _lbLeft.rightChannelLevel = 2.0f;

    _lbRight = [[LARSBar alloc] init];
    _lbRight.transform = CGAffineTransformMakeRotation(M_PI * 1.5);
    _lbRight.frame = CGRectMake(Sparrow.stage.height - 40.0f, 0, 40, 320);
    _lbRight.minimumValue = 0.0f;
    _lbRight.maximumValue = 2.0f;
    _lbRight.leftChannelLevel = 2.0f;
    _lbRight.rightChannelLevel = 2.0f;

    self.topBar.backButtonVisible = YES;

	return self;
}

- (void)replaceObjectsInStage:(UIInterfaceOrientation)forOrientation
{
    DDLogVerbose(@"Organizing objects for orientation: %d", [[Sparrow currentController] interfaceOrientation]);

    [self removeChild:_downButton];
    [self removeChild:_upButton];
    [self removeChild:_leftButton];
    [self removeChild:_rightButton];
    [self removeChild:_starButton];
    [self removeChild:_submenu];
    [self removeChild:_gamestateButton];
    [self removeChild:_gamestateDialogBox];
    [_lbLeft removeFromSuperview];
    [_lbRight removeFromSuperview];

    [self addChild:_mjpegViewer];

    switch (forOrientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            DDLogInfo(@"Portrait - %f x %f", Sparrow.stage.width, Sparrow.stage.height);
            _left = 0;
            _right = 0;
            _isLandscape = NO;
            
            self.topBar.text = [NSString stringWithFormat:@"%@", self.robotName];
            self.topBar.backButtonVisible = YES;
            self.topBar.visible = YES;

            _mjpegViewer.x = 0.0f;
            _mjpegViewer.y = self.topBar.y + self.topBar.height;
            _mjpegViewer.width = 320.0f;
            _mjpegViewer.height = 240.0f;

            _downButton.x = 45.0f;
            _downButton.y = (_mjpegViewer.y + 240.0f) - _downButton.height;
            
            _upButton.x = 45.0f;
            _upButton.y = _mjpegViewer.y;
            
            _leftButton.x = 0.0f;
            _leftButton.y = _mjpegViewer.y;
            
            _rightButton.x = 280.0f;
            _rightButton.y = _mjpegViewer.y;

            // _submenu.y = _starButton.y - 47.0f
            _starButton.x = 20.0f;
            _starButton.y = _mjpegViewer.y + 248.0f + (Sparrow.stage.height > 480.0f? 140.0f : 62.0f);

            _submenu.x = 87.0f;
            _submenu.y = _starButton.y - 47.0f;

            _gamestateButton.x = 101.0f;
            _gamestateButton.y = _mjpegViewer.y + 248.0f + (Sparrow.stage.height > 480.0f? 140.0f : 62.0f);
            
            [self addChild:_downButton];
            [self addChild:_upButton];
            [self addChild:_leftButton];
            [self addChild:_rightButton];
            [self addChild:_starButton];
            [self addChild:_gamestateButton];
            [self addChild:_submenu];

            // Do not hide the status bar
            [[UIApplication sharedApplication] setStatusBarHidden:NO
                                                    withAnimation:UIStatusBarAnimationSlide];

            _mjpegViewer.rotation = 0;

            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            DDLogInfo(@"Landscape - %f x %f", Sparrow.stage.width, Sparrow.stage.height);
            self.topBar.visible = NO;
            _isLandscape = YES;

            // It is completely stupid, but width and height in Sparrow don't change, so
            // we have to think as if we were in portrait, with the exception that what
            // is now called 'width' it is 'height' in Landscape, and viceversa.
            _mjpegViewer.width = Sparrow.stage.width;
            _mjpegViewer.height = Sparrow.stage.height;

            // While x and y coordinates do change, as they are relative to the status bar.
            _mjpegViewer.x = 0.0f;
            _mjpegViewer.y = 0.0f;

            [[Sparrow currentController].view addSubview:_lbLeft];
            [[Sparrow currentController].view addSubview:_lbRight];

            // Hide the status bar
            [[UIApplication sharedApplication] setStatusBarHidden:YES
                                                    withAnimation:UIStatusBarAnimationSlide];
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
	
    [self addEventListener:@selector(onOrientationChanged:)
                  atObject:self
                   forType:OR_EVENT_ORIENTATION_ANIMATION_CHANGED];
	
#pragma mark - Background thread for Input messages
	// Background thread handling the logic of constantly sending a message
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		while (_running) {
            using namespace orwell::messages;
            Input input;

            if (_isLandscape) {
                _left = _lbLeft.value - 1.0f;
                _right = _lbRight.value - 1.0f;
                DDLogVerbose(@"In landscape: _left = %.2f - _right = %.2f", _left, _right);
            }

            input.mutable_move()->set_left(_left);
            input.mutable_move()->set_right(_right);

            ORServerMessage *message = [[ORServerMessage alloc] init];
            message.tag = @"Input ";
            message.receiver = @"TANK_0 ";
            message.payload = [NSData dataWithBytes:input.SerializeAsString().c_str()
                                             length:input.SerializeAsString().length()];
            [_serverCommunicator pushMessage:message];
            usleep(1000 * 100); // Send 4 messages per second
		}
		
		DDLogInfo(@"Leaving background thread");
	});
}


#pragma mark - Callback responder
- (BOOL)messageReceived:(NSDictionary *)message
{
	NSNumber *playing = [message objectForKey:CB_GAMESTATE_KEY_PLAYING];

	if (playing != nil)
        self.topBar.text = [NSString stringWithFormat:@"%@ (%llu)", _robotName, _gamestateCounts++];

	return YES;
}

#pragma mark - Events methods
- (void)onDownButtonClicked:(SPTouchEvent *)event
{
    SPTween *alphaAnimator = [SPTween tweenWithTarget:_downButton time:0.5f];
    
    if ([[event touchesWithTarget:_downButton andPhase:SPTouchPhaseBegan] allObjects].count) {
        DDLogInfo(@"Down button started");
        _left = -1;
        _right = -1;
        [alphaAnimator animateProperty:@"backgroundAlpha" targetValue:0.75f];
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

- (void)onStarButtonClicked:(SPEvent *)event
{
    DDLogInfo(@"StarButton clicked");

    if (!_submenu.visible) {
        [_submenu animateAppear:0.50f];
        SPTexture *tmp = _starButton.upState;
        _starButton.upState = _starButton.downState;
        _starButton.downState = tmp;
    }

    else {
        [_submenu animateDisappear:0.50f];
        SPTexture *tmp = _starButton.downState;
        _starButton.downState = _starButton.upState;
        _starButton.upState = tmp;
    }
}

- (void)onGamestateButtonClicked:(SPEvent *)event
{
    DDLogInfo(@"Gamestate");
    _gamestateDialogBox.x = 40.0f;
    _gamestateDialogBox.y = 110.0f;
    [self addChild:_gamestateDialogBox];
}

- (void)onFireLeft:(SPEvent *)event
{
    DDLogInfo(@"Fire left");
}

- (void)onFireRight:(SPEvent *)event
{
    DDLogInfo(@"Fire right");
}

- (void)onResetControls:(SPEvent *)event
{
    DDLogInfo(@"Reset controls");
}

- (void)willGoBack
{
    DDLogInfo(@"Back button pressed");
	[_serverCommunicator deleteResponder:self forMessage:@"GameState"];
	_running = NO;

    [_lbLeft removeFromSuperview];
    _lbLeft = nil;
    [_lbRight removeFromSuperview];
    _lbRight = nil;

    [_mjpegViewer stop];
    _mjpegViewer = nil;
    [_serverCommunicator disconnect];
    
    ORViewController *viewController = (ORViewController *)[Sparrow currentController];
    viewController.supportedOrientations = UIInterfaceOrientationPortrait;
}

- (void)onOrientationChanged:(SPEvent *)event
{
    DDLogInfo(@"Orientation changed");
    OREventOrientation *eventOrientation = (OREventOrientation *)event;
    
    [self replaceObjectsInStage:eventOrientation.orientation];
}

#pragma mark - Dialog box delegate methods
- (void)dialogBox:(ORDialogBox *)dialogBox startedMoveAtX:(float)x andY:(float)y
{

}

- (void)dialogBox:(ORDialogBox *)dialogBox continuedMovingAtX:(float)x andY:(float)y
{

}

- (void)dialogBox:(ORDialogBox *)dialogBox didMoveAtX:(float)x andY:(float)y
{

}

- (void)dialogBoxWantsToLeave:(ORDialogBox *)dialogBox
{
    [self removeChild:dialogBox];
}

@end
