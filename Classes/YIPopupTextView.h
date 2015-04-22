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
- (BOOL)popupTextView:(YIPopupTextView *)textView shouldDismissWithText:(NSString *)text cancelled:(BOOL)cancelled;
- (void)popupTextView:(YIPopupTextView*)textView willDismissWithText:(NSString*)text cancelled:(BOOL)cancelled;
- (void)popupTextView:(YIPopupTextView*)textView didDismissWithText:(NSString*)text cancelled:(BOOL)cancelled;

@end


@interface YIPopupTextView : YISSTextView

@property (nonatomic, assign) id <YIPopupTextViewDelegate> delegate;

@property (nonatomic, strong) UIColor* outerBackgroundColor;    // default = black opaque

@property (nonatomic, assign) BOOL caretShiftGestureEnabled;    // default = NO
@property (nonatomic, assign) NSUInteger maxCount;
@property (nonatomic) CGFloat topUIBarMargin;       // set statusBar+navBar height for iOS7 fullscreen size manually
@property (nonatomic) CGFloat bottomUIBarMargin;    // set tabBar+toolbar height for iOS7 fullscreen size manually

- (id)initWithPlaceHolder:(NSString*)placeHolder
                 maxCount:(NSUInteger)maxCount;     // YIPopupTextViewButtonStyleRightCancel

- (id)initWithPlaceHolder:(NSString*)placeHolder
                 maxCount:(NSUInteger)maxCount
              buttonStyle:(YIPopupTextViewButtonStyle)buttonStyle;

- (id)initWithPlaceHolder:(NSString*)placeHolder
                 maxCount:(NSUInteger)maxCount
              buttonStyle:(YIPopupTextViewButtonStyle)buttonStyle
          doneButtonColor:(UIColor*)doneColor;      // set doneButtonColor=nil to show preset green color

- (id)initWithPlaceHolder:(NSString*)placeHolder
                 maxCount:(NSUInteger)maxCount
              buttonStyle:(YIPopupTextViewButtonStyle)buttonStyle
          doneButtonColor:(UIColor*)doneButtonColor
           textViewInsets:(UIEdgeInsets)textViewInsets;

- (void)showInView:(UIView*)view;
- (void)showInViewController:(UIViewController*)viewController;     // automatically adjusts top/bottomUIBarMargin for iOS7

- (void)dismiss;

@end

