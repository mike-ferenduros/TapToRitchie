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

- (void)setZoom:(float)z
{
	_zoom = z;
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


- (void)drawRect:(CGRect)rect
{
	glClearColor( 0, 0, 0, 1 );
	glClear( GL_COLOR_BUFFER_BIT );

	check_gl_error();

	if( pendingBuf )
		[self reloadTexture];

	glViewport( 0, 0, self.drawableWidth, self.drawableHeight );

	GLuint shader = passthroughShader;

	glUseProgram( shader );

	float z = _zoom;
	float xy[4][2] = { {-z,-z}, {-z,z}, {z,-z}, {z,z} };
	glVertexAttribPointer( 0, 2, GL_FLOAT, GL_FALSE, 0, xy );
	glEnableVertexAttribArray( 0 );
	glBindAttribLocation( shader, 0, "xy" );

	float  st[4][2] = { {1,0}, {1,1}, {0,0}, {0,1} };
	glVertexAttribPointer( 1, 2, GL_FLOAT, GL_FALSE, 0, st );
	glEnableVertexAttribArray( 1 );
	glBindAttribLocation( shader, 1, "st" );

	glBindTexture( GL_TEXTURE_2D, texture );
	glUniform1i( glGetUniformLocation(shader,"tex"), 0 );

	glDrawArrays( GL_TRIANGLE_STRIP, 0, 4 );

	check_gl_error();
}

@end
