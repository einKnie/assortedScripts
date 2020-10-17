
# Assorted Scripts
This is a collection of scripts I have written for my personal use.  
I will probably add to it over time.

## Content

### [cpulog.sh](cpulog.sh)

The script collects CPU usage of a single process continuously, until stopped with `ctrl-c`.  
The visualisation of the collected data with gnuplot is built in.

##### Usage


```
-f, --file         |   output file (default /tmp/generic.log)  
                   |   If the file exists, you have the option to plot it
                   |   instead of collecting data.  

-n, --name         |   set target by name   

-p, --pid          |   set target by pid

-c, --comment      |   an optional title appendix for the generated plot
                   |   for exmple "while playing a video"

-a                 |   automatic mode. overwrite file and plot data without prompt
-x                 |   what-if mode, just print the configuration
                   |   that resulted from your other parameters

-h, --help         |   show this help message
```  
---

### [setdns.sh](setdns.sh)

The script provides an interface to add or remove DNS entries from the current active network connection, using nmcli.  
No parameters, the script is interactive.

---

### [categorizeMusic.sh](categorizeMusic.sh)

The script categorizes audio files into a folder structure <i>/\<artist>/\<album>/\<track_title.fileextension></i> from metadata.

#### Usage

```
-s | --source      	|	 source folder
-o | --output-dir  	|	 destination folder
-w | --what-if     	|	 what-if mode. don't copy files, just print what would have been copied
-v | --verbose     	|	 log debug messages
-h | --help        	|	 show this help message
```

All valid audio files in the <i><b>source directory</b></i> are categorized and copied to their new location inside the <i><b>output directory</b></i>. If no output directory is given, what-if mode is enabled automatically.  
<b>Note:</b> The output directory is created if it does not already exists.


<b>The original files are not touched in any way! Files are copied to their respective destination and then renamed.</b>

#### Example
A song with the following metadata will be stored under
<b>/TheBand/AnAmazingAlbum/04\_Best\_Song.mp3</b>

```
[...]
FileType    : mp3
Track       : 4
Artist      : TheBand
Title       : Best Song
Album       : AnAmazingAlbum
```

<b>Note:</b> If artist or album of a song cannot be determined from the file's metadata, the file is copied to <i>\<various>/\<other></i>.  
In case the track number is not found, the file will keep its original name.

---

### [diffscript.sh](diffscript.sh)

The script runs two different executables with the same arguments and checks if there is a differece in the programs' output.


#### Usage

```
-x1         | left-side executable
-x2         | right-side executable
-c          | commands for the two executables; should be in quotes
-q          | quiet, disable all output	 
-h  --help  | show help screen
```


#### Example

```
> ./diffscript.sh -x1 /usr/bin/diff -x2 /usr/bin/diff -c "--help"
left:      /usr/bin/diff
right:     /usr/bin/diff
commands:  "--help"

it's the same!
>
```

<b>Note:</b> The respective output of the tested executables can be found in the script's directory afterwards, as ``` ./res_left ``` and ``` ./res_right ```, respectively.
In case the outputs differ, the diff result is also printed to stdout.
