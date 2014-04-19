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

#import "ORAlternativeButton.h"

@implementation ORAlternativeButton {
	SPImage *_iconImage;
}
- (id)initWithType:(ORIconType)iconType
{
	NSString *buttonImage;
	NSString *buttonImageDown;
	_icon = iconType;
	switch (_icon) {
		case OR_BUTTON_PLAY:
			buttonImage = @"PlayButton.png";
			buttonImageDown = @"PlayButton-down.png";
			break;
		case OR_BUTTON_INFORMATIONS:
			buttonImage = @"InformationsButton.png";
			buttonImageDown = @"InformationsButton-down.png";
			break;
		case OR_BUTTON_CREDITS:
			buttonImage = @"CreditsButton.png";
			buttonImageDown = @"CreditsButton-down.png";
			break;
		case OR_BUTTON_CONNECT:
			buttonImage = @"ConnectButton.png";
			buttonImageDown = @"ConnectButton-down.png";
			break;
		case OR_BUTTON_GAMESTATE:
			buttonImage = @"GamestateButton.png";
			buttonImageDown = @"GamestateButton-down.png";
			break;
		case OR_BUTTON_STAR:
			buttonImage = @"StarButton.png";
			buttonImageDown = @"StarButton-down.png";
			break;
	}

	SPTexture *buttonBackground = [SPTexture textureWithContentsOfFile:buttonImage];
	SPTexture *buttonBackgroundDown = [SPTexture textureWithContentsOfFile:buttonImageDown];

	self = [super initWithUpState:buttonBackground
						downState:buttonBackgroundDown];
	return self;
}
@end
