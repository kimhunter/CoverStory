#import <Foundation/Foundation.h>


@protocol CoverStoryLineCoverageProtocol

- (void)coverageTotalLines:(NSInteger *)outTotal
                 codeLines:(NSInteger *)outCode // doesn't include non-feasible
              hitCodeLines:(NSInteger *)outHitCode
          nonFeasibleLines:(NSInteger *)outNonFeasible
            coverageString:(NSString * *)outCoverageString
                  coverage:(float *)outCoverage; // use the string for display,
                                                 // this is just here for calcs
                                                 // and sorts
@end

// methods to get feedback while the data is processed
@protocol CoverStoryCoverageProcessingProtocol
- (void)coverageErrorForPath:(NSString *)path message:(NSString *)format, ...NS_FORMAT_FUNCTION(2, 3);
- (void)coverageWarningForPath:(NSString *)path message:(NSString *)format, ...NS_FORMAT_FUNCTION(2, 3);
@end
