//
//  VideoView.m
//  TapToRitchie
//
//  Created by Michael Ferenduros on 21/07/2013.
//  Copyright (c) 2013 Michael Ferenduros. All rights reserved.
//

#import "VideoView.h"

static void check_gl_error( void )
{
	switch( glGetError() )
	{
		case GL_NO_ERROR:				return;
		case GL_INVALID_ENUM:			NSLog(@"GL_INVALID_ENUM");			break;
		case GL_INVALID_VALUE:			NSLog(@"GL_INVALID_VALUE");			break;
		case GL_INVALID_OPERATION:		NSLog(@"GL_INVALID_OPERATION");		break;
		case GL_OUT_OF_MEMORY:			NSLog(@"GL_OUT_OF_MEMORY");			break;
	}
}

static GLuint makeDotTexture( void )
{
	unsigned char *pixels = new unsigned char [64*64];
	for( int y = 0; y < 64; y++ )
	{
		float fy = float(y)/16.0f;
		float sy = sin(fy*3.14159265f*2.0f);
		for( int x = 0; x < 64; x++ )
		{
			float fx = float(x)/16.0f;
			float sx = sin(fx*3.14159265f*2.0f);

			float v = ((sx*sy)+1.0f) * 127.5f;

			pixels[ x + y*64 ] = (v<0)?0 : (v>255 ? 255 : v);
		}
	}
	
	GLuint tex;
	glGenTextures( 1, &tex );
	glBindTexture( GL_TEXTURE_2D, tex );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
	glTexImage2D( GL_TEXTURE_2D, 0, GL_LUMINANCE, 64, 64, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, pixels );
	
	delete [] pixels;
	
	return tex;
}

@implementation VideoView (glsl)
- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType prefix:(NSString*)prefix
{
	NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
	NSError *error;
	NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
	if (!shaderString)
	{
		NSLog(@"Error loading shader: %@", error.localizedDescription);
		exit(1);
	}

	GLuint shaderHandle = glCreateShader(shaderType);

	const char * strings[2] = { prefix ? prefix.UTF8String : "", shaderString.UTF8String };
	glShaderSource( shaderHandle, 2, strings, 0 );

	glCompileShader(shaderHandle);

	GLint compileSuccess;
	glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
	if (compileSuccess == GL_FALSE)
	{
		GLchar messages[256];
		glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
		NSString *messageString = [NSString stringWithUTF8String:messages];
		NSLog(@"%@", messageString);
		exit(1);
	}

	return shaderHandle;
}


- (GLuint)compileProgramWithFragShader:(NSString*)fragName vertShader:(NSString*)vertName prefix:(NSString*)prefix
{
	GLuint vertexShader = [self compileShader:vertName withType:GL_VERTEX_SHADER prefix:prefix];
	GLuint fragmentShader = [self compileShader:fragName withType:GL_FRAGMENT_SHADER prefix:prefix];

	GLuint programHandle = glCreateProgram();
	glAttachShader(programHandle, vertexShader);
	glAttachShader(programHandle, fragmentShader);

	glLinkProgram(programHandle);

	GLint linkSuccess;
	glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
	if (linkSuccess == GL_FALSE)
	{
		GLchar messages[256];
		glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
		NSString *messageString = [NSString stringWithUTF8String:messages];
		NSLog(@"%@", messageString);
		exit(1);
	}

	return programHandle;
}

- (GLuint)compileProgramWithFragShader:(NSString*)fragName vertShader:(NSString*)vertName
{
	return [self compileProgramWithFragShader:fragName vertShader:vertName prefix:nil];
}
@end



@implementation VideoView

- (id)initWithFrame:(CGRect)frame
{
	EAGLContext *ctx = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if( self = [super initWithFrame:frame context:ctx] )
	{
		[EAGLContext setCurrentContext:self.context];
		passthroughShader = [self compileProgramWithFragShader:@"fragment_passthru" vertShader:@"vertex"];
		threshholdShader = [self compileProgramWithFragShader:@"fragment_threshhold" vertShader:@"vertex"];
		halftoneShader = [self compileProgramWithFragShader:@"fragment_halftone" vertShader:@"vertex"];
		dotTexture = makeDotTexture();
		[EAGLContext setCurrentContext:nil];

		_zoom = 1.0f;
    }
    return self;
}


- (void)newVideoFrame:(CMSampleBufferRef)sbuf
{
	if( pendingBuf )
	{
		CFRelease( pendingBuf );
		pendingBuf = 0;
	}

	if( sbuf )
	{
		CFRetain( sbuf );
		pendingBuf = sbuf;
		[self setNeedsDisplay];
	}
}

- (void)setTween:(float)t
{
	if( _tween != t )
	{
		_tween = t;
		[self setNeedsDisplay];
	}
}

- (void)setZoom:(float)z
{
	if( _zoom != z )
	{
		_zoom = z;
		[self setNeedsDisplay];
	}
}

