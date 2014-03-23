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

#import "ServerCommunicator.h"
#import "CallbackResponder.h"
#import <string>
#import <zmq.h>

#import "CallbackWelcome.h"
#import "CallbackGameState.h"
#import "CallbackGoodbye.h"
#import "CallbackInput.h"
#import "ORBroadcastRetriever.h"

@interface ServerCommunicator()

@property (nonatomic) void* zmq_context;
@property (nonatomic) void* zmq_socket_pusher;
@property (nonatomic) void* zmq_socket_subscriber;
@property (strong, nonatomic) NSMutableDictionary* callbacks;
@property (strong, nonatomic) ORBroadcastRetriever* broadcastRetriever;


// Initialization methods
- (id) init;

// Context initialization
- (BOOL) initContext;

// Sockets initialization
- (BOOL) initSockets;

// Sockets connections
- (BOOL) connectPusher;
- (BOOL) connectSubscriber;

@end

@implementation ServerMessage
@synthesize payload = _payload;
@synthesize receiver = _receiver;
@synthesize tag = _tag;
@end


@implementation ServerCommunicator
{
	BOOL _subscriberRunning;
	BOOL _broadcastRetrieved;
}

@synthesize zmq_context = _zmq_context;
@synthesize zmq_socket_pusher = _zmq_socket_pusher;
@synthesize zmq_socket_subscriber = _zmq_socket_subscriber;

@synthesize serverIp = _serverIp;
@synthesize pusherPort = _pusherPort;
@synthesize subscriberPort = _subscriberPort;

@synthesize callbacks = _callbacks;
@synthesize broadcastRetriever = _broadcastRetriever;

+ (id)initSingleton
{
	static dispatch_once_t pred;
	static id shared = nil;
	
	dispatch_once(&pred, ^(){
		DDLogDebug(@"Dispatching once...");
		shared = [[super alloc] init];
	});
	
	return shared;
}

- (id)init
{
	self = [super init];
	
	_subscriberRunning = NO;
	_broadcastRetrieved = NO;
	_callbacks = [NSMutableDictionary dictionary];
	
	[_callbacks setObject:[[CallbackWelcome alloc] init] forKey:@"Welcome"];
	[_callbacks setObject:[[CallbackGameState alloc] init] forKey:@"GameState"];
	[_callbacks setObject:[[CallbackGoodbye alloc] init] forKey:@"Goodbye"];
	[_callbacks setObject:[[CallbackInput alloc] init] forKey:@"Input"];
	
	return self;
}

- (BOOL)initContext
{
	_zmq_context = zmq_ctx_new();
	
	return (_zmq_context != (void*)0);
}

- (BOOL)initSockets
{
	_zmq_socket_pusher = zmq_socket(_zmq_context, ZMQ_PUSH);
	_zmq_socket_subscriber = zmq_socket(_zmq_context, ZMQ_SUB);
	
	return (_zmq_socket_pusher != (void*)0 and _zmq_socket_subscriber != (void*) 0);
}

- (BOOL)connectPusher
{
	// _serverUrl should contain something like: "tcp://192.168.1.10", we just have to append the port
	NSString *_fullUrl = [NSString stringWithFormat:@"%@:%@", _serverIp, _pusherPort];
	
	return (zmq_connect(_zmq_socket_pusher, [_fullUrl UTF8String]) == 0);
}

- (BOOL)connectSubscriber
{
	// _serverUrl should contain something like: "tcp://192.168.1.10", we just have to append the port
	NSString *_fullUrl = [NSString stringWithFormat:@"%@:%@", _serverIp, _subscriberPort];
	
	zmq_setsockopt(_zmq_socket_subscriber, ZMQ_SUBSCRIBE, std::string().c_str(), std::string().length());
	
	return (zmq_connect(_zmq_socket_subscriber, [_fullUrl UTF8String]) == 0);
}

- (BOOL)pushMessage:(ServerMessage *)message
{
	return [self pushMessageWithPayload:message.payload tag:message.tag receiver:message.receiver];
}

