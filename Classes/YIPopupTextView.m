//
//  YIPopupTextView.m
//  YIPopupTextView
//
//  Created by Yasuhiro Inami on 12/02/01.
//  Copyright (c) 2012 Yasuhiro Inami. All rights reserved.
//

#import "YIPopupTextView.h"

#define IS_ARC              (__has_feature(objc_arc))
#define IS_IPAD             (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define TEXTVIEW_INSETS     (IS_IPAD ? UIEdgeInsetsMake(30, 30, 30, 30) : UIEdgeInsetsMake(15, 15, 15, 15))
#define TEXT_SIZE           (IS_IPAD ? 32 : 16)
#define COUNT_SIZE          (IS_IPAD ? 32 : 16)
#define COUNT_MARGIN        (IS_IPAD ? 20 : 10)
#define CLOSE_IMAGE_WIDTH   (IS_IPAD ? 60 : 30)
#define CLOSE_BUTTON_WIDTH  (IS_IPAD ? 88 : 44)

#define ANIMATION_DURATION  0.25


#pragma mark -

@interface UIImage (YIPopupTextView)

+ (UIImage*)closeButtonImageWithSize:(CGSize)size strokeColor:(UIColor*)strokeColor fillColor:(UIColor*)fillColor shadow:(BOOL)hasShadow;
+ (UIImage*)acceptButtonImageWithSize:(CGSize)size strokeColor:(UIColor*)strokeColor fillColor:(UIColor*)fillColor shadow:(BOOL)hasShadow;

@end


@implementation UIImage (YIPopupTextView)

+ (UIImage*)closeButtonImageWithSize:(CGSize)size strokeColor:(UIColor*)strokeColor fillColor:(UIColor*)fillColor shadow:(BOOL)hasShadow
{
    UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, CGRectMake(0, 0, size.width, size.height));
    
    float cx = size.width/2;  
    float cy = size.height/2;  
    
    float radius = size.width > size.height ? size.height/2 : size.height/2;
    radius -= IS_IPAD ? 8 : 4;
    
    CGRect rectEllipse = CGRectMake(cx - radius, cy - radius, radius*2, radius*2);  
    
    if (fillColor) {
        [fillColor setFill];  
        CGContextFillEllipseInRect(context, rectEllipse); 
    }
    
    if (strokeColor) {
        [strokeColor setStroke];  
        CGContextSetLineWidth(context, IS_IPAD ? 6.0 : 3.0);  
        CGFloat lineLength  = radius/2.5;
        CGContextMoveToPoint(context, cx-lineLength, cy-lineLength);
        CGContextAddLineToPoint(context, cx+lineLength, cy+lineLength);
        CGContextDrawPath(context, kCGPathFillStroke);
        
        CGContextMoveToPoint(context, cx+lineLength, cy-lineLength);
        CGContextAddLineToPoint(context, cx-lineLength, cy+lineLength);
        CGContextDrawPath(context, kCGPathFillStroke);
    }
    
    if (hasShadow) {
        CGContextSetShadow(context, CGSizeMake(IS_IPAD ? 6 : 3, IS_IPAD ? 6 : 3), IS_IPAD ? 4 : 2);
    }
    
    if (strokeColor) {
        CGContextStrokeEllipseInRect(context, rectEllipse);  		
    }
    
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage*)acceptButtonImageWithSize:(CGSize)size strokeColor:(UIColor*)strokeColor fillColor:(UIColor*)fillColor shadow:(BOOL)hasShadow
{
    UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, CGRectMake(0, 0, size.width, size.height));
    
    float cx = size.width/2;
    float cy = size.height/2;
    
    float radius = size.width > size.height ? size.height/2 : size.height/2;
    radius -= IS_IPAD ? 8 : 4;
    
    CGRect rectEllipse = CGRectMake(cx - radius, cy - radius, radius*2, radius*2);
    
    if (fillColor) {
        [fillColor setFill];
        CGContextFillEllipseInRect(context, rectEllipse);
    }
    
    if (strokeColor) {
        [strokeColor setStroke];
        CGContextSetLineWidth(context, IS_IPAD ? 6.0 : 3.0);
        
        CGFloat t = (IS_IPAD ? 2.0 : 1.0); // transitionX
        CGFloat lineLength  = radius/3.0;
        
        CGContextMoveToPoint(context, cx-2*lineLength+2*t, cy); // extra +t for steep angle
        CGContextAddLineToPoint(context, cx-lineLength+t, cy+lineLength);
        CGContextAddLineToPoint(context, cx+lineLength+t, cy-lineLength);
        CGContextDrawPath(context, kCGPathFillStroke);
    }
    
    if (hasShadow) {
        CGContextSetShadow(context, CGSizeMake(IS_IPAD ? 6 : 3, IS_IPAD ? 6 : 3), IS_IPAD ? 4 : 2);
    }
    
    if (strokeColor) {
        CGContextStrokeEllipseInRect(context, rectEllipse);
    }
    
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
@end


