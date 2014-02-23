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

#import "FlowScene.h"
#import "MessagesWrapper.h"
#import "ServerCommunicator.h"
#import "controller.pb.h"
#import "CallbackResponder.h"
#import "Callback.h"

#import "ORButton.h"
#import "ORTextField.h"


@interface FlowScene() <CallbackResponder>
- (void)launchTest;
- (void)communicatorDidRetrieveAddress;
- (void)communicatorDidNotRetrieveAddress;
- (BOOL)messageReceived:(NSDictionary *)message;

@end

@implementation FlowScene
{
	MessagesWrapper *_messageWrapper;
	ServerCommunicator *_serverCommunicator;
	SPImage *_marvin;
	SPTween *_loadingAnimator;
	
	ORButton *_launchTestButton;
	ORTextField *_response;
	ORTextField *_gameState;
}

- (id)init
{
	self = [super init];
	[self addBackButton];
	[self registerSelector:@selector(onBackButton:)];
	
	_messageWrapper = [[MessagesWrapper alloc] init];
	_serverCommunicator = [ServerCommunicator initSingleton];
	
	_launchTestButton = [[ORButton alloc] initWithText:@"Launch Test"];

	_launchTestButton.x = (Sparrow.stage.width / 2) - (_launchTestButton.width / 2);
	_launchTestButton.y = 40.0f;
	
	_launchTestButton.touchable = NO;
	
	_response = [ORTextField textFieldWithWidth:Sparrow.stage.width - 30.0f height:60.0f text:@"Retrieving IP"];
	_response.x = 15.0f;
	_response.y = _launchTestButton.y + _launchTestButton.height + 10.0f;
	
	_gameState = [ORTextField textFieldWithWidth:Sparrow.stage.width - 30.0f height:60.0f text:@""];
	_gameState.x = 15.0f;
	_gameState.y = _response.y + _response.height + 10.0f;
	
	_marvin = [SPImage imageWithContentsOfFile:@"marvin.png"];
	_loadingAnimator = [SPTween tweenWithTarget:_marvin time:0.5f];
	[_loadingAnimator animateProperty:@"alpha" targetValue:0];
	_loadingAnimator.repeatCount = 0;
	_loadingAnimator.reverse = YES;
	[Sparrow.juggler addObject:_loadingAnimator];
	
	_marvin.x = (Sparrow.stage.width / 2) - (_marvin.width / 2);
	_marvin.y = [self getBackButtonY] - _marvin.height - 10.0f;
	
	[self addChild:_marvin];
	
	// Better not have a strong relationship with myself.
	__weak FlowScene *weakSelf = self;
	[_launchTestButton addEventListenerForType:SP_EVENT_TYPE_TRIGGERED
										 block:^(id par) {
		[weakSelf launchTest];
	}];
	
	[self addChild:_launchTestButton];
	[self addChild:_response];
	[self addChild:_gameState];
	
	
	dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_async(q, ^{
		BOOL ret = NO;
		
		ret = [_serverCommunicator retrieveServerFromBroadcast];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (ret) [self communicatorDidRetrieveAddress];
			else [self communicatorDidNotRetrieveAddress];
		});
		
	});
	
	return self;
}

- (void)communicatorDidRetrieveAddress
{
	[_serverCommunicator connect];
	[_serverCommunicator registerResponder:self forMessage:@"Welcome"];
	[_serverCommunicator registerResponder:self forMessage:@"GameState"];
	[_serverCommunicator registerResponder:self forMessage:@"Goodbye"];
	
	_response.text = [NSString stringWithFormat:@"IP %@", _serverCommunicator.serverIp];
	_launchTestButton.touchable = YES;

	[Sparrow.juggler removeObject:_loadingAnimator];
	_marvin.alpha = 1.0f;
}

- (void)communicatorDidNotRetrieveAddress
{
	_response.text = @"Failed Broadcast";

	[Sparrow.juggler removeObject:_loadingAnimator];
	_marvin.alpha = 1.0f;
}

- (void)launchTest
{
	using namespace orwell::messages;
	[_serverCommunicator runSubscriber];
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	orwell::messages::Hello *helloMsg = (orwell::messages::Hello *) [MessagesWrapper buildMessage:@"HELLO"
																				   withDictionary:dict];
	
	ServerMessage *msg = [[ServerMessage alloc] init];
	msg.tag = @"Hello ";
	msg.receiver = @"randomid ";
	
	NSData *data = [NSData dataWithBytes:(const void *) helloMsg->SerializeAsString().c_str()
								  length:helloMsg->SerializeAsString().size()];

	msg.payload = data;
	
	NSLog(@"About to send message: %@,%@,%s", msg.receiver, msg.tag, (const char *) [msg.payload bytes]);
	
	[_serverCommunicator pushMessage:msg];
}

-(void)onBackButton:(SPEvent *)event
{
	[self unregisterSelector:@selector(onBackButton:)];
	[self dispatchEventWithType:EVENT_TYPE_SCENE_CLOSING bubbles:YES];
}

- (BOOL)messageReceived:(NSDictionary *)message
{
	NSLog(@"Message Received: \n%@", [message debugDescription]);
	
	NSString *robot;
	robot = [message objectForKey:CB_WELCOME_KEY_ROBOT];
	if (robot)
		_response.text = robot;
	
	NSNumber *playing;
	playing = [message objectForKey:CB_GAMESTATE_KEY_PLAYING];
	if (playing)
		_gameState.text = [NSString stringWithFormat:@"Playing: %d", [playing boolValue]];
	
	if ([message objectForKey:CB_GOODBYE_KEY_GOODBYE])
		_response.text = @"Received Goodbye :-(";
	
	return YES;
}

@end
