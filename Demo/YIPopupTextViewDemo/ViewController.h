//
//  ViewController.h
//  YIPopupTextViewDemo
//
//  Created by Yasuhiro Inami on 12/02/01.
//  Copyright (c) 2012 Yasuhiro Inami. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "YIPopupTextView.h"

@interface ViewController : UIViewController <YIPopupTextViewDelegate>

@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) IBOutlet UIButton *editButton;

- (IBAction)handleEditButton:(id)sender;
- (IBAction)handleModalButton:(id)sender;
- (IBAction)handleDismissButton:(id)sender;

@end
