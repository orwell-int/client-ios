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

#import "CallbackInput.h"
#import "controller.pb.h"

@implementation CallbackInput

@synthesize delegate = _delegate;

- (BOOL)processMessage:(NSData *)message
{
	NSMutableDictionary *mutableDic = [NSMutableDictionary dictionary];
	orwell::messages::Input input;
	input.ParseFromArray([message bytes], (uint32_t) [message length]);
	DDLogVerbose(@"CallbackInput in");

	if (input.has_move()) {
		[mutableDic setObject:[NSNumber numberWithDouble:input.move().left()] forKey:CB_INPUT_MOVE_LEFT];
		[mutableDic setObject:[NSNumber numberWithDouble:input.move().right()] forKey:CB_INPUT_MOVE_RIGHT];
	}

	if (input.has_fire()) {
		[mutableDic setObject:[NSNumber numberWithBool:input.fire().weapon1()] forKey:CB_INPUT_FIRE_WEAPON1];
		[mutableDic setObject:[NSNumber numberWithBool:input.fire().weapon2()] forKey:CB_INPUT_FIRE_WEAPON2];
	}

	if (_delegate) {
		[_delegate messageReceived:mutableDic];
	}
	
	[mutableDic removeAllObjects];
	return YES;
}

@end
