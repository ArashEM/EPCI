/**
*	ecpi driver
*	Copyright (C) 2019	arash.golgol@gmail.com
*
*/
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/module.h>
#include <linux/pci.h>
#include <linux/cdev.h>



/**
*	ecpi private data structure
*/
struct epci_priv {
	struct cdev       cdev;		/* inherit char device */
	struct pci_dev    *pdev;   	/* soft link to pci device */
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
	return 0;
}

/**
*	epci remove 
*/
void epci_remove(struct pci_dev *dev)
{

}


/**
*	driver main structure
*/
static struct pci_driver epci_driver = {
	.name = "epci",
	.probe = epci_probe,
	.remove = epci_remove,
	.id_table = epci_pci_tbl,
};

MODULE_AUTHOR("Arash Golgol");
MODULE_DESCRIPTION("EPCI-V1.0X char driver");
MODULE_LICENSE("GPL");

module_pci_driver(epci_driver);
