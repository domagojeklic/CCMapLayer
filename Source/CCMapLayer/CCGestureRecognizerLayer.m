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
#import "cocos2d.h"

#pragma mark -
#pragma mark GestureRecognizer

@interface CCGestureRecognizer ()
@property (nonatomic) float panSpeed;
@property (nonatomic) CGPoint panDirection;
@end

@implementation CCGestureRecognizer {
    float _initialPinchDistance;
}

- (instancetype)initWithType:(GestureType)type state:(GestureRecognizerState)state touch:(CCTouch *)touch
{
    if (self = [super init]) {
        _type = type;
        _state = state;
        _touchOne = touch;
    }

    return self;
}

- (instancetype)initWithType:(GestureType)type
                       state:(GestureRecognizerState)state
                    touchOne:(CCTouch *)touchOne
                    touchTwo:(CCTouch *)touchTwo
{
    if (self = [super init]) {
        _type = type;
        _state = state;
        _touchOne = touchOne;
        _touchTwo = touchTwo;

        if (type == GestureTypePinch) {
            _initialPinchDistance = [self distanceBetweenTouchOne:touchOne touchTwo:touchTwo];
        }
    }
    return self;
}

- (CGPoint)getGLLocation
{
    return [[CCDirector sharedDirector] convertToGL:[_touchOne locationInView:[_touchOne view]]];
}

- (float)getPinchScale
{
    if (_type != GestureTypePinch)
        return 1.0f;

    float currentDistance = [self distanceBetweenTouchOne:_touchOne touchTwo:_touchTwo];
    return currentDistance / _initialPinchDistance;
}

- (CGPoint)getPinchCenter
{
    if (_type != GestureTypePinch)
        return CGPointZero;

    CGPoint touchOneLocation = [_touchOne locationInWorld];
    CGPoint touchTwoLocation = [_touchTwo locationInWorld];

    return ccpMidpoint (touchOneLocation, touchTwoLocation);
}

- (float)distanceBetweenTouchOne:(CCTouch *)touch1 touchTwo:(CCTouch *)touch2
{
    CGPoint location1 = [touch1 locationInWorld];
    CGPoint location2 = [touch2 locationInWorld];

    return ccpDistance (location1, location2);
}

@end

#pragma mark -
#pragma mark GestureRecognizerLayer

#define DEFAULT_LONG_TAP_DURATION 0.6f
#define DEFAULT_LONG_TAP_START_DURATION 0.2f

@implementation CCGestureRecognizerLayer {
    NSMutableSet *_touches;
    CCGestureRecognizer *_gesture;

    BOOL _isPanning;
    BOOL _isPinching;
    BOOL _isTap;

    CGPoint _touchBeginPoint;

    CCTimer *_longTapTimer;
}

- (instancetype)init
{
    NSAssert (NO, @"initWithContentSize should be called");

    return NULL;
}

- (instancetype)initWithContentSize:(CGSize)contentSize
{
    if (self = [super init]) {
        self.contentSize = contentSize;
        self.userInteractionEnabled = YES;
        self.multipleTouchEnabled = YES;

        _touches = [NSMutableSet set];
        _isPanning = NO;
        _isPinching = NO;
        _isTap = NO;

        _longTapStartDuration = DEFAULT_LONG_TAP_START_DURATION;
        _longTapDuration = DEFAULT_LONG_TAP_DURATION;
    }

    return self;
}

#pragma mark - Touch handling

- (void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    [_touches addObject:touch];

    _isTap = YES;

    [self beginLongTap:touch withEvent:event];

    _touchBeginPoint = [touch locationInView:touch.view];
}

