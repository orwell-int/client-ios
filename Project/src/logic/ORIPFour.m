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

#import "ORIPFour.h"

@implementation ORIPFour

@synthesize byte1 = _byte1;
@synthesize byte2 = _byte2;
@synthesize byte3 = _byte3;
@synthesize byte4 = _byte4;

+ (id)ipFour
{
	ORIPFour *ipFour = [[ORIPFour alloc] init];
	return ipFour;
}

+ (id)ipFourFromString:(NSString *)ip
{
	ORIPFour *ipFour = [ORIPFour ipFour];
	NSScanner *scanner = [NSScanner scannerWithString:ip];
	int32_t byte1 = 0, byte2 = 0, byte3 = 0, byte4 = 0;
	if ([scanner scanInt:&byte1])
		ipFour->_byte1 = [NSNumber numberWithInt:byte1];
	[scanner scanString:@"." intoString:nil];

	if ([scanner scanInt:&byte2])
		ipFour->_byte2 = [NSNumber numberWithInt:byte2];
	[scanner scanString:@"." intoString:nil];

	if ([scanner scanInt:&byte3])
		ipFour->_byte3 = [NSNumber numberWithInt:byte3];
	[scanner scanString:@"." intoString:nil];

	if ([scanner scanInt:&byte4])
		ipFour->_byte4 = [NSNumber numberWithInt:byte4];

	return ipFour;
}

+ (id)ipFourFromBytes:(uint8_t [4])bytes
{
	ORIPFour *ipFour = [ORIPFour ipFour];
	ipFour->_byte1 = [NSNumber numberWithUnsignedShort:bytes[0]];
	ipFour->_byte2 = [NSNumber numberWithUnsignedShort:bytes[1]];
	ipFour->_byte3 = [NSNumber numberWithUnsignedShort:bytes[2]];
	ipFour->_byte4 = [NSNumber numberWithUnsignedShort:bytes[3]];
	return ipFour;
}

- (id)init
{
	self = [super init];
	return self;
}

- (NSString *)debugDescription
{
	return [self toString];
}

- (NSString *)toString
{
	return [NSString stringWithFormat:@"%u.%u.%u.%u",
			[_byte1 unsignedShortValue],
			[_byte2 unsignedShortValue],
			[_byte3 unsignedShortValue],
			[_byte4 unsignedShortValue]];
}

- (BOOL)isValid
{
	if (_byte1 != nil && _byte2 != nil && _byte3 != nil && _byte4 != nil) {
		return YES;
	}

	return NO;
}
- (void)makeBroadcastIP
{
	if ([self isValid]) {
		_byte4 = [NSNumber numberWithUnsignedShort:255];
	}
}

@end
