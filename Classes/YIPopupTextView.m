//
//  YIPopupTextView.m
//  YIPopupTextView
//
//  Created by Yasuhiro Inami on 12/02/01.
//  Copyright (c) 2012 Yasuhiro Inami. All rights reserved.
//

#import "YIPopupTextView.h"

#define IS_IPAD             (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_PORTRAIT         UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)
#define IS_IOS_AT_LEAST(ver)    ([[[UIDevice currentDevice] systemVersion] compare:ver] != NSOrderedAscending)

#if defined(__IPHONE_7_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0
#   define IS_FLAT_DESIGN          IS_IOS_AT_LEAST(@"7.0")
#else
#   define IS_FLAT_DESIGN          NO
#endif

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

@property (nonatomic, weak) UIViewController* viewController;

- (void)updateCount;

- (void)startObservingNotifications;
- (void)stopObservingNotifications;

- (void)startCaretShiftTimer;
- (void)stopCaretShiftTimer;
- (void)shiftCaret;

@end


@implementation YIPopupTextView
{
    NSUInteger      _maxCount;
    UIEdgeInsets    _textViewInsets;
    
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
    return [self initWithPlaceHolder:placeHolder maxCount:maxCount buttonStyle:YIPopupTextViewButtonStyleRightCancel];
}

- (id)initWithPlaceHolder:(NSString*)placeHolder
                 maxCount:(NSUInteger)maxCount
              buttonStyle:(YIPopupTextViewButtonStyle)buttonStyle
{
    return [self initWithPlaceHolder:placeHolder maxCount:maxCount buttonStyle:buttonStyle doneButtonColor:nil];
}

- (id)initWithPlaceHolder:(NSString*)placeHolder
                 maxCount:(NSUInteger)maxCount
              buttonStyle:(YIPopupTextViewButtonStyle)buttonStyle
          doneButtonColor:(UIColor*)doneButtonColor
{
    return [self initWithPlaceHolder:placeHolder maxCount:maxCount buttonStyle:buttonStyle doneButtonColor:doneButtonColor textViewInsets:UIEdgeInsetsZero];
}

- (id)initWithPlaceHolder:(NSString*)placeHolder
                 maxCount:(NSUInteger)maxCount
              buttonStyle:(YIPopupTextViewButtonStyle)buttonStyle
          doneButtonColor:(UIColor*)doneButtonColor
           textViewInsets:(UIEdgeInsets)textViewInsets
{
    self = [super init];
    if (self) {
        _shouldAnimate = YES;
        _maxCount = maxCount;
        
        if (UIEdgeInsetsEqualToEdgeInsets(textViewInsets, UIEdgeInsetsZero)) {
            _textViewInsets = TEXTVIEW_INSETS;  // preset insets
        }
        else {
            _textViewInsets = textViewInsets;
        }
        
        _backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 460)];
        _backgroundView.backgroundColor = [UIColor blackColor];
        _backgroundView.alpha = 0;
        _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        _popupView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 240)];
        _popupView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_backgroundView addSubview:_popupView];
        
        self.placeholder = placeHolder;
        self.frame = UIEdgeInsetsInsetRect(_popupView.frame, _textViewInsets);
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.font = [UIFont systemFontOfSize:TEXT_SIZE];
        self.keyboardAppearance = UIKeyboardAppearanceAlert;
        self.autocorrectionType = UITextAutocorrectionTypeNo;
        self.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.layer.cornerRadius = 10;
        self.backgroundColor = [UIColor whiteColor];
        [_popupView addSubview:self];
        
        if (maxCount > 0) {
            _countLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            _countLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
#if (__IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_6_0)
			_countLabel.textAlignment = UITextAlignmentRight;
#else
			_countLabel.textAlignment = NSTextAlignmentRight;
#endif
            _countLabel.backgroundColor = [UIColor clearColor];
            _countLabel.textColor = [UIColor lightGrayColor];
            _countLabel.font = [UIFont boldSystemFontOfSize:COUNT_SIZE];
            [_popupView addSubview:_countLabel];
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
                    buttonX = _popupView.bounds.size.width-_textViewInsets.right-(1-buttonRisingRatio)*CLOSE_IMAGE_WIDTH;
                    autoresizing = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
                    break;
                case YIPopupTextViewButtonStyleRightCancelAndDone:
                    buttonX = _popupView.bounds.size.width-_textViewInsets.right-(2-buttonRisingRatio)*CLOSE_IMAGE_WIDTH;
                    autoresizing = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
                    break;
                default:
                    buttonX = _textViewInsets.left-(buttonRisingRatio)*CLOSE_IMAGE_WIDTH;
                    autoresizing = UIViewAutoresizingFlexibleRightMargin;
                    break;
            }
            
            _closeButton.frame = CGRectMake(buttonX, _textViewInsets.top-buttonRisingRatio*CLOSE_IMAGE_WIDTH, CLOSE_IMAGE_WIDTH, CLOSE_IMAGE_WIDTH);
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
                buttonX = _textViewInsets.left-(buttonRisingRatio)*CLOSE_IMAGE_WIDTH;
            }else{
                buttonX = _popupView.bounds.size.width-_textViewInsets.right/2-CLOSE_IMAGE_WIDTH;
            }
            
            UIViewAutoresizing autoresizing = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
            
            _acceptButton.frame = CGRectMake(buttonX, _textViewInsets.top-buttonRisingRatio*CLOSE_IMAGE_WIDTH, CLOSE_IMAGE_WIDTH, CLOSE_IMAGE_WIDTH);
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
}

