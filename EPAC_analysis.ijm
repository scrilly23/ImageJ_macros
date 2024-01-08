
    
//DJ Shiwarski 2014, ZY Weinberg 2017, SE Crilly 2019

//This code takes an interleaved multichannel image and calculates a ratio between two channels
//of the image. This is ideal for examining FRET changes over time. This is accomplished by:
// - All frames are background subtracted
// - Splitting initial stack into subchannels
// - A cell mask is created to filter out extraneous background
// - Channels to be ratioed are blurred to cancel out noise and diffusion between frames
// - A ratio image is calculated
// - User is prompted to draw an ROI around the image, and threshold.
// - Mean ratio within that ROI is returned across time dimension

//Before running this, set one ROI that is a small portion of background
//and one ROI that is the entire image

macro 'EPAC Analysis [E]' {
	rename("Original");
	setBatchMode(true);
	run("Duplicate...", "title=[EPAC Analysis] duplicate range=1-nSlices");
	selectWindow("Original")
	close()
	run("Set Measurements...", "  mean limit redirect=None decimal=9");

	//Uses ROIs selected earlier for background subtraction
	roiManager("Select", 0);
	roiManager("Remove Slice Info");
	roiManager("Select", 1);
	roiManager("Remove Slice Info");
		for (n= 1; n<=nSlices; n++) {
			selectWindow("EPAC Analysis");
			setSlice(n);
			roiManager("Select", 0);
			run("Measure");
			BG = getResult("Mean");
			roiManager("Select", 1);
			run("Subtract...", "value=BG slice");
		}
	//=======================================================================
	//assumes three channels, change ch here for different number of channels
	ch=3;
	fr=nSlices/ch;
	//=======================================================================

	selectWindow("EPAC Analysis")
	run("Stack to Hyperstack...", "order=xyczt(default) channels=ch slices=1 frames=fr display=Grayscale");

	//=======================================================================
	//this split assumes channel order is CFP > FRET > Receptor. 
	//Move these titles around if channels are in a different order
	selectWindow("EPAC Analysis")
		run("Split Channels");
	selectWindow("C1-EPAC Analysis");
		rename("EPAC CFP");
	selectWindow("C2-EPAC Analysis");
		rename("EPAC FRET");
	selectWindow("C3-EPAC Analysis");
		rename("EPAC Snap Label");
	//=======================================================================

	selectWindow("EPAC CFP");
	//generate mask from cell (we use CFP as it's usually our least noisy channel)
		run("Duplicate...", "title=[Mask] duplicate range=1-fr");
		selectWindow("Mask");		
		run("Gaussian Blur...", "sigma=2 stack");
		run("Convert to Mask", "method=Huang background=Dark calculate black");
	//convert mask to 0 or 1 so that we can multiply it into our FRET/CFP ratio and get rid of the background
	selectWindow("Mask");
		run("Divide...", "value=255 stack");

	//Gaussian blur images so as to remove variability due to diffusion
	selectWindow("EPAC FRET");
		run("Duplicate...", "title=[EPAC FRET for Ratio] duplicate range=1-fr");
	selectWindow("EPAC CFP");
		run("Duplicate...", "title=[EPAC CFP for Ratio] duplicate range=1-fr");
	selectWindow("EPAC FRET for Ratio");
		run("Gaussian Blur...", "sigma=2 stack");
	selectWindow("EPAC CFP for Ratio");
		run("Gaussian Blur...", "sigma=2 stack");

	//creates ratio image from FRET/CFP channel
		imageCalculator("Divide create 32-bit stack", "EPAC CFP for Ratio","EPAC FRET for Ratio");
		selectWindow("Result of EPAC CFP for Ratio");
		rename("EPAC CFP/FRET Ratio");

	//apply mask to final FRET image, then change lookup table to be pretty
	imageCalculator("Multiply create 32-bit stack", "EPAC CFP/FRET Ratio","Mask");
		selectWindow("Result of EPAC CFP/FRET Ratio");
		rename("Final CFP/FRET Image");
		run("Fire");

	//clean up workspace before final step
	selectWindow("Final CFP/FRET Image");	
		run("Clear Results");
	selectWindow("Mask");		
		run("Close");
	selectWindow("EPAC CFP/FRET Ratio");
		run("Close");
	selectWindow("EPAC FRET for Ratio");
		close();
	selectWindow("EPAC CFP for Ratio");
		close();
	run("Tile");
		selectWindow("EPAC Snap Label");
			run("Enhance Contrast", "saturated=0.35");
		selectWindow("EPAC FRET");
			run("Enhance Contrast", "saturated=0.35");
		selectWindow("EPAC CFP");
			run("Enhance Contrast", "saturated=0.35");
		selectWindow("Final CFP/FRET Image");
			run("Enhance Contrast", "saturated=0.1");

	setBatchMode("exit & display");
	run("Tile");
	
	//Loop for processing multiple ROIs (single cells) from an image
	keepGoing = true;
	currentROI = 2;
	setTool("freehand");
	do {
		waitForUser("Draw an ROI");
		run("Clear Results");
		selectWindow("Final CFP/FRET Image");
		roiManager("Select", currentROI);
		roiManager("Remove Slice Info");
		for (n= 1; n<=nSlices; n++) {
			selectWindow("Final CFP/FRET Image");
			setSlice(n);
			setThreshold(0.0200, 100.0000);
			run("Measure");
		}
		String.copyResults;
		currentROI = currentROI+1;
		keepGoing = getBoolean("Select another ROI?");
	} while (keepGoing);
}





