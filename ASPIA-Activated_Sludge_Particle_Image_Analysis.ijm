macro "ASPIA: Activated Sludge Particle Image Analysis"{
        args = getArgument() 
        print(args); 
//Of historical interest, this whole macro was an attempt to make a an old hardcoded imageJ macro a bit
//more flexible.  As you can see below, argument parsing and such is extremely fun in the native macro. 
// language. Were it any more so, it might be wise to scrap and rewrite in python, or at least write an 
// argparse macro in python which then calls the meat of the image processing macro.

var inputFolder = ""
var outputFolder = ""

sayHi();
filestring=File.openAsString(args); 
rows=split(filestring, "\n"); 
for (i=0; i<rows.length; i++){
  args=split(rows[i],",");
  for (j=0; j<args.length; j++){
    arg=split(args[j],"=");
    argKey=arg[0];
	argVal=arg[1];
    print(argKey);
	print(argVal);
	if(argKey=="indir"){
		inputFolder = argVal;
	}
	if(argKey=="outdir"){
		outputFolder = argVal;
	}
  }
  processFolder(inputFolder,outputFolder);
}

function sayHi(){
	print("Hi\n");
}
	
function processFolder(readDir,writeDir){
	print("Proc folder");
	print(readDir);
    images = getFileList(readDir);
    print(images[1]);  
	for (i=0; i<images.length; i++) {
        inputPath = readDir + "\\" + images[i];
        write(inputPath);
		print(inputPath);
	    if(endsWith(inputPath,'.tif')){
	      open(inputPath);  
		  fname=images[i];          run("32-bit");
          //run("Enhance Local Contrast (CLAHE)", "blocksize=127 histogram=256 maximum=3 mask=*None*");
		  setOption("BlackBackground", true);
		  setAutoThreshold("RenyiEntropy");
		  run("Set Measurements...", "area mean min centroid perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction add redirect=None decimal=3");
		  //Set size to be roughly 50 um diameter
		  run("Analyze Particles...", "size=0.00002-Infinity show=Outlines display exclude clear include summarize in_situ");
		  selectWindow("Results");
	      resultsDir=writeDir+"\\"+"results";
		  print(resultsDir);
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