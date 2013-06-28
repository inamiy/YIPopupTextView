//
//  YIPopupTextView.h
//  YIPopupTextView
//
//  Created by Yasuhiro Inami on 12/02/01.
//  Copyright (c) 2012 Yasuhiro Inami. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "YISSTextView.h"

@class YIPopupTextView;


typedef NS_ENUM(NSInteger, YIPopupTextViewButtonStyle) {
    YIPopupTextViewButtonStyleNone,
    YIPopupTextViewButtonStyleRightCancel,          // "x" on the upper-right
    YIPopupTextViewButtonStyleRightDone,            // "check" on the upper-right
    YIPopupTextViewButtonStyleLeftCancelRightDone,
    YIPopupTextViewButtonStyleRightCancelAndDone,
    YIPopupTextViewButtonStyleLeftDone
};


@protocol YIPopupTextViewDelegate <UITextViewDelegate>
@optional
- (void)popupTextView:(YIPopupTextView*)textView willDismissWithText:(NSString*)text cancelled:(BOOL)cancelled;
- (void)popupTextView:(YIPopupTextView*)textView didDismissWithText:(NSString*)text cancelled:(BOOL)cancelled;

@end


@interface YIPopupTextView : YISSTextView

@property (nonatomic, assign) id <YIPopupTextViewDelegate> delegate;

@property (nonatomic, strong) UIColor* outerBackgroundColor;    // default = black opaque

@property (nonatomic, assign) BOOL caretShiftGestureEnabled;    // default = NO

- (id)initWithPlaceHolder:(NSString*)placeHolder
                 maxCount:(NSUInteger)maxCount;     // YIPopupTextViewButtonStyleRightCancel & tintsDoneButton=NO

- (id)initWithPlaceHolder:(NSString*)placeHolder
                 maxCount:(NSUInteger)maxCount
              buttonStyle:(YIPopupTextViewButtonStyle)buttonStyle
          tintsDoneButton:(BOOL)tintsDoneButton;    // tints doneButton to green or black color

- (id)initWithPlaceHolder:(NSString*)placeHolder
                 maxCount:(NSUInteger)maxCount
              buttonStyle:(YIPopupTextViewButtonStyle)buttonStyle
          doneButtonColor:(UIColor*)doneColor;      // any doneButton color

- (void)showInView:(UIView*)view;
- (void)dismiss;

@end

