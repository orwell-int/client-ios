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

#import "MessagesWrapper.h"
#import "google/protobuf/message_lite.h"
#import <Foundation/Foundation.h>

#import "google/protobuf/message_lite.h"

#import "controller.pb.h"
#import "robot.pb.h"
#import "server-game.pb.h"
#import "server-web.pb.h"

using namespace orwell::messages;


@interface MessagesWrapper()

/*
 // Tell a player wants to join
 // answered by: Welcome, Goodbye
 message Hello {
   required string name = 1;
   optional bool ready = 2 [default = true];
   required uint32 port = 3;
   required string ip = 4;
 }
*/

+ (Hello *) buildHelloMessage:(NSString *)name
				  readyStatus:(BOOL)ready
						 port:(uint32_t)port
						   ip:(NSString *)ip;


/*
 // Notify the state of the inputs to control the robot
 message Input {
     optional group Move = 1 {
     optional double left = 1;
     optional double right = 2;
   }
     optional group Fire = 2 {
     optional bool weapon1 = 1;
     optional bool weapon2 = 2;
   }
 }
 
*/

+ (Input *) buildInputMessage:(NSString *)input
						 left:(NSNumber *)left
						right:(NSNumber *)right
					  weapon1:(NSNumber *) weapon1
					  weapon2:(NSNumber *) weapon2;

@end


@implementation MessagesWrapper

+ (void *)buildMessage:(NSString *)messageType
		withDictionary:(NSDictionary *)dictionary
{
	if ([messageType isEqual: @"HELLO"])
	{
		return (void *) [MessagesWrapper buildHelloMessage:@"name"
											   readyStatus:false
													  port:80
														ip:@"localhost"];
	}

	return nil;
}

+ (void *)buildMessage:(NSString *)messageType
		   withPayload:(NSData *)payload
{
	using namespace orwell::messages;
	
	void *ret = nullptr;
	
	if ([messageType isEqualToString:@"Welcome"])
	{
		ret = new Welcome();
		((Welcome *) ret)->ParseFromArray([payload bytes], [payload length]);
	}
	else if ([messageType isEqualToString:@"Goodbye"])
	{
		ret = new Goodbye();
		((Goodbye *) ret)->ParseFromArray([payload bytes], [payload length]);
	}
	
	return ret;
}

+ (Hello *)buildHelloMessage:(NSString *)name readyStatus:(BOOL)ready port:(uint32_t)port ip:(NSString *)ip
{
	orwell::messages::Hello *msg = new orwell::messages::Hello();
	msg->set_name([name cStringUsingEncoding:NSASCIIStringEncoding]);
	msg->set_ready(ready);
	msg->set_port(port);
	msg->set_ip([ip cStringUsingEncoding:NSASCIIStringEncoding]);
	
	return msg;
}

+ (Input *)buildInputMessage:(NSString *)input
						left:(NSNumber *)left
					   right:(NSNumber *)right
					 weapon1:(NSNumber *)weapon1
					 weapon2:(NSNumber *)weapon2
{
	orwell::messages::Input *msg = new orwell::messages::Input();
	
	return msg;
}

@end
