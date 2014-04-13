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

@interface ServerConnectionScene() <UITextFieldDelegate>
@end

@implementation ServerConnectionScene {
	UIImage *_fieldsBackground;
	UIImage *_fieldsBackgroundActive;
	UIView *_padding;
	UIView *_paddingActive;
	UITextField *_inputPlayerName;
	UITextField *_inputServerInfo;
	ORAlternativeButton *_connectButton;
	SPImage *_techStuff;

	ORServerCommunicator *_communicator;
}

- (id)init
{
	if (self = [super init]) {
		self.topBarVisible = YES;
		self.backButtonVisible = YES;
		self.topBarText = @"Choose a server";

		_communicator = [ORServerCommunicator singleton];
		_techStuff = [SPImage imageWithContentsOfFile:@"TechStuff.png"];
		_techStuff.x = 75.0f;
		_techStuff.y = 320.0f;

		_connectButton = [[ORAlternativeButton alloc] initWithType:OR_BUTTON_CONNECT];
		_connectButton.x = 66.0f;
		_connectButton.y = 240.0f;

		// Init the textfields
		_fieldsBackground = [[UIImage imageNamed:@"InputField.png"] stretchableImageWithLeftCapWidth:20
																						topCapHeight:0];
		_fieldsBackgroundActive = [[UIImage imageNamed:@"SelectedInputField.png"] stretchableImageWithLeftCapWidth:10
																									  topCapHeight:0];
		_padding = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 22.0f, 0)];
		_paddingActive = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 22.0f, 0)];

		_inputPlayerName = [[UITextField alloc] initWithFrame:CGRectMake(31, 83, 260, 38)];
		_inputPlayerName.background = [[UIImage imageNamed:@"InputField.png"] stretchableImageWithLeftCapWidth:20
																								  topCapHeight:0];
		_inputPlayerName.font = [UIFont fontWithName:@"Helvetica Neue" size:12];
		_inputPlayerName.textColor = [UIColor colorWithRed:255 green:255 blue:255 alpha:1.0f];
		_inputPlayerName.leftView = _padding;
		_inputPlayerName.leftViewMode = UITextFieldViewModeAlways;
		_inputPlayerName.rightView = _padding;
		_inputPlayerName.rightViewMode = UITextFieldViewModeAlways;
		_inputPlayerName.delegate = self;
		_inputPlayerName.placeholder = @"Player name";

		_inputServerInfo = [[UITextField alloc] initWithFrame:CGRectMake(31, 134, 260, 38)];
		_inputServerInfo.background = [[UIImage imageNamed:@"InputField.png"] stretchableImageWithLeftCapWidth:10
																								  topCapHeight:0];
		_inputServerInfo.font = [UIFont fontWithName:@"Helvetica Neue" size:12];
		_inputServerInfo.textColor = [UIColor colorWithRed:255 green:255 blue:255 alpha:1.0f];
		_inputServerInfo.leftView = _paddingActive;
		_inputServerInfo.leftViewMode = UITextFieldViewModeAlways;
		_inputServerInfo.rightView = _paddingActive;
		_inputServerInfo.rightViewMode = UITextFieldViewModeAlways;
		_inputServerInfo.delegate = self;
		_inputServerInfo.placeholder = @"server:puller,pusher";

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

}

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

@end