- (void)setInsetLeft:(int)l right:(int)r top:(int)t bottom:(int)b
{
	float scale = [[UIScreen mainScreen] scale];
	inset[0] = l * scale;
	inset[1] = t * scale;
	inset[2] = r * scale;
	inset[3] = b * scale;

	[self setNeedsDisplay];
}

- (void)setEffect:(enum VideoEffect)e
{
	if( _effect != e )
	{
		_effect = e;
		[self setNeedsDisplay];
	}
}

- (void)setCenter:(CGPoint)c
{
	float scale = [[UIScreen mainScreen] scale];
	_center = c;
	_center.x *= scale;
	_center.y *= scale;
	[self setNeedsDisplay];
}

- (void)reloadTexture
{
	check_gl_error();

	CVPixelBufferRef img = CMSampleBufferGetImageBuffer( pendingBuf );
	int w = CVPixelBufferGetWidth( img );
	int h = CVPixelBufferGetHeight( img );

	if( !texture || w!=texWidth || h!=texHeight )
	{
		if( !texture )
			glGenTextures( 1, &texture );

		glBindTexture( GL_TEXTURE_2D, texture );
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );

		texWidth = w;
		texHeight = h;
	}

	CVPixelBufferLockBaseAddress( img, 0 );
	void *pixels = CVPixelBufferGetBaseAddress( img );
	glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, texWidth, texHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, pixels );
	CVPixelBufferUnlockBaseAddress( img, 0 );

	CFRelease( pendingBuf );
	pendingBuf = 0;

	check_gl_error();
}

- (void)setCol:(int)c R:(float)r g:(float)g b:(float)b
{
	cols[c][0] = r;
	cols[c][1] = g;
	cols[c][2] = b;
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	glDisable( GL_SCISSOR_TEST );
	glClearColor( cols[2][0], cols[2][1], cols[2][2], 1 );
	glClear( GL_COLOR_BUFFER_BIT );

	check_gl_error();

	if( pendingBuf )
		[self reloadTexture];

	glViewport( 0, 0, self.drawableWidth, self.drawableHeight );
	
	float insl = inset[0]*_tween;
	float inst = inset[1]*_tween;
	float insr = self.drawableWidth - inset[2]*_tween;
	float insb = self.drawableHeight - inset[3]*_tween;
	glScissor( insl, inst, insr-insl, insb-inst );
	glEnable( GL_SCISSOR_TEST );

	GLuint shader;
	switch( _effect )
	{
		case EFFECT_NONE:
			shader = passthroughShader;
			break;

		case EFFECT_THRESHHOLD:
			shader = threshholdShader;
			break;

		case EFFECT_HALFTONE:
			shader = halftoneShader;
			break;
	}

	glUseProgram( shader );
	glUniform3f( glGetUniformLocation(shader,"col1"), cols[0][0], cols[0][1], cols[0][2] );
	glUniform3f( glGetUniformLocation(shader,"col2"), cols[1][0], cols[1][1], cols[1][2] );

	//Center tapped point but don't go offscreen
	float cx = (1.0f - (_center.x*2.0f/float(self.drawableWidth)));
	float cy = ((_center.y*2.0f/float(self.drawableHeight)) - 1.0f);
	if( fabsf(cx) > _zoom-1 )	cx = cx>0 ? _zoom-1 : 1-_zoom;
	if( fabsf(cy) > _zoom-1 )	cy = cy>0 ? _zoom-1 : 1-_zoom;
	cx *= _tween;
	cy *= _tween;

	float wx = ((insl+insr) / float(self.drawableWidth)) - 1.0f;
	float wy = ((inst+insb) / float(self.drawableHeight)) - 1.0f;
	cx += wx;
	cy += wy;

	float z = 1.0f + (_zoom-1.0f)*_tween;
	float xy[4][2] = { {cx-z,cy-z}, {cx-z,cy+z}, {cx+z,cy-z}, {cx+z,cy+z} };
	glVertexAttribPointer( 0, 2, GL_FLOAT, GL_FALSE, 0, xy );
	glEnableVertexAttribArray( 0 );
	glBindAttribLocation( shader, 0, "xy" );

	float  st[4][2] = { {1,0}, {1,1}, {0,0}, {0,1} };
	glVertexAttribPointer( 1, 2, GL_FLOAT, GL_FALSE, 0, st );
	glEnableVertexAttribArray( 1 );
	glBindAttribLocation( shader, 1, "st" );

	glActiveTexture( GL_TEXTURE1 );
	glBindTexture( GL_TEXTURE_2D, dotTexture );
	glActiveTexture( GL_TEXTURE0 );
	glBindTexture( GL_TEXTURE_2D, texture );

	glUniform1i( glGetUniformLocation(shader,"tex"), 0 );
	glUniform1i( glGetUniformLocation(shader,"dottex"), 1 );

	glDrawArrays( GL_TRIANGLE_STRIP, 0, 4 );

	check_gl_error();
}

@end