- (void)touchMoved:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{

    if (ccpDistance (_touchBeginPoint, [touch locationInView:touch.view]) < 10) {
        return;
    }

    [self cancelLongTap];

    _isTap = NO;

    if ([_touches count] == 1) {
        if (_isPanning == NO) {
            _isPanning = YES;
            _gesture = [[CCGestureRecognizer alloc] initWithType:GestureTypePan state:GestureStateBegan touch:touch];
        } else {
            _gesture.state = GestureStateInProgress;
            _gesture.touchOne = touch;
        }

        [self scroll:_gesture];
    } else if ([_touches count] == 2) {
        NSArray *touchesArr = [_touches allObjects];

        if (_isPinching == NO) {
            _isPinching = YES;
            _gesture = [[CCGestureRecognizer alloc] initWithType:GestureTypePinch
                                                           state:GestureStateBegan
                                                        touchOne:[touchesArr objectAtIndex:0]
                                                        touchTwo:[touchesArr objectAtIndex:1]];
        } else {
            _gesture.state = GestureStateInProgress;
            _gesture.touchOne = [touchesArr objectAtIndex:0];
            _gesture.touchTwo = [touchesArr objectAtIndex:1];
        }

        [self zoom:_gesture];
    }
}

- (void)touchCancelled:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    [self handleTouchEndedOrCanceled:touch withEvent:event];
}

- (void)touchEnded:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    [self handleTouchEndedOrCanceled:touch withEvent:event];
}

- (void)handleTouchEndedOrCanceled:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    [self cancelLongTap];

    if ([_touches count] == 1) {
        if (_isPanning) {
            _isPanning = NO;
            _gesture.state = GestureStateEnded;
            _gesture.touchOne = touch;

            [self scroll:_gesture];
        } else if (_isTap) {
            UIView *mainView = [CCDirector sharedDirector].view;
            CGPoint worldPosition = [[CCDirector sharedDirector] convertToGL:[touch locationInView:mainView]];

            [self tapOnWorldPosition:worldPosition];
        }
    } else if ([_touches count] == 2) {
        if (_isPinching) {
            _isPinching = NO;

            NSArray *touchesArr = [_touches allObjects];
            _gesture.state = GestureStateEnded;
            _gesture.touchOne = [touchesArr objectAtIndex:0];
            _gesture.touchTwo = [touchesArr objectAtIndex:1];

            [self zoom:_gesture];
        }
    }

    [_touches removeObject:touch];
    NSArray *touchesArr = [_touches allObjects];
    if (touchesArr.count > 0) {
        CCTouch *firstTouch = [touchesArr firstObject];
        _touchBeginPoint = [firstTouch locationInView:firstTouch.view];
        _isPanning = NO;
    }
}

#pragma mark - LongTap

- (void)beginLongTap:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    void (^longTapBlock) (CCTimer *timer) = ^void(CCTimer *timer) {
      [self touchCancelled:touch withEvent:event];

      CCGLView *mainView = (CCGLView *)[CCDirector sharedDirector].view;
      CGPoint worldPosition = [[CCDirector sharedDirector] convertToGL:[touch locationInView:mainView]];
      [self longTapOnWorldPosition:worldPosition];
    };

    void (^longTapStartBlock) (CCTimer *timer) = ^void(CCTimer *timer) {
      _isTap = NO;
      [_longTapTimer invalidate];
      _longTapTimer = [self scheduleBlock:longTapBlock delay:_longTapDuration - _longTapStartDuration];

      CCGLView *mainView = (CCGLView *)[CCDirector sharedDirector].view;
      CGPoint worldPosition = [[CCDirector sharedDirector] convertToGL:[touch locationInView:mainView]];
      [self longTapStartedOnWorldPosition:worldPosition];
    };

    if ([_touches count] == 1) {
        _longTapTimer = [self scheduleBlock:longTapStartBlock delay:_longTapStartDuration];
    } else {
        [_longTapTimer invalidate];
    }
}

- (void)cancelLongTap
{
    [_longTapTimer invalidate];
    [self longTapCanceled];
}

#pragma mark - On Scroll/Zoom/Tap/Long Tap

// needs to be overridden in subclass
- (void)scroll:(CCGestureRecognizer *)sender {}

// needs to be overridden in subclass
- (void)zoom:(CCGestureRecognizer *)sender {}

// needs to be overridden in subclass
- (void)tapOnWorldPosition:(CGPoint)worldPosition {}

// needs to be overridden in subclass
- (void)longTapStartedOnWorldPosition:(CGPoint)worldPosition {}

// needs to be overridden in subclass
- (void)longTapOnWorldPosition:(CGPoint)worldPosition {}

// needs to be overridden in subclass
- (void)longTapCanceled {}

@end
