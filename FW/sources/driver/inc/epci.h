/*
*	EPCI header 
*	Copyright (C) 2019      arash.golgol@gmail.com
*
*/
#ifndef _EPCI_H_INCLUDED
#define _EPCI_H_INCLUDED

#include <linux/cdev.h>
#include <linux/leds.h>

/**
*	epci board information
*	describe memory map of EPCI board
*/
struct epci_board_info {
	unsigned long  mem_offset;	/* SRAM base offset */
	unsigned long  led_offset;	/* LED controller   */
	struct led_platform_data *led_pdata;
};

/**
*	EPCI leds private data
*/
struct epci_priv;

struct epci_led {
	char   	name[32];
	int	led_num;			/* currently 0 to 2 */
	struct 	led_classdev led_cdev;		/* inherit led class device */
	enum 	led_brightness brightness;
	struct  epci_priv *board;		/* soft link */
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

	/* memory map offset of each peripheral */
	const struct epci_board_info *info;	

	struct epci_led *leds;
};


/*
*	register board leds
*/
int  epci_leds_register(struct epci_priv * board);
void epci_leds_unregister(struct epci_priv * board);

/*
*	register board memory as file
*/
int  epci_mem_register(struct epci_priv * board);
void epci_mem_unregister(struct epci_priv * board);


#endif /* _EPCI_H_INCLUDED */
