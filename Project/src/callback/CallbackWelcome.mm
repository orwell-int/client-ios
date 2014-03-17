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

#import "CallbackWelcome.h"
#import "server-game.pb.h"

@interface CallbackWelcome()


@end


@implementation CallbackWelcome
{
}

@synthesize delegate = _delegate;


- (BOOL)processMessage:(NSData *)messagePayload
{
	NSLog(@"CallbackWelcome in");
	
	orwell::messages::Welcome *message = new orwell::messages::Welcome();
	message->ParsePartialFromArray([messagePayload bytes], [messagePayload length]);
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	
	[dict setObject:[NSString stringWithCString:message->robot().c_str()
									   encoding:NSASCIIStringEncoding]
			 forKey:CB_WELCOME_KEY_ROBOT];
	
	[dict setObject:[NSNumber numberWithUnsignedInt:message->team()]
			 forKey:CB_WELCOKE_KEY_TEAM];
	
	if (message->has_game_state()) {
		orwell::messages::GameState const & gstate = message->game_state();
		[dict setObject:[NSNumber numberWithBool:gstate.playing()] forKey:CB_WELCOME_KEY_PLAYING];
	}

	if (_delegate)
		[_delegate messageReceived:dict];
	
	delete message;
	return YES;
}

@end
