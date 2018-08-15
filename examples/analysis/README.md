# Introduction
All SParMorIA anlyses are defined by a text based parameters file which, at a 
minimum, specifies the directory containing images to be analyzed.

Here, the basic structure is defined, specific parameters are listed, and 
example files located in this directory are described.

# Basic Structure
Each line of a parameters file can be either:

* a comment
* a set of parameters which affect all files (unless overridden)
* a specified input directory with (optionally) local parameters overriding 
  any global parameters and default settings

*Line order matters*. Each line is processed when read, the result is that
a parameter will not take effect until specified. In other words, if you 
specify an input directory *A* and *then* a global parameter and then another
input directory *B*, that parameter will only be applied to the analysis of 
files in direcotry *B*.

One use of this behavior is shown in ```global_params.txt```
  
## Comments
A comment line begins with the # character and may be used to relate any 
necessary information to the human reading the parameters file.

## Global parameters
A global parameter affects all files unless overridden and is identified
as a non comment line that *does not* begin with "indir=".

The line itself consists of comma-separated key-value pairs and has the
general format:

```key1=value1,key2=value2,key3=value3```

All parameters have a default global value and are listed at the end of this
document.

## Input directory, with optional local parameters/overrides
Each directory containing images to be processed should be specified on its
own line beginning with "inputdir=" and be followed by a comma-separated 
list of parameters overriding any global values for that directory only.


The general format is

```inputdir=c:\\data\\rep1,key1=value1"```

# Examples
For all examples, assume that images live in three directories:

* c:\\data\\rep1
* c:\\data\\rep2
* c:\\data\\rep3

A minimal example processing all three directories is given as:
```minimal_params.txt```

Specifying global parameters is shown in 
```global_params.txt```

Adding a local parameter to a directory which overrides those specified in a
global parameter is shown in 
```local_params.txt```

# Parameters
The current parameters available are:

| Parameter | Default | Others | Descriptions |
| --- | --- | --- | --- |
| ```useCLAHE``` | ```NO``` | ```YES``` | Attempt to enhance local contrast. May introduce noise. |
| ```outputFolder``` | ```inputbase``` | any valid path | Directory to which output should be written. Default is an ```output``` subdirectory within the inputdir |
| ```minDiamMicrons``` | ```50``` | any positive value or ```0``` | Do not include particles detected whose total area is less than that of a circle of the specified diameter |
| ```fontSize``` | ```NONE``` | Any valid pt size. |Quality control images have particle identifiers with best-guess font-sizes. This may be adjusted to any valid for easier reading. |
| ```darkBackground``` | ```true``` | ```false``` | Set as appropriate for thresholding |
| ```thresholdmethod``` | ```Otsu``` | See below | Otsu has proven reliable. |

Other threshold method which work reasonably well include: ```Default```,
    ```Intermodes```,```IsoData```,```IJ_IsoData```,```Li```,```Minimum```, 
       and ```Moments```,

