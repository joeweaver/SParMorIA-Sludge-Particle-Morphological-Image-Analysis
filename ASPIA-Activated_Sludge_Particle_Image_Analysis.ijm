macro "ASPIA: Activated Sludge Particle Image Analysis"{
s=getArgument();
print(s);processFolder(ASPIAinputFolder,ASPIAoutputFolder);
	
  function processFolder(readDir,writeDir){
    images = getFileList(readDir);
      for (i=0; i<images.length; i++) {
        inputPath = readDir + "\\" + images[i];
        write(inputPath);
	    if(endsWith(inputPath,'.tif')){
	      open(inputPath);
	      fname = getTitle();
	      write(fname + " (blue)");
	      run("Split Channels");
	      selectWindow(fname + " (blue)");
	      close();		
	      imageCalculator("Average create 32-bit", fname + " (red)",fname + " (green)");
		  selectWindow(fname + " (green)");
		  close();
		  selectWindow(fname + " (red)");
		  close();
		  selectWindow("Result of "+ fname + " (red)");
          //run("Enhance Local Contrast (CLAHE)", "blocksize=127 histogram=256 maximum=3 mask=*None*");
		  setOption("BlackBackground", true);
		  setAutoThreshold("RenyiEntropy");
		  run("Set Measurements...", "area mean min centroid perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction add redirect=None decimal=3");
		  //Set size to be roughly 50 um diameter
		  run("Analyze Particles...", "size=0.00002-Infinity show=Outlines display exclude clear include summarize in_situ");
		  selectWindow("Results");
	      saveAs("Results",outputFolder+"\\"+fname+"_PSD.csv");
		  run("Invert");
		  open(inputPath);
		  selectWindow(fname);
		  run("Add Image...", "image=[Result of "+fname+" (red)] x=0 y=0 opacity=60 zero");
		  run("8-bit");
		  run("Scale...", "x=.25 y=.25 width=1024 height=822 interpolation=Bicubic average create");
          saveAs("Gif",writeDir +"\\"+fname+"_overlay.gif");
		  run("Close All");
		  while (nImages>0) { 
			selectImage(nImages); 
			close(); 
		  } 
	  }
    }  
  }
}