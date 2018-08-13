##############################################################################
# Compare changes in particle size distributions over time between two
# two reactors, using data taken from image analysis as desribed in
# the paper XXX title name XXX in JOVE XXX pub info XXX
#
# Joseph E. Weaver
# jeweave4@ncsu.edu
# joe.e.weaver@gmail.com
# NC State University
#
##############################################################################

# Include packages --------------------------------------------------------
import glob            # file management
import os.path
import pandas as pd    # data science
import numpy as np     # numeric methods and constants
import seaborn as sns  # plotting, builds upon matplotlib
import matplotlib.pyplot as plt

# Read in particle data from multiple csvs --------------------------------

# get a list of all CSV
data_dir = "data/two_reactor_time_series"
file_list = glob.glob(os.path.join(data_dir, "*.csv"))

# Read each csv and merge into one dataframe
dfs = []
for f in file_list:
    df = pd.read_csv(f)
    df['filename'] = os.path.basename(f)
    dfs.append(df)

psd_data = pd.concat(dfs, ignore_index=True)

# There is probably experimental metadata we would like to incorporate. For
# example, things sampling date, the reactor from which the sample came, or
# even annotations like 'cloudy effluent'.
#
# There are two good ways to deal with this, including the metadata in
# the filename itself or by including it in a separate file.
#
# In the case of base metadata, like dates and reactor names, I prefer to
# store the information direclty in the filename.  These can be split out
# and added as new columns to our data frame.

# First, let's get the reactor number
psd_data['reactor'] = psd_data['filename'].str.extract(
                      'reactor-(\\d+)_', expand=True)

# Now, let's get the date string
psd_data['date'] = psd_data['filename'].str.extract(
                      'date-([\\d|-]+)_', expand=True)

# In the case of external metadata, we can record observations in an external
# file, read it into a dataframe, then merge the result with our existing
# data.  For example, let's say that reactor 1 was 'yeasty' on 2017-12-19
# and reactor 2 was 'vinegary' on 2017-12-08.
#
# We could record that data in a csv (viewable in data/observations.csv)
# and then read and merge, like so:

# read and prepare metadata
# note, we're specifying 'reactor' should be read a string
# this matches the format of the reactor name in 'data'
smells = pd.read_csv("data/observations.csv", dtype=str)
full_data = pd.merge(psd_data, smells, how='left', on=['date', 'reactor'])

# Data processing ---------------------------------------------------------
#
# Often we will want to further process the data before plotting it.
# For example, we may want to plot particles by the log of their
# equivalent diameter, rather than as total area.

full_data['eqd_um'] = np.sqrt(full_data['Area'] * 1e8 / 2) / np.pi
full_data['log_eqd_um'] = np.log10(full_data['eqd_um'])

# Let's also turn dates into experiment days
start_date = pd.to_datetime("2017-12-08-1200", format='%Y-%m-%d-%H%M')
full_data.date = pd.to_datetime(full_data.date)

full_data['Day'] = (full_data['date'] - start_date).dt.days

# Figure generation ------------------

# While data importing, metadata attachment, and (to some extent) data
# processing will be similar between experiments, there is almost an infinite
# variety of figures which can be generated.  Here, we generate a simple
# violin plot to give an example of how the dataframe we've generated can
# be used in conjunction with the seaborn package.

sns.set_context("paper")
sns.set_style("white", {
        "font.family": "sans",
        "font.serif": ["Calibri", "Arial", "sans"]
    })
sns.set(style="white")
sns.despine()
ax = sns.violinplot(x="Day", y="log_eqd_um",
                    hue="reactor", data=full_data, col="Reactor",
                    palette="muted", inner="quartile", split=True)
plt.legend(loc='upper left', ncol=2, title="Reactor")
plt.rc('xtick', labelsize=20)
plt.rc('ytick', labelsize=20)
ax.set_ylabel("log Equivalent Diameter (μm)", fontsize=20)

# Save the figure as an SVG and PDF
ax.get_figure().savefig(os.path.join("output", "two_reactor_time_series.svg"))
ax.get_figure().savefig(os.path.join("output", "two_reactor_time_series.pdf"))

# Try to record some relevant session info
with open(os.path.join("output", "sessionInfo.txt"), "w") as f:
    import sys
    f.write("Python: " + sys.version + "\n")
    f.write("Pandas: " + pd.__version__ + "\n")
    f.write("Numpy: " + np.__version__ + "\n")
    f.write("Seaborn: " + sns.__version__ + "\n")
    import matplotlib
    f.write("Pyplot via Matplotlib: " + matplotlib.__version__ + "\n")
