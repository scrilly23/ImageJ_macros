II//--------------------------------------------------------------------------------
//DJ Shiwarski 2015, SE Crilly, W Ko 2018, SE Crilly 2020

// This macro was designed to analyze localization of expressed receptor (GPCR) and biosensor
// in a region of a cell defined by a fiduciary marker (TGN-38 Golgi marker).

//--------------------------------------------------------------------------------

macro "Analyze GFP-GPCR Golgi Retention and sensor loc  [F5]"
{

//Opening file and renaming slices. Assumes TGN-38, sensor, GPCR order	

open();
rename("GFP-GPCR Golgi Retention");
run("Stack to Images");
selectWindow("GFP-GPCR-0001");
rename("TGN-38");
run("Enhance Contrast...", "saturated=0.35 normalize");
selectWindow("GFP-GPCR-0002");
rename("sensor");
run("Enhance Contrast...", "saturated=0.35");
selectWindow("GFP-GPCR-0003");
rename("GFP-GPCR");
run("Enhance Contrast...", "saturated=0.35 normalize");

//Thresholding the GPCR channel using an Auto Local Threshold mask

run("Duplicate...", "title=[GFP-GPCR Mask]");
run("8-bit");
run("Auto Local Threshold", "method=Phansalkar radius=15 parameter_1=0 parameter_2=0");
setOption("BlackBackground", false);
run("Convert to Mask");
run("Divide...", "value=255");
run("16-bit");
imageCalculator("Multiply create", "GFP-GPCR","GFP-GPCR Mask");
selectWindow("Result of GFP-GPCR");
selectWindow("GFP-GPCR Mask");
close();
selectWindow("Result of GFP-GPCR");

//Creating the Golgi mask using a standard Auto Threshold

selectWindow("TGN-38");
run("Duplicate...", "title=[TGN-38 Mask]");
setAutoThreshold("IsoData dark");
//run("Threshold...");
setOption("BlackBackground", false);
run("Convert to Mask");
run("Erode");
run("Erode");
run("Dilate");
run("Dilate");
run("Divide...", "value=255");
run("16-bit");

//Creating an inverse TGN-38 mask to calculate sensor fluorescence outside the Golgi region

run("Duplicate...", "title=[TGN-38 inverse Mask]");
selectWindow("TGN-38 inverse Mask");
run("Invert");

//Applying TGN-38 Mask to thresholded GPCR channel to get GPCR in the Golgi

imageCalculator("Multiply create", "Result of GFP-GPCR","TGN-38 Mask");
selectWindow("Result of Result of GFP-GPCR");
rename("GPCR in TGN");
setAutoThreshold( "Huang dark" );
selectWindow("Result of GFP-GPCR");
rename("GPCR thresholded");
setAutoThreshold( "Huang dark" );

//Thresholding sensor channe using an Auto Local Threshold mask

selectWindow("sensor");
run("Duplicate...", "title=[sensor Mask]");
run("Enhance Contrast...", "saturated=0.35");
run("8-bit");
run("Auto Local Threshold", "method=MidGrey radius=15 parameter_1=0 parameter_2=0");
setOption("BlackBackground", false);
run("Convert to Mask");
run("Divide...", "value=255");
run("16-bit");
imageCalculator("Multiply create", "sensor","sensor Mask");
selectWindow("Result of sensor");
selectWindow("sensor Mask");
close();

//Applying TGN-38 mask to thresholded sensor to get sensor in TGN

imageCalculator("Multiply create", "Result of sensor","TGN-38 Mask");
selectWindow("Result of Result of sensor");
rename("sensor in TGN");
setAutoThreshold( "Huang dark" );
selectWindow("TGN-38 Mask");
close();

//Applying TGN-38 inverse mask to thresholded sensor to get sensor everywhere else in cell

imageCalculator("Multiply create", "Result of sensor","TGN-38 inverse Mask");
selectWindow("Result of Result of sensor");
rename("sensor NOT in TGN");
setAutoThreshold( "Huang dark" );
selectWindow("Result of sensor");
rename("sensor thresholded");
setAutoThreshold( "Huang dark" );
selectWindow("TGN-38 inverse Mask");
close();


//Cleaning up workspace

selectWindow("sensor");
selectWindow("sensor thresholded");
selectWindow("sensor in TGN");
selectWindow("sensor NOT in TGN");
run("Tile");

//---------------------------------------------------------------------------------
// Pause to select the ROIs to be analyzed
// Draw ROI's around whole cells
// paste accordingly in Excel.
//
//---------------------------------------------------------------------------------

selectWindow("GFP-GPCR");

setTool("freehand");

waitForUser("Select ROIs")

//---------------------------------------------------------------------------------
// Selection of all the ROIs to measure and copy the measurements to the clipboard 
// Make the selection of the ROIs on the Original image for accuracy

// The macro will measure from the thresholded image
// Always check to make sure measurements are limited to threshold
//Check the thresholded image and adjust at this point if required
//
// Once completed, the Results can be pasted directly into Excel or other software
//---------------------------------------------------------------------------------

run("Set Measurements...", "area mean integrated limit redirect=None decimal=2");

selectWindow("GPCR thresholded");

roiManager("Select All");
	roiManager("Measure");

selectWindow("GPCR in TGN");

roiManager("Select All");
	roiManager("Measure");

selectWindow("sensor thresholded");

roiManager("Select All");
	roiManager("Measure");

selectWindow("sensor in TGN");

roiManager("Select All");
	roiManager("Measure");

selectWindow("sensor NOT in TGN");

roiManager("Select All");
	roiManager("Measure");

String.copyResults

waitForUser("Paste the results into Excel \n then click OK to Clear All")


//---------------------------------------------------------------------------------
// Clear all of the windows, results, and ROIs
// Clicking OK will Clear everything and prepare for the next analysis 
//---------------------------------------------------------------------------------

roiManager("Select All");
	roiManager("Delete");

run("Clear Results");

run("Close All");

}


