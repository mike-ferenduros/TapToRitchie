//
//  ViewController.m
//  TapToRitchie
//
//  Created by Michael Ferenduros on 21/07/2013.
//  Copyright (c) 2013 Michael Ferenduros. All rights reserved.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>


@implementation ViewController

- (id)init
{
	if( self = [super init] )
	{
		bufferedFrames = [NSMutableArray array];
	}
	return self;
}


- (void)loadView
{
	self.view = mainView = [[VideoView alloc] initWithFrame:CGRectMake(0,0,100,100)];

	capSesh = [[AVCaptureSession alloc] init];
	capSesh.sessionPreset = AVCaptureSessionPreset640x480;

	capCam = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	AVCaptureDeviceInput *camDev = [AVCaptureDeviceInput deviceInputWithDevice:capCam error:nil];
	[capSesh addInput:camDev];

	capDataOut = [[AVCaptureVideoDataOutput alloc] init];
	[capDataOut setVideoSettings:@{(__bridge NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];
	dispatch_queue_t q = dispatch_queue_create( "CaptureVC", DISPATCH_QUEUE_SERIAL );
	[capDataOut setSampleBufferDelegate:self queue:q];
	[capSesh addOutput:capDataOut];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	[capSesh startRunning];

	tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
	[self.view addGestureRecognizer:tapper];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
	CFRetain( sampleBuffer );

	dispatch_async( dispatch_get_main_queue(),
	^{
		//For now just drop frames while we animate
		if( !zoomStarted )
			[mainView newVideoFrame:sampleBuffer];

		CFRelease( sampleBuffer );
	} );
}



- (void)tapped:(UITapGestureRecognizer*)gest
{
	if( tapper.state!=UIGestureRecognizerStateRecognized || zoomStarted )
		return;

	zoomStarted = [NSDate date];
	zoomTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f/30.0f target:self selector:@selector(animTick:) userInfo:nil repeats:YES];

	mainView.effect = EFFECT_THRESHHOLD;
	[mainView setCol:0 R:0.2 g:0.2 b:0.2];
	[mainView setCol:1 R:0.5 g:0.7 b:0.2];
}


#define ZOOM_DURATION 0.3f
#define ANIM_DURATION 2.5f
#define ANIM_ZOOM 1.8f

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
		if( mainView.zoom < ANIM_ZOOM )
			mainView.zoom = ANIM_ZOOM;
	}
	else if( elapsed < ANIM_DURATION )
	{
		float t = (ANIM_DURATION-elapsed)/ZOOM_DURATION;
		mainView.zoom = 1.0f + (ANIM_ZOOM-1.0f)*t;
	}
	else
	{
		mainView.effect = EFFECT_NONE;
		zoomStarted = nil;
		[zoomTimer invalidate];
		zoomTimer = nil;
	}
}

@end