////////////////////////////////////////////////////////////////////////////////
#pragma mark -

typedef enum {
    CaretShiftDirectionNone,
    CaretShiftDirectionLeft,
    CaretShiftDirectionRight,
} CaretShiftDirection;


@interface YIPopupTextView () <UIGestureRecognizerDelegate>

- (void)updateCount;

- (void)startObservingNotifications;
- (void)stopObservingNotifications;

- (void)startCaretShiftTimer;
- (void)stopCaretShiftTimer;
- (void)shiftCaret;

@end


@implementation YIPopupTextView
{
    NSUInteger  _maxCount;
    
    UIView*     _backgroundView;
    UIView*     _popupView;
    UILabel*    _countLabel;
    UIButton*   _closeButton;
    UIButton*   _acceptButton;

    
    BOOL        _shouldAnimate;
    
    UIPanGestureRecognizer* _panGesture;
    CGPoint                 _panStartLocation;
    NSTimer*                _caretShiftTimer;
    CaretShiftDirection     _caretShiftDirection;
}

@dynamic delegate;

- (id)initWithPlaceHolder:(NSString*)placeHolder
                 maxCount:(NSUInteger)maxCount
{
    return [self initWithPlaceHolder:placeHolder maxCount:maxCount buttonStyle:YIPopupTextViewButtonStyleRightCancel tintsDoneButton:NO];
}

- (id)initWithPlaceHolder:(NSString*)placeHolder
                 maxCount:(NSUInteger)maxCount
              buttonStyle:(YIPopupTextViewButtonStyle)buttonStyle
          tintsDoneButton:(BOOL)tintsDoneButton
{
    UIColor* tintColor;
    if (tintsDoneButton) {
        tintColor = [UIColor colorWithRed:68.0/255.0 green:153.0/255.0 blue:34.0/255.0 alpha:1]; // #449922
    }
    else {
        tintColor = [UIColor blackColor];
    }
    
    return [self initWithPlaceHolder:placeHolder maxCount:maxCount buttonStyle:buttonStyle doneButtonColor:tintColor];
}

- (id)initWithPlaceHolder:(NSString*)placeHolder
                 maxCount:(NSUInteger)maxCount
              buttonStyle:(YIPopupTextViewButtonStyle)buttonStyle
          doneButtonColor:(UIColor*)doneButtonColor
{
    self = [super init];
    if (self) {
        _shouldAnimate = YES;
        _maxCount = maxCount;
        
        _backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 460)];
        _backgroundView.backgroundColor = [UIColor blackColor];
        _backgroundView.alpha = 0;
        _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        _popupView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 240)];
        _popupView.autoresizingMask = UIViewAutoresizingFlexibleWidth; // height will be set at KeyboardWillShow
        [_backgroundView addSubview:_popupView];
#if !IS_ARC
        [_popupView release];
#endif
        
        self.placeholder = placeHolder;
        self.frame = UIEdgeInsetsInsetRect(_popupView.frame, TEXTVIEW_INSETS);
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.font = [UIFont systemFontOfSize:TEXT_SIZE];
        self.keyboardAppearance = UIKeyboardAppearanceAlert;
        self.autocorrectionType = UITextAutocorrectionTypeNo;
        self.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.layer.cornerRadius = 10;
        self.backgroundColor = [UIColor whiteColor];
        [_popupView addSubview:self];
#if !IS_ARC
        [self release];