- (BOOL)pushMessageWithPayload:(NSData *)payload tag:(NSString *)tag receiver:(NSString *)receiver
{
	NSMutableData *_load = [[NSMutableData alloc] init];
		
	[_load appendData:[receiver dataUsingEncoding:NSASCIIStringEncoding]];
	[_load appendData:[tag dataUsingEncoding:NSASCIIStringEncoding]];
	[_load appendData:payload];
	
	DDLogDebug(@"ServerCommunicator: pushing %s \n", (const char *) [_load bytes]);
	
	zmq_msg_t zmq_message;
	zmq_msg_init_size(&zmq_message, [_load length]);
	memcpy(zmq_msg_data(&zmq_message), [_load bytes], [_load length]);
	
	return (zmq_msg_send(&zmq_message, _zmq_socket_pusher, 0) == [_load length]);
}

- (BOOL)connect
{
	return [self initContext] and
	       [self initSockets] and
	       [self connectPusher] and
	       [self connectSubscriber];
}

- (void)runSubscriber
{
	if (!_subscriberRunning)
	{
		_subscriberRunning = YES;
		dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
		dispatch_async(q, ^(){
			while (true)
			{
				DDLogVerbose(@"Subscriber waiting for a message..");
				using std::string;
				zmq_msg_t zmq_message;
				zmq_msg_init_size(&zmq_message, 5024);
				
				uint32_t bytes = zmq_recv(_zmq_socket_subscriber, zmq_msg_data(&zmq_message), 5024, 0);
				
				if (bytes) {
					NSString *msg = [NSString stringWithCString:(char *)zmq_msg_data(&zmq_message)
													   encoding:NSASCIIStringEncoding];
					
					NSScanner *scanner = [NSScanner scannerWithString:msg];
					
					__autoreleasing NSString *clients, *tag, *payload;
					[scanner scanUpToString:@" " intoString:&clients];
					[scanner scanUpToString:@" " intoString:&tag];
					
					if ([msg length] > [scanner scanLocation]+1)
						payload = [NSString stringWithString:[msg substringFromIndex:[scanner scanLocation]+1]];
					else
						payload = [NSString stringWithFormat:@"NO PAYLOAD"];

					Callback *cb = [_callbacks objectForKey:tag];
					
					if (cb != nil)
					{
						DDLogVerbose(@"Launching cb %@ (message is for: %@, tag: %@)", [cb description], clients, tag);
						[cb processMessage:[payload dataUsingEncoding:NSASCIIStringEncoding]];
					}
				}
			}
		});
	}
}

- (BOOL)registerResponder:(id<CallbackResponder>)responder forMessage:(NSString *)message
{
	if ([_callbacks objectForKey:message] != nil) {
		((Callback *) [_callbacks objectForKey:message]).delegate = responder;
		return YES;
	}
	
	return NO;
}

- (BOOL)deleteResponder:(id<CallbackResponder>)responder forMessage:(NSString *)message
{
	DDLogInfo(@"Wanting to remove delegate %@ for message %@", [responder debugDescription], message);
	Callback *callback = [_callbacks objectForKey:message];

	if (callback != nil) {
		DDLogInfo(@"Removing delegate from callback %@", [callback debugDescription]);
		callback.delegate = nil;
		return YES;
	}
	
	return NO;
}

- (BOOL)retrieveServerFromBroadcast
{
	if (_broadcastRetrieved)
		return YES;
	
	BOOL response = NO;
	_broadcastRetriever = [ORBroadcastRetriever retrieverWithTimeout:3];
	
	if ([_broadcastRetriever retrieveAddress]) {
		_serverIp = [NSString stringWithFormat:@"tcp://%@", _broadcastRetriever.responderIp];
		_pusherPort = [_broadcastRetriever.firstPort stringValue];
		_subscriberPort = [_broadcastRetriever.secondPort stringValue];
		
		DDLogInfo(@"Retrieved: %@:%@ and %@:%@", _serverIp, _pusherPort, _serverIp, _subscriberPort);
		
		response = YES;
	}

	return response;
}

- (void)setServerIp:(NSString *)serverIp
{
	_serverIp = serverIp;
	DDLogWarn(@"Using provided server IP (broadcast failed?) %@", _serverIp);
}

- (void)setPusherPort:(NSString *)pusherPort
{
	_pusherPort = pusherPort;
	DDLogWarn(@"Using provided pusher port (broadcast failed?) %@", _pusherPort);
}

- (void)setSubscriberPort:(NSString *)subscriberPort
{
	_subscriberPort = subscriberPort;
	DDLogWarn(@"Using provided subscriber port (broadcast failed?) %@", _subscriberPort);
}

@end
