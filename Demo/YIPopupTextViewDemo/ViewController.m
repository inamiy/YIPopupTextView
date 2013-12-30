//
//  ViewController.m
//  YIPopupTextViewDemo
//
//  Created by Yasuhiro Inami on 12/02/01.
//  Copyright (c) 2012 Yasuhiro Inami. All rights reserved.
//

#import "ViewController.h"

#define IS_IOS_AT_LEAST(ver)    ([[[UIDevice currentDevice] systemVersion] compare:ver] != NSOrderedAscending)


@interface ViewController ()
@property (nonatomic) YIPopupTextView* popupTextView;
@end


@implementation ViewController
@synthesize textView;
@synthesize editButton;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [self setTextView:nil];
    [self setEditButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    
    return YES;
    //return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark -

#pragma mark iOS7 StatusBar

- (BOOL)prefersStatusBarHidden
{
//    return !!_popupTextView;
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (_popupTextView) {
        return UIStatusBarStyleLightContent;    // white text
    }
    else {
        return UIStatusBarStyleDefault;         // black text
    }
}

#pragma mark -

#pragma mark IBActions

- (IBAction)handleEditButton:(id)sender 
{
    BOOL editable = YES;
    
    YIPopupTextView* popupTextView =
    [[YIPopupTextView alloc] initWithPlaceHolder:@"input here"
                                        maxCount:1000
                                     buttonStyle:YIPopupTextViewButtonStyleRightCancelAndDone];
    popupTextView.delegate = self;
    popupTextView.caretShiftGestureEnabled = YES;       // default = NO. using YISwipeShiftCaret is recommended.
    popupTextView.text = self.textView.text;
    popupTextView.editable = editable;                  // set editable=NO to show without keyboard
    
    [popupTextView showInViewController:self];
    
    //
    // NOTE:
    // You can add your custom-button after calling -showInView:
    // (it's better to add on either superview or superview.superview)
    // https://github.com/inamiy/YIPopupTextView/issues/3
    //
    // [popupTextView.superview addSubview:customButton];
    //
    
    _popupTextView = popupTextView;
    
#if defined(__IPHONE_7_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0
    if (IS_IOS_AT_LEAST(@"7.0")) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
#endif
}

- (IBAction)handleModalButton:(id)sender
{
    UIViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ViewController"];
    vc.title = @"modal";
    
    if (self.navigationController) {
        UINavigationController* naviC = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentModalViewController:naviC animated:YES];
    }
    else {
        [self presentModalViewController:vc animated:YES];
    }
}

- (IBAction)handleDismissButton:(id)sender 
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark -

#pragma mark YIPopupTextViewDelegate

- (void)popupTextView:(YIPopupTextView *)textView willDismissWithText:(NSString *)text cancelled:(BOOL)cancelled
{
    NSLog(@"will dismiss: cancelled=%d",cancelled);
    self.textView.text = text;
    
    _popupTextView = nil;
    
#if defined(__IPHONE_7_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0
    if (IS_IOS_AT_LEAST(@"7.0")) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
#endif
}

- (void)popupTextView:(YIPopupTextView *)textView didDismissWithText:(NSString *)text cancelled:(BOOL)cancelled
{
    NSLog(@"did dismiss: cancelled=%d",cancelled);
}

@end
