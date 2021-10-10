
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

### [collect_gitdata.sh](collect_gitdata.sh)


Starting at a given directory, this script recursively checks every subdirectory and lists information on every found git repository.

The script takes two arguments, the starting directory and the desired depth to check for subdirectories. If depth is not provided, the script will recurse indefinitely, until no further subdirectories are found.

**Beware:** Infinite depth may take a while, depending on the folder strucure.

##### Usage

````
> ./collect_gitdata.sh ~/projects/ 1
````
Check only toplevel folders in ~/projects/, e.g. ~/projects/some_project

````
> ./collect_gitdata.sh ~/projects/ 2
````
Check first- and second-level subdirectories of ~/projects/, e.g. ~/projects/javascript/zensur

````
> ./collect_gitdata.sh ~/projects/ <n>
```` 
Check \<n> levels of subdirectories of ~/projects/

````
> ./collect_gitdata.sh ~/projects/
```` 
Check all descendent subdirectories of ~/projects/

##### Example

````
> ./collect_gitdata.sh ~/projects/
path:   /home/einKnie/projects/gourmet
remote: < no remote >
hash:   b474b0b7a55f03adb67640547006b83d6db6f275
tags/heads:
b474b0b7a55f03adb67640547006b83d6db6f275 refs/heads/master

path:   /home/einKnie/projects/javascript/urgent_mail
remote: https://github.com/einKnie/urgentMail.git
hash:   25bc3f59d25c4642bf82cbc94876134305d1467a
tags/heads:
25bc3f59d25c4642bf82cbc94876134305d1467a refs/heads/master
25bc3f59d25c4642bf82cbc94876134305d1467a refs/tags/v1.3

path:   /home/einKnie/projects/javascript/zensur
remote: https://github.com/einKnie/zensur.git
hash:   490ceab71bea95df82dba93e7477c976a4fba735
tags/heads:
490ceab71bea95df82dba93e7477c976a4fba735 refs/heads/master
490ceab71bea95df82dba93e7477c976a4fba735 refs/tags/v1.4^{}

path:   /home/einKnie/projects/libraries/log
remote: https://github.com/einKnie/Logger.git
hash:   8b3ba44e08093c8fcea8c519d1c655d3778758b3
tags/heads:
8b3ba44e08093c8fcea8c519d1c655d3778758b3 refs/heads/master

path:   /home/einKnie/projects/vpn_detection
remote: https://github.com/einKnie/vpn_status.git
hash:   9d800caf5e612174a2782d83f146b6edb234c604
tags/heads:
9d800caf5e612174a2782d83f146b6edb234c604 refs/heads/monitoring_mode

...

>

````

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
debug() {
  	if [ $DEBUG -eq 1 ]; then
    		echo $1
  	fi
}

warning() {
  	echo -e "\033[0;31m$1\033[0m"
}
</pre>

</td>
<td>

<pre>
debug() {
	echo "in $(basename $BASH_SOURCE) ${FUNCNAME[0]}"
  	if [ $DEBUG -eq 1 ]; then
    		echo $1
  	fi
}

warning() {
	echo "in $(basename $BASH_SOURCE) ${FUNCNAME[0]}"
  	echo -e "\033[0;31m$1\033[0m"
}
</pre>

</td>
</tr>
</table>

The debugifier works with all sorts of function definition styles, such as `function foo() {}`, `foo() {}`, or even `foo {}`.

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

### [reomgr.sh](repomgr.sh)

Provides simple automatic repo management.
I use this to automatically push changes to a repository from different nodes.

#### Usage

```
 -d <path>  ... the git directory [ default: pwd ]
 -b <name>  ... remote branch to track [ default: master ]
 -c <path>  ... path to config file * (optional, overrides -d and -b)
 -a         ... automatic - pull && push changes as they come
 -q         ... quiet, print only error messages
 -v         ... verbose, print debug messages
 -h         ... print this help
```

A default config file may be generated (as `$PWD/.repocfg`) by calling:
```
repomgr.sh -c ""
```

The config file allows a number of options:

```
workdir: /path/to/repo
branch: branchname
commit: The default commit message to use for commits performed by this script

```

---

### [setdns.sh](setdns.sh)

The script provides an interface to add or remove DNS entries from the current active network connection, using nmcli.  
No parameters, the script is interactive.

---
