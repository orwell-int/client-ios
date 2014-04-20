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

#import "ORServerCommunicator.h"
#import "ORBroadcastRetriever.h"
#import "ORIPFour.h"
#import "ORServerCommunicatorDelegate.h"

// Callbacks
#import "CallbackResponder.h"
#import "CallbackGameState.h"
#import "CallbackWelcome.h"
#import "CallbackGoodbye.h"

// Messages
#import "server-game.pb.h"

// Utilities
#import "ORZMQURL.h"

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

- (void)testIpFour
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

- (void)testBroadcastRetriever
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
	[[[mocked_retriever stub] andReturnValue:@YES] sendMessageToServer:(int *)[OCMArg anyPointer]];
	[[[mocked_retriever stub] andReturn:data] getResponseFromServer:(int *)[OCMArg anyPointer]];
	
	XCTAssert([mocked_retriever retrieveAddress]);
	XCTAssert([[mocked_retriever firstIp] isEqual:@"tcp://*:9000"]);
	XCTAssert([[mocked_retriever secondIp] isEqual:@"tcp://*:9001"]);
	XCTAssert([[mocked_retriever firstPort] intValue] == 9000);
	XCTAssert([[mocked_retriever secondPort] intValue] == 9001);

}

- (void)testServerCommunicator
{
	ORServerCommunicator *communicator = [ORServerCommunicator singleton];
	
	// Communicator is not properly set, so it shouldn't work
	XCTAssert(![communicator connect]);
	
	// There is no broadcast service (yet), communicator should fail
	XCTAssert(![communicator retrieveServerFromBroadcast]);
}

- (void)testServerCommunicatorProtocol
{
	id protocolMocker = [OCMockObject mockForProtocol:@protocol(ORServerCommunicatorDelegate)];
	
	// Mockers, this is what we expect
	[[[protocolMocker stub] andDo:^(NSInvocation *invocation) {
		XCTAssert(YES);
	}] communicator:[OCMArg any] didConnectToServer:NO];
	
	// This will be a failure
	[[[protocolMocker stub] andDo:^(NSInvocation *invocation){
		XCTAssert(NO);
	}] communicator:[OCMArg any] didConnectToServer:YES];
	
	ORServerCommunicator *communicator = [ORServerCommunicator singleton];
	communicator.delegate = protocolMocker;
	[communicator connect];
}

- (void)testCallbackWelcome
{
	id protocolMocker = [OCMockObject mockForProtocol:@protocol(CallbackResponder)];
	[[[protocolMocker stub] andDo:^(NSInvocation *invocation) {
		__unsafe_unretained NSDictionary *dictionary;
		[invocation getArgument:&dictionary atIndex:2];
		
		NSLog(@"Received object: %@", [invocation debugDescription]);
		NSLog(@"Received dictionary: %@", [dictionary debugDescription]);
		
		XCTAssert([[dictionary objectForKey:CB_WELCOME_KEY_ROBOT] isEqualToString:@"DamienChilot"]);
		XCTAssert([[dictionary objectForKey:CB_WELCOME_KEY_ROBOT] intValue] == orwell::messages::RED);
	}] messageReceived:[OCMArg any]];

	CallbackWelcome *callback = [[CallbackWelcome alloc] init];
	callback.delegate = protocolMocker;
	
	// Create a fake Welcome message
	orwell::messages::Welcome welcome;
	welcome.set_robot("DamienChilot");
	welcome.set_team(orwell::messages::RED);
	NSData *message = [NSData dataWithBytes:welcome.SerializeAsString().c_str()	length:welcome.SerializeAsString().size()];
	[callback processMessage:message];
}

- (void)testZMQURL
{
	// Basic one
	ORZMQURL *url = [[ORZMQURL alloc] initWithString:@"tcp://192.168.1.10:8080,8081"];
	XCTAssert([url isValid]);
	XCTAssert(url.protocol == ZMQTCP);
	XCTAssert([url.pusherPort isEqual:@(8080)]);
	XCTAssert([url.pullerPort isEqual:@(8081)]);
	XCTAssert([url.ip isEqual:@"192.168.1.10"]);
	XCTAssert([[url pusherToString] isEqual:@"tcp://192.168.1.10:8080"]);
	
	// Uncomplete url
	url = [[ORZMQURL alloc] initWithString:@"tcp://192.168.1.10"];
	XCTAssert(![url isValid]);
	XCTAssert(url.pusherPort == nil);
	XCTAssert([url.ip isEqual:@"192.168.1.10"]);
	XCTAssert([[url pusherToString] isEqual:@"tcp://192.168.1.10:(null)"]);
	
	// Building piece after piece
	url = [[ORZMQURL alloc] init];
	url.protocol = ZMQTCP;
	XCTAssert(!url.valid);
	
	url.ip = @"192.168.1.10";
	XCTAssert(!url.valid);
	
	url.pusherPort = @(8080);
	XCTAssert(!url.valid);
	
	url.pullerPort = @(8081);
	XCTAssert(url.valid);
	XCTAssert([[url pusherToString] isEqual:@"tcp://192.168.1.10:8080"]);
	XCTAssert([[url pullerToString] isEqual:@"tcp://192.168.1.10:8081"]);
}

- (void)testZMQURLWithORIPFour
{
	ORIPFour *ipFour = [ORIPFour ipFourFromString:@"192.168.1.10"];
	[ipFour makeBroadcastIP];

	ORZMQURL *url = [[ORZMQURL alloc] initWithORIPFour:ipFour];
	XCTAssert(!url.valid);

	url.protocol = ZMQUDP;
	url.pusherPort = @(8080);
	XCTAssert(!url.valid);

	url.pullerPort = @(8081);
	XCTAssert(url.valid);

	XCTAssert([[url toString] isEqual:@"udp://192.168.1.255:8080"]);

	uint8_t bytes[] = { 192, 168, 1, 10 };
	ipFour = [ORIPFour ipFourFromBytes:bytes];
	url = [[ORZMQURL alloc] initWithORIPFour:ipFour];
	XCTAssert(!url.valid);


	url.protocol = ZMQTCP;
	url.pusherPort = @(8080);
	XCTAssert([[url toString] isEqual:@"tcp://192.168.1.10:8080"]);
}

// This test became useless as of version 0.3.0
//- (void)testIpFourRetrieving
//{
//	ORBroadcastRetriever *broadcastRetriever = [ORBroadcastRetriever retrieverWithTimeout:2];
//	NSArray *array = [broadcastRetriever retrieveAddresses];
//	
//	XCTAssert(array != nil, @"Array is nil");
//	
//	NSLog(@"%@", [array debugDescription]);
//}

@end