#pragma mark -

#pragma mark Accessors

- (NSUInteger)maxCount {
    return _maxCount;
}

- (void)setMaxCount:(NSUInteger)maxCount {
     _maxCount = maxCount;
    [self updateCount];
}

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
    
    [self _changePopupViewFrameWithNotification:nil];
    
    [self becomeFirstResponder];
}

- (void)showInViewController:(UIViewController*)viewController
{
    _viewController = viewController;
    
    if ([viewController.view isKindOfClass:[UIScrollView class]]) {
        [self showInView:viewController.view.superview];
    }
    else {
        [self showInView:viewController.view];
    }
}

- (void)dismiss
{
    [self dismissWithCancelled:NO];
}

- (void)dismissWithCancelled:(BOOL)cancelled
{
    // stop observing before resignFirstResponder, for not to adjust frame while dismissing
    [self stopObservingNotifications];
    
    if ([self isFirstResponder]) {
        [self resignFirstResponder];
    }
    
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
    
    //
    // NOTE:
    // UIKeyboardWillShowNotification is not called when using iPad with splitted keyboard,
    // so use willChangeFrameNotification instead.
    //
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onKeyboardWillChangeFrameNotification:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    // CAUTION: UIKeyboardDidChangeFrameNotification returns wrong keyboardRect when using iPhone + Japanese keyboard
    // NOTE: required for iPad + splitted keyboard
    if (IS_IPAD) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onKeyboardDidChangeFrameNotification:)
                                                     name:UIKeyboardDidChangeFrameNotification
                                                   object:nil];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onTextDidChangeNotification:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:nil];
}

- (void)stopObservingNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    
    if (IS_IPAD) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidChangeFrameNotification object:nil];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)onKeyboardWillChangeFrameNotification:(NSNotification*)notification
{
    [self _changePopupViewFrameWithNotification:notification];
}

- (void)onKeyboardDidChangeFrameNotification:(NSNotification*)notification
{
    [self _changePopupViewFrameWithNotification:notification];
}

