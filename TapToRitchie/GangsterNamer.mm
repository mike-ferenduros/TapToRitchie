//
//  GangsterNamer.m
//  TapToRitchie
//
//  Created by Michael Ferenduros on 22/07/2013.
//  Copyright (c) 2013 Michael Ferenduros. All rights reserved.
//

#import "GangsterNamer.h"

@implementation GangsterNamer

static NSArray *loadStringsFile( NSString *fname )
{
	NSURL *url = [[NSBundle mainBundle] URLForResource:fname withExtension:@"txt"];
	NSString *str = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
	return [str componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

static NSArray *adjectives = nil;
static NSArray *mnames = nil;
static NSArray *fnames = nil;
static NSArray *nouns = nil;

static NSString *word( NSArray *words )
{
	int i = (rand()/100) % words.count;
	return [words objectAtIndex:i];
}

+ (void)loadStrings
{
	adjectives = loadStringsFile( @"adjectives" );
	mnames = loadStringsFile( @"mnames" );
	fnames = loadStringsFile( @"fnames" );
	nouns = loadStringsFile( @"nouns" );
}

+ (NSString*)randomName:(BOOL)female
{
	NSArray *names = female ? fnames : mnames;

	int what = (rand()/100) % 10;
	if( what < 3 )
	{
		return [NSString stringWithFormat:@"%@ the %@", word(names), word(nouns)];
	}
	else
	{
		return [NSString stringWithFormat:@"%@ %@", word(adjectives), word(names)];
	}
}

@end
