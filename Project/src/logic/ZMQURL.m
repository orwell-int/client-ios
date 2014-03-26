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

#import "ZMQURL.h"
#import "ORIPFour.h"

@implementation ZMQURL
@synthesize valid = _valid;

- (id)init
{
	self = [super init];
	_valid = NO;
	return self;
}

- (id)initWithString:(NSString *)string
{
	// We can have different things in the string, actually
	// first format:  'tcp://192.168.1.10:8080', contains everything
	// second format: 'tcp://192.168.1.10', contains protocol but not port
	// third format:  '192.168.1.10:8080', contains port but not protocol
	// fourth format: 'tcp://192.168.1.10:8080,8081, contains pusher and puller port
	
	self = [self init];
	_valid = NO;

	NSScanner *scanner = [NSScanner scannerWithString:string];
	if ([scanner scanString:@"tcp://" intoString:nil])
		_protocol = ZMQTCP;
	else if ([scanner scanString:@"udp://" intoString:nil])
		_protocol = ZMQUDP;
	else
		_protocol = ZMQUNKNOWN;
	
	// Then we have to scan the IP address
	int byte1, byte2, byte3, byte4, port;
	if ([scanner scanInt:&byte1] && [scanner scanString:@"." intoString:nil] &&
		[scanner scanInt:&byte2] && [scanner scanString:@"." intoString:nil] &&
		[scanner scanInt:&byte3] && [scanner scanString:@"." intoString:nil] &&
		[scanner scanInt:&byte4])
		_ip = [NSString stringWithFormat:@"%d.%d.%d.%d", byte1, byte2, byte3, byte4];
	
	// Then scan the port
	if ([scanner scanString:@":" intoString:nil] && [scanner scanInt:&port])
		_pusherPort = [NSNumber numberWithInt:port];
	
	// Scan for a comma and then the other port
	if ([scanner scanString:@"," intoString:nil] && [scanner scanInt:&port])
		_pullerPort = [NSNumber numberWithInt:port];
	
	if (_protocol != ZMQUNKNOWN && _pusherPort != nil && _pullerPort != nil && _ip != nil)
		_valid = YES;
	
	return self;
}

- (id)initWithString:(NSString *)string andPullerPort:(NSNumber *)port
{
	self = [self initWithString:string];
	_pusherPort = port;
	return self;
}

- (id)initWithString:(NSString *)string andPullerPort:(NSNumber *)port andPusherPort:(NSNumber *)pusherPort
{
	self = [self initWithString:string];
	_pusherPort = pusherPort;
	_pullerPort = port;
	return self;
}

- (id)initWithString:(NSString *)string andPullerPort:(NSNumber *)port andPusherPort:(NSNumber *)pusherPort andProtocol:(ZMQProtocol)protocol
{
	self = [self initWithString:string andPullerPort:port andPusherPort:pusherPort];
	_protocol = protocol;
	return self;
}

- (id)initWithORIPFour:(ORIPFour *)ipFour
{
	self = [self initWithString:[ipFour toString]];
	return self;
}

- (id)initWithORIPFour:(ORIPFour *)ipFour andPullerPort:(NSNumber *)port
{
	self = [self initWithString:[ipFour toString] andPullerPort:port];
	return self;
}

- (id)initWithORIPFour:(ORIPFour *)ipFour andPullerPort:(NSNumber *)port andPusherPort:(NSNumber *)pusherPort andProtocol:(ZMQProtocol)protocol
{
	self = [self initWithString:[ipFour toString] andPullerPort:port andPusherPort:pusherPort andProtocol:protocol];
	return self;
}

- (NSString *)toString
{
	return [NSString stringWithFormat:@"%@://%@:%@", _protocol == ZMQTCP? @"tcp" : @"udp", _ip, [_pusherPort stringValue]];
}

- (NSString *)pusherToString
{
	return [self toString];
}

- (NSString *)pullerToString
{
	return [NSString stringWithFormat:@"%@://%@:%@", _protocol == ZMQTCP? @"tcp" : @"udp", _ip, [_pullerPort stringValue]];
}

- (BOOL)isValid
{
	_valid = (_protocol != ZMQUNKNOWN && _pusherPort != nil && _pullerPort != nil && _ip != nil);
	return _valid;
}

@end
