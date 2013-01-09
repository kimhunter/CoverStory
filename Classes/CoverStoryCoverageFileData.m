//
//  CoverStoryCoverageFileData.m
//  CoverStory
//
//  Created by Kim Hunter on 9/01/13.
//  Copyright (c) 2013 Google Inc. All rights reserved.
//

#import "CoverStoryCoverageFileData.h"
#import "CoverStoryCoverageLineData.h"
#import "CoverStoryDocument.h"
#import "GTMRegex.h"

@interface CoverStoryCoverageFileData ()

@property (readwrite, nonatomic, assign) NSInteger hitLines;
@property (readwrite, nonatomic, assign) NSInteger codeLines;
@property (readwrite, nonatomic, assign) NSInteger nonfeasible;

@end

@implementation CoverStoryCoverageFileData

+ (id)newCoverageFileDataFromPath:(NSString *)path
                         document:(CoverStoryDocument *)document
                  messageReceiver:(id<CoverStoryCoverageProcessingProtocol>)receiver
{
    return [[self alloc] initWithPath:path
                             document:document
                      messageReceiver:receiver];
}

- (id)initWithPath:(NSString *)path
          document:(CoverStoryDocument *)document
   messageReceiver:(id<CoverStoryCoverageProcessingProtocol>)receiver
{
    if ((self = [super init]))
    {
        _document = document;
        _lines    = [[NSMutableArray alloc] init];
        // The dirty secret: we queue up warnings and don't report them in realtime.
        // Why?  if we report them now, then if the directory with multiple arches
        // we'll send the warning for each arch, and if the file occures in more
        // then one set of gcda/gcno (say for headers w/ inlines), the we'll report
        // each time we read that header.  So instead we queue them, and don't
        // send them over to the receiver until it's added to a set, and only if
        // it's new, this way we're sure we only send them once.
        _warnings = [[NSMutableArray alloc] init];
        
        // Scan in our data and create up out CoverStoryCoverageLineData objects.
        // TODO(dmaclach): make this routine a little more "error tolerant"
        
        // Let NSString try to handle the encoding when opening
        NSStringEncoding encoding;
        NSError *error;
        NSString *string = [NSString stringWithContentsOfFile:path
                                                 usedEncoding:&encoding
                                                        error:&error];
        if (!string)
        {
            // Sadly, NSString doesn't detect/handle NSMacOSRomanStringEncoding very
            // well, so we have to manually try Roman.  math.h in the system headers
            // is in MacRoman easily causes us errors w/o this extra code.
            // (we don't care about the error here, we'll just report the parent
            // error)
            string = [NSString stringWithContentsOfFile:path
                                               encoding:NSMacOSRomanStringEncoding
                                                  error:NULL];
        }
        if (!string)
        {
            [receiver coverageErrorForPath:path message:@"failed to open file %@", error];
            self = nil;
        }
        else
        {
            NSCharacterSet *linefeeds   = [NSCharacterSet newlineCharacterSet];
            GTMRegex *nfLineRegex       = [GTMRegex regexWithPattern:@"//[[:blank:]]*COV_NF_LINE"];
            GTMRegex *nfRangeStartRegex = [GTMRegex regexWithPattern:@"//[[:blank:]]*COV_NF_START"];
            GTMRegex *nfRangeEndRegex   = [GTMRegex regexWithPattern:@"//[[:blank:]]*COV_NF_END"];
            BOOL inNonFeasibleRange     = NO;
            NSScanner *scanner          = [NSScanner scannerWithString:string];
            [scanner setCharactersToBeSkipped:nil];
            while (![scanner isAtEnd])
            {
                NSString *segment;
                // scan in hit count
                BOOL goodScan = [scanner scanUpToString:@":" intoString:&segment];
                [scanner setScanLocation:[scanner scanLocation] + 1];
                NSInteger hitCount = 0;
                if (goodScan)
                {
                    hitCount = [segment intValue];
                    if (hitCount == 0)
                    {
                        if ([segment characterAtIndex:[segment length] - 1] != '#')
                        {
                            hitCount = kCoverStoryNotExecutedMarker;
                        }
                    }
                }
                // scan in line number
                goodScan = [scanner scanUpToString:@":" intoString:&segment];
                if (goodScan)
                {
                    [scanner setScanLocation:[scanner scanLocation] + 1];
                    // scan in the code line
                    goodScan = [scanner scanUpToCharactersFromSet:linefeeds
                                                       intoString:&segment];
                }
                if (!goodScan)
                {
                    segment = @"";
                }
                // skip over the end of line marker (CR, LF, CRLF), and it's possible
                // on the end of the file that there is none of them.
                [scanner scanCharactersFromSet:linefeeds intoString:NULL];
                // handle the non feasible markers
                if (inNonFeasibleRange)
                {
                    if (hitCount > 0)
                    {
                        NSString *warning =
                        [NSString stringWithFormat:@"Line %lu is in a Non Feasible block,"
                         " but was executed.",
                         (unsigned long)[_lines count] - 4];
                        [_warnings addObject:warning];
                    }
                    // if the line was gonna count, mark it as non feasible (we only mark
                    // the lines that would have counted so the total number of non
                    // feasible lines isn't too high (otherwise comment lines, blank
                    // lines, etc. count as non feasible).
                    if (hitCount != kCoverStoryNotExecutedMarker)
                    {
                        hitCount = kCoverStoryNonFeasibleMarker;
                    }
                    // if it has the end marker, clear our state
                    if ([nfRangeEndRegex matchesSubStringInString:segment])
                    {
                        inNonFeasibleRange = NO;
                    }
                }
                else
                {
                    // if it matches the line marker, don't count it
                    if ([nfLineRegex matchesSubStringInString:segment])
                    {
                        if (hitCount > 0)
                        {
                            NSString *warning =
                            [NSString stringWithFormat:@"Line %lu is marked as a Non"
                             " Feasible line, but was executed.",
                             (unsigned long)[_lines count] - 4];
                            [_warnings addObject:warning];
                        }
                        hitCount = kCoverStoryNonFeasibleMarker;
                    }
                    // if it matches the start marker, don't count it and set state
                    else if ([nfRangeStartRegex matchesSubStringInString:segment])
                    {
                        if (hitCount > 0)
                        {
                            NSString *warning =
                            [NSString stringWithFormat:@"Line %lu is in a Non Feasible"
                             " block, but was executed.",
                             (unsigned long)[_lines count] - 4];
                            [_warnings addObject:warning];
                        }
                        // if the line was gonna count, mark it as non feasible (we only mark
                        // the lines that would have counted so the total number of non
                        // feasible lines isn't too high (otherwise comment lines, blank
                        // lines, etc. count as non feasible).
                        if (hitCount != kCoverStoryNotExecutedMarker)
                        {
                            hitCount = kCoverStoryNonFeasibleMarker;
                        }
                        inNonFeasibleRange = YES;
                    }
                }
                [_lines addObject:[CoverStoryCoverageLineData newCoverageLineDataWithLine:segment
                                                                                 hitCount:hitCount
                                                                             coverageFile:self]];
            }
            
            // The first five lines are not data we want to show to the user
            if ([_lines count] > 5)
            {
                // The first line contains the path to our source.  Most projects use
                // paths relative to the project, so just incase they walk into a
                // neighbor directory, resolve them.
                NSString *srcPath = [[[_lines objectAtIndex:0] line] substringFromIndex:7];
                _sourcePath = [srcPath stringByStandardizingPath];
                [_lines removeObjectsInRange:NSMakeRange(0, 5)];
                // get out counts
                [self updateCounts];
            }
            else
            {
                [receiver coverageErrorForPath:path message:@"illegal file format"];
                
                // something bad
                self = nil;
            }
        }
    }
    
    return self;
}


