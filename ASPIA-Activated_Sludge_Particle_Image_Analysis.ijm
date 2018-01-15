macro "ASPIA: Activated Sludge Particle Image Analysis"{
//args should point to a file containing processing information. See params_example.txt
args = getArgument() 

//Of historical interest, this whole macro was an attempt to make a an old hardcoded imageJ macro a bit
//more flexible.  As you can see below, argument parsing and such is extremely fun in the native macro. 
// language. Were it any more so, it might be wise to scrap and rewrite in python, or at least write an 
// argparse macro in python which then calls the meat of the image processing macro.

//DEFAULT PARAMETERS
gParam_useCLAHE="NO";
gParam_outputFolder="inputbase";

//BEGIN SECTION ARGUMENT AND PARAMETER PARSING
filestring=File.openAsString(args); 
rows=split(filestring, "\n"); 
//each line can be a comment, a set of global parameters, or directions for specific input folders
//right now, there is no way to specific settings for individual images.
for (i=0; i<rows.length; i++){
  //# indicates a comment
  if("#"==substring(rows[i],0,1)){
	print("Found comment: "+rows[i]);
  }
  else{
	//all other lines are comma-separated parameters
	// if the first arg is "inputFolder" we are processing a specific folder
    // otherwise, parameters take global effect.  Global parameters are superceded by folder specific instructions and are overwritten if redefined in a later global param line
	lineArgs=split(rows[i],",");
    //looking for "indir=" at beginning of row to identify parameter types
    //no indir found, so setting global param
	if("indir="!=substring(rows[i],0,6)){
		for (j=0; j<lineArgs.length; j++){
			arg=split(lineArgs[j],"=");
			argKey=arg[0];
			argVal=arg[1];
			print("Using global option. Key: "+argKey+" val: "+argVal);
			//doing something hackey here. afaik, ij1 macros don't support dicts
			if(argKey=="useCLAHE"){
				gParam_useCLAHE = toUpperCase(argVal);
			}
			if(argKey=="outdir"){
				gParam_outputFolder = argVal;
			}
		 }
    }
	//directory-specific options
    else{
		//reset params to global values
		local_useCLAHE=gParam_useCLAHE;
		local_outputFolder=gParam_outputFolder;
		
		//read in all other params
		for (j=0; j<lineArgs.length; j++){
			arg=split(lineArgs[j],"=");
			argKey=arg[0];
			argVal=arg[1];
			if(argKey=="indir"){
				inputFolder = argVal;
			}
			if(argKey=="outdir"){
				local_outputFolder = argVal;
			}
			if(argKey=="useCLAHE"){
				local_useCLAHE = argVal;
			}
		  }
        
		//where the work actually gets done
		processFolder(inputFolder,local_outputFolder,local_useCLAHE);
	}
  }
}

//BEGIN SECTION ACTUAL IMAGE PROCESSING	
function processFolder(readDir,writeDir,useCLAHE){
    images = getFileList(readDir);
	for (i=0; i<images.length; i++) {
        inputPath = readDir + "\\" + images[i];
        //write(inputPath);
	    if(endsWith(inputPath,'.tif')){
	      open(inputPath);  
		  fname=images[i];          run("32-bit");

		if("YES"==useCLAHE){
			run("Enhance Local Contrast (CLAHE)", "blocksize=127 histogram=256 maximum=3 mask=*None*");
		}	

		  setOption("BlackBackground", true);
		  setAutoThreshold("RenyiEntropy");
		  run("Set Measurements...", "area mean min centroid perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction add redirect=None decimal=3");
		  //Set size to be roughly 50 um diameter
			getPixelSize(unit,pw,ph,pd);
			minArea=1963.495408;
			if(pw!=ph){
				//TODO pick reasonable default or interpretation for minimum particle size when pixels are not square
				exit("This macro does not support images with pixels that are not square.");
			}
			else{
				convFactor=1;
				if("cm"==unit){
					convFactor=0.00000001;
				}
				else if("um"==unit){
					convFactor=1;
				}
				else if("m"==unit){
					convFactor=0.000000000001
				}
				else if("pixel"==unit){
					convFactor=1
				}
				else{
					exit("Don't know how to support pixel size info using the unit: "  + unit);
				}
				size=convFactor*minArea;
			}
		  run("Analyze Particles...", "size="+size+"-Infinity show=Outlines display exclude clear summarize in_situ");
		  selectWindow("Results");
		  if("inputbase"==writeDir){
			writeDir=readDir + "\\output";
		  }
          if(!File.exists(writeDir)){
			File.makeDirectory(writeDir);
		  }
	      resultsDir=writeDir+"\\"+"results";
          if(!File.exists(resultsDir)){
			File.makeDirectory(resultsDir);
		  }
	      saveAs("Results",resultsDir+"\\"+fname+"_PSD.csv");
		  run("Invert");
		  open(inputPath);
		  selectWindow(fname);
		  baseName=substring(fname,0,lengthOf(fname)-4);
		  run("Add Image...", "image=["+baseName+"-1.tif] x=0 y=0 opacity=60 zero");
		  run("8-bit");
		 // run("Scale...", "x=.25 y=.25 width=1024 height=822 interpolation=Bicubic average create");
	      overlayDir=writeDir+"\\"+"overlays";
          if(!File.exists(overlayDir)){
			File.makeDirectory(overlayDir);
		  }
          saveAs("Gif",overlayDir +"\\"+baseName+"_overlay.gif");
		  run("Close All");
		  while (nImages>0) { 
			selectImage(nImages); 
			close(); 
		  } 
	  }
    }  
  }
}