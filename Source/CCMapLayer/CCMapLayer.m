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

#import "CCMapLayer.h"
#import "cocos2d.h"

#define DEFAULT_SCROLL_SPEED_MULTIPLICATOR 1.2f
#define DEFAULT_SCROLL_START_THRESHOLD 10.0f
#define DEFAULT_DECELERATE_MULTIPLICATOR 0.95f
#define DEFAULT_DECELERATE_SCROLL_SPEED_CAP 600
#define DEFAULT_DECELERATE_STOP_THRESHOLD 20.0f

#define DEFAULT_ZOOM_SPEED_MULTIPLICATOR 0.3f
#define DEFAULT_ZOOM_MIN_SCALE 0.5f
#define DEFAULT_ZOOM_MAX_SCALE 1.2f

@implementation CCMapLayer {
    CGSize _scrollBoundaries;

    CGPoint _startLocation;
    CGPoint _oldLocation;
    NSTimeInterval _oldTimestamp;
    float _oldScale;

    ZoomType _zoomType;

    // decelaration
    BOOL _decelerateEnabled;
    CGPoint _scrollVecNormalized;
    float _currentScrollSpeed;
}

- (instancetype)initWithLayerSize:(CGSize)layerSize zoomType:(ZoomType)zoomType decelerateScroll:(BOOL)decelerateEnabled
{
    if (self = [super initWithContentSize:layerSize]) {
        _scrollBoundaries = layerSize;

        _zoomType = zoomType;
        _decelerateEnabled = decelerateEnabled;

        [self setDefaultParameters];
    }

    return self;
}

- (instancetype)initWithNode:(CCNode *)node zoomType:(ZoomType)zoomType decelerateScroll:(BOOL)decelerateEnabled
{
    if (self = [self initWithLayerSize:node.contentSize zoomType:zoomType decelerateScroll:decelerateEnabled]) {
        node.anchorPoint = CGPointZero;
        node.position = CGPointZero;

        [self addChild:node];
    }

    return self;
}

- (void)setDefaultParameters
{
    _isZoomAndScrollAllowed = YES;

    _scrollSpeedMultiplicator = DEFAULT_SCROLL_SPEED_MULTIPLICATOR;
    _scrollStartThreshold = DEFAULT_SCROLL_START_THRESHOLD;
    _decelerateMultiplicator = DEFAULT_DECELERATE_MULTIPLICATOR;
    _decelerateScrollSpeedCap = DEFAULT_DECELERATE_SCROLL_SPEED_CAP;
    _decelerateStopThreshold = DEFAULT_DECELERATE_STOP_THRESHOLD;

    _zoomSpeedMultiplicator = DEFAULT_ZOOM_SPEED_MULTIPLICATOR;
    _zoomMinScale = DEFAULT_ZOOM_MIN_SCALE;
    _zoomMaxScale = DEFAULT_ZOOM_MAX_SCALE;
}

- (void)scroll:(CCGestureRecognizer *)sender
{
    if (!_isZoomAndScrollAllowed) {
        return;
    }

    CGPoint newLocation = [sender getGLLocation];
    NSTimeInterval newTimestamp = [[NSDate date] timeIntervalSince1970];

    if (sender.state == GestureStateBegan) {
        _startLocation = newLocation;
        _oldLocation = newLocation;
        _oldTimestamp = newTimestamp;
        [self unschedule:@selector (decelerateScroll:)];
    }

    if (sender.state == GestureStateEnded && _decelerateEnabled) {
        if (_currentScrollSpeed > _decelerateScrollSpeedCap) {
            _currentScrollSpeed = _decelerateScrollSpeedCap;
        }

        [self schedule:@selector (decelerateScroll:) interval:(1.0f / 60.0f)];
    } else {
        CGPoint startDiff = ccpMult (ccpSub (newLocation, _startLocation), _scrollSpeedMultiplicator);
        float diffNum = ccpLength (startDiff);
        if (diffNum > _scrollStartThreshold) {
            CGPoint diff = ccpMult (ccpSub (newLocation, _oldLocation), _scrollSpeedMultiplicator);
            CGPoint newLayerPosition = ccpAdd (self.position, diff);

            if ([self isPositionXInsideBoundaries:newLayerPosition.x]) {
                self.position = ccp (newLayerPosition.x, self.position.y);
            }

            if ([self isPositionYInsideBoundaries:newLayerPosition.y]) {
                self.position = ccp (self.position.x, newLayerPosition.y);
            }

            _scrollVecNormalized = ccpNormalize (diff);
            _currentScrollSpeed = ccpLength (diff) / (newTimestamp - _oldTimestamp);
            _oldTimestamp = newTimestamp;
        }

        _oldLocation = newLocation;
    }
}

