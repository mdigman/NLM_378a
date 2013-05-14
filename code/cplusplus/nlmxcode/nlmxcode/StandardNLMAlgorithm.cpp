//
//  StandardNLMAlgorithm.cpp
//  nlmxcode
//
//  Created by Thomas Walther on 5/12/13.
//  Copyright (c) 2013 Non Local Mean Guys. All rights reserved.
//

/*
 * File:   StandardNLMAlgorithm.cpp
 * Author: thomas
 *
 * Created on May 10, 2013, 10:55 PM
 */

#include "StandardNLMAlgorithm.h"
#include <math.h>
#include "TestConfig.h"


uchar roundToChar(float d) {
    int i = round(d);
    i = i > 255 ? 255 : i;
    i = i < 0 ? 0 : i;
    return (uchar)i;
}


StandardNLMAlgorithm::StandardNLMAlgorithm(TestConfig config)
: NLMAlgorithm(config) {
}

Mat StandardNLMAlgorithm::runAlgorithm(Mat noisyImg) {
    printf("StandardNLMAlgorithm::runAlgorithm\n");
    
    // because OpenCV elementwise matrix multiplication only works when both matrices
    // have the same type, we need to convert our noisyImg to the same  type of the local
    // weights.
    noisyImg.convertTo(noisyImg, CV_32F);
    
    int kSize = config.kSize;
    int searchSize = config.searchSize;
    double h = config.h;
    // double noiseSig = config.noiseSig; // unused in Matlab, too
    // bool color = config.color; // no color support yet
    
    int halfSearchSize = searchSize/2; // integer division floors automatically
    int halfKSize = kSize/2;; // integer division floors automatically
    float hSq = h * h;
    
    // TODO: removed color code because I don't know how openCV handles three
    // dimensional matrices.
    int M = noisyImg.rows;
    int N = noisyImg.cols;
    
    Mat deNoisedImg = noisyImg.clone();
    
    int borderSize = halfKSize+halfSearchSize+1;
    
    // make sure printf outputs immediately
    setbuf(stdout, NULL);
    printf("loop from j=%d, j < %d, j++\n", borderSize, M-borderSize);
    
    
    Mat kernel;
    Mat localWeights;
    
    
    // local weights are floating point numbers
    // TODO: see if we can pack them in a single byte of memory.
    localWeights = Mat::zeros(searchSize, searchSize, CV_32F);
    
    // perform algorithm
    // both i, j loops can easily be parallelized
    for(int j = borderSize - 1; j < M - borderSize; j++) {
        printf("%d ", j);
        for(int i = borderSize - 1; i < N - borderSize; i++) {
            kernel = noisyImg.rowRange(j-halfKSize, j+halfKSize+1)
                             .colRange(i-halfKSize, i+halfKSize+1);
            
            for(int jP = 0; jP < searchSize; jP++) {
                for(int iP = 0; iP < searchSize; iP++) {
                    int vJ = j - halfSearchSize + jP;
                    int vI = i - halfSearchSize + iP;
                    
                    Mat v = noisyImg.rowRange(vJ - halfKSize, vJ + halfKSize + 1)
                                    .colRange(vI - halfKSize, vI + halfKSize + 1);
                    
                    float distSq = sum((kernel - v).mul(kernel - v))[0];
                    
                    // TODO: see if we can pack the weights in a single byte of memory.
                    // Idea: The exponential is always < 1. We can multiply the result by 255.
                    localWeights.at<float>(jP, iP) = exp(-((float)distSq) / hSq);
                }
            }
            
            double scale = 1.0/sum(localWeights)[0];
            
            Mat subImg = noisyImg.rowRange(j-halfSearchSize, j + halfSearchSize + 1)
            .colRange(i-halfSearchSize, i + halfSearchSize + 1);
            
            // TODO: make this work with a localWeights matrix of type uchar
            // Idea: Do the elementwise summing manually. That way, we can cast in every iteration to a
            // short/int because otherwise the element multiplication would exceed the uchar bounds.
            // Then, at the very end, divide by 255 (since we multiplied all weights by 255)
            deNoisedImg.at<float>(j,i) = sum(localWeights.mul(subImg, scale))[0];
        }
    }
    
    // convert back to uchar;
    deNoisedImg.convertTo(deNoisedImg, CV_8U);
    
    return deNoisedImg;
}

