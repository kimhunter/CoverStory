//
//  CoverStoryCoverageLineData.h
//  CoverStory
//
//  Created by Kim Hunter on 9/01/13.
//  Copyright (c) 2013 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoverStoryCoverageFileData.h"

// Keeps track of the number of times a line of code has been hit. There is
// one CoverStoryCoverageLineData object per line of code in the file.

@interface CoverStoryCoverageLineData : NSObject {
}

@property (readonly, nonatomic, assign) NSInteger hitCount; // how many times this line has been hit
@property (readonly, nonatomic, copy) NSString *line; //  the line
@property (weak) CoverStoryCoverageFileData *coverageFile;

+ (id)newCoverageLineDataWithLine:(NSString *)line hitCount:(NSInteger)hitCount coverageFile:(CoverStoryCoverageFileData *)coverageFile;
- (id)initWithLine:(NSString *)line hitCount:(NSInteger)hitCount coverageFile:(CoverStoryCoverageFileData *)coverageFile;
- (void)addHits:(NSInteger)newHits;

@end

@interface CoverStoryCoverageLineData (ScriptingMethods)
@end