- (BOOL)isEqual:(id)object
{
    BOOL equal = NO;
    if ([object isKindOfClass:[self class]])
    {
        equal = [[object sourcePath] isEqual:[self sourcePath]];
    }
    return equal;
}

- (NSUInteger)hash
{
    return [_sourcePath hash];
}

- (void)updateCounts
{
    NSInteger hitLines    = 0;
    NSInteger codeLines   = 0;
    NSInteger nonfeasible = 0;
    for (CoverStoryCoverageLineData *dataPoint in _lines)
    {
        NSInteger hitCount = [dataPoint hitCount];
        switch (hitCount) {
            case kCoverStoryNonFeasibleMarker:
                ++nonfeasible;
                break;
            case kCoverStoryNotExecutedMarker:
                // doesn't count;
                break;
            case 0:
                // line of code that wasn't hit
                ++codeLines;
                break;
            default:
                // line of code w/ hits
                ++hitLines;
                ++codeLines;
                break;
        }
    }
    [self setCodeLines:codeLines];
    [self setHitLines:hitLines];
    [self setNonfeasible:nonfeasible];
}

- (NSArray *)queuedWarnings
{
    return _warnings;
}

- (NSNumber *)coverage
{
    float result = 0.0f;
    [self coverageTotalLines:NULL
                   codeLines:NULL
                hitCodeLines:NULL
            nonFeasibleLines:NULL
              coverageString:NULL
                    coverage:&result];
    return @(result);
}

