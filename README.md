
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