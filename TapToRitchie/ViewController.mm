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
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
	CFRetain( sampleBuffer );

	dispatch_async( dispatch_get_main_queue(),
	^{
		[mainView newVideoFrame:sampleBuffer];
		CFRelease( sampleBuffer );
	} );
}

@end
