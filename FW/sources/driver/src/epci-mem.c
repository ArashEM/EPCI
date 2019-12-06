/**
*	epci memory map handler
*	Copyright (C) 2019	arash.golgol@gmail.com
*
*/
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/cdev.h>
#include <linux/fs.h>
#include <linux/pci.h>
#include <linux/uaccess.h>
#include <linux/moduleparam.h>
#include "epci.h"


/**
*	constants
*/
const  unsigned EPCI_MAX_DEV	= 1;
const  char EPCI_MEM_NAME[] = "epci-mem";


/**
*	module parameters
*/
static int	mem_len = 256;	/*how many bytes is available in BAR of EPCI*/
module_param(mem_len, int, S_IRUGO);
MODULE_PARM_DESC(mem_len, "Lenght of memory part in EPCI");

/* =================================================== 	*/
/*	file operatinos 					*/
/* =================================================== 	*/
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

	if(copy_to_user(buf, priv->base + *offset, count)) {
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
	
	if(*offset > priv->size)
		goto out;
	if(*offset + count > priv->size)
		count = priv->size - *offset;
	
	if(copy_from_user(priv->base + *offset, buf, count)) {
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

int  epci_mem_register(struct epci_priv * board)
{
	dev_t	devno = 0;
	int		ret = 0;
	struct pci_dev *dev = board->pdev;
	
	if(!mem_len) {
		dev_err(&dev->dev, "memory length can not be 0\n");
		return -EINVAL;
	}
	board->size = mem_len;		/* set memory length */
	
	/* char device  */
	ret = alloc_chrdev_region(&devno, 0, EPCI_MAX_DEV, EPCI_MEM_NAME);
	if(ret < 0) {
		dev_err(&dev->dev, "alloc_chrdev_region() failed for %s\n",EPCI_MEM_NAME);
		return ret;
	}

	cdev_init(&board->cdev, &epci_fops);
	board->cdev.owner = THIS_MODULE;
	ret = cdev_add(&board->cdev, devno, EPCI_MAX_DEV);
	if(ret < 0) {
		dev_err(&dev->dev, "cdev_add() failed for %s\n",EPCI_MEM_NAME);
		goto error_cdev;
	}		
	
	return 0;
	
error_cdev:
	unregister_chrdev_region(devno, EPCI_MAX_DEV);
	
	return ret;
}

void epci_mem_unregister(struct epci_priv * board)
{
	cdev_del(&board->cdev);
	/* cdev had dev_t internaly, so we use it in unregisteration */
	unregister_chrdev_region(board->cdev.dev, EPCI_MAX_DEV);
}
