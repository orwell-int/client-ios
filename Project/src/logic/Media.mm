/* Copyright (c) 2014, Massimo Gengarelli, orwell-int members
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *  - Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * - Neither the name of the orwell-int organization nor the
 * names of its contributors may be used to endorse or promote products
 * derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL MASSIMO GENGARELLI BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "Media.h"


@implementation Media

static SPTextureAtlas *atlas = NULL;
static NSMutableDictionary *sounds = NULL;

#pragma mark Texture Atlas

+ (void)initAtlas
{
    if (!atlas)
        atlas = [[SPTextureAtlas alloc] initWithContentsOfFile:@"atlas.xml"];
}

+ (void)releaseAtlas
{
    atlas = nil;
}

+ (SPTexture *)atlasTexture:(NSString *)name
{
    if (!atlas) [self initAtlas];
    return [atlas textureByName:name];
}

+ (NSArray *)atlasTexturesWithPrefix:(NSString *)prefix
{
    if (!atlas) [self initAtlas];
    return [atlas texturesStartingWith:prefix];
}

#pragma mark Audio

+ (void)initSound
{
    if (sounds) return;
    
    [SPAudioEngine start];
    sounds = [[NSMutableDictionary alloc] init];
    
    // enumerate all sounds
    
    NSString *soundDir = [[NSBundle mainBundle] resourcePath];    
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:soundDir];   
    
    NSString *filename;
    while (filename = [dirEnum nextObject]) 
    {
        if ([[filename pathExtension] isEqualToString: @"caf"])
        {
            SPSound *sound = [[SPSound alloc] initWithContentsOfFile:filename];            
            sounds[filename] = sound;
        }
    }
}

+ (void)releaseSound
{
    sounds = nil;
    
    [SPAudioEngine stop];    
}

+ (void)playSound:(NSString *)soundName
{
    SPSound *sound = sounds[soundName];
    
    if (sound)
        [sound play];
    else        
        [[SPSound soundWithContentsOfFile:soundName] play];    
}

+ (SPSoundChannel *)soundChannel:(NSString *)soundName
{
    SPSound *sound = sounds[soundName];
    
    // sound was not preloaded
    if (!sound)        
        sound = [SPSound soundWithContentsOfFile:soundName];
    
    return [sound createChannel];
}

@end
