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

#import "robot.pb.h"
#import "controller.pb.h"

#import <MotionJpegImageView.h>

@interface InputGameScene() <CallbackResponder>
@property (strong, nonatomic) ORTextField *playerTextField;
@property (strong, nonatomic) ORTextField *feedbackTextField;
@property (strong, nonatomic) ServerCommunicator *serverCommunicator;

@property (strong, nonatomic) ORArrowButton *leftButton;
@property (strong, nonatomic) ORArrowButton *downButton;
@property (strong, nonatomic) ORArrowButton *rightButton;
@property (strong, nonatomic) ORArrowButton *upButton;
@property (strong, nonatomic) NSMutableArray *buttonsArray;
@property (strong, nonatomic) MotionJpegImageView *mjpegViewer;

@end

@implementation InputGameScene

@synthesize playerTextField = _playerTextField;
@synthesize serverCommunicator = _serverCommunicator;
@synthesize leftButton = _leftButton;
@synthesize downButton = _downButton;
@synthesize rightButton = _rightButton;
@synthesize upButton = _upButton;
@synthesize buttonsArray = _buttonsArray;
@synthesize mjpegViewer = _mjpegViewer;
@synthesize feedbackTextField = _feedbackTextField;

- (id)init
{
	self = [super init];
	[self addBackButton];
	[self registerSelector:@selector(onBackButton:)];
	
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
	_mjpegViewer = [[MotionJpegImageView alloc] initWithFrame:CGRectMake(0.0f, 70.0f, 320.0f, 240.0f)];
	_mjpegViewer.url = [NSURL URLWithString:@"http://87.232.128.229/axis-cgi/mjpg/video.cgi"];
	_mjpegViewer.hidden = NO;


	// Event block
	for (ORArrowButton *button in _buttonsArray) {
		[button addEventListenerForType:SP_EVENT_TYPE_TRIGGERED block:^(SPEvent *event) {
			using namespace orwell::messages;
			ORArrowButton *button = (ORArrowButton *) event.target;
			DDLogInfo(@"Button %@ pressed, rotation: %d", button.name, button.rotation);

			double left = 0, right = 0;
			
			Input inputMessage;
			switch (button.rotation) {
				case UP:
					left = 1;
					right = 1;
					break;
				case DOWN:
					left = -1;
					right = -1;
					break;
				case LEFT:
					left = 1;
					right = -1;
					break;
				case RIGHT:
					left = -1;
					right = 1;
					break;
			}
			
			DDLogDebug(@"Sending message with left: %f, right: %f", left, right);
			
			inputMessage.mutable_move()->set_left(left);
			inputMessage.mutable_move()->set_right(right);
			inputMessage.mutable_fire()->set_weapon1(false);
			inputMessage.mutable_fire()->set_weapon2(false);
			
			ServerMessage *message = [[ServerMessage alloc] init];
			message.tag = @"Input ";
			message.receiver = @"iphoneclient ";
			message.payload = [NSData dataWithBytes:inputMessage.SerializeAsString().c_str() length:inputMessage.SerializeAsString().length()];
			DDLogDebug(@"Pushing message Input");
			
			[_serverCommunicator pushMessage:message];
			[_mjpegViewer pause];
			[_mjpegViewer play];

		}];
	}
	
	// This is active already
	_serverCommunicator = [ServerCommunicator initSingleton];
	[_serverCommunicator registerResponder:self forMessage:@"Input"];
	[_serverCommunicator registerResponder:self forMessage:@"GameState"];

	return self;
}

- (void)onBackButton:(SPEvent *)event
{
	[self unregisterSelector:@selector(onBackButton:)];
	[self dispatchEventWithType:EVENT_TYPE_INPUT_SCENE_CLOSING bubbles:YES];

	[_mjpegViewer removeFromSuperview];
}

- (void)placeObjectInStage
{
	DDLogDebug(@"Inited with robot name: %@", self.robotName);
	DDLogDebug(@"Inited with player name: %@", self.playerName);

	DDLogDebug(@"Placed mjpegViewer in screen %@", [_mjpegViewer debugDescription]);

	self.playerTextField.text = [NSString stringWithFormat:@"%@ @ %@", self.playerName, self.robotName];
	self.playerTextField.x = 0.0f;
	self.playerTextField.y = 0.0f;
	[self addChild:self.playerTextField];
	[Sparrow.currentController.view addSubview:_mjpegViewer];
	
	_downButton.width = 240.0f;
	_downButton.height = 40.0f;
	_downButton.x = 40.0f;
	_downButton.y = 270.0f;
	[self addChild:_downButton];

	_feedbackTextField.x = 0.0f;
	_feedbackTextField.y = 330.0f;
	[self addChild:_feedbackTextField];
	
//	[self addChild:self.rightButton];
//	[self addChild:self.downButton];
//	[self addChild:self.leftButton];
//	[self addChild:self.upButton];
}

- (void)startObjects
{
	[_serverCommunicator registerResponder:self forMessage:@"Input"];
	[_mjpegViewer play];
}

- (BOOL)messageReceived:(NSDictionary *)message
{
	DDLogVerbose(@"Received message : %@", [message debugDescription]);
	NSNumber *playing = [message objectForKey:CB_GAMESTATE_KEY_PLAYING];
	if (playing != nil) {
		_feedbackTextField.text = @"GameState received";
	}
	
	return YES;
}

@end
