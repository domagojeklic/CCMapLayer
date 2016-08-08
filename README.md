# CCMapLayer

CCMapLayer is a open source, Cocos2d implementation of simple map navigation layer with scroll and zoom functionality. Full list of features includes:
> - Layer scrolling on pan gesture
> - Support for scrolling deceleration (inertia)
> - Two supported types of zooming on pinch gesture: ***view center fixed*** and ***pinch center fixed***
> - Tap and long tap detection on layer
> - Customizable parameters

## Usage
Simply copy the folder into your Cocos2d project. Import the header file

`#import "CCMapLayer.h"`

Create a node that you want to navigate through and pass it to the `CCMapLayer` initializer

    CCSprite *background = [CCSprite spriteWithImageNamed:@"world_map.png"];

    CCMapLayer *map = [[CCMapLayer alloc] initWithNode:background zoomType:ZoomTypePinchCenterFixed decelerateScroll:YES];
    map.anchorPoint = CGPointZero;
    map.position = CGPointZero;
    [self addChild:map];
  
Alternatively, you can subclass the CCMapLayer and override `tapOnWorldPosition:`, `longTapStartedOnWorldPosition:`, `longTapOnWorldPosition:` methods to react on tap and long tap actions.
