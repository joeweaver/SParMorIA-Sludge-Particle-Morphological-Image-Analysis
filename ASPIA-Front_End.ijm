macro "ASPIA: Front End"{
	var ASPIAinputFolder =getDirectory("PSD - Choose the input folder!");
	var ASPIAoutputFolder =getDirectory("PSD - Choose the output folder!");
	run("ASPIA-Activated Sludge Particle Image Analysis",ASPIAinputFolder)
}