macro "SParMorIA: Sludge Particle Morphological Image Analysis"{

// Pipeline described in "Measuring the shape and size of activated sludge 
// particles immobilized in agar with an open source software pipeline" 
// submitted to [JOVE](https://www.jove.com/)

// args should point to a file containing processing information.
// See params_example.txt
args = getArgument();

// Of historical interest, this whole macro was an attempt to make a an old 
// hardcoded imageJ macro a bit more flexible.  As you can see below, argument 
// parsing and such is extremely "fun" in the native macro language. Were it 
// any more so, it might be wise to scrap and rewrite in python, or at least 
// write an argparse macro in python which then calls the meat of the image 
// processing macro.

/////////////////////////////////////////////////////////////////////////////
// Default parameters
/////////////////////////////////////////////////////////////////////////////
List.set("gParam_useCLAHE", "NO");
List.set("gParam_outputFolder", "inputbase");
List.set("gParam_minDiamMicrons", "50");
List.set("gParam_thresholdmethod", "Otsu");
  // Others which work well:
  //   "Default","Intermodes","IsoData","IJ_IsoData","Li","Minimum","Moments",
  //   "RenyiEntropy","Triangle","Yen"
List.set("gParam_darkBackground", "true");  //or "false"
List.set("gParam_fontSize","NONE"); //Try to guess font size, or specify as pt 

/////////////////////////////////////////////////////////////////////////////
// Define useful constants
/////////////////////////////////////////////////////////////////////////////
List.set("sq_um_to_sq_cm", "0.00000001");
List.set("sq_um_to_sq_m" , "0.000000000001");
List.set("sq_um_to_sq_um" , "1"); //seems silly, but works with code
List.set("sq_um_to_sq_pixel" , "1"); //understood that min-area is in px


/////////////////////////////////////////////////////////////////////////////
// Argument and parameter parsing
/////////////////////////////////////////////////////////////////////////////
filestring = File.openAsString(args); 
rows = split(filestring, "\n");

// Each line can be a comment, a set of global parameters, or directions for
// specific input folders. Right now, there is no way to specify settings for 
// individual images.
for (i = 0; i < rows.length; i++){
  // Found a comment line
  if("#" == substring(rows[i], 0, 1)){
    print("Found comment: " + rows[i]);
  }
  // All non comment lines are comma-separated parameters and may specifiy
  // global parameters or input folders with optional parameter overrides.
  // The second case is identified by the first paramter being "indir"
  else{ 
    // looking for "indir=" at beginning of row to identify parameter types
    // #TODO be more forgiving of spaces between =
    isGlobal = ("indir=" != substring(rows[i], 0, 6));
    
    if(isGlobal){ 
      print("Setting global params.");
      readParams(rows[i], "gParam_");
    }
    else{
      resetLocals();
      readParams(rows[i], "");
      
      //Process the input folder
      processFolder();
    }
  }
}

/////////////////////////////////////////////////////////////////////////////
// Read key/value pairs from a line and store them in the list.
/////////////////////////////////////////////////////////////////////////////
function readParams(line, prefix){
  // #TODO gracefully handle blank lines and other format breaking issues
  // Example, at least have an informative dialog box with line causing
  // error.  This would've helped with malformed double ",," debugging.
  lineArgs = split(line, ",");
  for (j = 0; j < lineArgs.length; j++){
    arg=split(lineArgs[j], "=");
    print("Using global option. Key: " + arg[0] + " val: " + arg[1]);
    List.set(prefix + arg[0], arg[1]);
  }
}

/////////////////////////////////////////////////////////////////////////////
// Reset all local args to global values. 
// Avoids using local args from otherfolders.
/////////////////////////////////////////////////////////////////////////////
function resetLocals(){
  // I don't immediately see an easy way to iterate through the list.
  // #TOD find a less brute force reset
  List.set("useCLAHE", List.get("gParam_useCLAHE"));
  List.set("outdir", List.get("gParam_outdir")); 
  List.set("minDiamMicrons", List.get("gParam_minDiamMicrons")); 
  List.set("thresholdmethod", List.get("gParam_thresholdmethod"));
  List.set("darkBackground", List.get("gParam_darkBackground"));
  List.set("fontSize", List.get("gParam_fontSize"));
}

/////////////////////////////////////////////////////////////////////////////
// Process all the images in a specified input folder and save results.
// Note on lack of args. I prefer to pass args to functions, but List appears
// global, so there's no need here
/////////////////////////////////////////////////////////////////////////////
function processFolder(){
  readDir = List.get("indir");
  writeDir = List.get("outdir");
  images = getFileList(readDir);
  
  // Process folder image by image
  for (i = 0; i < images.length; i++){
    inputPath = readDir + "\\" + images[i];
    // Images must have .tif extension to be recognized
    if(endsWith(inputPath, '.tif')){
      open(inputPath);
      fname = images[i];
      
      // All operations assume 32 bit images
      run("32-bit");

      if("YES" == toUpperCase(List.get("useCLAHE"))){
        run("Enhance Local Contrast (CLAHE)", 
            "blocksize=127 histogram=256 maximum=3 mask=*None*");
      }

      // Define thresholding method
      setOption("BlackBackground", 
                ("TRUE" == toUpperCase(List.get("darkBackground"))));
      setAutoThreshold(List.get("thresholdmethod"));
      run("Set Measurements...", "area mean min centroid perimeter" +
           " bounding fit shape feret's integrated median skewness" +
           " kurtosis area_fraction add redirect=None decimal=3");
    
    
      //Determine minimum size particle to observe
      getPixelSize(unit, pw, ph, pd);
      minDiamUm = parseInt(List.get("minDiamMicrons"));
      minArea = minDiamUm*minDiamUm/4*3.14159265;//3.14159265 * ((minDiamUm / 2)^2); //sq microns
      if(pw != ph){
        // TODO pick reasonable default or interpretation for minimum 
        // particle size when pixels are not square
        exit("This macro does not support pixels that are not square.");
      }

      convFactor = List.get("sq_um_to_sq_" + unit);
      if( "" == convFactor){
        exit("Don't know how to support pixel size given as unit: " + unit);
      }
      size = parseFloat(convFactor) * minArea;
      // #TODO warn if min area will give < ~ 25 px per side, error if < 1)
      // Determine our font size based on either min particle size or as
      // specified in the params file.
      if("NONE" == toUpperCase(List.get("fontSize"))){
        pxdiam = minDiamUm * sqrt(convFactor) / pw;
        fontsize = maxOf(48, pxdiam / 0.75);
      }
      else{
        fontsize = parseInt(List.get("fontSize"));
      }

      // No need to convert to pixels (e.g. pw or ph). "Analyze particles",
      // as called here, understands the unit param and does the conversion.
      // Perform image analysis
      run("Analyze Particles...", "size=" + size + "-Infinity" + 
          " show=[Bare Outlines] display add exclude clear summarize");

      // Add legible labels to the outlined detected particles
      run("Labels...", "color=black font=" + fontsize + " show"); 

      // Use the ROI manager and color channesl to create a high contrast
      // composite overlay for QC checking.
      // This is, charitably, "acrobatic" and could be simplified.
      roiManager("Set Color", "black");
      roiManager("Set Line Width", 5);
      run("Flatten");
      run("View 100%");
      im1 = getInfo("window.title");
      open(inputPath);
      selectWindow(fname);
      run("RGB Color");
      run("Split Channels");
      selectWindow(fname + " (green)");
      run("View 100%");
      im2 = getInfo("window.title");
      imageCalculator("Add create 32-bit", im1, im2);
      run("View 100%");
      im3 = getInfo("window.title");
      run("8-bit");
      run("Merge Channels...", "c1=[" + fname + " (green)" + "] c2=[" +
          im3 + "] c3=[" + fname + " (green)" + "] create");
      selectWindow("Composite");
      run("RGB Color");
      run("8-bit Color", "number=256");
      run("View 100%");
      imfinal = getInfo("window.title");
      
      // Write numeric results
      // # TODO append unit to results and/or make target unit a parameter?
      selectWindow("Results");
      if("inputbase" == writeDir){
        writeDir=readDir + "\\output";
      }
      if(!File.exists(writeDir)){
        File.makeDirectory(writeDir);
      }
      resultsDir = writeDir + "\\"+"results";
      if(!File.exists(resultsDir)){
        File.makeDirectory(resultsDir);
      }
      saveAs("Results", resultsDir + "\\" + fname + "_PSD.csv");

      // Write overlay for QC
      selectWindow(imfinal);
      overlayDir = writeDir + "\\" + "overlays";
      if(!File.exists(overlayDir)){
        File.makeDirectory(overlayDir);
      }

      saveAs("Gif", overlayDir + "\\" + fname + "_overlay.gif");
      
      // Cleanup after ourselves
      run("Close All");
      while (nImages > 0) { 
        selectImage(nImages); 
        lose(); 
      } 
    }
  }  
}
}