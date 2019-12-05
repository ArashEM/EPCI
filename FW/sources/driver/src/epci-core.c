/**
*	epci driver
*	Copyright (C) 2019	arash.golgol@gmail.com
*
*/
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/pci.h>
#include <linux/errno.h>
#include <linux/io.h>
#include "epci.h"

/**
*	constants
*/
const  char	EPCI_DEV_NAME[]	= "epci-board";
const  unsigned EPCI_MEM_BAR	= 0;

const  int	EPCI_FW_VER	= 0x40;	/* fw version offset */

enum epci_rev {
	epci_v1,
	epci_v2,
};

const struct epci_board_info epci_board_info[] = {
	[epci_v1] = {
		.mem_offset = 0x0000,
		.led_offset = 0x8010,
	},
};


/**
*	pci id table
*/
static const struct pci_device_id epci_pci_tbl[] = {
	{ PCI_DEVICE(0x10EE,0x0600) },
	{0, }
};

MODULE_DEVICE_TABLE(pci, epci_pci_tbl);

/**
*	ecpi probe
*/
static int epci_probe(struct pci_dev *dev, const struct pci_device_id *id)
{
	struct	epci_priv  *priv;
	// dev_t	devno = 0;
	int	ret = 0;
	u32	fw_ver = 0;
	u8	fw_ver_maj,fw_ver_min = 0;
	u16	fw_build = 0;

	dev_info(&dev->dev, "probing pci device %#04x:%#04x\n",dev->vendor, dev->device);
	
	/* get fw version from device maj.min.build */
	pci_read_config_dword(dev, EPCI_FW_VER, &fw_ver);
	fw_ver_maj = (fw_ver >> 24 ) & 0xFF;
	fw_ver_min = (fw_ver >> 16 ) & 0xFF;
	fw_build   = (fw_ver       ) & 0xFFFF;
	dev_info(&dev->dev, "FW:%d.%d #%d\n",fw_ver_maj,fw_ver_min, fw_build);

	priv = devm_kzalloc(&dev->dev, sizeof(*priv),GFP_KERNEL);
	if(!priv)
		return -ENOMEM;

	priv->pdev  = dev; 		/* soft link for file operation use */
	pci_set_drvdata(dev, priv);	/* soft link for deiver model usage */
	priv->info = &epci_board_info[epci_v1]; /* V1.00 memory map */

	ret = pci_enable_device(dev);
	if(ret < 0) {
		dev_err(&dev->dev, "pci_enable_device() filed for %s\n",EPCI_DEV_NAME);
		goto error_pci;
	}

	priv->memaddr = pci_resource_start(dev, EPCI_MEM_BAR);
	if(!priv->memaddr) {
		dev_err(&dev->dev, "no IO address at PCI BAR%d\n",EPCI_MEM_BAR);
		ret = -ENODEV;
		goto error_pci;
	}

	if((pci_resource_flags(dev, EPCI_MEM_BAR) & IORESOURCE_MEM) == 0) {
		dev_err(&dev->dev, "no MEM resource at PCI BAR%d\n",EPCI_MEM_BAR);
		ret = -ENODEV;
		goto error_pci;
	}

	ret = pci_request_region(dev, EPCI_MEM_BAR, EPCI_DEV_NAME);
	if(ret < 0) {
		dev_err(&dev->dev, "I/O resource @0x%lx busy\n",priv->memaddr);
		goto error_pci;
	}

	priv->base = pci_iomap(dev, EPCI_MEM_BAR, 0);	
	if(priv->base == NULL) {
		dev_err(&dev->dev, "pci_iomap() failed\n");
		ret = -ENOMEM;
		goto error_map;
	}
	
	/*--------------------------------------------------------------*/
	/* PCI is available now. time to register in various frameworks */
	/*--------------------------------------------------------------*/
	// /* char device  */
	ret = epci_mem_register(priv);
	if(ret < 0)
		goto error_mem;

	/* led device */
	ret = epci_leds_register(priv);
	if(ret < 0) 
		goto error_led_alloc;

	return 0;

error_led_alloc:
	epci_mem_unregister(priv);
error_mem:
	pci_iounmap(dev, priv->base);
error_map:
	pci_release_region(dev, EPCI_MEM_BAR);
error_pci:
	/* devm_kfree(&dev->dev, priv); */

	return ret;
}

/**
*	epci remove 
*/
void epci_remove(struct pci_dev *dev)
{
	struct epci_priv * priv = NULL;
	priv = pci_get_drvdata(dev);
	
	epci_leds_unregister(priv);
	epci_mem_unregister(priv);
	pci_iounmap(dev, priv->base);
	pci_release_region(dev, EPCI_MEM_BAR);
	/* by using devm_ allocation function, there is no need to free */
	/* devm_kfree(&dev->dev, priv); */
}


/**
*	driver main structure
*/
static struct pci_driver epci_driver = {
	.name      =  EPCI_DEV_NAME,
	.probe     =  epci_probe,
	.remove    =  epci_remove,
	.id_table  =  epci_pci_tbl,
};

MODULE_AUTHOR("Arash Golgol");
MODULE_DESCRIPTION("EPCI-V1.0X char driver");
MODULE_LICENSE("GPL");

module_pci_driver(epci_driver);
