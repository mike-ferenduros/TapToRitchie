//
//  VideoView.h
//  TapToRitchie
//
//  Created by Michael Ferenduros on 21/07/2013.
//  Copyright (c) 2013 Michael Ferenduros. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <CoreMedia/CoreMedia.h>

@interface VideoView : GLKView
{
	CMSampleBufferRef		pendingBuf;

	GLuint					texture;
	int						texWidth;
	int						texHeight;
	
	GLuint					passthroughShader;
}

@property (nonatomic) float zoom;

- (void)newVideoFrame:(CMSampleBufferRef)sbuf;

@end
