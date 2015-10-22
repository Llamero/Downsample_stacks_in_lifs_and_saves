//Ask user to choose the input and output directories
directory = getDirectory("Choose input directory");
fileList = getFileList(directory);
outputDirectory = getDirectory("Choose output directory");


//----------------------------------------Prompt user for how they want to process data-------------------------------
//Count the maximum number of positions and slices in dataset
run("Bio-Formats Macro Extensions");

//Create checkbox to allow user to set downsampling options
//There are 7 options, so make label and default array of 7
n = 7;
labels = newArray(n);
defaults = newArray(n);

labels[0] = "Equalize Stack Intensity";
defaults[0] = true;
labels[1] = "Run 3D Median Filter";
defaults[1] = true;
labels[2] = "Downsample Voxel Dimsensions";
defaults[2] = true;
labels[3] = "Autocontrast Stack";
defaults[3] = true;
labels[4] = "Downsample Bit Depth to 8-Bit";
defaults[4] = true;
labels[5] = "Generate a Maximum Intensity Projection (MIP)";
defaults[5] = true;
labels[6] = "Add steps to output file name";
defaults[6] = true;

//Create check box prompt
Dialog.create("How would you like to process the stacks?");
Dialog.addCheckboxGroup(n,1,labels,defaults);
Dialog.show();

//Save state of checked boxes
Equalize = Dialog.getCheckbox();
Median = Dialog.getCheckbox();
Dimensions = Dialog.getCheckbox();
Autocontrast = Dialog.getCheckbox();
BitDepth = Dialog.getCheckbox();
MIP = Dialog.getCheckbox();
addName =  Dialog.getCheckbox();

//Ask user to verify parameters for checked methods
if (Median == 1){
	medianDim = getNumber("By what factor would you like to do a 3D median filter?", 2); 
}

if (Dimensions == 1){
	voxelDim = getNumber("By what factor would you like to downsample voxel dimensions?", 2); 
}

if (Autocontrast == 1){
	autoSaturation = getNumber("What percent saturated pixels would you like to use for autocontrast?", 0.01); 
}

setBatchMode(true);

//--------------------------------Open each file and process containing stacks accordingly----------------------------------
for (i=0; i<fileList.length; i++) {
	file = directory + fileList[i];
	Ext.setId(file);

	//Measure number of series in file
	Ext.getSeriesCount(nStacks);

	//Open all stacks from set of lif files, one stack at a time
	for(a=1; a<nStacks+1; a++) {	

		//Show/update progress to user in a bar 
		progress = (a*(i+1)-1)/(fileList.length*nStacks);
		showProgress(progress);
		
		run("Bio-Formats Importer", "open=file color_mode=Default view=[Standard ImageJ] stack_order=Default use_virtual_stack series_"+d2s(a,0)); 
		
		//Get name of opened stack
		title = getTitle();
		getDimensions(width, height, channels, slices, frames);

		if (slices > 1) {
			//Perform stack intensity equalization if checked
			if (Equalize == 1) {
				run("Set Slice...", "slice="+1);
				for(l=0; l<nSlices+1; l++) {
					getStatistics(count, sliceMean, min, max, std);
					if(l==0){
						sliceMean1=sliceMean;
						}
					int_ratio=sliceMean1/sliceMean;
					run("Multiply...", "slice value="+int_ratio);
					run("Next Slice [>]");
				}
				
				//Modify title name to reflect step
				if (addName == 1) {
					title = title + " - Equalized";
				}
	
			}
	
			//Perform 3D median filter if checked
			if (Median == 1) {
				run("Median 3D...", "x=" + medianDim + " y="  + medianDim + " z="  + medianDim);
	
				//Modify title name to reflect step
				if (addName == 1) {
					title = title + " - " + medianDim + "x" + medianDim + "x" + medianDim + " Median";
				}
			}
			
			//Downsample dimensions if checked
			if (Dimensions == 1) {
				newWidth = width/voxelDim;
				newHeight = height/voxelDim;
				newDepth = 	slices/voxelDim;
	
				run("Size...", "width=" + newWidth + " height=" + newHeight + " depth=" + newDepth + " constrain average interpolation=Bicubic");		
				
				//Modify title name to reflect step
				if (addName == 1) {
					title = title + " -  Voxel Reduced " + voxelDim + "x";	
				}		
			}
			//Autocontrast stack if checked
			if (Autocontrast == 1){
				run("Enhance Contrast...", "saturated=" + autoSaturation + " normalize process_all use");
	
				//Modify title name to reflect step
				if (addName == 1) {
					title = title + " - Autocontrast";	
				}	
			}
	
			//Change bit depth to 8-bit if checked
			if (BitDepth == 1){
				run("8-bit");
				
				//Modify title name to reflect step
				if (addName == 1) {
					title = title + " - 8-bit";	
				}
			}
			//Create MIP if checked
			if (MIP == 1){
				run("Z Project...", "projection=[Max Intensity]");
				
				//Modify title name to reflect step
				if (addName == 1) {
					title = title + " - MIP";	
				}
			}
			
		}

		//Save and close new stack
		saveAs("Tiff", outputDirectory + title);
		close("*");
	}	
}
	
setBatchMode(false);