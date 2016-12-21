# BoardManagerFiles
Storage for Arduino Board Manager JSON and package files etc

Boards available:

	* STM32F103RB-Nucleo
	* STM32L476RG-Nucleo

### Installing STM32 Cores

1- Launch Arduino.cc IDE. Click on "**File**" menu and then "**Preferences**".

![Preferences](/img/preferences.png)

The "**Preferences**" dialog will open, then add the following link to the "*Additional Boards Managers URLs*" field:

https://github.com/stm32duino/BoardManagerFiles/raw/master/STM32/package_stm_index.json

Click "**Ok**"

2- Click on "**Tools**" menu and then "**Boards > Boards Manager**"

![BoardsManager Menu](/img/menu_bm.png)

The board manager will open and you will see a list of installed and available boards. 

Select "**Contributed**" type.

![BoardsManager dialog](/img/boardsmanager.png)

Select the STM32 core wanted and click on install.

![BoardsManager dialog](/img/boardsmanager2.png)

After installation is complete an "*INSTALLED*" tag appears next to the core name. 

You can close the Board Manager.

![Boards list](/img/boardslist.png)

Now you can find the new board in the "**Board**" menu. 

### Troubleshooting

If you have any issue to download a package, ensure to not be behind a proxy.

Else configure the proxy in the Arduino.cc IDE (open the "**Preferences**" dialog and select "**Network**" tab).
