//
//  main.cpp
//  nlmxcode
//
//  Created by Thomas Walther on 5/12/13.
//  Copyright (c) 2013 Non Local Mean Guys. All rights reserved.
//

#include <opencv2/opencv.hpp>
#include <iostream>
#include <boost/filesystem.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>
#include "testconfig.h"
#include "StandardNLMAlgorithm.h"
#include "EmptyAlgorithm.h"
#include <boost/timer/timer.hpp>
#include <cmath>


//using namespace boost::filesystem;
using namespace boost::posix_time;
using namespace cv;

void nlm_algorithm(Mat image);

int main( int argc, char** argv )
{
	const char* imageName = argv[1];
    
    if( !argc == 2) {
        printf("No image specified. Will quit now.\n");
        return -1;
    }
    
	Mat image;
	// TODO: right now we're always loading the imagefile in grayscale. No color support.
	image = imread( imageName, CV_LOAD_IMAGE_GRAYSCALE );
    
	if( !image.data ) {
		printf( "Could not read image. Will quit now.\n " );
		return -3;
	}
    
	ptime date_time = microsec_clock::universal_time();
    
	std::string p = "./output-" + to_iso_string(date_time) + "/";
	boost::filesystem::path outputDirectory(p);
	boost::filesystem::path inputFilePath(imageName);
	boost::filesystem::path outputFilePath(outputDirectory.native() + inputFilePath.filename().native());
    
	bool error = boost::filesystem::create_directories(outputDirectory);
	if(error) {
		printf("couldn't create output directory\n");
		return -1;
	}
    
	// now run algorithm
	// no need to pass a reference. OpenCV will take
	// care of not copying the matrix.
	// done
    TestConfig config; // TODO: make this configurable via tests
    
    // add noise
    // code from http://opencv.willowgarage.com/documentation/cpp/introduction.html
    Mat noisyImage = Mat(image.rows, image.cols, CV_8U);
    Mat noise = Mat(image.rows, image.cols, CV_8U);
    
    randn(noise, config.noiseMean, config.noiseSig);
    addWeighted(image, 1, noise, 1, -128, noisyImage);
    
    // run algorithm
    
	StandardNLMAlgorithm algorithm(config);
    //EmptyAlgorithm algorithm(config);
    
    boost::timer::auto_cpu_timer *t = new boost::timer::auto_cpu_timer();
	Mat denoisedImage = algorithm.runAlgorithm(noisyImage);
    delete t;
    
	imwrite( outputFilePath.c_str(), denoisedImage );
    
	namedWindow( imageName, CV_WINDOW_AUTOSIZE );
    
	imshow( imageName, denoisedImage );
    
	waitKey(0);
    
	return 0;
}