# Raspberry Pi Internet Connectivity Checker

This repository contains a Bash script for an Embedded Linux System, in my case Raspberry Pi 4, that utilizes GPIO to indicate internet connectivity status using an LED. <br>
The script brings up a GPIO LED using a device tree overlay, checks internet connectivity by pinging `google.com`, and then controls the LED based on the connectivity status.<br>
**NOTE**: The utilized Raspberry pi device tree overlay may be found at [raspberry pi linux repo](https://github.com/raspberrypi/linux/blob/rpi-6.1.y/arch/arm/boot/dts/overlays/gpio-led-overlay.dts) or at `/boot/overlays/gpio-led-overlay.dts`
For other embedded linux devices, you may need to update .dtbo file.

## Demo

0. **Dependencies** You will need to install a tool named `gpiod`. It is used to check gpio pin availability.<br>
In case your kit or image does not support it, You may replace it at [led-net-check.sh : line 67](https://github.com/AladdinT/led-internet-check/blob/master/led-ner-check.sh#L67)

    ```bash
    sudo apt install gpiod
    ```

1. **Connect** the LED to the desired GPIO pin. (26 in my case)
2. **Run** the script using the following command:
    ```bash
    sudo ./led-net-check.sh label=led-checker gpio=26 
    ```
3. **Voila**
<div style="text-align:center; width:45%;">
    <img src="./media/demo.gif" alt="Raspberry Pi Demo">
    <!-- <img src="https://raw.githubusercontent.com/AladdinT/led-internet-check/master/media/demo.gif" alt="Raspberry Pi Demo" style="width:45%; text-align:center;"> -->
</div>

## Systemd Service
A systemd service file _`my-net-check.service`_ is included to automate execution of the led internet connectivity checker script at system start up.

In order to run script at start up, follow these steps line by line:

```bash
# Update file ExecStart, and ExecStop with your paths, and parameters
nano ./systemd-service/my-net-check.service
# Copy the systemd service file to the appropriate systemd service directory
sudo cp ./systemd-service/my-net-check.service /usr/lib/systemd/system/
# Reload the systemd manager to recognize the new service file
sudo systemctl daemon-reload
# Enable the service to start automatically at boot
sudo systemctl enable   my-net-check.service
# Start the service to immediately run
sudo systemctl start    my-net-check.service
# Check Service Status
sudo systemctl status your_service_name.service
```

## Undo changes
### Reset gpio-led

```bash
# Replace label, and gpio parameters with your values
sudo ./led-net-check.sh --remove label=led-checker gpio=26 
```

### Remove systemd service 
```bash
# To stop the service from running automatically on boot
sudo systemctl disable your_service_name.service
# To remove the service from systemd
sudo rm /usr/lib/systemd/system/your_service_name.service
sudo systemctl daemon-reload
```
