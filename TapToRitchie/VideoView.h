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
	GLuint					threshholdShader;

	float					cols[2][3];
}

enum VideoEffect
{
	EFFECT_NONE = 0,
	EFFECT_THRESHHOLD,
};

@property (nonatomic) float zoom;
@property (nonatomic) enum VideoEffect effect;

- (void)setCol:(int)c R:(float)r g:(float)g b:(float)b;

- (void)newVideoFrame:(CMSampleBufferRef)sbuf;

@end
