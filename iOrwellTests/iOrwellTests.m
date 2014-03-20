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

#import <XCTest/XCTest.h>
#import <OCMock.h>

#import "ServerCommunicator.h"
#import "ORBroadcastRetriever.h"
#import "ORIPFour.h"

@interface iOrwellTests : XCTestCase

@end

@implementation iOrwellTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testIpFour
{
	ORIPFour *ipFour;
	uint8_t array[4];
	array[0] = 192;
	array[1] = 168;
	array[2] = 0;
	array[3] = 10;
	ipFour = [ORIPFour ipFourFromBytes:array];

	XCTAssert([ipFour isValid]);
	XCTAssert([[ipFour toString] isEqual:@"192.168.0.10"]);
	[ipFour makeBroadcastIP];
	XCTAssert([[ipFour debugDescription] isEqual:@"192.168.0.255"]);
	
	ipFour = [ORIPFour ipFour];
	XCTAssert(![ipFour isValid]);
	
	ipFour = [ORIPFour ipFourFromString:@"192.168.1.10"];
	XCTAssert([[ipFour toString] isEqual:@"192.168.1.10"]);
}

- (void) testBroadcastRetriever
{
	ORBroadcastRetriever *retriever;
	retriever = [ORBroadcastRetriever retrieverWithTimeout:2];
	NSData *data = [NSData dataWithBytes:"\xA0" "\x0C" "tcp://*:9000" "\xA1" "\x0C" "tcp://*:9001" "\x0" length:256];
	[retriever parseMessageFromServer:data];
	XCTAssert([retriever.firstIp isEqual:@"tcp://*:9000"]);
	XCTAssert([retriever.secondIp isEqual:@"tcp://*:9001"]);
	XCTAssert([retriever.firstPort intValue] == 9000);
	XCTAssert([retriever.secondPort intValue] == 9001);
	
	// Mock objects!
	id mocked_retriever = [OCMockObject partialMockForObject:[ORBroadcastRetriever retrieverWithTimeout:2]];
	[[[mocked_retriever stub] andReturnValue:@YES] sendMessageToServer:[OCMArg anyPointer]];
	[[[mocked_retriever stub] andReturn:data] getResponseFromServer:[OCMArg anyPointer]];
	
	XCTAssert([mocked_retriever retrieveAddress]);
	XCTAssert([[mocked_retriever firstIp] isEqual:@"tcp://*:9000"]);
	XCTAssert([[mocked_retriever secondIp] isEqual:@"tcp://*:9001"]);
	XCTAssert([[mocked_retriever firstPort] intValue] == 9000);
	XCTAssert([[mocked_retriever secondPort] intValue] == 9001);

}

- (void) testServerCommunicator
{
	ServerCommunicator *communicator = [ServerCommunicator initSingleton];
	
	// Communicator is not properly set, so it shouldn't work
	XCTAssert(![communicator connect]);
	
	// There is no broadcast service (yet), communicator should fail
	XCTAssert(![communicator retrieveServerFromBroadcast]);
}

@end
