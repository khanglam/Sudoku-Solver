
//
//  OpenCVWrapper.m
//  SudokuSolver
//
//  Created by Khang Lam on 4/22/18.
//  Copyright © 2018 Khang Lam. All rights reserved.
//
#import "OpenCVWrapper.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#include "TesseractOCR/baseapi.h"
#include "TesseractOCR/G8Tesseract.h"
#include "leptonica/allheaders.h"
#include "Solver.hpp"


using namespace cv;
using namespace std;
using namespace tesseract;

@implementation OpenCVWrapper

unsigned int sudoku[9][9] = {{1,0,0,9,0,0,0,7,3},
    {0,0,0,1,0,0,0,0,0},
    {0,0,8,0,7,6,0,0,0},
    {0,4,0,3,0,0,0,0,1},
    {3,0,7,0,8,0,2,0,9},
    {0,0,0,6,9,0,8,0,0},
    {0,0,0,0,2,3,0,0,0},
    {0,0,0,0,1,0,4,0,2},
    {0,0,0,0,0,0,0,0,0}};

struct StraightEdge //create the struct to easier access of a line
{
    
    cv::Point pt1;
    cv::Point pt2;
    
    std::size_t id; //This is for vertical container
    std::size_t hori_and_veritical; //horiz and vertical
    
    multimap<double,size_t> intersect; //check intersection
};

struct Pairing
{
    Pairing(size_t new_struct1=0, size_t new_struct2=0, double new_intertersection=0)
    : struct1(new_struct1), struct2(new_struct2), inter(new_intertersection)
    {
        
    }
    double inter;
    //cout
    size_t struct1;
    size_t struct2;
    
};


bool intersectingAt(Point2f vert, Point2f point1, Point2f hor, Point2f point2,
                    Point2f &intersectPointer)
{
    Point2f x = hor - vert;
    Point2f first = point1 - vert;
    Point2f second = point2 - hor;
    
    float mix = first.x*second.y - first.y*second.x;
    if (abs(mix) < 1e-8)
        return false;
    
    double tempo = (x.x * second.y - x.y * second.x)/mix;
    intersectPointer = vert + first * tempo;
    return true;
}
void plug_points( Mat& img, cv::Point center )
{
    circle(img, center, 3, Scalar(255, 0, 0), 20, 8);
}

bool detect_Line(const vector<pair<double,StraightEdge>>& L1, vector<set<size_t>>& lineVector)
{
    double distance = 20;
    
    
    if (L1.empty()) //return if no line
        return false;
    else
    {
        
        vector<pair<double,Pairing>> difference_int;
        
        size_t h_ID = round(L1.size()/2);
        auto align = L1.begin()+h_ID;
        const StraightEdge& MID = align->second;
        
    
        if (MID.intersect.size()<=9)
            return false;
        else
        {
            auto previous = MID.intersect.begin();
            auto crossing = MID.intersect.begin();
            ++crossing;
            for(; crossing!=MID.intersect.end(); ++crossing,++previous)
                difference_int.push_back(make_pair(crossing->first-previous->first,Pairing(previous->second, crossing->second, crossing->first)));
            
            sort(difference_int.begin(),difference_int.end(),[](const std::pair<double,Pairing> &left, const std::pair<double,Pairing> &right) {return left.first < right.first;});
            
            /////////////////////////////////////////////////////////////
            auto inner1 = difference_int.begin();
            auto inner2 = difference_int.begin()+8;
            double minimum_dif = 99999;
            int minimum_ind = -1;
            size_t current_ind = 0;
            for(;inner2<difference_int.end(); ++inner1, ++inner2, ++current_ind)
            {
                if(inner1->first>distance)
                {
                    if(inner2->first-inner1->first<minimum_dif)
                    {
                        minimum_dif = inner2->first-inner1->first;
                        minimum_ind  = (int)current_ind;
                    }
                }
            }
            
   
            if(minimum_ind<0)
                return false;
            else if(max(difference_int[minimum_ind].first,difference_int[minimum_ind+8].first)/min(difference_int[minimum_ind].first,difference_int[minimum_ind+8].first) > 1.3)
                return false;
            else
            {
        
                vector<Pairing> pairsVectors(9);
                for(std::size_t i=0; i<9; ++i)
                    pairsVectors[i] = difference_int[minimum_ind+i].second;
                sort(pairsVectors.begin(),pairsVectors.end(),[](const Pairing &left, const Pairing &right) {return left.inter < right.inter;});
                
       
                lineVector.resize(10);
                for(std::size_t i=0; i<9; ++i)
                {
                    lineVector[i  ].insert(pairsVectors[i].struct1);
                    lineVector[i+1].insert(pairsVectors[i].struct2);
                }
                
            }
        }
    }
    return true;
}
Point2f averageInts(const set<size_t>& h, const set<size_t>& v, const vector<pair<double,StraightEdge>>& HORIZONTAL, const vector<pair<double,StraightEdge>>& VERTICAL)
{

    std::vector<Point2f> all_intersections;//Get the intersections
    for(auto e1:h)
    {
        for(auto e2:v)
        {
            Point2f inters;
            if(intersectingAt(HORIZONTAL[e1].second.pt1, HORIZONTAL[e1].second.pt2,
                              VERTICAL[e2].second.pt1, VERTICAL[e2].second.pt2,
                              inters))
                all_intersections.push_back(inters);
        }
    }
    
    //Get the mean
    Point2f avg = all_intersections[0];
    for (std::size_t i=1; i<all_intersections.size(); ++i)
        avg = avg + all_intersections[i];
    avg.x = avg.x / (float)all_intersections.size();
    avg.y = avg.y / (float)all_intersections.size();
    return avg;
}

