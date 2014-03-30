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

#import "ORBroadcastRetriever.h"
#include <netinet/udp.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netdb.h>
#include <unistd.h>

@interface ORBroadcastRetriever()
- (BOOL) retrieveIPFour;
- (id) init;
@end

@implementation ORBroadcastRetriever {
	struct timeval _timeout;
}

@synthesize firstIp = _firstIp;
@synthesize secondIp = _secondIp;
@synthesize firstPort = _firstPort;
@synthesize secondPort = _secondPort;
@synthesize responderIp = _responderIp;
@synthesize ipFour = _ipFour;

- (id)init
{
	self = [super init];
	return self;
}

+ (id)retriever
{
	ORBroadcastRetriever *retriever = [[ORBroadcastRetriever alloc] init];
	retriever->_timeout.tv_sec = 1;
	retriever->_timeout.tv_usec = 1000;
	
	return retriever;
}

+ (id)retrieverWithTimeout:(int)timeout
{
	ORBroadcastRetriever *retriever = [[ORBroadcastRetriever alloc] init];
	retriever->_timeout.tv_sec = timeout;
	retriever->_timeout.tv_usec = 1000;
	
	return retriever;
}

- (BOOL)retrieveIPFour
{
	char szBuffer[1024];
	
	if(gethostname(szBuffer, sizeof(szBuffer)) == -1)
	{
		return NO;
	}
	
	struct hostent *host = gethostbyname(szBuffer);
	if(host == NULL)
	{
		return NO;
	}

	_ipFour = [ORIPFour ipFourFromBytes:(uint8_t *) host->h_addr_list[0]];
	
	return YES;
}

- (BOOL)retrieveAddress
{
	int broadcastSocket;
	BOOL returnValue = YES;

	DDLogInfo(@"Retrieving address from broadcast");
	   
	// Build the socket
	if ( (broadcastSocket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP) ) < 0)
	{
		DDLogError(@"Could not create the socket");
		returnValue = NO;
	}
	
	if (! [self retrieveIPFour])
	{
		DDLogError(@"Error while retrieving IP4");
	}
	
	// IPFour should set the last byte to 255
	
	if ([_ipFour isValid])
	{
		[_ipFour makeBroadcastIP];
		DDLogDebug(@"Retrieved IP: %@", [_ipFour debugDescription]);
	}
	
	if ([self sendMessageToServer:&broadcastSocket]) {
		NSData *data = [self getResponseFromServer:&broadcastSocket];

		if (data != nil)
			[self parseMessageFromServer:data];
		else
			returnValue = NO;
	}
	
	if (returnValue)
		close(broadcastSocket);
	
	return returnValue;
}

- (NSData *)getResponseFromServer:(int *)socket
{
	struct sockaddr_in responder;
	unsigned int responder_length;
	char reply[256];
	NSData *data = nil;
	
	memset(&responder, 0, sizeof(responder));
	responder_length = sizeof(responder);
	
	if (recvfrom(*socket, reply, sizeof(reply), 0, (struct sockaddr *) &responder, &responder_length) == -1) {
		DDLogWarn(@"Fell into receive timeout");
	}
	else {
		DDLogInfo(@"Received message: %s : from %@", reply, _responderIp);
		data = [NSData dataWithBytes:reply length:sizeof(reply)];
		_responderIp = [NSString stringWithCString:addr2ascii(AF_INET, &responder.sin_addr, sizeof(responder.sin_addr), 0)
										  encoding:NSASCIIStringEncoding];
		
	}
	
	return data;
}

- (void)parseMessageFromServer:(NSData *)message
{
	// <0xA0><size>tcp://*:9000<0xA1><size>tcp://*:9001<0x0>
	if (message != nil) {
		char *reply = (char *) [message bytes];
		uint8_t separator = 0, first_size = 0, second_size = 0;
		
		separator = (uint8_t) reply[0];
		first_size = (uint8_t) reply[1];
		_firstIp = [[NSString alloc] initWithBytes:&reply[2] length:first_size encoding:NSASCIIStringEncoding];
		DDLogDebug(@"Retrieved first ip: %@", _firstIp);
		
		separator = (uint8_t) reply[2 + first_size];
		second_size = (uint8_t) reply[2 + first_size + 1];
		_secondIp = [[NSString alloc] initWithBytes:&reply[2 + first_size + 2] length:second_size encoding:NSASCIIStringEncoding];
		DDLogDebug(@"Retrieved second ip: %@", _secondIp);
		
		uint64_t first_port = 0, second_port = 0;
		NSScanner *scanner = [NSScanner scannerWithString:_firstIp];
		[scanner scanString:@"tcp://*:" intoString:nil];
		[scanner scanUnsignedLongLong:&first_port];
		DDLogDebug(@"Retrieved first port: %llu", first_port);
		
		scanner = [NSScanner scannerWithString:_secondIp];
		[scanner scanString:@"tcp://*:" intoString:nil];
		[scanner scanUnsignedLongLong:&second_port];
		DDLogDebug(@"Retrieved second port: %llu", second_port);

		_firstPort = [NSNumber numberWithUnsignedLongLong:first_port];
		_secondPort = [NSNumber numberWithUnsignedLongLong:second_port];
	}
}

- (BOOL)sendMessageToServer:(int *)socket
{
	BOOL return_value = YES;
	struct sockaddr_in destination;
	int broadcast = 1;

	// Set the destination to the socket
	setsockopt(*socket, IPPROTO_IP, IP_MULTICAST_IF, &destination, sizeof(destination));
	
	// Allow the socket to send broadcast messages
	if ( (setsockopt(*socket, SOL_SOCKET, SO_BROADCAST, &broadcast, sizeof(int))) == -1) {
		DDLogError(@"Couldn't set BROADCAST option on Socket");
		return_value = NO;
	}
	
	// Send timeout..
	if ( (setsockopt(*socket, SOL_SOCKET, SO_SNDTIMEO, (char*)&_timeout, sizeof(_timeout))) == -1) {
		DDLogError(@"Couldn't set SNDTIMEO option on Socket");
		return_value = NO;
	}
	
	// Receive timeout..
	if ( (setsockopt(*socket, SOL_SOCKET, SO_RCVTIMEO, (char*)&_timeout, sizeof(_timeout))) == -1) {
		DDLogError(@"Could'nt set RCVTIMEOUT option on Socket");
		return_value = NO;
	}

	// Build the destination object
	memset(&destination, 0, sizeof(destination));
	destination.sin_family = AF_INET;
	destination.sin_addr.s_addr = inet_addr([[_ipFour toString] cStringUsingEncoding:NSASCIIStringEncoding]);
	destination.sin_port = htons(9080);
	
	if (sendto(*socket, "b", 2, 0, (struct sockaddr *) &destination, sizeof(destination)) != 2) {
		DDLogError(@"Couldn't send to socket");
		return_value = NO;
	}
	
	return return_value;
}

@end
