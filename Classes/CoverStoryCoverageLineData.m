//
//  CoverStoryCoverageLineData.m
//  CoverStory
//
//  Created by Kim Hunter on 9/01/13.
//  Copyright (c) 2013 Google Inc. All rights reserved.
//

#import "CoverStoryCoverageLineData.h"


@interface CoverStoryCoverageLineData ()
@property (readwrite, nonatomic, assign) NSInteger hitCount;
@end

@implementation CoverStoryCoverageLineData

+ (id)newCoverageLineDataWithLine:(NSString *)line
                         hitCount:(NSInteger)hitCount
                     coverageFile:(CoverStoryCoverageFileData *)coverageFile
{
    return [[self alloc] initWithLine:line hitCount:hitCount coverageFile:coverageFile];
}

- (id)initWithLine:(NSString *)line
          hitCount:(NSInteger)hitCount
      coverageFile:(CoverStoryCoverageFileData *)coverageFile
{
    if ((self = [super init]))
    {
        _hitCount     = hitCount;
        _line         = [line copy];
        _coverageFile = coverageFile;
    }
    return self;
}


- (void)addHits:(NSInteger)newHits
{
    // we could be processing big and little endian runs, and w/ ifdefs one set of
    // lines would be ignored in one run, but not in the other. so...  if we were
    // a not hit line, we just take the new hits, otherwise we add any real hits
    // to our count.
    if (self.hitCount == kCoverStoryNotExecutedMarker)
    {
        self.hitCount = newHits;
    }
    else if (newHits > 0)
    {
        NSAssert1(self.hitCount >= 0,
                  @"how was it not feasible in only one version? (hitCount_ = %ld)",
                  (long)_hitCount);
        self.hitCount += newHits;
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%ld %@", (long)self.hitCount, self.line];
}

@end




@implementation CoverStoryCoverageLineData (ScriptingMethods)

- (NSScriptObjectSpecifier *)objectSpecifier
{
    return [[self coverageFile] objectSpecifierForLineData:self];
}

// For scripting, we don't want to return any negative hit counts
- (NSInteger)adjustedHitCount
{
    NSInteger hitCount = [self hitCount];
    if (hitCount < 0)
    {
        hitCount = 0;
    }
    return hitCount;
}

- (NSString *)coverageType
{
    NSInteger hitCount = [self hitCount];
    NSString *type     = nil;
    switch (hitCount) {
        case 0:
            type = @"missed";
            break;
        case kCoverStoryNotExecutedMarker:
            type = @"non-executable";
            break;
        case kCoverStoryNonFeasibleMarker:
            type = @"non-feasible";
            break;
        default:
            type = @"executed";
            break;
    }
    return type;
}

@end
