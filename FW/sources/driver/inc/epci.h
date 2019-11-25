/*
*	EPCI header 
*	Copyright (C) 2019      arash.golgol@gmail.com
*
*/
#ifndef _EPCI_H_INCLUDED
#define _EPCI_H_INCLUDED

/**
*	EPCI leds private data
*/
struct epci_priv;

struct epci_led {
	char   	name[32];
	int	led_num;			/* currently 0 to 2 */
	struct 	led_classdev led_cdev;		/* inherit led class device */
	enum 	led_brightness brightness;
	struct  epci_priv *chip;		/* soft link */
};

/**
*	ecpi private data structure
*/
struct epci_priv {
	struct cdev	cdev;		/* inherit char device */
	struct pci_dev	*pdev;   	/* soft link to pci device */

	unsigned long	memaddr;	/* physical address */
	void __iomem	*base;		/* memory mapped address */
	unsigned long	size;		/* memory lenght of EPCI */

	struct epci_led *leds;
};

#endif /* _EPCI_H_INCLUDED */
