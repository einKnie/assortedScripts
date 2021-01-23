
# Assorted Scripts
This is a collection of scripts I have written for my personal use.  
I will probably add to it over time.

## Content

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

### [debugifier.sh](debugifier.sh)

The script adds simple debug output to a given bash script, and removes it again when no longer needed.

More specifically, the line 
`echo "in $(basename $BASH_SOURCE) ${FUNCNAME[0]}"` is added at the start of every defined function. This line outputs `in <filename> <functionname>`, allowing for a quick overview of the script flow, even across multiple files.


#### Usage

```
-s <path>        | shell script
-o <1|0>         | operation

```


#### Example

```
> ./debugifier.sh -s ~/scripts/some_script.sh -o 1

```

<table>
<tr>
<th>
Original
</th>
<th>
Debugified
</th>
</tr>
<tr>
<td>

<pre>
function debug() {
  	if [ $DEBUG -eq 1 ]; then
    		echo $1
  	fi
}

function warning() {
  	echo -e "\033[0;31m$1\033[0m"
} 
</pre>

</td>
<td>

<pre>
function debug() {
	echo "in $(basename $BASH_SOURCE) ${FUNCNAME[0]}"
  	if [ $DEBUG -eq 1 ]; then
    		echo $1
  	fi
}

function warning() {
	echo "in $(basename $BASH_SOURCE) ${FUNCNAME[0]}"
  	echo -e "\033[0;31m$1\033[0m"
} 
</pre>

</td>
</tr>
</table>

---
### [diffscript.sh](diffscript.sh)

The script runs two different executables with the same arguments and checks if there is a differece in the programs' output. Useful for refactoring.


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

---
### [reminder.sh](reminder.sh)

Set yourself a reminder, either for your next reboot, or after a set time.  



#### Usage

```
--on          | set a timer
--off         | unset a reminder [only for reboot reminder]
-m --message  | the reminder
-t --time     | time for timer, in format "5m 3h 1d" *
              |  -> 5 minutes, 3 hours, and 1 day
              |  (only non-zero values need to be specified)	 
-l --link     | treat the message as a link, making it clickable in the reminder window
-h --help     | show help screen
```

\* time may also be specified without whitespaces, in which case the string need not be quoted. __5m3h__ is a valid time string.  

If __message__ is not set, the user will be queried via an entry window. The same holds true for __time__: if the _-t_ parameter is given without a time string, the user is queried for one. 

#### Example

```
> ./reminder.sh --on --message "Good morning!"
```
will set a reminder for your next reboot with the message "Good morning!"



```
> ./reminder.sh --on -t 5m --message "mind the stove!"
```
will remind you to mind the stove in five minutes.

---

### [setdns.sh](setdns.sh)

The script provides an interface to add or remove DNS entries from the current active network connection, using nmcli.  
No parameters, the script is interactive.

---



