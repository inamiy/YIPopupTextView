//
//  YIPopupTextView.h
//  YIPopupTextView
//
//  Created by Yasuhiro Inami on 12/02/01.
//  Copyright (c) 2012 Yasuhiro Inami. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "SSTextView.h"

@class YIPopupTextView;


@protocol YIPopupTextViewDelegate <UITextViewDelegate>
@optional
- (void)popupTextView:(YIPopupTextView*)textView willDismissWithText:(NSString*)text;
- (void)popupTextView:(YIPopupTextView*)textView didDismissWithText:(NSString*)text;
@end


@interface YIPopupTextView : SSTextView {
    NSUInteger  _maxCount;
    
    UIView*     _backgroundView;
    UIView*     _popupView;
    UILabel*    _countLabel;
    UIButton*   _closeButton;
    
    BOOL        _shouldAnimate;
}

@property (nonatomic, assign) id <YIPopupTextViewDelegate> delegate;
@property (nonatomic, assign) BOOL showCloseButton;

- (id)initWithPlaceHolder:(NSString*)placeHolder maxCount:(NSUInteger)maxCount;
- (void)showInView:(UIView*)view;
- (void)dismiss;

@end

