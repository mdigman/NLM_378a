//
//  ByteNLMAlgorithm.h
//  nlmxcode
//
//  Created by Thomas Walther on 5/14/13.
//  Copyright (c) 2013 Non Local Mean Guys. All rights reserved.
//

#ifndef __nlmxcode__ByteNLMAlgorithm__
#define __nlmxcode__ByteNLMAlgorithm__

#include "NLMAlgorithm.h"

using namespace cv;

class ByteNLMAlgorithm : public NLMAlgorithm {
public:
    ByteNLMAlgorithm(TestConfig config);
    
    Mat runAlgorithm(Mat image);
    
};

#endif /* defined(__nlmxcode__ByteNLMAlgorithm__) */
