/* 
 * File:   StandardNLMAlgorithm.cpp
 * Author: thomas
 * 
 * Created on May 10, 2013, 10:55 PM
 */

#include "StandardNLMAlgorithm.h"
#include <math.h>

StandardNLMAlgorithm::StandardNLMAlgorithm(TestConfig config)
            : NLMAlgorithm(config) {
}

Mat StandardNLMAlgorithm::runAlgorithm(Mat noisyImg) {
    printf("StandardNLMAlgorithm::runAlgorithm\n");
    
    int kSize = config.kSize;
    int searchSize = config.searchSize;
    double h = config.h;
    double noiseSig = config.noiseSig;
    bool color = config.color;

    int halfSearchSize = floor( searchSize/2.0 );
    int halfKSize = floor( kSize/2.0 );
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

    // perform algorithm
    // the outer loop can easily be parallelized
    for (int j= 489/*borderSize*/; j < M-borderSize; j++) {
        printf("%d ", j);
        for(int i= 494/*borderSize*/; i < N-borderSize; i++) {
            // As far as I (Thomas) know, noisyImg can't be easily sliced to
            // improve performance. Instead, one would have to use spmd to do
            // such things. However, most of the time is spent in the two inner 
            // loops anyway 
            
            Mat kernel;
            Mat localWeights;
            if(color) {
                kernel = noisyImg.rowRange(j-halfKSize, j+halfKSize+1)
                        .colRange(i-halfKSize,i+halfKSize+1);
               // TODO: check type CV_8UC3 for colors
              localWeights = Mat(searchSize, searchSize, CV_8UC3);
            } else {
                

                // endRow/Col is not included, thus + 1
                //end
                
                kernel = noisyImg.rowRange(j-halfKSize, j+halfKSize+1)
                        .colRange(i-halfKSize,i+halfKSize+1);
            
                localWeights = Mat(searchSize, searchSize, CV_8UC1);
            }

            for(int jP=0; jP < searchSize; jP++) {
                for(int iP=0; iP < searchSize; iP++) {
                    int vJ = j-halfSearchSize+jP;
                    int vI = i-halfSearchSize+iP;
                    Mat v;

                    v = noisyImg.rowRange(vJ-halfKSize, vJ+halfKSize + 1)
                      .colRange(vI-halfKSize, vI+halfKSize+1);
                    
                    // TODO: does this work for color?
                    //L2 norm squared
                    //Scalar distSq = sum(( kernel - v ).mul( kernel - v ));

                    // TODO: does this work for color?
                    //exp( - distSq / hSq, localWeights.at<Scalar>(jP, iP) );
                }
            }

            // TODO: does this work for color?
            localWeights = localWeights.mul(1.0/sum(sum(localWeights)));

            Mat subImg = noisyImg.rowRange(j-halfSearchSize, j+halfSearchSize + 1)
                .colRange(i-halfSearchSize, i+halfSearchSize + 1);

            Mat mulLocalWeights = localWeights.mul(subImg);
            Scalar sum1LocalWeights = sum(mulLocalWeights);
            Scalar sum2LocalWeights = sum(sum1LocalWeights);
            
            Scalar oldValue = deNoisedImg.at<Scalar>(j,i);
            
            deNoisedImg.at<Scalar>(j,i) = sum2LocalWeights;
        }
    }
    
    return deNoisedImg;
}

