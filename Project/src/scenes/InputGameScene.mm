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

@end

@implementation InputGameScene

- (id)init
{
	self = [super init];
	[self addBackButton];
	
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

	// Event block
	for (ORArrowButton *button in _buttonsArray) {
		__weak InputGameScene *wself = self;
		[button addEventListenerForType:SP_EVENT_TYPE_TRIGGERED block:^(SPEvent *event) {
			using namespace orwell::messages;
			__weak ORArrowButton *button = (ORArrowButton *) event.target;
			DDLogInfo(@"Button %@ pressed, rotation: %d", button.name, button.rotation);

			button.backgroundAlpha = 0.0f;
			SPTween *alphaAnimator = [SPTween tweenWithTarget:button time:0.5f];
			[alphaAnimator animateProperty:@"backgroundAlpha" targetValue:1.0f];
			alphaAnimator.reverse = YES;
			alphaAnimator.repeatCount = 2;
			[Sparrow.juggler addObject:alphaAnimator];
			
			// Make sure the Tween is removed at the end of the animation
			__weak SPTween *weakAlphaAnimator = alphaAnimator;
			[alphaAnimator addEventListenerForType:SP_EVENT_TYPE_COMPLETED block:^(id event){
				DDLogInfo(@"Removing tween");
				[Sparrow.juggler removeObject:weakAlphaAnimator];
			}];
			
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
			
			[wself.serverCommunicator pushMessage:message];
		}];
	}

	return self;
}

- (void)onBackButton:(SPEvent *)event
{
	[self unregisterSelector:@selector(onBackButton:)];
	[self dispatchEventWithType:EVENT_TYPE_INPUT_SCENE_CLOSING bubbles:YES];
	[_serverCommunicator deleteResponder:self forMessage:@"GameState"];
	[_serverCommunicator deleteResponder:self forMessage:@"Input"];
}

- (void)placeObjectInStage
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
	[self addChild:_feedbackTextField];
	
	[self addChild:_downButton];
	[self addChild:_upButton];
	[self addChild:_leftButton];
	[self addChild:_rightButton];
}

- (void)startObjects
{
	// This is active already
	_serverCommunicator = [ServerCommunicator initSingleton];
	[_serverCommunicator registerResponder:self forMessage:@"Input"];
	[_serverCommunicator registerResponder:self forMessage:@"GameState"];
	
	[self registerSelector:@selector(onBackButton:)];
}

- (BOOL)messageReceived:(NSDictionary *)message
{
	static int count = 0;
	DDLogVerbose(@"Received message : %@", [message debugDescription]);
	NSNumber *playing = [message objectForKey:CB_GAMESTATE_KEY_PLAYING];

	if (playing != nil) {
		_feedbackTextField.text = [NSString stringWithFormat:@"GameState received (%d)", count++];
	}

	return YES;
}

@end
