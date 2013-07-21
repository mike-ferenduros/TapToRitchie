//
//  ViewController.h
//  TapToRitchie
//
//  Created by Michael Ferenduros on 21/07/2013.
//  Copyright (c) 2013 Michael Ferenduros. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>
#import "VideoView.h"

@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>
{
	AVCaptureSession *			capSesh;
	AVCaptureDevice *			capCam;
	AVCaptureVideoDataOutput *	capDataOut;

	VideoView *					mainView;

	NSDate *					zoomStarted;
	NSTimer *					zoomTimer;
	NSMutableArray *			bufferedFrames;
	
	UITapGestureRecognizer *	tapper;
}

- (id)init;

@end
