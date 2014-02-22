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


#include "BroadcastRetriever.h"

#include <iostream>
#include <string>
#include <zmq.h>
#include <netinet/udp.h>
#include <arpa/inet.h>
#import <sys/socket.h>
#import <sys/types.h>
#import <netdb.h>
#include <unistd.h>
#include <cstring>


BroadcastRetriever::BroadcastRetriever() : _initialized(false)
{
	
}

BroadcastRetriever::~BroadcastRetriever()
{
	
}

bool BroadcastRetriever::getIP4()
{
    char szBuffer[1024];
    
    if(gethostname(szBuffer, sizeof(szBuffer)) == -1)
    {
        return false;
    }
    
    struct hostent *host = gethostbyname(szBuffer);
    if(host == NULL)
    {
        return false;
    }
    
    //Obtain the computer's IP
    _ip4.b1 = (uint8_t) host->h_addr_list[0][0];
    _ip4.b2 = (uint8_t) host->h_addr_list[0][1];
    _ip4.b3 = (uint8_t) host->h_addr_list[0][2];
    _ip4.b4 = (uint8_t) host->h_addr_list[0][3];
    
    return true;
}

BroadcastRetriever::BroadcastError BroadcastRetriever::launchTest(std::string const & message)
{	
	int broadcastSocket;
    ssize_t messageLength;
    struct sockaddr_in destination;
    unsigned int destinationLength;
    char reply[256];
    char messageToSend[255];
	memcpy(&messageToSend[0], message.c_str(), message.size());

    messageLength = strlen(messageToSend);
	
	BroadcastError returnValue(kOk);
    
    int broadcast = 1;
    
    // Build the socket
    if ( (broadcastSocket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP) ) < 0)
    {
        perror("socket()");
    }
    
    if (not getIP4())
	{
        NSLog(@"Error while retrieving IP4");
	}
    _ip4.b4 = 255;
    
    if (_ip4)
	{
        NSLog(@"Everything's good: %@",
              [NSString stringWithUTF8String:((std::string) _ip4).c_str()]);
	}
    
    // Build the destination object
    memset(&destination, 0, sizeof(destination));
    destination.sin_family = AF_INET;
    destination.sin_addr.s_addr = inet_addr(
											((std::string) _ip4).c_str());
    destination.sin_port = htons(9080);
    
    // Set the destination to the socket
    setsockopt(broadcastSocket, IPPROTO_IP, IP_MULTICAST_IF, &destination, sizeof(destination));
    
    // Allow the socket to send broadcast messages
    if ( (setsockopt(broadcastSocket, SOL_SOCKET, SO_BROADCAST, &broadcast, sizeof(int))) == -1)
    {
        NSLog(@"Couldn't set sockopt for broadcast");
		returnValue = kUnknownError;
    }
    
	// Send timeout..
	if ( (setsockopt(broadcastSocket, SOL_SOCKET, SO_SNDTIMEO, (char*)&_timeout, sizeof(_timeout))) == -1)
	{
		NSLog(@"Could not set sockopt for SNDTIMEO");
		returnValue = kUnknownError;
	}
	
	// Receive timeout..
	if ( (setsockopt(broadcastSocket, SOL_SOCKET, SO_RCVTIMEO, (char*)&_timeout, sizeof(_timeout))) == -1)
	{
		NSLog(@"Could not set sockopt RCVTIMEO");
		returnValue = kUnknownError;
	}
	
    if (sendto(broadcastSocket, messageToSend, messageLength, 0, (struct sockaddr *) &destination, sizeof(destination)) != messageLength)
    {
        NSLog(@"Couldn't send message");
		returnValue = kSendTimeout;
    }
    
    destinationLength = sizeof(destination);
    if (recvfrom(broadcastSocket, reply, sizeof(reply), 0, (struct sockaddr *) &destination, &destinationLength) == -1)
    {
        NSLog(@"Fell into RCV Timeout");
		returnValue = kRecvTimeout;
    }
	
	_responderIp = std::string(addr2ascii(AF_INET, &destination.sin_addr, sizeof(destination.sin_addr), 0));
	
	NSLog(@"Received message: %s : from %s",
		  reply,
		  _responderIp.c_str());
    
    // Some magic here to retrieve the datas..
	if (returnValue == kOk)
	{
		NSLog(@"Yeah, retrieving everything..");
		uint8_t firstSeparator, secondSeparator, firstSize, secondSize;
		
		firstSeparator = (uint8_t) reply[0];
		firstSize = (uint8_t) reply[1];
		_firstIp = std::string(&reply[2], firstSize);
		secondSeparator = (uint8_t) reply[2 + firstSize];
		secondSize = (uint8_t) reply[2 + firstSize + 1];
		_secondIp = std::string(&reply[2 + firstSize + 2], secondSize);
		
		char aBufferForLogger[128];
		sprintf(aBufferForLogger, "0x%X %d (%s) 0x%X %d (%s)\n",
				firstSeparator, firstSize, _firstIp.c_str(), secondSeparator, secondSize, _secondIp.c_str());
		
		_firstPort = _firstIp.substr(_firstIp.find(":")+1);
		_firstPort = _firstPort.substr(_firstPort.find(":") + 1);
		
		_secondPort = _secondIp.substr(_secondIp.find(":")+1);
		_secondPort = _secondPort.substr(_secondPort.find(":") + 1);
		
		NSLog(@"Message decoded: %s", aBufferForLogger);
		NSLog(@"First port: %s - second port: %s", _firstPort.c_str(), _secondPort.c_str());
	}
	
	if (returnValue != kUnknownError)
		close(broadcastSocket);
	
	return returnValue;
}

void BroadcastRetriever::setTimeout(const struct timeval &iTimeout)
{
	_timeout.tv_sec = iTimeout.tv_sec;
	_timeout.tv_usec = iTimeout.tv_usec;
	
	NSLog(@"tv_sec = %ld  -  tv_usec = %d", _timeout.tv_sec, _timeout.tv_usec);
}

std::string const & BroadcastRetriever::getFirstIP() const
{
	return _firstIp;
}

std::string const & BroadcastRetriever::getSecondIP() const
{
	return _secondIp;
}

std::string const & BroadcastRetriever::getResponderIP() const
{
	return _responderIp;
}

std::string const & BroadcastRetriever::getFirstPort() const
{
	return _firstPort;
}

std::string const & BroadcastRetriever::getSecondPort() const
{
	return _secondPort;
}