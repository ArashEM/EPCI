/**
*	epci led handler
*	Copyright (C) 2019	arash.golgol@gmail.com
*
*/

#include <linux/kernel.h>
#include <linux/pci.h>
#include <linux/leds.h>
#include "epci.h"


/**
*	epci led information
*/
struct led_info epci_led_info[] = {
	{
		.name = "d1:blue",
		.default_trigger = "none",
	},
	{
		.name = "d2:green",
		.default_trigger = "heartbeat",
	},
	{
		.name = "d3:red",
		.default_trigger = "default-on",
	}

};

struct led_platform_data epci_led_pdata = {
	.num_leds = ARRAY_SIZE(epci_led_info),
	.leds = epci_led_info,
};

/**
*	set PWM
*/
static void epci_set_pwm(struct epci_led *led)
{
	unsigned long  offset  = (led->led_num) << 2;	/* each led has 4 bytes register */
	void __iomem *led_addr = led->board->base + 		
				 led->board->info->led_offset +
				 offset;
	iowrite32(0xFFFF0000, led_addr);	/*set PWM to 0xFFFF */
}

/**
*
*/
static void epci_led_brightness_set(struct led_classdev *led_cdev, 
	enum led_brightness brightness)
{
	struct epci_led *led = 
		container_of(led_cdev, struct epci_led, led_cdev);
	unsigned long  offset  = (led->led_num) << 2;
	void __iomem *led_addr = led->board->base + 		
							led->board->info->led_offset +
							offset;

	switch(brightness) {
	case LED_FULL:
		iowrite8(0x01, led_addr);
		break;
	case LED_OFF:
		iowrite8(0x00, led_addr);
		break;
	default:
		iowrite8(0x00, led_addr);
		break;
	}
}


int  epci_leds_register(struct epci_priv * board)
{
	struct  epci_led *leds = NULL;
	struct  pci_dev  *dev = board->pdev;
	int		num_leds = epci_led_pdata.num_leds;
	int		i,ret = 0;

	leds = devm_kzalloc(&dev->dev, num_leds*sizeof(*leds), GFP_KERNEL);
	if(!leds) 
		return -ENOMEM;
	
	board->leds = leds;
	
	for(i=0; i < num_leds; i++) {
		leds[i].led_num = i;
		leds[i].board = board;
		
		snprintf(leds[i].name, sizeof(leds[i].name),
				"epci:%s",
				 epci_led_pdata.leds[i].name);
		
		leds[i].led_cdev.default_trigger = 
				epci_led_pdata.leds[i].default_trigger;
		leds[i].led_cdev.name = leds[i].name;
		leds[i].led_cdev.brightness_set = epci_led_brightness_set;
		
		epci_set_pwm(&leds[i]);		/* turn led off and set PWM to max */
		
		ret = led_classdev_register(&dev->dev, &leds[i].led_cdev);
		if(ret < 0) {
			dev_err(&dev->dev, 
				"led class device registeration failed\n");
		goto error_register;
		} 	
	}

	return 0;	
	
error_register:
	while(i--)
		led_classdev_unregister(&leds[i].led_cdev);
	
	return ret;
}

void epci_leds_unregister(struct epci_priv * board)
{
	int		num_leds = epci_led_pdata.num_leds;
	struct  epci_led *leds = board->leds;
	int 	i=0;
	
	for(i=0; i < num_leds; i++)
		led_classdev_unregister(&leds[i].led_cdev);
}
