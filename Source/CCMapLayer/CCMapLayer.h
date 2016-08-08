/*
 * cocos2d for iPhone: http://www.cocos2d-iphone.org
 *
 * Copyright (c) 2014 Domagoj Eklic
 * Copyright (c) 2014 Cocos2D Authors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "CCGestureRecognizerLayer.h"
#import "CCNode.h"

/*
 Two types of zooming are supported:
        ZoomTypeViewCenterFixed - Point in center of the screen stays at fixed position while zooming. Zoom-in/out
                towards the center of the screen.
        ZoomTypePinchCenterFixed - Point in center of the pinch stays at fixed position on the screen while zooming.
                Zoom-in/out towards the center of the pinch.
 */
typedef enum {
    ZoomTypeViewCenterFixed,
    ZoomTypePinchCenterFixed,
} ZoomType;

@interface CCMapLayer : CCGestureRecognizerLayer

/**
Default layer initializer.
 @param layerSize - Map area. Defines allowed borders for scrolling/zooming
 @param zoomType - Type of zooming used on map.
 @param decelerateEnabled - Defines is scroll deceleration(inertia) enabled
 */

- (instancetype)initWithLayerSize:(CGSize)layerSize
                         zoomType:(ZoomType)zoomType
                 decelerateScroll:(BOOL)decelerateEnabled;
- (instancetype)initWithNode:(CCNode *)node zoomType:(ZoomType)zoomType decelerateScroll:(BOOL)decelerateEnabled;

@property (nonatomic) BOOL isZoomAndScrollAllowed;

/*
 All parameters are initially set to default values.
 Default values are defined at the beginning of the source file (CCMapLayer.m)
 */
#pragma mark - Scroll parameters
/*
 Scroll speed is multiplied by this property. Use values higher than default to achieve faster scrolling, or values
 lower
 than default to achieve slower scrolling.
 */
@property (nonatomic) float scrollSpeedMultiplicator;

/*
 Minimum distance from tap start position needed to start scrolling. Prevents scrolling on accidental tap.
 */
@property (nonatomic) float scrollStartThreshold;

/*
 Multiplicator in range <0.0f, 1.0f>. Defines deceleration speed. Use higher value for slower deceleration, or lower
 values for faster deceleration.
 */
@property (nonatomic) float decelerateMultiplicator;

/*
Scroll speed at the beginning of deceleration is caped to this value.
 */
@property (nonatomic) float decelerateScrollSpeedCap;

/*
Scroll deceleration stops when speed drops below this value
 */
@property (nonatomic) float decelerateStopThreshold;

#pragma mark - Zoom parameters
/*
 Zoom speed is multiplied by this property. Use values higher than default to achieve faster zooming, or values lower
 than default to achieve slower zooming.
 */
@property (nonatomic) float zoomSpeedMultiplicator;

/*
 Minimum layer scale - Maximum zoom-in
 */
@property (nonatomic) float zoomMinScale;

/*
 Maximum layer scale - Maximum zoom-out
 */
@property (nonatomic) float zoomMaxScale;

@end
