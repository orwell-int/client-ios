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

@interface InputGameScene() <CallbackResponder>
@property (strong, nonatomic) ORTextField *playerTextField;
@property (strong, nonatomic) ServerCommunicator *serverCommunicator;
@property (strong, nonatomic) ORArrowButton *leftButton;
@end

@implementation InputGameScene

@synthesize playerTextField = _playerTextField;
@synthesize serverCommunicator = _serverCommunicator;
@synthesize leftButton = _leftButton;

- (id)init
{
	self = [super init];
	[self addBackButton];
	[self registerSelector:@selector(onBackButton:)];
	
	_playerTextField = [ORTextField textFieldWithWidth:Sparrow.stage.width - 30.0f height:40.0f text:@""];
	_leftButton = [[ORArrowButton alloc] init];
	
	// This is active already
	_serverCommunicator = [ServerCommunicator initSingleton];

	return self;
}

- (void)onBackButton:(SPEvent *)event
{
	[self unregisterSelector:@selector(onBackButton:)];
	[self dispatchEventWithType:EVENT_TYPE_INPUT_SCENE_CLOSING bubbles:YES];
}

- (void)placeObjectInStage
{
	NSLog(@"Inited with robot name: %@", self.robotName);
	NSLog(@"Inited with player name: %@", self.playerName);

	self.playerTextField.text = [NSString stringWithFormat:@"%@ @ %@", self.playerName, self.robotName];
	self.playerTextField.x = 15.0f;
	self.playerTextField.y = 10.0f;
	[self addChild:self.playerTextField];
	
	self.leftButton.x = 15.0f;
	self.leftButton.y = self.playerTextField.y + self.playerTextField.height + 15.0f;
	[self addChild:self.leftButton];
}

- (void)startObjects
{
	[_serverCommunicator registerResponder:self forMessage:@"Input"];
}

- (BOOL)messageReceived:(NSDictionary *)message
{
	return YES;
}

@end