#endif
        
        if (maxCount > 0) {
            _countLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            _countLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
            _countLabel.textAlignment = UITextAlignmentRight;
            _countLabel.backgroundColor = [UIColor clearColor];
            _countLabel.textColor = [UIColor lightGrayColor];
            _countLabel.font = [UIFont boldSystemFontOfSize:COUNT_SIZE];
            [_popupView addSubview:_countLabel];
#if !IS_ARC
            [_countLabel release];
#endif
        }
        
        CGFloat buttonRisingRatio = 0.3;
        
        // close (cancel) button
        if (buttonStyle == YIPopupTextViewButtonStyleRightCancel ||
            buttonStyle == YIPopupTextViewButtonStyleLeftCancelRightDone ||
            buttonStyle == YIPopupTextViewButtonStyleRightCancelAndDone) {
            
            _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [_closeButton setImage:[UIImage closeButtonImageWithSize:CGSizeMake(CLOSE_IMAGE_WIDTH, CLOSE_IMAGE_WIDTH)
                                                         strokeColor:[UIColor whiteColor]
                                                           fillColor:[UIColor blackColor]
                                                              shadow:NO]
                          forState:UIControlStateNormal];
            
            CGFloat buttonX;
            UIViewAutoresizing autoresizing;
            
            switch (buttonStyle) {
                case YIPopupTextViewButtonStyleRightCancel:
                    buttonX = _popupView.bounds.size.width-TEXTVIEW_INSETS.right-(1-buttonRisingRatio)*CLOSE_IMAGE_WIDTH;
                    autoresizing = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
                    break;
                case YIPopupTextViewButtonStyleRightCancelAndDone:
                    buttonX = _popupView.bounds.size.width-TEXTVIEW_INSETS.right-(2-buttonRisingRatio)*CLOSE_IMAGE_WIDTH;
                    autoresizing = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
                    break;
                default:
                    buttonX = TEXTVIEW_INSETS.left-(buttonRisingRatio)*CLOSE_IMAGE_WIDTH;
                    autoresizing = UIViewAutoresizingFlexibleRightMargin;
                    break;
            }
            
            _closeButton.frame = CGRectMake(buttonX, TEXTVIEW_INSETS.top-buttonRisingRatio*CLOSE_IMAGE_WIDTH, CLOSE_IMAGE_WIDTH, CLOSE_IMAGE_WIDTH);
            _closeButton.showsTouchWhenHighlighted = YES;
            [_closeButton addTarget:self action:@selector(handleCloseButton:) forControlEvents:UIControlEventTouchUpInside];
            _closeButton.autoresizingMask = autoresizing;
            [_popupView addSubview:_closeButton];
        }
        
        // accept (done) button
        if (buttonStyle == YIPopupTextViewButtonStyleRightDone ||
            buttonStyle == YIPopupTextViewButtonStyleLeftDone ||
            buttonStyle == YIPopupTextViewButtonStyleLeftCancelRightDone ||
            buttonStyle == YIPopupTextViewButtonStyleRightCancelAndDone) {
            
            if (!doneButtonColor) {
                doneButtonColor = [UIColor colorWithRed:68.0/255.0 green:153.0/255.0 blue:34.0/255.0 alpha:1]; // #449922
            }
            
            _acceptButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [_acceptButton setImage:[UIImage acceptButtonImageWithSize:CGSizeMake(CLOSE_IMAGE_WIDTH, CLOSE_IMAGE_WIDTH)
                                                           strokeColor:[UIColor whiteColor]
                                                             fillColor:doneButtonColor
                                                                shadow:NO]
                           forState:UIControlStateNormal];
            
            CGFloat buttonX;
            if (buttonStyle == YIPopupTextViewButtonStyleLeftDone) {
                buttonX  = buttonX = TEXTVIEW_INSETS.left-(buttonRisingRatio)*CLOSE_IMAGE_WIDTH;
            }else{
                buttonX = buttonX = _popupView.bounds.size.width-TEXTVIEW_INSETS.right/2-CLOSE_IMAGE_WIDTH;
            }

            UIViewAutoresizing autoresizing = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
            
            _acceptButton.frame = CGRectMake(buttonX, TEXTVIEW_INSETS.top-buttonRisingRatio*CLOSE_IMAGE_WIDTH, CLOSE_IMAGE_WIDTH, CLOSE_IMAGE_WIDTH);
            _acceptButton.showsTouchWhenHighlighted = YES;
            [_acceptButton addTarget:self action:@selector(handleAcceptButton:) forControlEvents:UIControlEventTouchUpInside];
            _acceptButton.autoresizingMask = autoresizing;
            [_popupView addSubview:_acceptButton];
        }
        
    }
    return self;
}

- (void)dealloc
{
    self.delegate = nil;
    
    // comment-out: don't call endGeneratingDeviceOrientationNotifications twice
    //[self stopObservingNotifications];
    
#if !IS_ARC
    [super dealloc];
#endif
}

#pragma mark -

#pragma mark Accessors

- (UIColor *)outerBackgroundColor
{
    return _backgroundView.backgroundColor;
}

- (void)setOuterBackgroundColor:(UIColor *)outerBackgroundColor
{
    _backgroundView.backgroundColor = outerBackgroundColor;
}

- (BOOL)caretShiftGestureEnabled
{
    return !!_panGesture;
}

