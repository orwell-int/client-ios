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


#ifndef __iOrwell2__BroadcastRetriever__
#define __iOrwell2__BroadcastRetriever__

#import <string>
#import <iostream>

struct IP4
{
    uint8_t b1, b2, b3, b4 = 0;
    
    operator std::string() const
    {
        char buffer[32];
        sprintf(&buffer[0], "%u.%u.%u.%u", b1, b2, b3, b4);
        
        return std::string(buffer);
    };
    
    operator bool() const
    {
        return (not
                (b1 == 0 and b2 == 0 and b3 == 0 and b4 == 0));
    };
    
    friend std::ostream & operator<<(std::ostream & _stream, IP4 const & ip4)
    {
        _stream << (std::string) ip4;
        return _stream;
    };
};


class BroadcastRetriever
{
public:
	typedef enum {
		kSendTimeout,
		kRecvTimeout,
		kOk,
		kUnknownError
	} BroadcastError;
	
	BroadcastRetriever();
	virtual ~BroadcastRetriever();
	
	bool getIP4();
	BroadcastError launchTest(std::string const & message);
	void setTimeout(struct timeval const & iTimeout);
	
	std::string const & getFirstIP() const;
	std::string const & getSecondIP() const;
	
	std::string const & getResponderIP() const;
	
	std::string const & getFirstPort() const;
	std::string const & getSecondPort() const;
	
private:
	bool _initialized;
	struct timeval _timeout;
	IP4 _ip4;
	std::string _firstIp;
	std::string _secondIp;
	std::string _responderIp;
	
	std::string _firstPort;
	std::string _secondPort;
};

#endif /* defined(__iOrwell2__BroadcastRetriever__) */
