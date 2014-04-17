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

#import "ServerConnectionScene.h"
#import "ORAlternativeButton.h"
#import "ORServerCommunicator.h"
#import "ORServerCommunicatorDelegate.h"
#import "ORZMQURL.h"
#import "controller.pb.h"
#import "CallbackResponder.h"
#import "InputGameScene.h"

@interface ServerConnectionScene() <UITextFieldDelegate, ORServerCommunicatorDelegate, CallbackResponder>
@end

@implementation ServerConnectionScene {
	UIImage *_fieldsBackground;
	UIImage *_fieldsBackgroundActive;
	UIView *_paddingInputPlayerName;
	UIView *_paddingInputServerInfo;
	UITextField *_inputPlayerName;
	UITextField *_inputServerInfo;
	ORAlternativeButton *_connectButton;
	SPImage *_techStuff;
	InputGameScene *_inputGameScene;

	ORServerCommunicator *_communicator;
}

#pragma mark - Initialization of object
- (id)init
{
	if (self = [super init]) {
		self.topBar.visible = YES;
		self.topBar.backButtonVisible = YES;
		self.topBar.text = @"Choose a server";

		_communicator = [ORServerCommunicator singleton];
		_communicator.delegate = self;
		[_communicator registerResponder:self forMessage:@"Welcome"];
		[_communicator registerResponder:self forMessage:@"Goodbye"];
		_techStuff = [SPImage imageWithContentsOfFile:@"TechStuff.png"];
		_techStuff.x = 75.0f;
		_techStuff.y = 320.0f;

		_connectButton = [[ORAlternativeButton alloc] initWithType:OR_BUTTON_CONNECT];
		_connectButton.x = 66.0f;
		_connectButton.y = 240.0f;
		[_connectButton addEventListener:@selector(onConnectButton:)
								atObject:self
								 forType:SP_EVENT_TYPE_TRIGGERED];

		// Init the textfields
		_fieldsBackground = [[UIImage imageNamed:@"InputField.png"] stretchableImageWithLeftCapWidth:20
																						topCapHeight:0];
		_fieldsBackgroundActive = [[UIImage imageNamed:@"SelectedInputField.png"] stretchableImageWithLeftCapWidth:10
																									  topCapHeight:0];
		_paddingInputPlayerName = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 28.0f, 0)];
		_paddingInputServerInfo = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 28.0f, 0)];

		_inputPlayerName = [[UITextField alloc] initWithFrame:CGRectMake(31, 83, 260, 38)];
		_inputPlayerName.background = [[UIImage imageNamed:@"InputField.png"] stretchableImageWithLeftCapWidth:20
																								  topCapHeight:0];
		_inputPlayerName.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12];
		_inputPlayerName.textColor = [UIColor colorWithRed:255 green:255 blue:255 alpha:1.0f];
		_inputPlayerName.leftView = _paddingInputPlayerName;
		_inputPlayerName.leftViewMode = UITextFieldViewModeAlways;
		_inputPlayerName.rightView = _paddingInputPlayerName;
		_inputPlayerName.rightViewMode = UITextFieldViewModeAlways;
		_inputPlayerName.delegate = self;
		NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"Player name"
																			   attributes:@{NSForegroundColorAttributeName : [UIColor grayColor]}];
		_inputPlayerName.attributedPlaceholder = attributedString;

		_inputServerInfo = [[UITextField alloc] initWithFrame:CGRectMake(31, 134, 260, 38)];
		_inputServerInfo.background = [[UIImage imageNamed:@"InputField.png"] stretchableImageWithLeftCapWidth:10
																								  topCapHeight:0];
		_inputServerInfo.font = [UIFont fontWithName:@"AmericanTypewriter" size:12];
		_inputServerInfo.textColor = [UIColor colorWithRed:255 green:255 blue:255 alpha:1.0f];
		_inputServerInfo.leftView = _paddingInputServerInfo;
		_inputServerInfo.leftViewMode = UITextFieldViewModeAlways;
		_inputServerInfo.rightView = _paddingInputServerInfo;
		_inputServerInfo.rightViewMode = UITextFieldViewModeAlways;
		_inputServerInfo.delegate = self;
		_inputServerInfo.autocorrectionType = UITextAutocorrectionTypeNo;
		_inputServerInfo.autocapitalizationType = UITextAutocapitalizationTypeNone;
		attributedString = [[NSAttributedString alloc] initWithString:@"server:puller,pusher"
														   attributes:@{NSForegroundColorAttributeName : [UIColor grayColor]}];
		_inputServerInfo.attributedPlaceholder = attributedString;

		[self addChild:_techStuff];
		[self addChild:_connectButton];

		if (_inputPlayerName)
			[Sparrow.currentController.view addSubview:_inputPlayerName];

		if (_inputServerInfo)
			[Sparrow.currentController.view addSubview:_inputServerInfo];
	}

	return self;
}

