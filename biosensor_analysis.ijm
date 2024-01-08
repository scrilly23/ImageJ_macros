
    
//DJ Shiwarski 2014, ZY Weinberg 2017, SE Crilly 2019

//This code takes an interleaved multichannel image and calculates the integrated density in both channels
//within user-defined ROIs. Ideal for measuring changes in fluorescent protein localization over time.
// - Splitting initial stack into subchannels.
// - A mask corresponding to a fiduciary marker for ROI is created.
// - Mask is applied to both channels.
// - User is prompted to draw an ROI around the regions of interest.
// - Mean intensity and integrated density is returned for each ROI.

macro 'Sensor Analysis [E]' {
	rename("Original");
	setBatchMode(true);
	run("Duplicate...", "title=[Sensor Analysis] duplicate range=1-nSlices");
	selectWindow("Original")
	close()
	run("Set Measurements...", "  mean integrated density limit redirect=None decimal=9");

	//=======================================================================
	//assumes two channels, change ch here for different number of channels
	ch=2;
	fr=nSlices/ch;
	//=======================================================================

	selectWindow("Sensor Analysis")
	run("Stack to Hyperstack...", "order=xyczt(default) channels=ch slices=1 frames=fr display=Grayscale");

	//=======================================================================
	//this split assumes channel order is Receptor > Sensor. 
	//Move these titles around if channels are in a different order
	selectWindow("Sensor Analysis")
		run("Split Channels");
	selectWindow("C1-Sensor Analysis");
		rename("Receptor");
	selectWindow("C2-Sensor Analysis");
		rename("Sensor");
	//=======================================================================

	selectWindow("Receptor");
	//generate mask from Receptor channel using Auto Local threshold
	//masking method specific for image/applications-try other methods if this performs poorly for your types of images
		run("Duplicate...", "title=[Mask] duplicate range=1-fr");
		selectWindow("Mask");		
		run("8-bit");
		run("Auto Local Threshold", "method=Bernsen radius=15 parameter_1=0 parameter_2=0 white stack");
	//convert mask to 0 or 1 so that we can multiply it into our Sensor and get sensor in the Golgi
	selectWindow("Mask");
		run("Divide...", "value=255 stack");
		run("16-bit");

	//apply mask to Receptor image
	imageCalculator("Multiply create 32-bit stack", "Receptor","Mask");
		selectWindow("Result of Receptor");
		rename("Thresholded Receptor");
	
	//apply mask to Sensor image
	imageCalculator("Multiply create 32-bit stack", "Sensor","Mask");
		selectWindow("Result of Sensor");
		rename("Sensor in Golgi");

	//clean up workspace before final step
	selectWindow("Mask");		
		run("Close");
	run("Tile");
		selectWindow("Receptor");
			run("Enhance Contrast", "saturated=0.35");
		selectWindow("Sensor");
			run("Enhance Contrast", "saturated=0.35");
		selectWindow("Thresholded Receptor");
			run("Enhance Contrast", "saturated=0.35");
		selectWindow("Sensor in Golgi");
			run("Enhance Contrast", "saturated=0.35");

	setBatchMode("exit & display");
	run("Tile");
	
	//Loop for processing multiple ROIs (single cells) from an image
	keepGoing = true;
	currentROI = 2;
	setTool("freehand");
	do {
		waitForUser("Draw an ROI");
		run("Clear Results");
		selectWindow("Sensor in Golgi");
		roiManager("Select", 0);
		roiManager("Remove Slice Info");
		for (n= 1; n<=nSlices; n++) {
			selectWindow("Sensor in Golgi");
			setSlice(n);
			setAutoThreshold("Huang dark");
			run("Measure");
		}
		String.copyResults;
		currentROI = currentROI+1;
		keepGoing = getBoolean("Select another ROI?");
	} while (keepGoing);
}