- (void)decelerateScroll:(CCTime)dt
{
    float resultAmplitude = _currentScrollSpeed * dt;
    CGPoint resultVec = ccpMult (_scrollVecNormalized, resultAmplitude);

    CGPoint newLayerPosition = ccpAdd (self.position, resultVec);
    if ([self isPositionXInsideBoundaries:newLayerPosition.x] &&
        [self isPositionYInsideBoundaries:newLayerPosition.y]) {
        self.position = newLayerPosition;
    } else {
        [self unschedule:@selector (decelerateScroll:)];
    }

    // framerate independent scroll speed adjustment
    float fps = 1.0 / dt;
    float p = 60 / fps;
    _currentScrollSpeed *= powf (_decelerateMultiplicator, p);

    if (_currentScrollSpeed < _decelerateStopThreshold) {
        [self unschedule:@selector (decelerateScroll:)];
    }
}

- (void)zoom:(CCGestureRecognizer *)sender
{
    if (!_isZoomAndScrollAllowed) {
        return;
    }

    if (_zoomType == ZoomTypeViewCenterFixed) {
        [self zoomWithViewCenterFixed:sender];
    } else {
        [self zoomWithPinchCenterFixed:sender];
    }
}

// implements zoom-in/zoom-out so that ceneter of the view is always fixed
- (void)zoomWithViewCenterFixed:(CCGestureRecognizer *)sender
{
    if (sender.state == GestureStateBegan) {
        _oldScale = 1.0f;
    }

    float newScale = [sender getPinchScale];
    float diff = (newScale - _oldScale) * _zoomSpeedMultiplicator;

    if ((self.scale + diff) > _zoomMaxScale) {
        diff = _zoomMaxScale - self.scale;
    }
    if ((self.scale + diff) < _zoomMinScale) {
        diff = _zoomMinScale - self.scale;
    }

    CGSize viewSize = [CCDirector sharedDirector].viewSize;
    CGPoint screenCenter = ccp (viewSize.width / 2, viewSize.height / 2);

    CGPoint screenCenterNodePosition = [self convertToNodeSpace:screenCenter];
    self.scale += diff;
    CGPoint newScreenCenter = [self convertToWorldSpace:screenCenterNodePosition];

    CGPoint diffVec = ccpSub (screenCenter, newScreenCenter);
    self.position = ccpAdd (self.position, diffVec);

    [self correctPositionInsideBoundaries];

    _oldScale = newScale;
}

// implements zoom-in/zoom-out so that pinch center is always fixed
- (void)zoomWithPinchCenterFixed:(CCGestureRecognizer *)sender
{
    if (sender.type != GestureTypePinch) {
        return;
    }

    if (sender.state == GestureStateBegan) {
        _oldScale = 1.0f;
    }

    float newScale = [sender getPinchScale];
    float diff = (newScale - _oldScale) * _zoomSpeedMultiplicator;

    if ((self.scale + diff) > _zoomMaxScale) {
        diff = _zoomMaxScale - self.scale;
    }
    if ((self.scale + diff) < _zoomMinScale) {
        diff = _zoomMinScale - self.scale;
    }

    CGPoint pinchCenter = [sender getPinchCenter];

    CGPoint pinchCenterNodePosition = [self convertToNodeSpace:pinchCenter];
    self.scale += diff;
    CGPoint newPinchCentar = [self convertToWorldSpace:pinchCenterNodePosition];

    CGPoint diffVec = ccpSub (pinchCenter, newPinchCentar);
    self.position = ccpAdd (self.position, diffVec);

    [self correctPositionInsideBoundaries];

    _oldScale = newScale;
}

- (BOOL)isPositionXInsideBoundaries:(float)xCoor
{
    BOOL isInside = NO;

    CGSize viewSize = [CCDirector sharedDirector].viewSize;
    if (xCoor <= 0 && xCoor >= -(_scrollBoundaries.width * self.scale - viewSize.width)) {
        isInside = YES;
    }

    return isInside;
}

- (BOOL)isPositionYInsideBoundaries:(float)yCoor
{
    BOOL isInside = NO;

    CGSize viewSize = [CCDirector sharedDirector].viewSize;
    if (yCoor <= 0 && yCoor >= -(_scrollBoundaries.height * self.scale - viewSize.height)) {
        isInside = YES;
    }

    return isInside;
}

- (void)correctPositionInsideBoundaries
{
    CGSize viewSize = [CCDirector sharedDirector].viewSize;

    if (self.position.x > 0) {
        self.position = ccp (0, self.position.y);
    }
    if (self.position.x < -(_scrollBoundaries.width * self.scale - viewSize.width)) {
        self.position = ccp (-(_scrollBoundaries.width * self.scale - viewSize.width), self.position.y);
    }
    if (self.position.y > 0) {
        self.position = ccp (self.position.x, 0);
    }
    if (self.position.y < -(_scrollBoundaries.height * self.scale - viewSize.height)) {
        self.position = ccp (self.position.x, -(_scrollBoundaries.height * self.scale - viewSize.height));
    }
}

#pragma mark - Scroll Parameters

- (void)setDecelerateMultiplicator:(float)decelerateMultiplicator
{
    NSAssert (decelerateMultiplicator > 0.0f && decelerateMultiplicator < 1.0f,
              @"Decelerate multiplicator needs to be in range <0.0f, 1.0f>");

    _decelerateMultiplicator = decelerateMultiplicator;
}

@end
