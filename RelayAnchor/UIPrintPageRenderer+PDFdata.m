//
//  UIPrintPageRenderer+PDFdata.m
//  RelayAnchor
//
//  Created by chuck johnston on 3/5/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "UIPrintPageRenderer+PDFdata.h"

@implementation UIPrintPageRenderer (PDFdata)

- (NSData*) printToPDF
{
    NSMutableData *pdfData = [NSMutableData data];
    UIGraphicsBeginPDFContextToData( pdfData, self.paperRect, nil );
    [self prepareForDrawingPages: NSMakeRange(0, self.numberOfPages)];
    CGRect bounds = UIGraphicsGetPDFContextBounds();
    for ( int i = 0 ; i < self.numberOfPages ; i++ )
    {
        UIGraphicsBeginPDFPage();
        [self drawPageAtIndex: i inRect: bounds];
    }
    UIGraphicsEndPDFContext();
    return pdfData;
}

@end
