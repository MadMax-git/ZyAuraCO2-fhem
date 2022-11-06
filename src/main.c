/*
 * main.c
 *
 *  Created on: Jan 18, 2017
 *      Author: jo
 */

#include <stdio.h>
#include <unistd.h>
#include <holtekco2.h>

#define MAX_LOOP 25

int main(int argc, char *argv[])
{
bool finishReading = false;
bool encrypted = true;
int LoopCount = 0;
co2_device_data data;

	if(argc == 2)
	{
		if(strcmp("-n", argv[1]) != 0)
		{
            fprintf(stdout, "CO2 concentration:\n wrong parameter\n");
			return -1;
		}
		encrypted = false;
	}

	co2_device * devHandler = co2_open_first_device();
	//you can wait some time (about 2s) to (re-)initialize device, but it's not required
	while (!finishReading  && LoopCount < MAX_LOOP)
	{
		LoopCount++;
		if(encrypted == true)
		{
		    data = co2_read_data(devHandler);
		}
		else
		{
		    data = co2_read_data_undecrypted(devHandler);
		}
	    if (data.valid){
	        switch (data.tag)
	        {
	          case CO2:
	              fprintf(stdout, "CO2 concentration:\n%hd PPM\n", data.value);
	              finishReading = true;
	              break;
/*
	          case TEMP:
	              printf("Ambient temparature: %lf C\n", co2_get_celsius_temp(data.value));
	              break;
	          case HUMIDITY:
	              printf("Relative humidity: %lf %%\n", co2_get_relative_humidity(data.value)); //or simply divide by 100.0: data.value/100.0
	              break;
*/
	          default:
	        	  ;
	              //ignore this, device may send some ghost values
	              //looks like some kind of generic framework on this device sending different values
	        }
	    }
	    usleep(100); //usually there's 80+ms delay between device sending data
	}
	co2_close(devHandler);//properly finish work with device

	if(LoopCount >= MAX_LOOP)
	{
        fprintf(stdout, "CO2 concentration:\n general error\n");
		return -1;
	}

	return 0;
}
