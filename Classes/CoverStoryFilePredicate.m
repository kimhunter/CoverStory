//
//  CoverStoryFilePredicate.m
//  CoverStory
//
//  Created by dmaclach on 03/20/08.
//  Copyright 2008 Google Inc.
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
#import "CoverStoryFilePredicate.h"
#import "CoverStoryPreferenceKeys.h"
#import "CoverStoryDocument.h"
#import "GTMRegex.h"
#import <fnmatch.h>

@interface NSString (CoverStoryStringMatching)
- (BOOL)cs_isRegularExpressionEqual:(NSString *)string;
- (BOOL)cs_isWildcardPatternEqual:(NSString *)string;
- (BOOL)cs_isMatchForPatternArray:(NSArray *)patterns;
@end

// the one key in our array of dictionaries.  we uses an array of dicts instead
// of an array of strings, because then we can KVC the UI for editing them.
static NSString * const kFilter = @"filter";

@implementation CoverStoryFilePredicate

+ (void)registerDefaults
{
    NSUserDefaults *defaults        = [NSUserDefaults standardUserDefaults];
    NSDictionary *predicateDefaults = @{
        kCoverStoryHideSystemSourcesKey: @YES, // hide the systems sources by default
        kCoverStorySystemSourcesPatternsKey: @[
            @{kFilter:@"/usr/*"},
            @{kFilter: @"/System/Library/Frameworks/*"},
            @{kFilter:@"*/SDKs/MacOSX10.*"},
            @{kFilter: @"*/SDKs/iPhone*"}
        ],
        kCoverStoryHideUnittestSourcesKey : @NO, // do NOT hide the unittest sources by default
        kCoverStoryUnittestSourcesPatternsKey: @[
            @{kFilter:@"*Test.[hHmM]"},
            @{kFilter:@"*Test.mm"}
        ]
    };
    
    [defaults registerDefaults:predicateDefaults];
}

- (BOOL)evaluateWithObject:(id)object
{
    BOOL isGood              = YES;
    NSString *path           = [object valueForKey:@"sourcePath"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    BOOL hideSDKFiles = [document_ hideSDKSources];
    if (hideSDKFiles)
    {
        NSArray *systemSourcesPatterns =
        [defaults arrayForKey:kCoverStorySystemSourcesPatternsKey];
        if (systemSourcesPatterns)
        {
            isGood = ![path cs_isMatchForPatternArray:systemSourcesPatterns];
        }
    }
    if (isGood)
    {
        BOOL hideUnittestFiles = [document_ hideUnittestSources];
        if (hideUnittestFiles)
        {
            NSArray *unittestSourcesPatterns =
            [defaults arrayForKey:kCoverStoryUnittestSourcesPatternsKey];
            if (unittestSourcesPatterns)
            {
                isGood = ![path cs_isMatchForPatternArray:unittestSourcesPatterns];
            }
        }
    }
    if (isGood)
    {
        NSString *text = [searchField_ stringValue];
        if ([text length] == 0)
        {
            isGood = YES;
        }
        else
        {
            CoverStoryFilterStringType type
            = [defaults integerForKey:kCoverStoryFilterStringTypeKey];
            switch (type) {
                default:
                case kCoverStoryFilterStringTypeWildcardPattern:
                    isGood = [path cs_isWildcardPatternEqual:text];
                    break;
                    
                case kCoverStoryFilterStringTypeRegularExpression:
                    isGood = [path cs_isRegularExpressionEqual:text];
                    break;
            }
        }
    }
    return isGood;
}

@end

@implementation NSString (CoverStoryStringMatching)
- (BOOL)cs_isRegularExpressionEqual:(NSString *)string
{
    // if the pattern didn't parse, always show things
    BOOL result = YES;
    
    // no point in catching errors since we do this as they type
    GTMRegex *regex = [GTMRegex regexWithPattern:string
                                         options:kGTMRegexOptionIgnoreCase];
    if (regex)
    {
        result = [regex matchesSubStringInString:self];
    }
    return result;
}

- (BOOL)cs_isWildcardPatternEqual:(NSString *)string
{
    NSString *pattern = [NSString stringWithFormat:@"*%@*", string];
    int flags         = FNM_CASEFOLD;
    BOOL isGood       = fnmatch([pattern UTF8String], [self UTF8String], flags) == 0;
    return isGood;
}

- (BOOL)cs_isMatchForPatternArray:(NSArray *)patterns
{
    const char *utf8Self = [self UTF8String];
    for (NSDictionary *patternDict in patterns)
    {
        NSString *pattern = patternDict[kFilter];
        if (([pattern length] > 0) &&
            (fnmatch([pattern UTF8String], utf8Self, 0) == 0))
        {
            return YES;
        }
    }
    return NO;
}

@end

