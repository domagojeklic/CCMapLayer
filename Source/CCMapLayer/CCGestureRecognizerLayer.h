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

#import "cocos2d.h"

typedef enum { GestureTypePan, GestureTypePinch } GestureType;

typedef enum {
    GestureStateBegan,
    GestureStateInProgress,
    GestureStateEnded,
} GestureRecognizerState;


@interface CCGestureRecognizer : NSObject

@property (nonatomic) GestureRecognizerState state;
@property (nonatomic) GestureType type;
@property (nonatomic, strong) CCTouch *touchOne;
@property (nonatomic, strong) CCTouch *touchTwo;

- (instancetype)initWithType:(GestureType)type state:(GestureRecognizerState)state touch:(CCTouch *)touch;
- (instancetype)initWithType:(GestureType)type
                       state:(GestureRecognizerState)state
                    touchOne:(CCTouch *)touchOne
                    touchTwo:(CCTouch *)touchTwo;

- (CGPoint)getGLLocation;
- (float)getPinchScale;
- (CGPoint)getPinchCenter;
@end

@interface CCGestureRecognizerLayer : CCNode

@property (nonatomic) float longTapStartDuration;
@property (nonatomic) float longTapDuration;

- (instancetype)initWithContentSize:(CGSize)contentSize;

- (void)scroll:(CCGestureRecognizer *)sender;
- (void)zoom:(CCGestureRecognizer *)sender;
- (void)tapOnWorldPosition:(CGPoint)worldPosition;
- (void)longTapStartedOnWorldPosition:(CGPoint)worldPosition;
- (void)longTapOnWorldPosition:(CGPoint)worldPosition;

@end
