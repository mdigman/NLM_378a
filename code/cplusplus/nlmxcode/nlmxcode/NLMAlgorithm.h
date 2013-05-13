//
//  NLMAlgorithm.h
//  nlmxcode
//
//  Created by Thomas Walther on 5/12/13.
//  Copyright (c) 2013 Non Local Mean Guys. All rights reserved.
//

#ifndef __nlmxcode__NLMAlgorithm__
#define __nlmxcode__NLMAlgorithm__

#include <opencv2/opencv.hpp>
#include "TestConfig.h"

using namespace cv;

/**
 This class is the basic abstract class for every algorithm.
 If you want to implement a new algorithm, you must subclass this.
 
 Every subclass must implement runAlgorithm(Mat image).
 */
class NLMAlgorithm {
public:
    NLMAlgorithm(TestConfig config);
    
    /**
     runs the algorithm of this class. Must be reimplemented
     by a subclass.
     */
    virtual Mat runAlgorithm(Mat image) = 0;
    
protected:
    TestConfig config;
};

#endif /* defined(__nlmxcode__NLMAlgorithm__) */
