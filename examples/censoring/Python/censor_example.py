################################################################################
# Example of non-destructive, explicit, and trackable censoring of whole files
# and individual particles in image analysis, supporting the paper 
# XXX title name XXX in JOVE XXX pub info XXX
#
# Joseph E. Weaver
# jeweave4@ncsu.edu
# joe.e.weaver@gmail.com
# NC State University
#
################################################################################

# Include packages --------------------------------------------------------
import glob            # file management
import os.path
import pandas as pd    # data science
from tabulate import tabulate     # output table of results

# Read in particle data from multiple csvs --------------------------------

# get a list of all CSV files
data_dir = "data"
file_list = glob.glob(os.path.join(data_dir, "*.csv"))

# Read each csv and merge into one dataframe
dfs = []
for f in file_list:
    df = pd.read_csv(f)
    df['filename'] = os.path.basename(f)
    dfs.append(df)

psd_data = pd.concat(dfs, ignore_index=True)

# Censor whole files  --------------------------------
# Keep track unique filenames and row count to track progress.
cens_prog = pd.DataFrame.from_records([{
              'operation': "Raw Data",
              'files': psd_data.filename.unique().size,
              'remaining_particles': psd_data.shape[0],
            }])

# Read in our censoring specifciation
files_2_ignore = pd.read_csv("censor_files.csv")

censored=pd.merge(psd_data, files_2_ignore, on=['filename'], how="outer", indicator=True)
censored=censored[censored['_merge'] =='left_only']

cens_prog = cens_prog.append(pd.DataFrame.from_records([{
              'operation': "Remove whole file",
              'files': censored.filename.unique().size,
              'remaining_particles': censored.shape[0],
            }]))

# Censor individual particles  --------------------------------
# Read in our censoring specifciation
parts_2_ignore = pd.read_csv("censor_particles.csv")

# A small, illustrative data issue here. FIJI does not provide a header name 
# for particle IDs, we have chosen to respect that format. When read by 
# read_csv, this column is given the header "X1". The corresponding column
# in the censoring file is "particleId".
# 
# One could either rename the columns to match, or use the following form
# of merge. Note how filename is still included, this ensures removing
# the particleID only from rows corresponding to the correct file. 
# (i.e. per-particle censoring requires both a particleId and filename to 
# uniquely identify a particle).

print(psd_data.columns.values)
 
censored=pd.merge(censored, parts_2_ignore, left_on=['filename',' '], right_on=['filename','particleId'], how="outer", indicator="_merge2")
censored=censored[censored['_merge2'] =='left_only']

# At this point, censored is ready to use for analysis, the remaining
# code produces a table showing the particle and file count from each
# censoring step

cens_prog = cens_prog.append(pd.DataFrame.from_records([{
              'operation': "Remove individual particles",
              'files': censored.filename.unique().size,
              'remaining_particles': censored.shape[0],
            }]))

print(tabulate(cens_prog,headers="keys", tablefmt="pipe"))

# Save the results of censoring progess to a table
with open(os.path.join("output", "censor_results.txt"), "w") as f:
    import sys
    f.write(tabulate(cens_prog,headers="keys", tablefmt="pipe"))

# Try to record some relevant session info
with open(os.path.join("output", "sessionInfo.txt"), "w") as f:
    import sys
    f.write("Python: " + sys.version + "\n")
    f.write("Pandas: " + pd.__version__ + "\n")
    