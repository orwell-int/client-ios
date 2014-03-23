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
#import "ServerCommunicator.h"
#import "CallbackResponder.h"
#import "ORButton.h"
#import "ORTextField.h"
#import "InputGameScene.h"

#import "controller.pb.h"

@interface PlayGameScene() <CallbackResponder, UITextFieldDelegate>
@property (strong, nonatomic) ORTextField *header;
@property (strong, nonatomic) ORTextField *response;
@property (strong, nonatomic) UITextField *inputPlayerName;
@property (strong, nonatomic) ORButton *startButton;
@property (weak, nonatomic) ServerCommunicator *serverCommunicator;
@property (strong, nonatomic) InputGameScene *inputGameScene;
@property (nonatomic) BOOL messageSent;

-(void) onSubSceneClosing:(SPEvent *)event;

@end

@implementation PlayGameScene

@synthesize header = _header;
@synthesize inputPlayerName = _inputPlayerName;
@synthesize serverCommunicator = _serverCommunicator;
@synthesize startButton = _startButton;
@synthesize response = _response;
@synthesize messageSent = _messageSent;
@synthesize inputGameScene = _inputGameScene;

- (id)init
{
	self = [super init];
	[self addBackButton];
	[self registerSelector:@selector(onBackButton:)];
	
	_serverCommunicator = [ServerCommunicator initSingleton];
	[self.serverCommunicator registerResponder:self forMessage:@"Welcome"];
	_inputPlayerName = [[UITextField alloc] init];
	_header = [ORTextField textFieldWithWidth:Sparrow.stage.width - 30 height:40.0f text:@"Welcome to iOrwell"];
	_response = [ORTextField textFieldWithWidth:Sparrow.stage.width - 30 height:40.0f text:@"Waiting for response"];
	_startButton = [[ORButton alloc] initWithText:@"Start"];
	
	_messageSent = NO;
	
	[self addEventListener:@selector(onSubSceneClosing:) atObject:self forType:EVENT_TYPE_INPUT_SCENE_CLOSING];
	
	return self;
}

- (void)onBackButton:(SPEvent *)event
{
	[self unregisterSelector:@selector(onBackButton:)];
	[self dispatchEventWithType:EVENT_TYPE_SCENE_CLOSING bubbles:YES];
	
	[_inputPlayerName removeFromSuperview];
}

- (BOOL)messageReceived:(NSDictionary *)message
{
	NSLog(@"Welcome message received");
	
	_response.text = [message objectForKey:CB_WELCOME_KEY_ROBOT];
	_messageSent = YES;
	
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
		}
	});
	
	return YES;
}

- (void)placeObjectInStage
{
	float usableHeight;
	static const float space = 15.0f;
	
	NSLog(@"Placing objects in stage for PlayGameScene");
	
	_header.x = 15.0f;
	_header.y = 20.0f;
	usableHeight = _header.y + _header.height + space;

	_inputPlayerName.frame = CGRectMake(15.0f, usableHeight, Sparrow.stage.width - 30.0f, 30.0f);
	_inputPlayerName.placeholder = @"Type your name";
	_inputPlayerName.delegate = self;
	_inputPlayerName.borderStyle = UITextBorderStyleRoundedRect;
	[Sparrow.currentController.view addSubview:_inputPlayerName];
	
	usableHeight = _inputPlayerName.frame.origin.y + _inputPlayerName.frame.size.height + space;
	
	_startButton.x = (Sparrow.stage.width / 2) - (_startButton.width / 2);
	_startButton.y = usableHeight;
	
	// I am weak.
	__weak PlayGameScene *wself = self;
	[_startButton addEventListenerForType:SP_EVENT_TYPE_TRIGGERED block:^(SPEvent *event) {
		NSLog(@"StartButton handling..");
		
		if ([wself.inputPlayerName.text isEqualToString:@""])
			return;

		orwell::messages::Hello hello;
		NSLog(@"Player name will be: %@", wself.inputPlayerName.text);
		hello.set_name([wself.inputPlayerName.text cStringUsingEncoding:NSASCIIStringEncoding]);
		hello.set_ip("0");
		hello.set_port(0);
		
		ServerMessage *msg = [[ServerMessage alloc] init];
		msg.payload = [NSData dataWithBytes:hello.SerializeAsString().c_str() length:hello.SerializeAsString().size()];
		msg.receiver = @"iphoneclient ";
		msg.tag = @"Hello " ;
		
		[wself.serverCommunicator pushMessage:msg];
		
	}];
	
	usableHeight = _startButton.y + _startButton.height + space;
	
	_response.x = 15.0f;
	_response.y = usableHeight;
	
	[self addChild:_header];
	[self addChild:_startButton];
	[self addChild:_response];
}

- (void)startObjects
{
	NSLog(@"Starting logic of PlayGameScene");
	[_serverCommunicator retrieveServerFromBroadcast];
	[_serverCommunicator connect];
	[_serverCommunicator runSubscriber];
	[_serverCommunicator registerResponder:self forMessage:@"Welcome"];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[_inputPlayerName resignFirstResponder];
	return YES;
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
}

@end
