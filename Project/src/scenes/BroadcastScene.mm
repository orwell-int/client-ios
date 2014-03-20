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

#import "BroadcastScene.h"
#import "ORButton.h"
#import <sys/types.h>
#import "ORBroadcastRetriever.h"

@interface BroadcastScene()
- (void) launchTest:(SPEvent *)event;

@end

@implementation BroadcastScene
{
	SPTextField *_textField;
	ORButton *_launchTest;
	SPTextField *_result;
	UITextField *_input;
	
	// C++ Objects here..
	std::string _message;
}

- (id)init
{
	self = [super init];
	
	[self addBackButton];
	[self registerSelector:@selector(onBackButton:)];
	
	_textField = [SPTextField textFieldWithWidth:Sparrow.stage.width - 30
										  height:180
											text:@"Lorem ipsum"];
	
	_result = [SPTextField textFieldWithWidth:Sparrow.stage.width - 30 height:80 text:@""];
	
	_textField.y = 15;
	_textField.x = 15;
	
	_textField.fontName = @"Verdana";
	_textField.fontSize = 16;
	_textField.hAlign = SPHAlignLeft;
	_textField.vAlign = SPVAlignTop;
	_textField.text = @"Welcome to the broadcast test. Press the button below to fire a broadcast message to the local network, you will see what happens! Do not forget to start the server ;)\nTimeout is 5 seconds.";
	
	[self addChild:_textField];
		
	_launchTest = [[ORButton alloc] initWithText:@"Launch test"];
	_launchTest.name = @"TestLauncher";
	
	_launchTest.x = (Sparrow.stage.width/2) - (_launchTest.width/2);
	_launchTest.y = _textField.y + _textField.height + 10;
	
	[_launchTest addEventListener:@selector(launchTest:) atObject:self forType:SP_EVENT_TYPE_TRIGGERED];
	
	[self addChild:_launchTest];
	
	_result.x = 15;
	_result.y = _launchTest.y + _launchTest.height + 10;
	_result.vAlign = SPVAlignTop;
	_result.hAlign = SPHAlignLeft;
	_result.fontName = @"Verdana";
	_result.fontSize = 14;
	
	_input = [[UITextField alloc] initWithFrame:CGRectMake(
														   15.0f,
														   _textField.y + (_textField.height - 30.0f),
														   Sparrow.stage.width - 30.0f,
														   30.0f)];
	_input.font = [UIFont fontWithName:@"Helvetica" size:15];
	_input.clearsOnBeginEditing = YES;
	_input.placeholder = @"Enter the message here";
	_input.delegate = self;
	_input.borderStyle = UITextBorderStyleRoundedRect;
	
	[self addChild:_result];
	SPViewController *controller = Sparrow.currentController;
	[controller.view addSubview:_input];
	
	return self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	
	_message = std::string([textField.text UTF8String]);
	
	return YES;
}

- (void)onBackButton:(SPEvent *)event
{
	[self unregisterSelector:@selector(onBackButton:)];
	[self dispatchEventWithType:EVENT_TYPE_SCENE_CLOSING bubbles:YES];
	
	[_input removeFromSuperview];
}

- (void)launchTest:(SPEvent *)event
{
	DDLogDebug(@"Launching test...");
	_result.text = @"Launching test...";
	
	struct timeval tv;
	tv.tv_sec = 5;
	tv.tv_usec = 3000;
	
	DDLogDebug(@"Sending message: %s", _message.c_str());
	
	ORBroadcastRetriever *retriever = [ORBroadcastRetriever retrieverWithTimeout:2];
	if ([retriever retrieveAddress]) {
		_result.text = [NSString stringWithFormat:@"Got from %@\nIP1: %@\nIP2: %@",
						retriever.responderIp, retriever.firstIp, retriever.secondIp];
	}
	else {
		_result.text = @"Could not retrieve broadcast address";
		DDLogWarn(@"Could not retrieve broadcast address");
	}
}

@end
