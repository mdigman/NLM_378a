#ifndef NLM_ALGORITHM_H
#define NLM_ALGORITHM_H

#include <opencv2/opencv.hpp>

using namespace cv;

/**
  This class is the basic abstract class for every algorithm.
  If you want to implement a new algorithm, you must subclass this.

  Every subclass must implement runAlgorithm(Mat image).
 */
class NLMAlgorithm {
public:
	NLMAlgorithm() {};

	/**
	 runs the algorithm of this class. Must be reimplemented
	 by a subclass.
	*/
	virtual void runAlgorithm(Mat image) = 0;
};


#endif