# SParMorIA: Sludge Particle Morphological Image Analysis

FIJI/ImageJ macro which analyzes images of activated and granular sludge particles immoblized in agar. Supports the paper "Measuring the shape and size of activated sludge particles immobilized in agar with an open source software pipeline" submitted to [JOVE](https://www.jove.com/).

## Getting Started


### Prerequisites

* A recent copy of [FIJI](https://imagej.net/Fiji/Downloads).
* Preferably, a collection of images to be analyzed. Sample images can be found in the supporting infomration for the journal article.XXX linkXXX

### Installing

Installation consisits simply of placing the macro in the appropriate FIJI directory.
Under windows, edit the included ```install.bat``` so that ```macro_dir``` points to your local copy of FIJI and then run.
Alternately, the macro may be directly copied to ```\Fiji.app\macros```

## Running

Define the analysis parameters in a text file, according to the description given in ```examples\analysis\README.md```

Run from the command line:

```<FIJI-PATH>\ImageJ-win64.exe --console -macro SParMorIA-SludgeParticle_Morphological_Image_Analysis <paramsfile>```
where ```<FIJI-path>``` is the directory in which ImageJ-win64.exe is located and ```<paramsfile>``` the location of the text file describing the analysis setup.

CSV files and quality control images will be placed respectively in the ```results``` and ```overlays``` subdirectories of the specified ```output``` folder.

Example CSV files are located under ```examples\data```.
Example quality control images are available in the supporting infomration for the journal article.XXX linkXXX.

Images and particles failing quality control can be censored in a reproducible, non-destructive manner, see ```examples\censoring``` for R and Python examples.

Further data analysis, such as figure generation, can be carried out on the CSV data, see ```examples\figures``` for R and Python code.


## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags). 

## Authors

* **[Joseph E. Weaver](https://github.com/joeweaver/)** - *Main Developer*
* For authors of related work, see the journal article
* See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## Acknowledgments
* The FIJI and ImageJ teams for making image analysis freely accessible to all.
* [Billie Thompson](https://github.com/PurpleBooth) for providing a [template README](https://gist.githubusercontent.com/PurpleBooth/109311bb0361f32d87a2/raw/8254b53ab8dcb18afc64287aaddd9e5b6059f880/README-Template.md)
* Countless open source contributors
