/* 
 * File:   NLMAlgorithm.h
 * Author: thomas
 *
 * Created on May 10, 2013, 10:35 PM
 */

#ifndef NLMALGORITHM_H
#define	NLMALGORITHM_H

#include <opencv2/opencv.hpp>
#include "testconfig.h"

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

#endif	/* NLMALGORITHM_H */

