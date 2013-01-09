//
//  CoverStoryCoverageData.h
//  CoverStory
//
//  Created by dmaclach on 12/24/06.
//  Copyright 2006-2008 Google Inc.
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

#import <Cocoa/Cocoa.h>
#import "GTMDefines.h"
#import "CoverStoryProtocols.h"
#import "CoverStoryCoverageFileData.h"

@class CoverStoryDocument;
extern float codeCoverage(NSInteger codeLines, NSInteger hitCodeLines, NSString * *outCoverageString);

enum {
    // Value for hitCount for lines that aren't executed
    kCoverStoryNotExecutedMarker = -1,
    // Value for hitCount for lines that are non-feasible
    kCoverStoryNonFeasibleMarker = -2
};

#pragma mark -

#pragma mark -

@interface NSEnumerator (CodeCoverage)

- (void)coverageTotalLines:(NSInteger *)outTotal
                 codeLines:(NSInteger *)outCode
              hitCodeLines:(NSInteger *)outHitCode
          nonFeasibleLines:(NSInteger *)outNonFeasible
            coverageString:(NSString * *)outCoverageString
                  coverage:(float *)outCoverage; // use the string for display,
                                                 // this is just here for calcs
                                                 // and sorts
@end


#pragma mark -

// Keeps track of the data for a whole source file.

#pragma mark -


#pragma mark -
