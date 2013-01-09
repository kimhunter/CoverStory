//
//  CoverStoryCoverageSet.m
//  CoverStory
//
//  Created by Kim Hunter on 9/01/13.
//  Copyright (c) 2013 Google Inc. All rights reserved.
//

#import "CoverStoryCoverageSet.h"
#import "CoverStoryCoverageFileData.h"
#import "CodeCoverage.h"

@interface CoverStoryCoverageSet () {
    NSMutableArray *_fileDatas;
}
@property (readonly) NSMutableArray *fileDatas;
@end



@implementation CoverStoryCoverageSet

- (id)init
{
    if ((self = [super init]))
    {
        _fileDatas = [[NSMutableArray alloc] init];
    }
    return self;
}


- (BOOL)addFileData:(CoverStoryCoverageFileData *)fileData
    messageReceiver:(id<CoverStoryCoverageProcessingProtocol>)receiver
{
    BOOL wasGood   = NO;
    NSUInteger idx = [_fileDatas indexOfObject:fileData];
    if (idx != NSNotFound)
    {
        CoverStoryCoverageFileData *currentData = [_fileDatas objectAtIndex:idx];
        // we need to merge them
        // (this is needed for headers w/ inlines where if you process >1 gcno/gcda
        // then you could get that header reported >1 time)
        wasGood = [currentData addFileData:fileData messageReceiver:receiver];
    }
    else
    {
        // it's new, save it
        NSUInteger index = [_fileDatas count];
        [self willChange:NSKeyValueChangeInsertion
         valuesAtIndexes:[NSIndexSet indexSetWithIndex:index]
                  forKey:@"fileDatas"];
        [_fileDatas insertObject:fileData atIndex:index];
        [self didChange:NSKeyValueChangeInsertion
        valuesAtIndexes:[NSIndexSet indexSetWithIndex:index]
                 forKey:@"fileDatas"];
        
        // send the queued up warnings since this is the first time we've seen the
        // file.
        // TODO: this is really a hack, we would be better (since these currently
        // are line specific) is to extend the structure to allow warnings to be
        // hung on the line data along w/ the hit counts.  Then w/in the UI indicate
        // how many warnings are on a file in the files list, and in the source
        // display show the warnings inline (sorta like Xcode 3).  The other option
        // would be to keep this basic structure, but be able to relay info w/ the
        // warning so our warning/error ui could take clicks and open to the right
        // file/line so the user can take action on the message.
        for (NSString *warning in [fileData queuedWarnings])
        {
            [receiver coverageWarningForPath:[fileData sourcePath]
                                     message:@"%@", warning];
        }
        wasGood = YES;
    }
    return wasGood;
}

- (void)coverageTotalLines:(NSInteger *)outTotal
                 codeLines:(NSInteger *)outCode
              hitCodeLines:(NSInteger *)outHitCode
          nonFeasibleLines:(NSInteger *)outNonFeasible
            coverageString:(NSString * *)outCoverageString
                  coverage:(float *)outCoverage
{
    // use the enum helper
    NSEnumerator *enumerator = [_fileDatas objectEnumerator];
    [enumerator coverageTotalLines:outTotal
                         codeLines:outCode
                      hitCodeLines:outHitCode
                  nonFeasibleLines:outNonFeasible
                    coverageString:outCoverageString
                          coverage:outCoverage];
}

- (void)removeAllData
{
    NSRange fullRange   = NSMakeRange(0, [_fileDatas count]);
    NSIndexSet *fullSet = [NSIndexSet indexSetWithIndexesInRange:fullRange];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:fullSet forKey:@"fileDatas"];
    [_fileDatas removeAllObjects];
    [self didChange:NSKeyValueChangeRemoval
    valuesAtIndexes:fullSet forKey:@"fileDatas"];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ <%p>: %lu items in set",
            [self class], self, (unsigned long)[_fileDatas count]];
}

@end