- (void)placeObjectInStage
{
	
}

- (void)startObjects
{
	[self.topBar animateBusyIndicatorWithDelay:0.5f];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		[_communicator retrieveServerFromBroadcast];
	});
}

#pragma mark - Events handling
- (void)willGoBack
{
	[_inputPlayerName removeFromSuperview];
	[_inputServerInfo removeFromSuperview];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
	textField.background = _fieldsBackgroundActive;
	textField.textColor = [UIColor colorWithRed:0 green:206 blue:155 alpha:1.0f];
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	textField.background = _fieldsBackground;
	textField.textColor = [UIColor colorWithRed:255 green:255 blue:255 alpha:1.0f];
}

- (void)communicator:(ORServerCommunicator *)communicator didRetrieveServerFromBroadcast:(BOOL)retrieve withIP:(NSString *)serverIP
{
	[self.topBar stopBusyIndicator];
	dispatch_async(dispatch_get_main_queue(), ^{
		if (retrieve) {
			_inputServerInfo.text = serverIP;
			_inputPlayerName.text = @"Ludmann";
		}
	});
}

- (void)communicator:(ORServerCommunicator *)communicator didConnectToServer:(BOOL)connect
{
	if (connect) {
		[_communicator runSubscriber];
		orwell::messages::Hello hello;
		hello.set_name([_inputPlayerName.text UTF8String]);
		hello.set_port(0);
		hello.set_ip("localhost");

		ORServerMessage *msg = [[ORServerMessage alloc] init];
		msg.receiver = @"iphoneclient ";
		msg.tag = @"Hello ";
		msg.payload = [NSData dataWithBytes:hello.SerializeAsString().c_str()
									 length:hello.SerializeAsString().size()];

		[_communicator pushMessage:msg];
	}
}

- (BOOL)messageReceived:(NSDictionary *)dictionary
{
	NSString *robotName = [dictionary objectForKey:CB_WELCOME_KEY_ROBOT];

	if (robotName != nil) {
		DDLogInfo(@"Robot name: %@", robotName);
		_inputGameScene = [[InputGameScene alloc] init];
		_inputGameScene.robotName = robotName;
		_inputGameScene.playerName = _inputPlayerName.text;
		[_inputGameScene placeObjectInStage];
		[_inputGameScene startObjects];
		[self willGoBack];

		[self addChild:_inputGameScene];
	}
	else {
		DDLogInfo(@"Goodby received");
	}
	return YES;
}

#pragma mark - Button handling
- (void)onConnectButton:(SPEvent *)event
{
	DDLogInfo(@"On connect button");
	ORZMQURL *zmqUrl = [[ORZMQURL alloc] initWithString:_inputServerInfo.text];
	zmqUrl.protocol = ZMQTCP;

	if ([_inputPlayerName.text isEqualToString:@""]) {
//		[_inputPlayerName becomeFirstResponder];
		_inputPlayerName.text = @"Ludmann";
	}
	else if (! zmqUrl.valid) {
//		[_inputServerInfo becomeFirstResponder];
		_inputServerInfo.text = @"tcp://127.0.0.1:8000,8001";
	}
	else {
//		_communicator.pullerIp = [zmqUrl pullerToString];
//		_communicator.pusherIp = [zmqUrl pusherToString];
//		[_communicator connect];
		_inputGameScene = [[InputGameScene alloc] init];
		_inputGameScene.robotName = @"Test Robot";
		_inputGameScene.playerName = @"Ludmann";
		[_inputGameScene placeObjectInStage];
		[_inputGameScene startObjects];
		[self willGoBack];
		[self addChild:_inputGameScene];
	}
}

@end
