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

#import "PlayGameScene.h"
#import "ORServerCommunicator.h"
#import "CallbackResponder.h"
#import "ORButton.h"
#import "ORTextField.h"
#import "InputGameScene.h"

#import "controller.pb.h"
#import "ORServerCommunicatorDelegate.h"
#import "ORZMQURL.h"
#import "ORViewController.h"
#import "OREventOrientation.h"

#pragma mark Interface begins
@interface PlayGameScene() <CallbackResponder, UITextFieldDelegate, ORServerCommunicatorDelegate>
@property (strong, nonatomic) ORTextField *header;
@property (strong, nonatomic) UITextField *inputPlayerName;
@property (strong, nonatomic) UITextField *inputServerInfo;
@property (strong, nonatomic) ORButton *startButton;
@property (weak, nonatomic) ORServerCommunicator *serverCommunicator;
@property (strong, nonatomic) InputGameScene *inputGameScene;
@property (nonatomic) BOOL messageSent;

- (void)onSubSceneClosing:(SPEvent *)event;
- (void)communicator:(ORServerCommunicator *)server didRetrieveServerFromBroadcast:(BOOL)retrieve withIP:(NSString *)serverIP;
- (void)communicator:(ORServerCommunicator *)server didConnectToServer:(BOOL)connect;
- (void)serverDidDisconnectFromServer;
- (void)onConnectButtonPressed:(SPEvent *)event;

@end

#pragma mark Implementation begins
@implementation PlayGameScene

#pragma mark Init methods
- (id)init
{
	self = [super init];
	[self addBackButton];
	[self registerSelector:@selector(onBackButton:)];
	
	_serverCommunicator = [ORServerCommunicator singleton];
	_serverCommunicator.delegate = self;
	[self.serverCommunicator registerResponder:self forMessage:@"Welcome"];
	_inputPlayerName = [[UITextField alloc] init];
	_inputServerInfo = [[UITextField alloc] init];

	_header = [ORTextField textFieldWithWidth:320.0f height:60.0f text:@"Connect to a server"];
	_startButton = [[ORButton alloc] initWithText:@"Connect"];
	_startButton.name = @"connect";
	
	_messageSent = NO;

	// Register selectors
	[self addEventListener:@selector(onSubSceneClosing:)
				  atObject:self
				   forType:EVENT_TYPE_INPUT_SCENE_CLOSING];
	
	return self;
}

- (void)placeObjectInStage
{
	DDLogInfo(@"Placing object in stage for PlayGameScene");
	
	_header.x = 0.0f;
	_header.y = 0.0f;
	[self addChild:_header];
	
	_inputPlayerName.frame = CGRectMake(20.0f, 80.0f, 280.0f, 40.0f);
	_inputPlayerName.placeholder = @"Type your name";
	_inputPlayerName.delegate = self;
	_inputPlayerName.borderStyle = UITextBorderStyleRoundedRect;
	[Sparrow.currentController.view addSubview:_inputPlayerName];
	
	_inputServerInfo.frame = CGRectMake(20.0f, 140.0f, 280.0f, 40.0f);
	_inputServerInfo.placeholder = @"server:puller,pusher";
	_inputServerInfo.delegate = self;
	_inputServerInfo.borderStyle = UITextBorderStyleRoundedRect;
	[Sparrow.currentController.view addSubview:_inputServerInfo];
	
	_startButton.x = Sparrow.stage.width / 2 - (_startButton.width / 2);
	_startButton.y = 220.0f;
	[self addChild:_startButton];
	
	// Avoid having multiple blocks
	if (![_startButton hasEventListenerForType:SP_EVENT_TYPE_TRIGGERED])
		[_startButton addEventListener:@selector(onConnectButtonPressed:) atObject:self forType:SP_EVENT_TYPE_TRIGGERED];
}

- (void)startObjects
{
	NSLog(@"Starting logic of PlayGameScene");
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		[_serverCommunicator retrieveServerFromBroadcast];
	});
}

#pragma mark Callbacks responder
- (BOOL)messageReceived:(NSDictionary *)message
{
	DDLogDebug(@"Message received");
	
	_messageSent = YES;
	
	if ([message objectForKey:CB_WELCOME_KEY_ROBOT] != nil) {
		// This has to be done in the main thread
		dispatch_async(dispatch_get_main_queue(), ^(){
			if (_inputGameScene == nil) {
				_inputGameScene = [[InputGameScene alloc] init];

				_inputGameScene.robotName = [message objectForKey:CB_WELCOME_KEY_ROBOT];
				_inputGameScene.playerName = [NSString stringWithString:_inputPlayerName.text];
				[_inputGameScene placeObjectInStage];
				[_inputGameScene startObjects];
				[self addChild:_inputGameScene];
				[_inputPlayerName removeFromSuperview];
				[_inputServerInfo removeFromSuperview];

				// Unregister callbacks
				[_serverCommunicator deleteResponder:self forMessage:@"Welcome"];
				[_serverCommunicator deleteResponder:self forMessage:@"Goodbye"];
			}
		});
	}
	else {
		// We have received a Goodbye message, notify the user
		dispatch_async(dispatch_get_main_queue(), ^{
			_header.text = @"Goodbye message received";
		});
	}
	
	return YES;
}

