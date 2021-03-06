//
//  ReturnToFieldBehavior.m
//  Fling
//

#import "ReturnToFieldBehavior.h"
#import "TokenView.h"

@interface ReturnToFieldBehavior ()

@property (readwrite, strong) TokenView* token;
@property (assign) CGPoint snapToPoint;
@property (strong) UISnapBehavior* snapToBottomBehavior;
@property (strong) UIPushBehavior* pushOpacityBehavior;

@end

@implementation ReturnToFieldBehavior

- (instancetype) initWithToken:(TokenView*)token snapToPoint:(CGPoint)returnPoint
{
    self = [super init];
    if ( self )
    {
        self.token = token;
        self.snapToPoint = returnPoint;
    }
    return self;
}


- (void (^)(void))action
{
    return ^{
        // did our item move out of bounds of the reference view?
        UIView* referenceView = self.dynamicAnimator.referenceView;
        CGRect referenceViewBounds = CGRectInset(referenceView.bounds, 10.0, 10.0);
            // we'll inset the reference bounds just a bit so things aren't impossibly close
            // to the edge to manipulate
        CGRect tokenFrame = self.token.frame;
        tokenFrame = [referenceView convertRect:tokenFrame fromView:self.token.superview];
        
        BOOL isContained = CGRectContainsRect(referenceViewBounds, tokenFrame);
        BOOL doesIntersect = CGRectIntersectsRect(referenceViewBounds, tokenFrame);
        
        if ( !self.snapToBottomBehavior && !isContained && !doesIntersect )
        {
            // the item might have some velocity we need to negate
            // (alternatively the item can be removed from all behaviors
            //  and then re-added)
            
            CGPoint itemVelocity = [self.token.dynamicItemBehavior linearVelocityForItem:self.token];
            
            CGPoint counterVelocity = itemVelocity;
            counterVelocity.x = -counterVelocity.x;
            counterVelocity.y = -counterVelocity.y;
            
            [self.token.dynamicItemBehavior addLinearVelocity:counterVelocity forItem:self.token];
            
            // Move the token off below the bottom
            
            self.token.center = (CGPoint){CGRectGetMidX(referenceViewBounds), CGRectGetMaxY(referenceViewBounds) + 300.0};
            [self.dynamicAnimator updateItemUsingCurrentState:self.token];
            
            self.snapToBottomBehavior= [[UISnapBehavior alloc] initWithItem:self.token snapToPoint:self.snapToPoint];
            self.snapToBottomBehavior.damping = 0.9;
            [self addChildBehavior:self.snapToBottomBehavior];
            
            // Drive the opacity of the item with the animator
            self.token.alpha = 0.0;
            
            self.pushOpacityBehavior = [[UIPushBehavior alloc] initWithItems:@[self.token.opacityItem] mode:UIPushBehaviorModeInstantaneous];
            self.pushOpacityBehavior.magnitude = 2.0;
            
            [self addChildBehavior:self.pushOpacityBehavior];
            [self addChildBehavior:self.token.opacityItem.dynamicItemBehavior];
        }
        else if ( self.snapToBottomBehavior != nil || self.pushOpacityBehavior != nil )
        {
            CGPoint itemVelocity = [self.token.dynamicItemBehavior linearVelocityForItem:self.token];
            CGFloat magnitude = sqrt( (itemVelocity.x * itemVelocity.x) + (itemVelocity.y * itemVelocity.y) );
            
            if (magnitude < 0.01)
            {
                [self removeChildBehavior:self.snapToBottomBehavior];
                self.snapToBottomBehavior = nil;
            }
            
            CGPoint opacityVelocty = [self.token.opacityItem.dynamicItemBehavior linearVelocityForItem:self.token.opacityItem];
            if ( opacityVelocty.x < 0.01 )
            {
                [self removeChildBehavior:self.pushOpacityBehavior];
                [self removeChildBehavior:self.token.opacityItem.dynamicItemBehavior];
                self.pushOpacityBehavior = nil;
                self.token.alpha = 1.0;
            }
        }
    };
}

@end