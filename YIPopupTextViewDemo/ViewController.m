//
//  ViewController.m
//  YIPopupTextViewDemo
//
//  Created by Yasuhiro Inami on 12/02/01.
//  Copyright (c) 2012 Yasuhiro Inami. All rights reserved.
//

#import "ViewController.h"

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

#pragma mark IBActions

- (IBAction)handleEditButton:(id)sender 
{
    // NOTE: maxCount = 0 to hide count
    YIPopupTextView* popupTextView = [[YIPopupTextView alloc] initWithPlaceHolder:@"input here" maxCount:1000];
    popupTextView.delegate = self;
    popupTextView.showCloseButton = YES;
    popupTextView.caretShiftGestureEnabled = YES;   // default = NO
    popupTextView.text = self.textView.text;
//    popupTextView.editable = NO;                  // set editable=NO to show without keyboard
    [popupTextView showInView:self.view];
    
    //
    // NOTE:
    // You can add your custom-button after calling -showInView:
    // (it's better to add on either superview or superview.superview)
    // https://github.com/inamiy/YIPopupTextView/issues/3
    //
    // [popupTextView.superview addSubview:customButton];
    //
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

- (void)popupTextView:(YIPopupTextView *)textView willDismissWithText:(NSString *)text
{
    NSLog(@"will dismiss");
    self.textView.text = text;
}

- (void)popupTextView:(YIPopupTextView *)textView didDismissWithText:(NSString *)text
{
    NSLog(@"did dismiss");
}

@end
