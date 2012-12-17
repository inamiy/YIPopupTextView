//
//  YISSTextView.m
//  SSToolkit
//
//  Created by Sam Soffes on 8/18/10.
//  Copyright 2010-2011 Sam Soffes. All rights reserved.
//

#import "YISSTextView.h"

#define IS_ARC              (__has_feature(objc_arc))


@interface YISSTextView (PrivateMethods)
- (void)_updateShouldDrawPlaceholder;
- (void)_textChanged:(NSNotification *)notification;
@end


@implementation YISSTextView

#pragma mark -
#pragma mark Accessors

@synthesize placeholder = _placeholder;
@synthesize placeholderColor = _placeholderColor;

- (void)setText:(NSString *)string {
	[super setText:string];
	[self _updateShouldDrawPlaceholder];
}


- (void)setPlaceholder:(NSString *)string {
	if ([string isEqual:_placeholder]) {
		return;
	}
	
#if IS_ARC
    _placeholder = string;
#else
	[_placeholder release];
	_placeholder = [string retain];
#endif
	
	[self _updateShouldDrawPlaceholder];
}


#pragma mark -
#pragma mark NSObject

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:self];
	
#if !IS_ARC
	[_placeholder release];
	[_placeholderColor release];
	[super dealloc];
#endif
}


#pragma mark -
#pragma mark UIView

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_textChanged:) name:UITextViewTextDidChangeNotification object:self];
		
		self.placeholderColor = [UIColor colorWithWhite:0.702f alpha:1.0f];
		_shouldDrawPlaceholder = NO;
	}
	return self;
}


- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	if (_shouldDrawPlaceholder) {
		[_placeholderColor set];
		[_placeholder drawInRect:CGRectMake(8.0f, 8.0f, self.frame.size.width - 16.0f, self.frame.size.height - 16.0f) withFont:self.font];
	}
}


#pragma mark -
#pragma mark Private Methods

- (void)_updateShouldDrawPlaceholder {
	BOOL prev = _shouldDrawPlaceholder;
	_shouldDrawPlaceholder = self.placeholder && self.placeholderColor && self.text.length == 0;
	
	if (prev != _shouldDrawPlaceholder) {
		[self setNeedsDisplay];
	}
}


- (void)_textChanged:(NSNotification *)notificaiton {
	[self _updateShouldDrawPlaceholder];	
}

@end
