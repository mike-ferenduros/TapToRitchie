//
//  ViewController.m
//  TapToRitchie
//
//  Created by Michael Ferenduros on 21/07/2013.
//  Copyright (c) 2013 Michael Ferenduros. All rights reserved.
//

#import "ViewController.h"
#import "GangsterNamer.h"
#import <GLKit/GLKit.h>


static int randy( int r )
{
	return (rand()/100) % r;
}


@implementation ViewController

- (id)init
{
	if( self = [super init] )
	{
		[GangsterNamer loadStrings];
	}
	return self;
}


- (void)loadView
{
	self.view = mainView = [[VideoView alloc] initWithFrame:CGRectMake(0,0,300,300)];

	capSesh = [[AVCaptureSession alloc] init];
	capSesh.sessionPreset = AVCaptureSessionPreset640x480;

	capCam = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	AVCaptureDeviceInput *camDev = [AVCaptureDeviceInput deviceInputWithDevice:capCam error:nil];
	[capSesh addInput:camDev];

	capDataOut = [[AVCaptureVideoDataOutput alloc] init];
	[capDataOut setVideoSettings:@{(__bridge NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];
	dispatch_queue_t q = dispatch_queue_create( "CaptureVC", DISPATCH_QUEUE_SERIAL );
	[capDataOut setSampleBufferDelegate:self queue:q];
	capDataOut.alwaysDiscardsLateVideoFrames = NO;
	[capSesh addOutput:capDataOut];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	label = [[UILabel alloc] initWithFrame:CGRectInset(self.view.bounds,32,32)];
	label.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	label.font = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:32.0f];
	label.textColor = [UIColor whiteColor];
	label.backgroundColor = [UIColor clearColor];
	label.contentMode = UIViewContentModeBottom;
	label.numberOfLines = 3;
	label.hidden = YES;
	[self.view addSubview:label];

	[capSesh startRunning];

	tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
	[self.view addGestureRecognizer:tapper];

	twoTapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
	twoTapper.numberOfTouchesRequired = 2;
	[self.view addGestureRecognizer:twoTapper];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sbuf fromConnection:(AVCaptureConnection *)connection
{
	CFRetain( sbuf );

	dispatch_async( dispatch_get_main_queue(),
	^{
		if( zoomStarted || !bufferedFrames.empty() )
		{
			//We're either Ritchieing or catching up
			//Keep every 5th frame only

			if( (skipCounter % 5) == 0 )
				bufferedFrames.push_back( sbuf );
			else
				CFRelease( sbuf );

			skipCounter++;
		}
		else
		{
			//Pass it on for display
			[mainView newVideoFrame:sbuf];
			CFRelease( sbuf );
		}
	} );
}

- (void)catchUpTick:(NSTimer*)timer
{
	if( !bufferedFrames.empty() )
	{
		CMSampleBufferRef sbuf2 = bufferedFrames.front();
		bufferedFrames.pop_front();
		[mainView newVideoFrame:sbuf2];
		CFRelease( sbuf2 );
	}

	if( bufferedFrames.empty() )
	{
		[zoomTimer invalidate];
		zoomTimer = nil;
	}
}



- (void)setTextLeft:(NSString*)str
{
	str = [[str componentsSeparatedByString:@" "] componentsJoinedByString:@"\n"];
	label.numberOfLines = 0;
	CGRect f = self.view.bounds;
	f.size.width /= 2;
	label.frame = CGRectInset( f, 16, 16 );
	label.textAlignment = NSTextAlignmentRight;
	label.text = str;
}

- (void)setTextRight:(NSString*)str
{
	str = [[str componentsSeparatedByString:@" "] componentsJoinedByString:@"\n"];
	label.numberOfLines = 0;
	CGRect f = self.view.bounds;
	f.size.width /= 2;
	f.origin.x += f.size.width;
	label.frame = CGRectInset( f, 16, 16 );
	label.textAlignment = NSTextAlignmentLeft;
	label.text = str;
}

- (void)setTextCLeft:(NSString*)str upper:(BOOL)upper
{
	str = [str stringByAppendingString:@" ★"];
	label.numberOfLines = 1;
	CGRect f = self.view.bounds;
	if( !upper )
		f.origin.y += f.size.height*0.3f;
	f.size.height *= 0.7f;
	label.frame = CGRectInset( f, 16, 16 );
	label.textAlignment = NSTextAlignmentLeft;
	label.text = str;
}

- (void)setTextCRight:(NSString*)str upper:(BOOL)upper
{
	str = [@"★ " stringByAppendingString:str];
	label.numberOfLines = 1;
	CGRect f = self.view.bounds;
	if( !upper )
		f.origin.y += f.size.height*0.3f;
	f.size.height *= 0.7f;
	label.frame = CGRectInset( f, 16, 16 );
	label.textAlignment = NSTextAlignmentRight;
	label.text = str;
}

- (void)setTextBLeft:(NSString*)str
{
	str = [str stringByAppendingString:@" ★"];
	label.numberOfLines = 1;
	CGRect f = self.view.bounds;
	f.origin.y = f.size.height-64;
	f.size.height = 64;
	label.frame = CGRectInset( f, 16, 16 );
	label.textAlignment = NSTextAlignmentLeft;
	label.text = str;
}

- (void)setTextBRight:(NSString*)str
{
	str = [@"★ " stringByAppendingString:str];
	label.numberOfLines = 1;
	CGRect f = self.view.bounds;
	f.origin.y = f.size.height-64;
	f.size.height = 64;
	label.frame = CGRectInset( f, 16, 16 );
	label.textAlignment = NSTextAlignmentRight;
	label.text = str;
}


- (void)beginRitchie:(BOOL)isFemale center:(CGPoint)center
{
	int tappedLeft = center.x < self.view.bounds.size.width*0.5f;
	int tappedUp = center.y < self.view.bounds.size.height*0.5f;

	static const float cols[][3] =
	{
		{ 0.5, 0.7, 0.2 },
		{ 0.7, 0.5, 0.2 },
		{ 1.0, 0.4, 0.2 },
		{ 1.0, 0.24, 0.8 },
		{ 0.47, 0.72, 1.0 },
	};
	int ncols = sizeof(cols) / sizeof(cols[0]);
	int c = randy( ncols );
	const float *col = cols[c];

	[mainView setCol:0 R:0 g:0 b:0];
	[mainView setCol:1 R:col[0] g:col[1] b:col[2]];
	[mainView setCol:2 R:col[0] g:col[1] b:col[2]];

	[mainView setCenter:center];

	NSString *name = [[GangsterNamer randomName:isFemale] uppercaseString];

	switch( randy(3) )
	{
		case 0:
		case 1:
			mainView.effect = EFFECT_HALFTONE;
			break;

		case 2:
			mainView.effect = EFFECT_THRESHHOLD;
			break;
	}

	switch( randy(3) )
	{
		case 0:
			[mainView setInsetLeft:0 right:0 top:0 bottom:0];
			if( tappedLeft )
				[self setTextCRight:name upper:!tappedUp];
			else
				[self setTextCLeft:name upper:!tappedUp];
			break;

		case 1:
			[mainView setInsetLeft:0 right:0 top:75 bottom:75];
			if( tappedLeft )
				[self setTextBRight:name];
			else
				[self setTextBLeft:name];
			break;

		case 2:
			if( randy(2)==0 )
			{
				[mainView setInsetLeft:0 right:240 top:0 bottom:0];
				[self setTextRight:name];
			}
			else
			{
				[mainView setInsetLeft:240 right:0 top:0 bottom:0];
				[self setTextLeft:name];
			}
			break;
	}


	[mainView setZoom:2.2f];

	zoomStarted = [NSDate date];
	skipCounter = 0;

	zoomTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f/30.0f target:self selector:@selector(animTick:) userInfo:nil repeats:YES];
}

- (void)endRitchie
{
	mainView.effect = EFFECT_NONE;
	mainView.tween = 0.0f;
	zoomStarted = nil;
	[zoomTimer invalidate];
	zoomTimer = nil;
	label.hidden = YES;

	//Catch up
	zoomTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f/30.0f target:self selector:@selector(catchUpTick:) userInfo:nil repeats:YES];
}



- (void)tapped:(UITapGestureRecognizer*)gest
{
	if( gest.state==UIGestureRecognizerStateRecognized && !zoomStarted && bufferedFrames.empty() )
	{
		[self beginRitchie:(gest==twoTapper) center:[gest locationInView:self.view]];
	}
}


#define ZOOM_DURATION 0.15f
#define ANIM_DURATION 1.5f

- (void)animTick:(NSTimer*)timer
{
	NSTimeInterval elapsed = -[zoomStarted timeIntervalSinceNow];
	if( elapsed < ZOOM_DURATION )
	{
		mainView.tween = elapsed/ZOOM_DURATION;
	}
	else if( elapsed < ANIM_DURATION-ZOOM_DURATION )
	{
		label.hidden = NO;
		if( mainView.tween < 1.0f )
			mainView.tween = 1.0f;
	}
	else if( elapsed < ANIM_DURATION )
	{
		label.hidden = YES;
		mainView.tween = (ANIM_DURATION-elapsed)/ZOOM_DURATION;
	}
	else
	{
		label.hidden = YES;
		[self endRitchie];
	}
}

@end