- (void)setCaretShiftGestureEnabled:(BOOL)caretShiftGestureEnabled
{
    if (caretShiftGestureEnabled) {
        if (!_panGesture) {
            _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
//            _panGesture.delegate = self;
//            [self addGestureRecognizer:_panGesture];
            [_backgroundView addGestureRecognizer:_panGesture];
        }
    }
    else {
        if (_panGesture) {
            [_backgroundView removeGestureRecognizer:_panGesture];
            _panGesture = nil;
        }
    }
    
}

#pragma mark -

#pragma mark Show/Dismiss

- (void)showInView:(UIView*)view
{
    _shouldAnimate = YES;
    
    // TODO: show in window + orientation handling
    if (!view || [view isKindOfClass:[UIWindow class]]) {
        NSLog(@"Warning: show in window currently doesn't support orientation.");
    }
    
    UIView* targetView = nil;
    CGRect frame;
    if (!view) {
        targetView = [UIApplication sharedApplication].keyWindow;
        frame = [UIScreen mainScreen].applicationFrame;
    }
    else {
        targetView = view;
        frame = view.bounds;
    }
    
    _backgroundView.alpha = 0;
    _backgroundView.frame = frame;
    [targetView addSubview:_backgroundView];
#if !IS_ARC
    [_backgroundView release];
#endif
    
    [self updateCount];
    
    [self startObservingNotifications];
    
    // NOTE: textView popup animation doesn't work when using UIView animation
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation.delegate = self;
    animation.duration = ANIMATION_DURATION;
    animation.repeatCount = 0;
    animation.fromValue =[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.25, 0.25, 0.25)];
    animation.toValue =[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)];
    [_popupView.layer addAnimation:animation forKey:@"popupAnimation"];
    
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        _backgroundView.alpha = 1;
    }];
    
    if (!self.editable) {
        _popupView.frame = _backgroundView.bounds;
    }
    
    [self becomeFirstResponder];
}

- (void)dismiss
{
    [self dismissWithCancelled:NO];
}

- (void)dismissWithCancelled:(BOOL)cancelled
{
    if ([self isFirstResponder]) {
        [self resignFirstResponder];
    }
    
    [self stopObservingNotifications];
    
    if ([self.delegate respondsToSelector:@selector(popupTextView:willDismissWithText:cancelled:)]) {
        [self.delegate popupTextView:self willDismissWithText:self.text cancelled:cancelled];
    }
    
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        
        _backgroundView.alpha = 0;
        
    } completion:^(BOOL finished) {
        
        if (finished) {
            if ([self.delegate respondsToSelector:@selector(popupTextView:didDismissWithText:cancelled:)]) {
                [self.delegate popupTextView:self didDismissWithText:self.text cancelled:cancelled];
            }
            
            [_backgroundView removeFromSuperview];
            _backgroundView = nil;
            _popupView = nil;
        }
        
    }];
}

#pragma mark -

#pragma mark Notifications

- (void)startObservingNotifications
{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveOrientationDidChangeNotification:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveKeyboardWillShowNotification:)
                                                 name:UIKeyboardWillShowNotification 
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveTextDidChangeNotification:)
                                                 name:UITextViewTextDidChangeNotification 
                                               object:nil];
}

- (void)stopObservingNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

// for editable = NO
- (void)didReceiveOrientationDidChangeNotification:(NSNotification*)notification
{
    if (!self.editable) {
        _popupView.frame = _backgroundView.bounds;
    }
}

// for editable = YES
- (void)didReceiveKeyboardWillShowNotification:(NSNotification*)notification
{
    if (!_backgroundView.superview) return;
    
    NSDictionary* userInfo = [notification userInfo];
    
    CGRect keyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    //NSLog(@"keyboardRect = %f %f %f %f",keyboardRect.origin.x,keyboardRect.origin.y,keyboardRect.size.width,keyboardRect.size.height);
    
    CGPoint origin = [self.window convertPoint:_backgroundView.frame.origin fromView:_backgroundView];
    //NSLog(@"origin = %f %f",origin.x,origin.y);
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    CGFloat popupViewHeight = 0;
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            popupViewHeight = keyboardRect.origin.y - origin.y;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            popupViewHeight = origin.y - keyboardRect.size.height;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            popupViewHeight = keyboardRect.origin.x - origin.x;
            break;
        case UIInterfaceOrientationLandscapeRight:
            popupViewHeight = origin.x - keyboardRect.size.width;
            break;
        default:
            break;
    }
    
    CGRect frame = _backgroundView.bounds;
    frame.size.height = popupViewHeight;
    _popupView.frame = frame;
    
}

- (void)didReceiveTextDidChangeNotification:(NSNotification*)notification
{
    if ([notification object] != self) return;
    
    [self updateCount];
}

