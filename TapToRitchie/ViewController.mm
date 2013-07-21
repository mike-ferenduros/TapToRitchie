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

			//If we're catching up, catch up
			//FIXME: Too speedy (and a bit hacky) maybe we need to do this on a separate timer
			if( !zoomStarted && !bufferedFrames.empty() )
			{
				CMSampleBufferRef sbuf2 = bufferedFrames.front();
				bufferedFrames.pop_front();
				[mainView newVideoFrame:sbuf2];
				CFRelease( sbuf2 );
			}
		}
		else
		{
			//Pass it on for display
			[mainView newVideoFrame:sbuf];
			CFRelease( sbuf );
		}
	} );
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
	dispatch_async( dispatch_get_main_queue(),
	^{
		//If we're catching up, catch up
		if( !zoomStarted && !bufferedFrames.empty() )
		{
			CMSampleBufferRef sbuf2 = bufferedFrames.front();
			bufferedFrames.pop_front();
			[mainView newVideoFrame:sbuf2];
			CFRelease( sbuf2 );
		}
	});
}



- (void)beginRitchie:(BOOL)isFemale
{
	label.text = [[GangsterNamer randomName:isFemale] uppercaseString];

	mainView.effect = EFFECT_HALFTONE;
	[mainView setCol:0 R:0.2 g:0.2 b:0.2];
	[mainView setCol:1 R:0.5 g:0.7 b:0.2];

	zoomStarted = [NSDate date];
	skipCounter = 0;

	zoomTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f/30.0f target:self selector:@selector(animTick:) userInfo:nil repeats:YES];
}

- (void)endRitchie
{
	mainView.effect = EFFECT_NONE;
	zoomStarted = nil;
	[zoomTimer invalidate];
	zoomTimer = nil;
	label.hidden = YES;
}



- (void)tapped:(UITapGestureRecognizer*)gest
{
	if( gest.state==UIGestureRecognizerStateRecognized && !zoomStarted && bufferedFrames.empty() )
	{
		[self beginRitchie:(gest==twoTapper)];
	}
}


#define ZOOM_DURATION 0.15f
#define ANIM_DURATION 2.0f
#define ANIM_ZOOM 1.5f

- (void)animTick:(NSTimer*)timer
{
	NSTimeInterval elapsed = -[zoomStarted timeIntervalSinceNow];
	if( elapsed < ZOOM_DURATION )
	{
		float t = elapsed/ZOOM_DURATION;
		mainView.zoom = 1.0f + (ANIM_ZOOM-1.0f)*t;
	}
	else if( elapsed < ANIM_DURATION-ZOOM_DURATION )
	{
		label.hidden = NO;
		if( mainView.zoom < ANIM_ZOOM )
			mainView.zoom = ANIM_ZOOM;
	}
	else if( elapsed < ANIM_DURATION )
	{
		label.hidden = YES;
		float t = (ANIM_DURATION-elapsed)/ZOOM_DURATION;
		mainView.zoom = 1.0f + (ANIM_ZOOM-1.0f)*t;
	}
	else
	{
		label.hidden = YES;
		[self endRitchie];
	}
}

@end
