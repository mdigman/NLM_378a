//
//  StandardNLMAlgorithm.h
//  nlmxcode
//
//  Created by Thomas Walther on 5/12/13.
//  Copyright (c) 2013 Non Local Mean Guys. All rights reserved.
//

#ifndef __nlmxcode__StandardNLMAlgorithm__
#define __nlmxcode__StandardNLMAlgorithm__

#include "NLMAlgorithm.h"

using namespace cv;

class StandardNLMAlgorithm : public NLMAlgorithm {
public:
    StandardNLMAlgorithm(TestConfig config);
    
    Mat runAlgorithm(Mat image);
    
};

#endif /* defined(__nlmxcode__StandardNLMAlgorithm__) */
