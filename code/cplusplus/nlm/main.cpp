#include <opencv2/opencv.hpp>
#include <iostream>
#include <boost/filesystem.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>
#include "testconfig.h"
#include "StandardNLMAlgorithm.h"

//using namespace boost::filesystem;
using namespace boost::posix_time;
using namespace cv;

void nlm_algorithm(Mat image);

int main( int argc, char** argv )
{
	char* imageName = argv[1];
    
    if( !argc == 2) {
        printf("No image specified. Will quit now.\n");
        return -1;
    }

	Mat image;
	// flag 0: convert to grayscale
	image = imread( imageName, 0 );

	if( !image.data ) {
		printf( "Could not read image. Will quit now.\n " );
		return -3;
	}

	#include <boost/date_time/posix_time/posix_time.hpp>

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

	StandardNLMAlgorithm algorithm(config);
	Mat denoisedImage = algorithm.runAlgorithm(image);

	imwrite( outputFilePath.c_str(), denoisedImage );

	namedWindow( imageName, CV_WINDOW_AUTOSIZE );

	imshow( imageName, denoisedImage );

	waitKey(0);

	return 0;
}

void nlm_algorithm(Mat image) {

}