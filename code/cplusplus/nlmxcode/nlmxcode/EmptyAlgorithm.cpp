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

#include "EmptyAlgorithm.h"
#include <math.h>
#include "TestConfig.h"

EmptyAlgorithm::EmptyAlgorithm(TestConfig config)
: NLMAlgorithm(config) {
}

Mat EmptyAlgorithm::runAlgorithm(Mat noisyImg) {
    return noisyImg;
}

