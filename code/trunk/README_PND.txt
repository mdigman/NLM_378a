1) Description
-----------------------------------------------------------------------------------
This file explains the files associated with the Principal Neighborhood
Dictionaries (PND) variant of the Non-Local Means algorithm, as well as additional 
PND variants.

(2) details the Matlab test scripts which are used to perform PND and variants on 
    test images with varying settings.

(3) details the Matlab function implementations of the PND algorithm and variants
-----------------------------------------------------------------------------------


2) Scripts to perform PND and PND-variants on images
-----------------------------------------------------------------------------------
NOTES: 	- Called in Matlab without arguments (i.e. "> run_PND")
	- All parameters (i.e. standard deviation of noise) are set in these files

Main Test Functions
runStuff_PND.m                           -> runs non-color PND functions
					    	- deNoise2D_PND
						- deNoise2D_PND_modPrior
						- deNoise2D_PND_modPrior2
runStuff_PND_color.m                     -> runs color PND functions with the same
						noise values for each channel (RGB)
						- deNoise2D_PND_color
						- deNoise2D_PND_Euc_color
						- deNoise2D_PND_modPrior_color
						- deNoise2D_PND_modPrior2_color
						- deNoise2D_PND_Euc_modPrior_color
runStuff_PND_color_randNoise.m           -> runs color PND functions with different
						noise values for each channel (RGB)
						- deNoise2D_PND_color
						- deNoise2D_PND_Euc_color
						- deNoise2D_PND_modPrior_color
						- deNoise2D_PND_modPrior2_color
						- deNoise2D_PND_Euc_modPrior_color

Individual Test Functions
run_PND.m                                -> runs deNoise2D_PND.m
run_PND_color.m                          -> runs deNoise2D_PND_color.m
run_PND_Bayes.m                          -> runs deNoise2D_PND_Bayes.m
run_PND_modPrior.m                       -> runs deNoise2D_PND_modPrior.m
run_PND_modPrior_color.m                 -> runs deNoise2D_PND_modPrior_color.m
run_PND_modPrior2.m                      -> runs deNoise2D_PND_modPrior2.m
run_PND_modPrior2_color.m                -> runs deNoise2D_PND_modPrior2_color.m
-----------------------------------------------------------------------------------

3) PND and PND-variant functions
-----------------------------------------------------------------------------------
deNoise2D_PND.m                          -> PND Implementation
deNoise2D_PND_color.m                    -> PND for RBG colorspace
deNoise2D_PND_Bayes.m                    -> PND w/ Bayesian Weighting
deNoise2D_PND_Euc.m                      -> PND w/ Euclidean distance weighting
deNoise2D_PND_Euc_color.m                -> PND_Euc for RGB colorspace
deNoise2D_PND_modPrior.m                 -> PND w/ modified prior weighting where 
					    	cross-correlation is computed in
						the original image space
deNoise2D_PND_modPrior_color.m           -> PND_modPrior for RGB colorspace
deNoise2D_PND_modPrior2.m                -> PND w/ modified prior weighting where
					    	cross-correlation is computed in
						the Principal Component Analysis 
						(PCA) subspace
deNoise2D_PND_modPrior2_color.m          -> PND_modPrior2 for RGB colorspace
deNoise2D_PND_Euc_modPrior.m             -> PND w/ Euclidean distance and Modified 
						Prior weighting
deNoise2D_PND_Euc_modPrior_color.m       -> PND_Euc_modPrior for RGB colorspace
deNoise2D_PND_PCA.m                      -> Helper function to perform Principal 
						Component Analysis (PCA) on image 
						neighborhoods
deNoise2D_PND_parallel.m                 -> Helper function to compute number of
						principal components to use in PND
-----------------------------------------------------------------------------------
