//
//  GangsterNamer.m
//  TapToRitchie
//
//  Created by Michael Ferenduros on 22/07/2013.
//  Copyright (c) 2013 Michael Ferenduros. All rights reserved.
//

#import "GangsterNamer.h"

extern int randy( int r );

@implementation GangsterNamer

static NSArray *loadStringsFile( NSString *fname )
{
	NSURL *url = [[NSBundle mainBundle] URLForResource:fname withExtension:@"txt"];
	NSString *str = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
	return [str componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

static NSArray *adjectives = nil;
static NSArray *names = nil;
static NSArray *nouns = nil;

static NSString *word( NSArray *words )
{
	int i = randy( words.count );
	return [words objectAtIndex:i];
}

+ (void)loadStrings
{
	adjectives = loadStringsFile( @"adjectives" );
	names = loadStringsFile( @"mnames" );
	nouns = loadStringsFile( @"nouns" );
}

+ (NSString*)randomName
{
	if( randy(2)==0 )
	{
		return [NSString stringWithFormat:@"%@ the %@", word(names), word(nouns)];
	}
	else
	{
		return [NSString stringWithFormat:@"%@ %@", word(adjectives), word(names)];
	}
}

@end
