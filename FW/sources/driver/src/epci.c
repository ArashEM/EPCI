/**
*	epci driver
*	Copyright (C) 2019	arash.golgol@gmail.com
*
*/
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/module.h>
#include <linux/pci.h>
#include <linux/cdev.h>
#include <linux/errno.h>
#include <linux/io.h>
#include <linux/moduleparam.h>
#include <linux/uaccess.h>
#include <linux/leds.h>

/**
*	constants
*/
const  unsigned EPCI_MAX_DEV	= 1;
const  char	EPCI_DEV_NAME[]	= "epci-mem";
const  unsigned EPCI_MEM_BAR	= 0;

const  int	EPCI_FW_VER	= 0x40;	/* fw version offset */

/**
*	module parameters
*/
static int	mem_len = 256;	/*how many bytes is available in BAR of EPCI*/
module_param(mem_len, int, S_IRUGO);
MODULE_PARM_DESC(mem_len, "Lenght of memory part in EPCI");

/**
*	EPCI leds private data
*/
struct epci_led {
	char   	name[32];
	int	led_num;			/* currently 0 to 2 */
	struct 	led_classdev led_cdev;		/* inherit led class device */
	enum 	led_brightness brightness;
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


/**
*	epci file operations 
*/
static ssize_t 
epci_read(struct file * file, char __user * buf, size_t count, loff_t *offset)
{
	struct epci_priv * priv = NULL;
	ssize_t	ret = 0;

	priv = file->private_data;

	if(*offset > priv->size)
		goto out;
	if(*offset + count > priv->size)
		count = priv->size - *offset;

	if(copy_to_user(buf, priv->base, count)) {
		ret = -EFAULT;
		goto out;
	}
	
	*offset += count;
	ret = count;
out:
	return ret;
	
}

static ssize_t 
epci_write(struct file * file, const char __user * buf, size_t count, loff_t *offset)
{
	struct epci_priv * priv = NULL;
	ssize_t	ret = -ENOMEM;

	priv = file->private_data;
	
	if(count > priv->size)
		count = priv->size;
	
	if(copy_from_user(priv->base, buf, count)) {
		ret = -EFAULT;
		goto out;
	}
	
	*offset += count;
	ret = count;
out:
	return ret;
}

static loff_t 
epci_llseek(struct file * file, loff_t offset, int whence)
{
	struct epci_priv * priv = NULL;
	priv = file->private_data;
	
	return 0;
}

static int epci_open(struct inode * inode, struct file * file)
{
	struct epci_priv *priv = NULL;

	/* resolve private data*/
	priv = container_of(inode->i_cdev , struct epci_priv, cdev);
	file->private_data = priv;

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
	struct	epci_priv  *priv;
	dev_t	devno = 0;
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

	if(!mem_len) {
		dev_err(&dev->dev, "memory length can not be 0\n");
		return -EINVAL;
	}

	priv = devm_kzalloc(&dev->dev, sizeof(*priv),GFP_KERNEL);
	if(!priv)
		return -ENOMEM;

	priv->size = mem_len;	/* set memory length */

	
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
	/* char device  */
	ret = alloc_chrdev_region(&devno, 0, EPCI_MAX_DEV, EPCI_DEV_NAME);
	if(ret < 0) {
		dev_err(&dev->dev, "alloc_chrdev_region() failed for %s\n",EPCI_DEV_NAME);
		goto error_alloc;
	}

	cdev_init(&priv->cdev, &epci_fops);
	priv->cdev.owner = THIS_MODULE;
	ret = cdev_add(&priv->cdev, devno, EPCI_MAX_DEV);
	if(ret < 0) {
		dev_err(&dev->dev, "cdev_add() failed for %s\n",EPCI_DEV_NAME);
		goto error_cdev;
	}		

	priv->pdev  = dev; 		/* soft link for file operation use */
	pci_set_drvdata(dev, priv);	/* soft link for deiver model usage */
	
	return 0;

error_cdev:
	unregister_chrdev_region(devno, EPCI_MAX_DEV);
error_alloc:
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
	pci_iounmap(dev, priv->base);
	pci_release_region(dev, EPCI_MEM_BAR);
	cdev_del(&priv->cdev);
	/* cdev had dev_t internaly, so we use it in unregisteration */
	unregister_chrdev_region(priv->cdev.dev, EPCI_MAX_DEV);
	/* by using devm_ allocation function, there is no need to free */
	/* devm_kfree(&dev->dev, priv); */
}


/**
*	driver main structure
*/
static struct pci_driver epci_driver = {
	.name      =  "epci",
	.probe     =  epci_probe,
	.remove    =  epci_remove,
	.id_table  =  epci_pci_tbl,
};

MODULE_AUTHOR("Arash Golgol");
MODULE_DESCRIPTION("EPCI-V1.0X char driver");
MODULE_LICENSE("GPL");

module_pci_driver(epci_driver);
