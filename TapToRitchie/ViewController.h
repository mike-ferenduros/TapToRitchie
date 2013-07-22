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
#import <deque>
#import "VideoView.h"

@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>
{
	AVCaptureSession *				capSesh;
	AVCaptureDevice *				capCam;
	AVCaptureVideoDataOutput *		capDataOut;

	VideoView *						mainView;

	NSDate *						zoomStarted;
	NSTimer *						zoomTimer;

	std::deque<CMSampleBufferRef>	bufferedFrames;
	int								skipCounter;

	UITapGestureRecognizer *		tapper;
	
	UILabel *						label;
}

- (id)init;

@end
