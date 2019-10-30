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
*	epci file operations 
*/
static ssize_t epci_read(struct file * file, char __user * buf, size_t count, loff_t *offset)
{
	return 0;
}

static ssize_t epci_write(struct file * file, const char __user * buf, size_t count, loff_t *offset)
{
	return 0;
}

static loff_t epci_llseek(struct file * file, loff_t offset, int whence)
{
	return 0;
}

static int epci_open(struct inode * inode, struct file * file)
{
	return 0;
}

static int epci_release(struct inode * inode, struct file * file)
{
	return 0;
}

static const struct file_operations epci_fops = {
	.owner   = THIS_MODULE,
	.read    = epci_read,
	.write   = epci_write,
	.llseek  = epci_llseek,
	.open    = epci_open,
	.release = epci_release,
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
	printk(KERN_NOTICE "PCI device: vendor: %#04x, device: %#04x \r\n",dev->vendor, dev->device);
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
