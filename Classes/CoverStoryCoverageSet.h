// Keeps track of a set of source files.

#import <Foundation/Foundation.h>
#import "CoverStoryProtocols.h"
#import "CoverStoryCoverageFileData.h"


@interface CoverStoryCoverageSet : NSObject<CoverStoryLineCoverageProtocol>
- (void)removeAllData;
- (BOOL)addFileData:(CoverStoryCoverageFileData *)fileData messageReceiver :(id<CoverStoryCoverageProcessingProtocol>)receiver;
@end
