#include <opencv2/opencv.hpp>
#include <iostream>
#include <boost/filesystem.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>

//using namespace boost::filesystem;
using namespace boost::posix_time;
using namespace cv;

int main( int argc, char** argv )
{
	char* imageName = argv[1];

	Mat image;
	// flag 0: convert to grayscale
	image = imread( imageName, 0 );

	if( argc != 2 || !image.data ) {
		printf( " No image data \n " );
		return -1;
	}

	#include <boost/date_time/posix_time/posix_time.hpp>

	ptime date_time = microsec_clock::universal_time();

	std::string path = "./output-" + to_iso_string(date_time) + "/";
	std::string imagePath = path + imageName;

	boost::filesystem::path p(path);

	bool error = boost::filesystem::create_directories(p);
	if(error) {
		printf("couldn't create output directory\n");
		return -1;
	}

	imwrite( imagePath.c_str(), image );

	namedWindow( imageName, CV_WINDOW_AUTOSIZE );

	imshow( imageName, image );

	waitKey(0);

	return 0;
}