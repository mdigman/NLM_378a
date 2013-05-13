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

typedef uchar weights_type;
#define WEIGHTS_TYPE_DEF CV_8U


StandardNLMAlgorithm::StandardNLMAlgorithm(TestConfig config)
: NLMAlgorithm(config) {
}

Mat StandardNLMAlgorithm::runAlgorithm(Mat noisyImg) {
    printf("StandardNLMAlgorithm::runAlgorithm\n");
    
    int kSize = config.kSize;
    int searchSize = config.searchSize;
    double h = config.h;
    // double noiseSig = config.noiseSig; // unused in Matlab, too
    // bool color = config.color; // no color support yet
    
    int halfSearchSize = searchSize/2; // integer division floors automatically
    int halfKSize = kSize/2;; // integer division floors automatically
    double hSq = h * h;
    
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
    Mat localWeights = Mat(searchSize, searchSize, WEIGHTS_TYPE_DEF);
    
    // perform algorithm
    // the outer loop can easily be parallelized
    for (int j= borderSize; j < M-borderSize; j++) {
        printf("%d ", j);
        for(int i= borderSize; i < N-borderSize; i++) {
            // As far as I (Thomas) know, noisyImg can't be easily sliced to
            // improve performance. Instead, one would have to use spmd to do
            // such things. However, most of the time is spent in the two inner
            // loops anyway
            kernel = noisyImg.rowRange(j-halfKSize, j+halfKSize+1)
                             .colRange(i-halfKSize,i+halfKSize+1);
            
            for(int jP=0; jP < searchSize; jP++) {
                for(int iP=0; iP < searchSize; iP++) {
                    int vJ = j-halfSearchSize+jP;
                    int vI = i-halfSearchSize+iP;
                    Mat v;
                    
                    v = noisyImg.rowRange(vJ-halfKSize, vJ+halfKSize + 1)
                                .colRange(vI-halfKSize, vI+halfKSize+1);
                    
                    // TODO: does this work for color?
                    //L2 norm squared
                    Mat kernelDiff = kernel - v;
                    Scalar distSum = sum(( kernelDiff ).mul( kernelDiff ));
                    double distSq = distSum[0];
                    
                    // TODO: does this work for color?
                    localWeights.at<weights_type>(jP, iP) = exp( - distSq / hSq );
                    
                    /*
                     * matlab code:
                     
                    distSq = ( kernel - v ) .* ( kernel - v );
                    distSq = sum( distSq(:) ); %L2 norm squared
                    
                    localWeights( jP+1, iP+1 ,:) = exp( - distSq / hSq );
                     */
                }
            }
            
            double localWeightsSum = sum(localWeights)[0]; // convert to floating point here
            double localWeightsScale = 1.0/localWeightsSum; // this must be floating point
            
            localWeights = localWeights.mul(Mat::ones(localWeights.size(), WEIGHTS_TYPE_DEF), localWeightsScale);
            
            Mat subImg = noisyImg.rowRange(j-halfSearchSize, j+halfSearchSize + 1)
                                 .colRange(i-halfSearchSize, i+halfSearchSize + 1);
            
            Mat weightedSubImg = subImg.mul(localWeights);
            deNoisedImg.at<Pixel>(j,i) = sum(weightedSubImg)[0];
        }
    }
    
    return deNoisedImg;
}

