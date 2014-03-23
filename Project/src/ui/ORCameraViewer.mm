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

#import "ORCameraViewer.h"
#define END_MARKER_BYTES { 0xFF, 0xD9 }

@interface ORCameraViewer() <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@property (strong, nonatomic) NSURL *url;
@property (strong, nonatomic) NSURLConnection *urlConnection;
@property (strong, nonatomic) NSMutableData *mutableData;
@property (strong, readonly) NSData *endData;
@property (strong, nonatomic) SPImage *image;

-(id) init;
@end


@implementation ORCameraViewer
@synthesize url = _url;
@synthesize urlConnection = _urlConnection;
@synthesize mutableData = _mutableData;
@synthesize image = _image;
@synthesize endData = _endData;

- (id)init
{
	self = [super init];
	self.width = 320.0f;
	self.height = 240.0f;
	
	uint8_t endMarker[2] = END_MARKER_BYTES;
	_endData = [[NSData alloc] initWithBytes:endMarker length:2];

	return self;
}

+ (id)cameraViewerFromURL:(NSURL *)url
{
	ORCameraViewer *cameraViewer = [[ORCameraViewer alloc] init];
	cameraViewer->_url = url;
	cameraViewer->_urlConnection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:url]
																 delegate:cameraViewer];
	[cameraViewer->_urlConnection start];
	return cameraViewer;
}

- (void)play
{
	if (!_urlConnection) {
		_urlConnection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:_url]
														 delegate:self];
		[_urlConnection start];
	}
}

- (void)pause
{
	
}

- (void)stop
{
	
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	_mutableData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (data != nil) {
		[_mutableData appendData:data];
		NSRange endRange = [_mutableData rangeOfData:_endData options:0 range:NSMakeRange(0, _mutableData.length)];
		long long endLocation = endRange.location + endRange.length;
		
		if (_mutableData.length >= endLocation) {
			NSData *imageData = [_mutableData subdataWithRange:NSMakeRange(0, (uint32_t) endLocation)];
			UIImage *receivedImage = [UIImage imageWithData:imageData];
			if (receivedImage) {
				SPTexture *texture = [[SPTexture alloc] initWithContentsOfImage:receivedImage];
				if (![self containsChild:_image]) {
					_image = [SPImage imageWithTexture:texture];
					_image.scaleX = 0.9f;
					_image.scaleY = 0.9f;
					[self addChild:_image];
				}
				else {
					_image.texture = texture;
				}

			}
		}
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	DDLogDebug(@"Connection Finished loading");
}

@end
