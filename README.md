# ZyAuraCO2-fhem

I found the ZyAura CO2 sensor and it was/is pretty cheap compared with others (was around 60EUR the time I started this).

After some search I found that it not only has a display to show the actual value (CO2 and Temperature) but also could be read out via usb.

After some more search I found the following sites where I pulled my input for my project to make this sensor available in fhem (open source perl-based home automation system):

https://hackaday.io/project/5301-reverse-engineering-a-low-cost-usb-co-monitor

https://github.com/vshmoylov/libholtekco2

https://github.com/signal11/hidapi

Thanks to those guys!!

Here a link to fhem:

http://fhem.de/fhem.html

---------------------------------------------------------------------------------------------------------------

Getting started with this project to get everything running (on fhem):

1. git clone https://github.com/MadMax-git/ZyAuraCO2-fhem.git

2. cd into directory and chmod +x build.sh

3. sudo apt-get update and sudo apt-get install libudev-dev

4. import the c-project into eclipse and call build project OR just build by calling  ./build.sh all \<name-of-executable\> \<path-to-act-dir\>

5. copy 74_ZyAuraCO2.pm into /opt/fhem/FHEM (when your fhem installation directory is /opt/fhem) and do a shutdown restart of fhem

6. define the module in fhem: define \<name-of-device\> ZyAuraCO2

7. set the attr CO2Path to where the ZyAuraCO2 executable is located (\<path-to-act-dir\>/Debug/\<name-of-executable\>)

8. done :-)

Remarks:
now also supporting newer CO2 devices which do not have encryption in place anymore.
Just add the parameter -n when calling the program for those.
Older devices: just call the program without anything like before.

