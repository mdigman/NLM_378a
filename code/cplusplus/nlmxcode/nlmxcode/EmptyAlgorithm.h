//
//  EmptyAlgorithm.h
//  nlmxcode
//
//  Created by Thomas Walther on 5/12/13.
//  Copyright (c) 2013 Non Local Mean Guys. All rights reserved.
//

#ifndef __nlmxcode__EmptyAlgorithm__
#define __nlmxcode__EmptyAlgorithm__

#include "NLMAlgorithm.h"

using namespace cv;

class EmptyAlgorithm : public NLMAlgorithm {
public:
    EmptyAlgorithm(TestConfig config);
    
    Mat runAlgorithm(Mat image);
    
};

#endif /* defined(__nlmxcode__EmptyAlgorithm__) */