#pragma mark Generic events handling
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if (textField == _inputServerInfo) {
		[_serverCommunicator disconnect];
	}
}

- (void)onSubSceneClosing:(SPEvent *)event
{
	if (_inputGameScene) {
		[_inputGameScene removeFromParent];
		__weak NSString *playerName = [NSString stringWithString:_inputGameScene.playerName];
		_inputPlayerName.text = playerName;
		_inputGameScene = nil;
	}

	[Sparrow.currentController.view addSubview:_inputPlayerName];
	[Sparrow.currentController.view addSubview:_inputServerInfo];
}

- (void)onBackButton:(SPEvent *)event
{
	[self unregisterSelector:@selector(onBackButton:)];
	[self dispatchEventWithType:EVENT_TYPE_SCENE_CLOSING bubbles:YES];
	
	[_inputPlayerName removeFromSuperview];
	[_inputServerInfo removeFromSuperview];
}

- (void)onConnectButtonPressed:(SPEvent *)event
{
	DDLogVerbose(@"StartButton handling..");
	if ([_startButton.name isEqualToString:@"play"]) {
		DDLogInfo(@"Handling the play logic");
		if ([_inputPlayerName.text isEqualToString:@""]) {
			_header.text = @"Name is not valid!";
			return;
		}
		
		orwell::messages::Hello hello;
		DDLogDebug(@"Player name will be: %@", _inputPlayerName.text);
		hello.set_name([_inputPlayerName.text cStringUsingEncoding:NSASCIIStringEncoding]);
		hello.set_ip("0");
		hello.set_port(0);
		
		ORServerMessage *msg = [[ORServerMessage alloc] init];
		msg.payload = [NSData dataWithBytes:hello.SerializeAsString().c_str() length:hello.SerializeAsString().size()];
		msg.receiver = @"iphoneclient ";
		msg.tag = @"Hello " ;
		
		[_serverCommunicator pushMessage:msg];
	}
	else {
		DDLogInfo(@"Handling the connect logic");
		ORZMQURL *url = [[ORZMQURL alloc] initWithString:_inputServerInfo.text];
		url.protocol = ZMQTCP;
		if ([url isValid]) {
			_serverCommunicator.pusherIp = [url pusherToString];
			_serverCommunicator.pullerIp = [url pullerToString];
			[_serverCommunicator connect];
		}
		else {
			_header.text = @"IP is not valid";
		}
	}
}

#pragma mark Communicator delegate methods
- (void)communicator:(ORServerCommunicator *)communicator didConnectToServer:(BOOL)connect
{
	dispatch_async(dispatch_get_main_queue(), ^(){
		DDLogInfo(@"ServerCommunicator didConnectToServer: %@", @(connect));
		if (connect) {
			[_serverCommunicator runSubscriber];
			[_serverCommunicator registerResponder:self forMessage:@"Welcome"];
			[_serverCommunicator registerResponder:self forMessage:@"Goodbye"];
			_header.text = @"Connected!";
			_startButton.text = @"Play!";
			_startButton.name = @"play";
		}
		else {
			_header.text = @"Unable to connect to server";
		}
	});
}

- (void)communicator:(ORServerCommunicator *)communicator didRetrieveServerFromBroadcast:(BOOL)retrieve withIP:(NSString *)serverIP
{
	dispatch_async(dispatch_get_main_queue(), ^(){
		DDLogInfo(@"Server Communicator retrieved server from broadcast: %@ : %@", @(retrieve), serverIP);
		if (retrieve) {
			_header.text = [NSString stringWithFormat:@"Retrieved %@", serverIP];
			_inputServerInfo.text = [NSString stringWithFormat:@"%@", serverIP];
		}
		else {
			_header.text = @"Broadcast Failed";
		}	
	});
}

- (void)serverDidDisconnectFromServer
{
	dispatch_async(dispatch_get_main_queue(), ^(){
		_header.text = @"Disconnected";
		_startButton.text = @"Connect";
		_startButton.name = @"connect";
	});
}


@end
