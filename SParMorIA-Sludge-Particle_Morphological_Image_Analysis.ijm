macro "SParMorIA: Sludge Particle Morphological Image Analysis"{

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
List.set("gParam_useCLAHE", "YES");
List.set("gParam_outputFolder", "inputbase");

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
    
    parPrefix = "";
    
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
}

// BEGIN SECTION ACTUAL IMAGE PROCESSING
// note on lack of args. I prefer to pass args to functions, but List appears
// global, so there's no need here
function processFolder(){
  readDir = List.get("indir");
  writeDir = List.get("outdir");
  images = getFileList(readDir);
  for (i = 0; i < images.length; i++){
    inputPath = readDir + "\\" + images[i];
    if(endsWith(inputPath, '.tif')){
      open(inputPath);
      fname = images[i];
      run("32-bit");

      if("YES" == toUpperCase(List.get("useCLAHE"))){
        run("Enhance Local Contrast (CLAHE)", 
            "blocksize=127 histogram=256 maximum=3 mask=*None*");
      }

      setOption("BlackBackground", true);
      setAutoThreshold("Otsu");
      run("Set Measurements...", "area mean min centroid perimeter" +
           " bounding fit shape feret's integrated median skewness" +
           " kurtosis area_fraction add redirect=None decimal=3");
    
      // Set size to be roughly 50 um diameter
      getPixelSize(unit, pw, ph, pd);
      minArea = 314/1963.495408;
      if(pw != ph){
        // TODO pick reasonable default or interpretation for minimum 
        // particle size when pixels are not square
        exit("This macro does not support pixels that are not square.");
      }
      else{
        // #TODO use list to store conversion factors
        convFactor = 1;
        if("cm" == unit){
            convFactor=0.00000001;
        }
        else if("um" == unit){
            convFactor=1;
        }
        else if("m" == unit){
            convFactor=0.000000000001
        }
        else if("pixel" == unit){
            convFactor=1
        }
        else{
            exit("Don't know how to support pixel size using the unit: "
                 + unit);
        }
        size = convFactor * minArea;
      }
      run("Analyze Particles...", "size=" + size + 
              "-Infinity show=Outlines display exclude clear summarize" +
              " in_situ");
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
      run("Invert");
      open(inputPath);
      selectWindow(fname);
      baseName = substring(fname, 0, lengthOf(fname) - 4);
      run("Add Image...", "image=["  +baseName +
              "-1.tif] x=0 y=0 opacity=60 zero");
      run("8-bit");

      overlayDir = writeDir + "\\" + "overlays";
      if(!File.exists(overlayDir)){
        File.makeDirectory(overlayDir);
      }
      saveAs("Gif", overlayDir + "\\" + baseName + "_overlay.gif");
      run("Close All");
      while (nImages > 0) { 
        selectImage(nImages); 
        lose(); 
      } 
    }
  }  
}
}