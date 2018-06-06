//
//  OpenCVWrapper.h
//  SudokuSolver
//
//  Created by Khang Lam on 4/22/18.
//  Copyright © 2018 Khang Lam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TesseractOCR/TesseractOCR.h"
#import "leptonica/allheaders.h"
//#import <opencv2/core/core.hpp>



@interface OpenCVWrapper : NSObject
-(UIImage *) makeGray:(UIImage *)image;
@end
