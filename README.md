YIPopupTextView 1.0.0
=====================

facebook's post-like input text view for iOS.

<img src="https://raw.github.com/inamiy/YIPopupTextView/master/Screenshots/screenshot1.png" alt="ScreenShot1" width="225px" style="width:225px;" /> <img src="https://raw.github.com/inamiy/YIPopupTextView/master/Screenshots/screenshot2.png" alt="ScreenShot1" width="225px" style="width:225px;" />

How to use
----------
```
// NOTE: maxCount = 0 to hide count
YIPopupTextView* popupTextView = [[YIPopupTextView alloc] initWithPlaceHolder:@"input here" maxCount:1000];
popupTextView.delegate = self;
popupTextView.caretShiftGestureEnabled = YES;   // default = NO
popupTextView.text = self.textView.text;
//popupTextView.editable = NO;                  // set editable=NO to show without keyboard
[popupTextView showInView:self.view];

//
// NOTE:
// You can add your custom-button after calling -showInView:
// (it's better to add on either superview or superview.superview)
// https://github.com/inamiy/YIPopupTextView/issues/3
//
// [popupTextView.superview addSubview:customButton];
//

```

### YIPopupTextViewButtonStyle

```
typedef NS_ENUM(NSInteger, YIPopupTextViewButtonStyle) {
    YIPopupTextViewButtonStyleNone,
    YIPopupTextViewButtonStyleRightCancel,          // "x" on the upper-right
    YIPopupTextViewButtonStyleRightDone,            // "check" on the upper-right
    YIPopupTextViewButtonStyleLeftCancelRightDone,
    YIPopupTextViewButtonStyleRightCancelAndDone
};

```

For `caret-shifting`, it is better to use [YISwipeShiftCaret](https://github.com/inamiy/YISwipeShiftCaret) for all UITextField/UITextViews.

License
-------
`YIPopupTextView` is available under the [Beerware](http://en.wikipedia.org/wiki/Beerware) license.

If we meet some day, and you think this stuff is worth it, you can buy me a beer in return.

