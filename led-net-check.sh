#!/bin/bash

## default values
LED_LABEL="led-checker"
LED_PIN=26
script_path=$(dirname "$(readlink -f "$0")")
DTBO_FILE="${script_path}/myoverlay/my-gpio-led.dtbo"
REMOVE_LED=0

## parameters Parsing            
for para in $@ 
do
    case $para in
        "label="*)
            LED_LABEL=${para:6}
        ;;
        "gpio="*)
            LED_PIN=${para:5}
        ;;
        "dtbo="*)
            DTBO_FILE=${para:5}
        ;;
        "stop"|"--remove"|"-r")
            REMOVE_LED=1
        ;;
        * | "-h" | "--help")
            echo "Usage: $0 [OPTION...] [label=<value>] [gpio=<value>] [dtbo=<value>]"
            echo "  label - led driver label (default: led-checker)"
            echo "  gpio  - gpio pin number  (default: 26)"
            echo "  dtbo  - gpio led device tree overlay (.dtbo) file "
            echo "          (default ${DTBO_FILE})"
            echo "  -h, --help      - show this help message"
            echo "  -r, --remove    - remove given led from dtoverlay"
            exit 0;
    esac
done

# Must be root user
if [ "$EUID" -ne 0 ]; then
    echo -e "\e[1;31m Error: This script requires sudo privileges. Please run it with sudo.\e[0m"
    exit 1
fi

# Removing led handler
if [ $REMOVE_LED -eq 1 ]
then
    echo "Removing ${LED_LABEL} with gpio${LED_PIN} "
    index=$(dtoverlay -l | grep "label=${LED_LABEL} gpio=${LED_PIN}$")
    index=${index:0:1}
    if [ -z "${index}" ]
    then
        echo "No loaded overlay with label=${LED_LABEL} gpio=${LED_PIN}$ to remove"
    else
        dtoverlay -r $index
    fi
    exit $?
fi

# if led is not overloaded
is_loaded=$(dtoverlay -l | grep "my-gpio-led  label=${LED_LABEL} gpio=${LED_PIN}")
if [ -z $is_loaded  ]
then
    echo "Adding led device tree overlay"
    is_label_valid=$(dtoverlay -l | grep "my-gpio-led  label=${LED_LABEL}")
    # if the label was not used
    if [ $is_label_valid -z ]
    then
        #### TODO : replace gpiod ####
        gpioinfo > /dev/null
        # if gpioinfo execution failed
        if [ $? -ne 0 ] 
        then
            echo -e "\e[1;31mError: gpioinfo does not seem to be installed.\e[0m"
            echo "HINT: use \` sudo apt install gpiod \`"
            echo "or update $0 with another tool"
            exit 1;
        else
            is_gpio_valid=$(gpioinfo | grep GPIO${LED_PIN}\" | grep "unused") 
            echo $(gpioinfo | grep GPIO${LED_PIN}\")
        fi
        

        if [ -z "${is_gpio_valid}" ]
        then
            # if the gpio pin was used
            echo -e "\e[1;31mError: The chosen gpio pin seems to be used or invalid .\e[0m"
            exit 1;
        else 
            # if the gpio pin was free to use
            $(dtoverlay $DTBO_FILE label=$LED_LABEL gpio=$LED_PIN)
        fi
    else 
        # if the label was used
        echo -e "\e[1;31mError: This led label seems to be used.\e[0m"
        exit 1;
    fi
else 
    echo -e "\e[1;33mWarning: This led was previously overloaded with same configurations.\e[0m"
fi

# Toggle led based on connection status
while true
do
    ping -c 2 -W 2 google.com > /dev/null
    # http_status=$(curl -s -o /dev/null -w "%{http_code}" http://www.google.com)
    # if [ "${http_status}" == "200" ]
    if [ $? == 0 ]
    then 
        echo 1 >  /sys/class/leds/${LED_LABEL}/brightness 
        echo "connected" # for debugging
    else
        echo 0 >  /sys/class/leds/${LED_LABEL}/brightness 
        echo "disconnected" # for debugging
    fi
    sleep 1  # delay
done
