/* 
 * File:   StandardNLMAlgorithm.h
 * Author: thomas
 *
 * Created on May 10, 2013, 10:55 PM
 */

#ifndef STANDARDNLMALGORITHM_H
#define	STANDARDNLMALGORITHM_H

#include "NLMAlgorithm.h"

class StandardNLMAlgorithm : public NLMAlgorithm {
public:
    StandardNLMAlgorithm(TestConfig config);
    
    Mat runAlgorithm(Mat image);

};

#endif	/* STANDARDNLMALGORITHM_H */

