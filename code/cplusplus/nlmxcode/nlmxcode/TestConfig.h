//
//  TestConfig.h
//  nlmxcode
//
//  Created by Thomas Walther on 5/12/13.
//  Copyright (c) 2013 Non Local Mean Guys. All rights reserved.
//

#ifndef __nlmxcode__TestConfig__
#define __nlmxcode__TestConfig__

// Define our Pixel data structure.
// TODO: make this usable for color, too.
typedef unsigned char Pixel;

/**
 This class contains the config for a test run.
 All variables are public. It is designed more like
 a struct than a class, except that all variables are
 initialized.
 */
class TestConfig {
public:
	// add new test configs here. Don't forget to add
	// them also to the appropriate constructor.
	enum TestConfiguration {TestConfigurationStandard = 1};
    
	int kSize;
	int searchSize;
	double noiseSig;
	double noiseMean;
	double h;
	bool color;
	bool testSuiteAddNoise;
    
	TestConfig() {
		initStandardConfig();
	}
    
	TestConfig(TestConfiguration conf) {
		switch(conf) {
			case TestConfigurationStandard:
			default:
				initStandardConfig();
		}
	}
    
private:
    void initStandardConfig() {
        kSize = 7;
        searchSize = 21;
        noiseSig = 20.0;
        h = 12.0 * noiseSig;
        // not 0 because we use a different method to add the noise. 0 equals half of the pixel value range
        noiseMean = 255.0/2.0;
        color = false;
        testSuiteAddNoise = true;
    }
};

#endif /* defined(__nlmxcode__TestConfig__) */