- (void)_changePopupViewFrameWithNotification:(NSNotification*)notification
{
    if (!_backgroundView.superview) return;
    
    CGFloat topMargin = _topUIBarMargin;
    CGFloat bottomMargin = _bottomUIBarMargin;
    
    CGFloat popupViewHeight = 0;
    
#if defined(__IPHONE_7_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0
    
    // automatically adjusts top/bottomUIBarMargin for iOS7 fullscreen size
    if (_viewController) {
        UINavigationBar* navBar = _viewController.navigationController.navigationBar;
        UIToolbar* toolbar = _viewController.navigationController.toolbar;
        UITabBar* tabBar = _viewController.tabBarController.tabBar;
        
        CGFloat statusBarHeight = (IS_PORTRAIT ? [UIApplication sharedApplication].statusBarFrame.size.height : [UIApplication sharedApplication].statusBarFrame.size.width);
        CGFloat navBarHeight = (navBar && !navBar.hidden ? navBar.bounds.size.height : 0);
        CGFloat toolbarHeight = (toolbar && !toolbar.hidden ? toolbar.bounds.size.height : 0);
        CGFloat tabBarHeight = (tabBar && !tabBar.hidden ? tabBar.bounds.size.height : 0);
        
        if (topMargin == 0.0 && IS_FLAT_DESIGN && (_viewController.edgesForExtendedLayout & UIRectEdgeTop)) {
            topMargin = statusBarHeight+navBarHeight;
        }
        if (bottomMargin == 0.0 && IS_FLAT_DESIGN && (_viewController.edgesForExtendedLayout & UIRectEdgeBottom)) {
            bottomMargin = toolbarHeight+tabBarHeight;
        }
    }
    
#endif

    if (notification) {
        NSDictionary* userInfo = [notification userInfo];
        
        CGRect keyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        if (CGRectEqualToRect(keyboardRect, CGRectZero)) {
            keyboardRect = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
        }
        
        CGPoint bgOrigin = [self.window convertPoint:CGPointZero fromView:_backgroundView];
        
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        
        switch (orientation) {
            case UIInterfaceOrientationPortrait:
                popupViewHeight = keyboardRect.origin.y - bgOrigin.y - topMargin;
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                popupViewHeight = bgOrigin.y - keyboardRect.origin.y - keyboardRect.size.height - topMargin;
                break;
            case UIInterfaceOrientationLandscapeLeft:
                // keyboard at portrait-right
                popupViewHeight = keyboardRect.origin.x - bgOrigin.x - topMargin;
                break;
            case UIInterfaceOrientationLandscapeRight:
                // keyboard at portrait-left
                popupViewHeight = bgOrigin.x - keyboardRect.origin.x - keyboardRect.size.width - topMargin;
                break;
            default:
                break;
        }
    }
    else {
        popupViewHeight = _backgroundView.bounds.size.height;
    }
    
    popupViewHeight = MIN(popupViewHeight, _backgroundView.bounds.size.height-topMargin-bottomMargin);
    
    CGRect frame = _backgroundView.bounds;
    frame.origin.y = topMargin;
    frame.size.height = popupViewHeight;
    _popupView.frame = frame;
    
}

- (void)onTextDidChangeNotification:(NSNotification*)notification
{
    if ([notification object] != self) return;
    
    [self updateCount];
}

#pragma mark -

#pragma mark Count

- (void)updateCount
{
    NSUInteger textCount = [self.text length];
    NSInteger deltaCount = _maxCount - textCount;
    _countLabel.text = [NSString stringWithFormat:@"%@",@(deltaCount)];
    
    if (_maxCount > 0 && textCount > _maxCount) {
        _acceptButton.enabled = NO;
        _countLabel.textColor = [UIColor redColor];
    } else {
        _acceptButton.enabled = YES;
        _countLabel.textColor = [UIColor lightGrayColor];
    }
    
    [_countLabel sizeToFit];
    _countLabel.frame = CGRectMake(_popupView.bounds.size.width-_textViewInsets.right-_countLabel.frame.size.width-COUNT_MARGIN,
                                   _popupView.bounds.size.height-_textViewInsets.bottom-_countLabel.frame.size.height-COUNT_MARGIN,
                                   _countLabel.frame.size.width,
                                   _countLabel.frame.size.height);
}

#pragma mark -

#pragma mark Buttons

- (void)handleCloseButton:(UIButton*)sender
{
    [self _handleButtonWithCancelled:YES];
}

- (void)handleAcceptButton:(UIButton*)sender
{
    [self _handleButtonWithCancelled:NO];
}

- (void)_handleButtonWithCancelled:(BOOL)cancelled
{
    if ([self.delegate respondsToSelector:@selector(popupTextView:shouldDismissWithText:cancelled:)]) {
        if (![self.delegate popupTextView:self shouldDismissWithText:self.text cancelled:cancelled]) {
            return;
        }
    }
    
    [self dismissWithCancelled:cancelled];
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