- (void)coverageTotalLines:(NSInteger *)outTotal
                 codeLines:(NSInteger *)outCode
              hitCodeLines:(NSInteger *)outHitCode
          nonFeasibleLines:(NSInteger *)outNonFeasible
            coverageString:(NSString * *)outCoverageString
                  coverage:(float *)outCoverage
{
    if (outTotal)
    {
        *outTotal = [_lines count];
    }
    if (outCode)
    {
        *outCode = [self codeLines];
    }
    if (outHitCode)
    {
        *outHitCode = [self hitLines];
    }
    if (outNonFeasible)
    {
        *outNonFeasible = [self nonfeasible];
    }
    if (outCoverageString || outCoverage)
    {
        float coverage = codeCoverage(_codeLines, _hitLines, outCoverageString);
        if (outCoverage)
        {
            *outCoverage = coverage;
        }
    }
}

- (BOOL)addFileData:(CoverStoryCoverageFileData *)fileData
    messageReceiver:(id<CoverStoryCoverageProcessingProtocol>)receiver
{
    // must be for the same paths
    if (![[fileData sourcePath] isEqual:_sourcePath])
    {
        if (receiver)
        {
            [receiver coverageErrorForPath:_sourcePath
                                   message:@"coverage is for different source path:%@",
             [fileData sourcePath]];
        }
        return NO;
    }
    
    // make sure the source file lines actually match
    NSArray *newLines = [fileData lines];
    if ([newLines count] != [_lines count])
    {
        if (receiver)
        {
            [receiver coverageErrorForPath:_sourcePath
                                   message:@"coverage source (%@) has different line count '%lu' vs '%lu'",
             [fileData sourcePath],
             (unsigned long)[newLines count],
             (unsigned long)[_lines count]];
        }
        return NO;
    }
    for (NSUInteger x = 0, max = [newLines count]; x < max; ++x )
    {
        CoverStoryCoverageLineData *lineNew = [newLines objectAtIndex:x];
        CoverStoryCoverageLineData *lineMe  = [_lines objectAtIndex:x];
        
        // string match the lines (since the Non Feasible support is via comments,
        // this makes sure they also match)
        if (![[lineNew line] isEqual:[lineMe line]])
        {
            if (receiver)
            {
                [receiver coverageErrorForPath:_sourcePath
                                       message:@"coverage source (%@) line %lu doesn't match, '%@' vs '%@'",
                 [fileData sourcePath], (unsigned long)x, [lineNew line], [lineMe line]];
            }
            return NO;
        }
        // we don't check if the lines weren't hit between the two because we could
        // be processing big and little endian runs, and w/ ifdefs one set of lines
        // would be ignored in one run, but not in the other.
    }
    
    // spin though once more summing the counts
    for (NSUInteger x = 0, max = [newLines count]; x < max; ++x )
    {
        CoverStoryCoverageLineData *lineNew = [newLines objectAtIndex:x];
        CoverStoryCoverageLineData *lineMe  = [_lines objectAtIndex:x];
        [lineMe addHits:[lineNew hitCount]];
    }
    
    // then add the number
    [self updateCounts];
    return YES;
}

- (NSString *)description
{
    return [NSString stringWithFormat:
            @"%@: %lu total lines, %ld lines non-feasible, "
            @"%ld lines of code, %ld lines hit",
            _sourcePath, (unsigned long)[_lines count],
            (long)_nonfeasible, (long)_codeLines, (long)_hitLines];
}


@end


@implementation CoverStoryCoverageFileData (ScriptingMethods)
- (NSScriptObjectSpecifier *)objectSpecifier
{
    NSScriptObjectSpecifier *containerSpec = [[self document] objectSpecifier];
    NSScriptClassDescription *containterClassDesc = [containerSpec keyClassDescription];
    NSString *name = [self sourcePath];
    return [[NSNameSpecifier alloc] initWithContainerClassDescription:containterClassDesc
                                                   containerSpecifier:containerSpec
                                                                  key:@"fileDatas"
                                                                 name:name];
}

- (NSScriptObjectSpecifier *)objectSpecifierForLineData:(CoverStoryCoverageLineData *)data
{
    NSScriptObjectSpecifier *containerSpec = [self objectSpecifier];
    NSScriptClassDescription *containterClassDesc = [containerSpec keyClassDescription];
    NSInteger index = [[self lines] indexOfObject:data];
    return [[NSIndexSpecifier alloc] initWithContainerClassDescription:containterClassDesc
                                                    containerSpecifier:containerSpec
                                                                   key:@"lines"
                                                                 index:index];
}

@end