unsigned int tesseractThisBitch(Mat& image,tesseract::TessBaseAPI api)
{
    api.SetImage((uchar*)image.data, image.size().width, image.size().height, image.channels(), (int)image.step1());
    api.Recognize(0);
    const char* extracted = api.GetUTF8Text();
    if (extracted)
        if(extracted[0]=='1')
            return 1;
        else if(extracted[0]=='2')
            return 2;
        else if(extracted[0]=='3')
            return 3;
        else if(extracted[0]=='4')
            return 4;
        else if(extracted[0]=='5')
            return 5;
        else if(extracted[0]=='6')
            return 6;
        else if(extracted[0]=='7')
            return 7;
        else if(extracted[0]=='8')
            return 8;
        else if(extracted[0]=='9')
            return 9;
        else
            return 0;
        else
            return 0;
    
}
- (UIImage *) makeGray:(UIImage *)image
{
    
    //Starting Tess
    G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng"];
    //This somehow fixes the TESSDATA_PREFIX Error
    tesseract::TessBaseAPI api;
    // setenv("TESSDATA_PREFIX", "/usr/local/Cellar/tesseract/3.05.01/share/tessdata/", 1);
    if (api.Init(NULL, "eng", OEM_TESSERACT_CUBE_COMBINED)) {
        fprintf(stderr, "Could not initialize tesseract.\n");
        exit(1);
    }
    tesseract.engineMode = G8OCREngineModeTesseractCubeCombined;
    tesseract.charWhitelist = @"0123456789";
    tesseract.charBlacklist = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    //   cout<<getenv("TESSDATA_PREFIX")<<endl;
    
    //In order for UIImage to be converted to cv Mat properly, you need to normalize the UIImage if its
    // taken from iPhone Camera...
    
    //Normalize UIImage
    if (image.imageOrientation == UIImageOrientationUp) return image;
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    size_t COL = normalizedImage.size.width;
    size_t ROW = normalizedImage.size.height;
    
    //UI to Mat
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(normalizedImage.CGImage);
    CGFloat cols = normalizedImage.size.width;
    CGFloat rows = normalizedImage.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                      // Width of bitmap
                                                    rows,                     // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), normalizedImage.CGImage);
    CGContextRelease(contextRef);
    
    //apply grayscale
    cv::Mat greyMat, blurred_greyMat;
    cv::cvtColor(cvMat, greyMat, CV_BGR2GRAY);
    //apply gaussian blur
    Mat gaussianBlur;
    // GaussianBlur(greyMat, gaussianBlur, cv::Size(3,3), 2 , 2);
    blur(greyMat, gaussianBlur, cv::Size(3,3));
    //Canny edge detector
    Mat cannyEdged;
    Canny(gaussianBlur, cannyEdged, 150, 200, 3);
    
    //cvtColor(cannyEdged, houghEdge, COLOR_GRAY2BGR);
    ///////////////////////////Hough Lines////////////////////////////////////
    vector<Vec2f> determine_LINE;
    HoughLines(cannyEdged, determine_LINE, 2, CV_PI/180, 300, 0, 0);
    vector<StraightEdge> edges(determine_LINE.size());
    
    for( size_t i = 0; i < determine_LINE.size(); i++ )    {
        float angle1 = determine_LINE[i][0];
        float angle2 = determine_LINE[i][1];
        double cosine = cos(angle2), sine = sin(angle2);
        double a0 = cosine*angle1, b0 = sine*angle1;
        edges[i].pt1.x = cvRound(a0 + 4000*(-sine));
        edges[i].pt1.y = cvRound(b0 + 4000*(cosine));
        edges[i].pt2.x = cvRound(a0 - 4000*(-sine));
        edges[i].pt2.y = cvRound(b0 - 4000*(cosine));
        edges[i].id = i;
    }
    vector<pair<double,StraightEdge>> HORIZONTAL;
    vector<pair<double,StraightEdge>> TEMP;
    vector<pair<double,StraightEdge>> VERTICAL;
    
    for( size_t i = 0; i < edges.size(); ++i )
        if(determine_LINE[i][1]<CV_PI/20 or determine_LINE[i][1]>CV_PI-CV_PI/20) // Vertical if close to 180 deg or to 0 deg
            VERTICAL.push_back(make_pair(determine_LINE[i][0],edges[i]));
        else if(abs(determine_LINE[i][1]-CV_PI/2)<CV_PI/20)                  // Horizontal if close to 90 deg
            HORIZONTAL.push_back(make_pair(determine_LINE[i][0],edges[i]));
        else
            TEMP.push_back(make_pair(determine_LINE[i][0],edges[i]));
    
   
    std::sort(VERTICAL.begin(), VERTICAL.end(), [](const std::pair<double,StraightEdge> &left, const std::pair<double,StraightEdge> &right) {return left.first < right.first;});
    std::sort(HORIZONTAL.begin(), HORIZONTAL.end(), [](const std::pair<double,StraightEdge> &left, const std::pair<double,StraightEdge> &right) {return left.first < right.first;});
    
    for(std::size_t i=0; i<VERTICAL.size(); ++i)
        VERTICAL[i].second.hori_and_veritical = i;
    for(std::size_t i=0; i<HORIZONTAL.size(); ++i)
        HORIZONTAL[i].second.hori_and_veritical = i;
    
    

  /*  for( auto e: VERTICAL) //Draw blue lines for vertial
        line(cvMat, e.second.pt1, e.second.pt2, Scalar(0,0,255), 2, CV_AA);
    for( auto e: HORIZONTAL) //Draw red lines for horizontal
        line( cvMat, e.second.pt1, e.second.pt2, Scalar(255,  0,  0), 2, CV_AA);*/
    
    
    for(auto& cosine: VERTICAL)
    {
        for(auto& sine: HORIZONTAL)
        {
            Point2f inters;
            if(intersectingAt(cosine.second.pt1, cosine.second.pt2,
                              sine.second.pt1, sine.second.pt2, inters))
            {
                if(inters.x>=0 and inters.x<COL and inters.y>=0 and inters.y<ROW)
                {
                    cosine.second.intersect.insert(make_pair(inters.y,sine.second.hori_and_veritical));
                    sine.second.intersect.insert(make_pair(inters.x,cosine.second.hori_and_veritical));
                }
            }
        }
    }
    
    
    vector<set<size_t>> sel_v;
    bool test1 = detect_Line(HORIZONTAL,sel_v);
    
    vector<set<size_t>> sel_h;
    bool test2 = detect_Line(VERTICAL,sel_h);
    
    if (test1 == true and test2==true)
    {
    
        vector<vector<Point2f>> rightAngles(10,vector<Point2f>(10));
        for(std::size_t i=0; i<10; ++i)
            for(std::size_t j=0; j<10; ++j)
                rightAngles[i][j] = averageInts(sel_h[i],sel_v[j],HORIZONTAL,VERTICAL);
        
        //THIS IS FOR PRINTING THOSE SHITTY DOTS//Finally working
        for(std::size_t i=0; i<10; ++i)
            for(std::size_t j=0; j<10; ++j)
                plug_points(cvMat, rightAngles[i][j]);
        ///////////////////////////////////////////////////
        //Create Boxes for every 4 dots
        float enlargeBy = 0.6;
        vector<vector<pair<Point2f,/*This is needed because you need two pts to make a box
                                    */Point2f>>> BOX(9,vector<pair<Point2f,Point2f>>(9));
        for(std::size_t i=0; i<9; ++i)
            for(std::size_t j=0; j<9; ++j)
            {
                Point2f upperleft = rightAngles[i][j];
                Point2f downright = rightAngles[i+1][j+1];
                
        
                float thickness = (downright.x - upperleft.x)*enlargeBy;
                float height = (downright.y - upperleft.y)*enlargeBy;
                float average_width = (downright.x + upperleft.x)/2;
                float average_height = (downright.y + upperleft.y)/2;
                upperleft.x = average_width-thickness/2;
                upperleft.y = average_height-height/2;
                downright.x = average_width+thickness/2;
                downright.y = average_height+height/2;
                
                BOX[i][j].first = upperleft;
                BOX[i][j].second = downright;
            }
        
        //test the boxes
        /*           for(std::size_t i=0; i<9; ++i)
         for(std::size_t j=0; j<9; ++j)
         rectangle(cvMat, boxes[i][j].first, boxes[i][j].second, Scalar(255,0,0) );*/
        /////////////////////////////////////////////////////////
        unsigned int upleftX = round(min(rightAngles[0][0].x,rightAngles[9][0].x));
        unsigned int upleftY = round(min(rightAngles[0][0].y,rightAngles[0][9].y));
        
        unsigned int downrightX = round(max(rightAngles[0][9].x,rightAngles[9][9].x));
        unsigned int downrightY = round(max(rightAngles[9][0].y,rightAngles[9][9].y));
        
        
        Mat su_grid(greyMat, cv::Rect(upleftX, upleftY,
                                      downrightX-upleftX,
                                      downrightY-upleftY));

        Mat su_thresh = su_grid.clone(); //turn it into threshold
        adaptiveThreshold(su_grid, su_thresh, 255, CV_ADAPTIVE_THRESH_GAUSSIAN_C, CV_THRESH_BINARY_INV, 101, 1);
        
        
        vector<vector<unsigned int>> tess(9,vector<unsigned int>(9)); //Use tess
        vector<vector<unsigned int>> mySudoku(9,vector<unsigned int>(9)); //hard code the board
        for(std::size_t i=0; i<9; ++i)
        {
            for(std::size_t j=0; j<9; ++j)
            {
                
                Mat newBox(su_thresh, cv::Rect(round(BOX[i][j].first.x)-upleftX, round(BOX[i][j].first.y)-upleftY,
                                               round(BOX[i][j].second.x-BOX[i][j].first.x),
                                               round(BOX[i][j].second.y-BOX[i][j].first.y)));
                
                //tess[i][j] = recognize_digit(newBox);
                tess[i][j] = sudoku[i][j];
                //  cout<<tess[i][j]<<endl;
                

            }
        }
        /*        for(std::size_t i=0; i<9; ++i)
         {
         cout<<endl;
         for(std::size_t j=0; j<9; ++j)
         {
         cout<<tess[i][j]<< " ";
         }
         }*/
        
        /////////////////////////////////////// detect the numbers
        for(std::size_t i=0; i<9; ++i)
            for(std::size_t j=0; j<9; ++j)
                if (tess[i][j]!=0)
                {
                    cv::Point layText(BOX[i][j].first.x+(BOX[i][j].second.x-BOX[i][j].first.x)/5,
                                      BOX[i][j].second.y-(BOX[i][j].second.y-BOX[i][j].first.y)/5);
                    stringstream input;
                    input << (int)tess[i][j];
                    putText(cvMat, input.str(), layText, CV_FONT_HERSHEY_DUPLEX, 1,
                            Scalar(0,0,255), 1, 8);
                }
        /////////////////////////////////////////////
        
        mySudoku[0][0] = 4;
        mySudoku[0][2] = 7;
        mySudoku[0][3] = 9;
        mySudoku[0][5] = 3;
        mySudoku[1][1] = 1;
        mySudoku[1][2] = 3;
        mySudoku[1][4] = 7;
        mySudoku[1][5] = 2;
        mySudoku[2][0] = 2;
        mySudoku[2][7] = 3;
        mySudoku[3][0] = 1;
        mySudoku[3][2] = 6;
        mySudoku[3][3] = 3;
        mySudoku[3][8] = 5;
        mySudoku[4][3] = 7;
        mySudoku[4][5] = 6;
        mySudoku[5][0] = 7;
        mySudoku[5][5] = 9;
        mySudoku[5][6] = 4;
        mySudoku[5][8] = 1;
        mySudoku[6][1] = 4;
        mySudoku[6][8] = 9;
        mySudoku[7][3] = 6;
        mySudoku[7][4] = 9;
        mySudoku[7][6] = 2;
        mySudoku[7][7] = 1;
        mySudoku[8][3] = 2;
        mySudoku[8][5] = 7;
        mySudoku[8][6] = 3;
        mySudoku[8][8] = 4;
        ////////////////SOLVE THE SUDOKU///////

        Solver<3> su;
        
        /* Set the recognized digits */
        for(std::size_t i=0; i<3*3; ++i)
            for(std::size_t j=0; j<3*3; ++j)
                su.set_value(i, j, tess[i][j]);
        
        if(su.solve())
        {
            cout<<"SOLVED !!!!!!"<<endl;
            
            for(std::size_t i=0; i<3*3; ++i)
                for(std::size_t j=0; j<3*3; ++j)
                    if (tess[i][j]==0)
                    {
                        cv::Point layText(BOX[i][j].first.x +(BOX[i][j].second.x-BOX[i][j].first.x)/5,
                                          BOX[i][j].second.y-(BOX[i][j].second.y-BOX[i][j].first.y)/5);
                        stringstream input;
                        input << (int)su.get_value(i,j);
                        putText(cvMat, input.str(), layText, CV_FONT_NORMAL, 2,
                                Scalar(0,0,255), 2, 8);
                        
                    }
        }
    }
    
    
    //Mat to UI
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return finalImage;
}
@end









