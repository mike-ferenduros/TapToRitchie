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

	GLuint					dotTexture;

	GLuint					passthroughShader;
	GLuint					threshholdShader;
	GLuint					halftoneShader;

	float					inset[4];
	float					cols[3][3];
}

enum VideoEffect
{
	EFFECT_NONE = 0,
	EFFECT_THRESHHOLD,
	EFFECT_HALFTONE,
};

@property (nonatomic) float tween;
@property (nonatomic) float zoom;
@property (nonatomic) enum VideoEffect effect;

- (void)setCol:(int)c R:(float)r g:(float)g b:(float)b;
- (void)setInsetLeft:(int)l right:(int)r top:(int)t bottom:(int)b;

- (void)newVideoFrame:(CMSampleBufferRef)sbuf;

@end