#pragma mark -

#pragma mark Count

- (void)updateCount
{
    NSUInteger textCount = [self.text length];
    _countLabel.text = [NSString stringWithFormat:@"%d", _maxCount-textCount];
    
    if (textCount > _maxCount) {
        _acceptButton.enabled = FALSE;
        _countLabel.textColor = [UIColor redColor];
    } else {
        _acceptButton.enabled = TRUE;
        _countLabel.textColor = [UIColor lightGrayColor];
    }
    
    [_countLabel sizeToFit];
    _countLabel.frame = CGRectMake(_popupView.bounds.size.width-TEXTVIEW_INSETS.right-_countLabel.frame.size.width-COUNT_MARGIN,
                                   _popupView.bounds.size.height-TEXTVIEW_INSETS.bottom-_countLabel.frame.size.height-COUNT_MARGIN, 
                                   _countLabel.frame.size.width,
                                   _countLabel.frame.size.height);
}

#pragma mark -

#pragma mark Buttons

- (void)handleCloseButton:(UIButton*)sender
{
    [self dismissWithCancelled:YES];
}

- (void)handleAcceptButton:(UIButton*)sender
{
    [self dismissWithCancelled:NO];
}

#pragma mark 

#pragma mark Gestures

- (void)handlePanGesture:(UIPanGestureRecognizer*)gesture
{
    if (self.dragging || self.decelerating) {
        [self stopCaretShiftTimer];
        return;
    }
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
        {
            CGPoint translation = [gesture translationInView:gesture.view];
            if (translation.x > 0) {
                _caretShiftDirection = CaretShiftDirectionRight;
            }
            else if (translation.x < 0) {
                _caretShiftDirection = CaretShiftDirectionLeft;
            }
            else {
                _caretShiftDirection = CaretShiftDirectionNone;
            }
            
            if (_caretShiftDirection != CaretShiftDirectionNone) {
                _panStartLocation = [gesture locationInView:gesture.view];
                [self shiftCaret];
            }
            
            [self performSelector:@selector(startCaretShiftTimer) withObject:nil afterDelay:0.5];
            
            break;
        }
        case UIGestureRecognizerStateChanged:
            
            if (_caretShiftTimer) {
                CGPoint velocity = [gesture velocityInView:gesture.view];
                //CGPoint translation = [gesture velocityInView:gesture.view];
                if (velocity.x > 0) {
                    _caretShiftDirection = CaretShiftDirectionRight;
                }
                else if (velocity.x < 0) {
                    _caretShiftDirection = CaretShiftDirectionLeft;
                }
            }
            
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            
            [self stopCaretShiftTimer];
            break;
            
        default:
            break;
    }
}

//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
//{
//    // recognize textView's scrolling gesture if _panGesture is vertically panning
//    if (gestureRecognizer == _panGesture && [_panGesture translationInView:_panGesture.view].x == 0.0) {
//        
//        return YES;
//    }
//    
//    return NO;
//}

#pragma mark -

#pragma mark Timers

- (void)startCaretShiftTimer
{
    if (!_caretShiftTimer) {
        _caretShiftTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(shiftCaret) userInfo:nil repeats:YES];
    }
}

- (void)stopCaretShiftTimer
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startCaretShiftTimer) object:nil];
    
    [_caretShiftTimer invalidate];
    _caretShiftTimer = nil;
    
    _caretShiftDirection = CaretShiftDirectionNone;
    _panStartLocation = CGPointZero;
}

- (void)shiftCaret
{
    NSRange range = self.selectedRange;
    if (range.length == 0) {
        if (_caretShiftDirection == CaretShiftDirectionRight && range.location < self.text.length) {
            range.location += 1;
        }
        else if (_caretShiftDirection == CaretShiftDirectionLeft && range.location > 0) {
            range.location -= 1;
        }
    }
    else {
        // right caret
        if (_panStartLocation.x > _panGesture.view.frame.size.width/2) {
            if (_caretShiftDirection == CaretShiftDirectionRight && range.location+range.length < self.text.length) {
                range.length += 1;
            }
            else if (_caretShiftDirection == CaretShiftDirectionLeft && range.length > 0) {
                range.length -= 1;
            }
        }
        // left caret
        else {
            if (_caretShiftDirection == CaretShiftDirectionRight && range.length > 0) {
                range.location +=1;
                range.length -= 1;
            }
            else if (_caretShiftDirection == CaretShiftDirectionLeft && range.location > 0) {
                range.location -=1;
                range.length += 1;
            }
        }
    }
    
    self.selectedRange = range;
}

@end