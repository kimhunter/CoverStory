//
//  CoverStoryArrayController.m
//  CoverStory
//
//  Created by dmaclach on 06/03/10.
//  Copyright 2006-2010 Google Inc.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not
//  use this file except in compliance with the License.  You may obtain a copy
//  of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
//  License for the specific language governing permissions and limitations under
//  the License.
//

#import "CoverStoryArrayController.h"
#import "CoverStoryDocument.h"
#import "CoverStoryPreferenceKeys.h"
#import "NSUserDefaultsController+KeyValues.h"

#define kCoverStoryHideSDKSources @"hideSDKSources"
#define kCoverStoryHideUnittestSources @"hideUnittestSources"
#define kCoverStoryRemoveCommonSourcePrefix @"removeCommonSourcePrefix"
#define kCoverStoryFilterString @"filterString"

@interface CoverStoryArrayController ()
@property (nonatomic, retain) NSArray *prefsToWatch;
@property (nonatomic, retain) NSArray *docKeyPathsToWatch;
@end

@implementation CoverStoryArrayController

- (void)dealloc
{
    [_docKeyPathsToWatch enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [_owningDocument removeObserver:self forKeyPath:obj];
    }];

    NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
    [self.prefsToWatch enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [defaults removeObserver:self forKeyPath:[NSUserDefaultsController cs_valuesKey:obj]];
    }];
}


- (void)awakeFromNib
{
    self.prefsToWatch = @[kCoverStorySystemSourcesPatternsKey, kCoverStoryUnittestSourcesPatternsKey];
    self.docKeyPathsToWatch = @[kCoverStoryHideSDKSources,
                                kCoverStoryHideUnittestSources,
                                kCoverStoryRemoveCommonSourcePrefix,
                                kCoverStoryFilterString];
    [_docKeyPathsToWatch enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [_owningDocument addObserver:self forKeyPath:obj options:0 context:nil];
    }];
    
    NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
    [self.prefsToWatch enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [defaults addObserver:self forKeyPath:[NSUserDefaultsController cs_valuesKey:obj] options:0 context:nil];

    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    BOOL handled = NO;
    if ([object isEqualTo:[NSUserDefaultsController sharedUserDefaultsController]])
    {
        if ([keyPath isEqualToString:[NSUserDefaultsController cs_valuesKey:kCoverStorySystemSourcesPatternsKey]])
        {
            if ([_owningDocument hideSDKSources])
            {
                // if we're hiding them then update because the pattern changed
                [self rearrangeObjects];
                handled = YES;
            }
        }
        else if ([keyPath isEqualToString:[NSUserDefaultsController cs_valuesKey:kCoverStoryUnittestSourcesPatternsKey]])
        {
            if ([_owningDocument hideUnittestSources])
            {
                // if we're hiding them then update because the pattern changed
                [self rearrangeObjects];
                handled = YES;
            }
        }
    }
    else if ([object isEqualTo:_owningDocument])
    {
        NSInteger keyIndex = [self.docKeyPathsToWatch indexOfObject:keyPath];
        if (keyIndex != NSNotFound)
        {
            [self rearrangeObjects];
            handled = YES;
        }
    }
    
    if (!handled)
    {
        LOG(@"Unexpected observance of %@ of %@ (%@)", keyPath, object, change);
    }
}

- (void)updateCommonPathPrefix
{
    if (!_owningDocument)
        return;
    
    NSString *newPrefix = nil;
    
    // now figure out a new prefix
    NSArray *arranged = [self arrangedObjects];
    if ([arranged count] == 0)
    {
        // empty string
        newPrefix = @"";
    }
    else
    {
        // process the list to find the common prefix
        
        // start w/ the first path, and now loop throught them all, but give up
        // the moment he only common prefix is "/"
        NSArray *sourcePaths     = [arranged valueForKey:@"sourcePath"];
        NSEnumerator *enumerator = [sourcePaths objectEnumerator];
        newPrefix = [enumerator nextObject];
        NSString *basePath;
        while (([newPrefix length] > 1) && (basePath = [enumerator nextObject]))
        {
            newPrefix = [newPrefix commonPrefixWithString:basePath options:NSLiteralSearch];
        }
        // if you have two files of:
        //   /Foo/bar/spam.m
        //   /Foo/baz/wee.m
        // we end up here w/ "/Foo/ba" as the common prefix, but we don't want
        // to do that, so we make sure we end in a slash
        if (![newPrefix hasSuffix:@"/"])
        {
            NSRange lastSlash = [newPrefix rangeOfString:@"/" options:NSBackwardsSearch];
            if (lastSlash.location == NSNotFound)
            {
                newPrefix = @"";
            }
            else
            {
                newPrefix = [newPrefix substringToIndex:NSMaxRange(lastSlash)];
            }
        }
        // if we just have the leading "/", use no prefix
        if ([newPrefix length] <= 1)
        {
            newPrefix = @"";
        }
    }
    // send it back to the document
    [_owningDocument setCommonPathPrefix:newPrefix];
}

- (void)rearrangeObjects
{
    // this fires when the filtering changes
    [super rearrangeObjects];
    [self updateCommonPathPrefix];
}

- (void)setContent:(id)content
{
    // this fires as results are added during a load
    [super setContent:content];
    [self updateCommonPathPrefix];
}

@end
