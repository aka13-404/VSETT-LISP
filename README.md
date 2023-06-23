# VSETT/Kaboo Display VESC(TM) Lisp connector

Disclaimer: Me, or this this project are not assotiated with either VESC® or Benjamin Vedder. VESC® is a registered trademark by Benjamin Vedder. You can visit the VESC® Project by [clicking this link here](https://vesc-project.com/).

Consider supporting Mr.Vedder for his work on the VESC Project and  Joel Svenssonfor his work on the lispBM integration. They are both great people and deserve your support.
If I have seen further than others, it is by standing on the shoulders of giants.

I am not affiliated with rollerplausch. I do not condone locked down forums, nickname squatting on telegram, and local forum warlords.  
I am only present on telegram and github, nowhere else.
  
## Feature Overview
This script is a "middleman" for you to ride your ~~shitbox~~ reliable and well made VSETT/Kaboo scooter with the VESC controller and the stock display. The stock display is already there, does the job, and does not cost anything.
  
As always, I'd like to kindly remind you, that everything you do you do on your own behalf. I am not responsible for you doing stupid stuff. Also consider the GPL v3 license.



### Limitations

1. The script **DOES NOT WORK** on 6.02. This is due to a bug with can-cmd in lisp present there. **You MUST use at least the 6.05 beta**, otherwisethe script will not be able to controll can-attached controllers.
2. This script does nothing with lights, turnlights, horn and brakes.  
VSETT/Kugoo uses a very strange, proprietary conector to connect to the esc. It's literally unbuyable and can not be found anywhere.  If you know where to buy the connector, let me know.  
That means - you will need a different harness, or propably two separate harnesses, one for display, one for everything else. When I have the budget I will design a simple PCB with a couple of fets, and do a howto on hall sensor installation for the brake levers but right now the money simply isn't there.

3. You will still need to crimp and/or solder, and require basic electric knowledge. This is not a software-only solution. 

4. You will need to adjust a couple of parameters to your liking. I am not your mother, and I am not your tuner. It's up to you, what you want to do, and how you want to do it. I just already did the heavy lifting for you. 

5. The display boots faster, than VESC controllers do. This means, that on every startup E10 will briefly flash. To clear the E00 from the screen it's enough to press the power button once.


### Current features
1. Speed display works, a bit more responsive than stock.
2. Gear selector works, for now it adjusts top speed and motor amps.
3. In addition to 3 stock gears two additional "gears" exist. The script waits for a specific order of "gear" selections, and turning on the lights. Afterwards, "gear" 2 and 3 switch to different values, and gear 1 returns to the usual "gears". Useful, if you want some special profiles for yourself, which are not easily accessible by your kids/wife.
4. Since speed display works properly, odometer also works properly. 

### Future features
1. The gear selector will change any arbitrary parameters you provide in the config
2. The display P-values could be used for changing some vesc parameters.
3. Arbitrary length for the key for hidden modes

### Installation
# The installation and the needed materials are covered [here](Installation.md). 




## Issues, bug reports, pull requests

If you think you have somethnig valuable to add, don't hesitate to reach out, open issues, or similar. Pull requests are welcome. 




### Happy Riding!

I enjoy fiddling with controllers. If you have a display-esc combo, and you think it would be cool to connect the display to the VESC, you can mail them to me, and I'll do my best to try and reverseengineer the protocol. 

Alternatively, if you want to fund my reckless cigar and burger consumption, feel free to drop me some money via paypal.  
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/donate/?hosted_button_id=9TZU9TG4NDSXY)