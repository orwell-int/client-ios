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

#import "ORSlider.h"

@interface ORSlider()
@property (strong, nonatomic) SPImage *sliderBackground;
@property (strong, nonatomic) SPImage *sliderDot;
@property (nonatomic) float sliderDotHeight;
@property (nonatomic) float sliderDotWidth;

- (void)initImages;
- (id)initWithWidth:(float)width andHeight:(float)height;
- (id)initWithWidth:(float)width andHeight:(float)height andMarkerPosition:(ORSliderMarkerPosition)position;
- (void)placeMarker;
- (void)setWidth:(float)width;
- (void)setHeight:(float)height;
- (void)setWidth:(float)width andHeight:(float)height;
- (void)onDotTouched:(SPTouchEvent *)event;
@end

@implementation ORSlider

#pragma mark Init methods
- (void)initImages
{
	_sliderDotHeight = 30.0f;
	_sliderDotWidth = 30.0f;
	_sliderAlpha = 1.0f;

	_sliderBackground = [SPImage imageWithContentsOfFile:@"SliderBar.png"];
	_sliderDot = [SPImage imageWithContentsOfFile:@"SliderDot.png"];
	_sliderDot.width = _sliderDotWidth;
	_sliderDot.height = _sliderDotHeight;

	// Place the marker
	[self placeMarker];
	_sliderDot.height = _sliderDotHeight;
	_sliderDot.width = _sliderDotWidth;
	_sliderDot.alpha = _sliderAlpha;

	[_sliderDot addEventListener:@selector(onDotTouched:)
						atObject:self
						 forType:SP_EVENT_TYPE_TOUCH];
}

- (void)placeMarker
{
	// There are some implicit default values, for example we cannot have
	// an Horizontal slider with the marker at the left or right side, so we will
	// default to the bottom position.
	// Same goes for the vertical slider.

	if (_orientation == ORSLIDER_HORIZONTAL) {
		if (_markerPosition == ORSLIDER_MP_TOP) {
			// Place the slider at the top
		}
		else {
			// Place the slider at the bottom
		}
	}
	else {
		if (_markerPosition == ORSLIDER_MP_LEFT) {
			// Mirror the slider
			_sliderDot.x = -10.0f;
			_sliderDot.rotation = SP_D2R(-180);
		}
		else {
			_sliderDot.x = 10.0f;
		}

		_sliderDot.y = 230.0f;
	}
}

- (id)initWithWidth:(float)width andHeight:(float)height
{
	if (self = [super init]) {
		_value = 0.0f;
		[self setWidth:width andHeight:height];
		[self initImages];

		[self addChild:_sliderBackground atIndex:0];
		[self addChild:_sliderDot];
	}
	
	return self;
}

- (id)initWithWidth:(float)width andHeight:(float)height andMarkerPosition:(ORSliderMarkerPosition)position
{
	if (self = [self initWithWidth:width andHeight:height]) {
		_markerPosition = position;
	}

	return self;
}

- (id)initHorizontalSlider
{
	self = [self initWithWidth:320.0f andHeight:40.0f andMarkerPosition:ORSLIDER_MP_BOTTOM];
	_orientation = ORSLIDER_HORIZONTAL;
	return self;
}

- (id)initVerticalSlider
{
	self = [self initWithWidth:40.0f andHeight:320.0f andMarkerPosition:ORSLIDER_MP_RIGHT];
	_orientation = ORSLIDER_VERTICAL;
	return self;
}

+ (id)verticalSlider
{
	__strong ORSlider *returnValue = [[ORSlider alloc] initVerticalSlider];
	return returnValue;
}

+ (id)horizontalSlider
{
	__strong ORSlider *returnValue = [[ORSlider alloc] initHorizontalSlider];
	return returnValue;
}

+ (id)verticalSliderWithMarkerPosition:(ORSliderMarkerPosition)position
{
	ORSlider *returnValue = [[ORSlider alloc] initVerticalSlider];
	returnValue->_markerPosition = position;
	return returnValue;
}

+ (id)horizontalSliderWithMarkerPosition:(ORSliderMarkerPosition)position
{
	ORSlider *returnValue = [[ORSlider alloc] initHorizontalSlider];
	returnValue->_markerPosition = position;
	return returnValue;
}

#pragma mark Helper functions
- (void)setWidth:(float)width
{
	[super setWidth:width];
	_sliderBackground.width = width;
	_sliderDot.width = _sliderDotWidth;
}

- (void)setHeight:(float)height
{
	[super setHeight:height];
	_sliderBackground.height = height;
	_sliderDot.height = _sliderDotHeight;
}

- (void)setWidth:(float)width andHeight:(float)height
{
	self.width = width;
	self.height = height;
}

#pragma mark Event Handlers
- (void)onDotTouched:(SPTouchEvent *)event
{
	DDLogInfo(@"SliderDot touched");
	NSSet *touches = event.touches;
	for (SPTouch *touch in touches) {
		if (touch.target == event.target) {
			DDLogInfo(@"Touched in %f", touch.globalY);
			if (_orientation == ORSLIDER_VERTICAL) {
				if (touch.globalY > (Sparrow.stage.height - _sliderDotHeight))
					_sliderDot.y = Sparrow.stage.height - _sliderDotHeight;
				else if (touch.globalY < 0.0f)
					_sliderDot.y = 0.0f;
				else
					_sliderDot.y = touch.globalY;

				// Recalculate the value now
				float tmp = touch.globalY / (Sparrow.stage.height / 2);
				_value = (tmp - 1.0f) * (-1);
				if (_delegate) {
					[_delegate slider:self didChangeValue:_value];
				}
			}
		}
	}
}

@end
