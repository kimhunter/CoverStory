//
//  CoverStoryCoverageFileData.h
//  CoverStory
//
//  Created by Kim Hunter on 9/01/13.
//  Copyright (c) 2013 Google Inc. All rights reserved.
//
// Keeps track of the data for a whole source file.

#import <Foundation/Foundation.h>
#import "CodeCoverage.h"

@class CoverStoryCoverageLineData;
@class CoverStoryDocument;

@interface CoverStoryCoverageFileData : NSObject<CoverStoryLineCoverageProtocol> {
@private
    NSMutableArray *_lines;
    NSString *_sourcePath;
    NSMutableArray *_warnings;
}

@property (nonatomic, weak) CoverStoryDocument *document;
@property (readonly, nonatomic, copy) NSString *sourcePath;
@property (readonly, nonatomic, strong) NSArray *lines; // of CoverStoryCoverageLineData

// this is only vended for the table to sort with
@property (readonly) NSNumber *coverage;

+ (id)newCoverageFileDataFromPath:(NSString *)path document:(CoverStoryDocument *)document messageReceiver:(id<CoverStoryCoverageProcessingProtocol>)receiver;
- (id)initWithPath:(NSString *)path document:(CoverStoryDocument *)document messageReceiver:(id<CoverStoryCoverageProcessingProtocol> )receiver;

- (BOOL)addFileData:(CoverStoryCoverageFileData *)fileData messageReceiver:(id<CoverStoryCoverageProcessingProtocol>)receiver;
- (NSArray *)queuedWarnings;

@end


@interface CoverStoryCoverageFileData (ScriptingMethods)
- (NSScriptObjectSpecifier *)objectSpecifierForLineData:(CoverStoryCoverageLineData *)data;
@end
