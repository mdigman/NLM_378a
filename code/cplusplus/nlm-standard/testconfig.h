#ifndef TEST_CONFIG_H
#define TEST_CONFIG_H

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
		noiseSig = 20.0 / 255.0;
		h = 12.0 * noiseSig;
		noiseMean = 0.0;
		color = false;
		testSuiteAddNoise = true;
	}
};

#endif