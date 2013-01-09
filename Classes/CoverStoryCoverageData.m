//
//  CoverStoryCoverageData.m
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

#import "CoverStoryCoverageData.h"
#import "CoverStoryDocument.h"
#import "GTMRegex.h"

// helper for building the string to make sure rounding doesn't get us
float codeCoverage (NSInteger codeLines, NSInteger hitCodeLines, NSString * *outCoverageString)
{
    float coverage = 0.0f;
    if (codeLines > 0)
    {
        coverage = (float)hitCodeLines / (float)codeLines * 100.0f;
    }
    if (outCoverageString)
    {
        *outCoverageString = [NSString stringWithFormat:@"%.1f", coverage];
        // make sure we never round to 100% if it's not 100%
        if ([*outCoverageString isEqual:@"100.0"])
        {
            if (hitCodeLines == codeLines)
            {
                *outCoverageString = @"100";
            }
            else
            {
                *outCoverageString = @"99.9";
            }
        }
    }
    return coverage;
}

@implementation NSEnumerator (CodeCoverage)

- (void)coverageTotalLines:(NSInteger *)outTotal
                 codeLines:(NSInteger *)outCode
              hitCodeLines:(NSInteger *)outHitCode
          nonFeasibleLines:(NSInteger *)outNonFeasible
            coverageString:(NSString * *)outCoverageString
                  coverage:(float *)outCoverage
{
    // collect the data
    NSInteger sumTotal       = 0;
    NSInteger sumCode        = 0;
    NSInteger sumHitCode     = 0;
    NSInteger sumNonFeasible = 0;
    id<CoverStoryLineCoverageProtocol> data;
    while ((data = [self nextObject]))
    {
        NSInteger localTotal       = 0;
        NSInteger localCode        = 0;
        NSInteger localHitCode     = 0;
        NSInteger localNonFeasible = 0;
        [data coverageTotalLines:&localTotal
                       codeLines:&localCode
                    hitCodeLines:&localHitCode
                nonFeasibleLines:&localNonFeasible
                  coverageString:NULL
                        coverage:NULL];
        sumTotal       += localTotal;
        sumCode        += localCode;
        sumHitCode     += localHitCode;
        sumNonFeasible += localNonFeasible;
    }
    
    if (outTotal)
    {
        *outTotal = sumTotal;
    }
    if (outCode)
    {
        *outCode = sumCode;
    }
    if (outHitCode)
    {
        *outHitCode = sumHitCode;
    }
    if (outNonFeasible)
    {
        *outNonFeasible = sumNonFeasible;
    }
    if (outCoverageString || outCoverage)
    {
        float coverage = codeCoverage(sumCode, sumHitCode, outCoverageString);
        if (outCoverage)
        {
            *outCoverage = coverage;
        }
    }
}
@end

