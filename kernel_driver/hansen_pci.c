
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/pci.h>
#include <linux/cdev.h>
#include <linux/fs.h>
#include <linux/uaccess.h>

#define DRIVER_NAME "hansen_accel"
#define VENDOR_ID 0x1234 // Custom FPGA Vendor ID (mock)
#define DEVICE_ID 0x0001 // Hansen Core ID

// Module Info
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Gabriel Hansen");
MODULE_DESCRIPTION("PCIe Driver for Hansen Accelerator");
MODULE_VERSION("1.0");

// Device State
struct hansen_dev {
    struct pci_dev *pdev;
    void __iomem *bar0_base;
    dev_t dev_major;
    struct cdev cdev;
    struct class *class;
};

static struct hansen_dev *my_hansen_dev;

// -- File Operations --

static int hansen_open(struct inode *inode, struct file *file) {
    return 0;
}

static int hansen_release(struct inode *inode, struct file *file) {
    return 0;
}

// Write to device (User Space -> Kernel -> MMIO)
static ssize_t hansen_write(struct file *file, const char __user *buf, size_t count, loff_t *ppos) {
    // Simple protocol: First 4 bytes = Address, Rest = Data
    u32 off;
    u8 *kbuf;
    int ret;
    int i;
    
    if (count < 4) return -EINVAL;
    
    kbuf = kmalloc(count, GFP_KERNEL);
    if (!kbuf) return -ENOMEM;
    
    if (copy_from_user(kbuf, buf, count)) {
        kfree(kbuf);
        return -EFAULT;
    }
    
    // Extract Address
    off = *(u32*)kbuf;
    
    // Write Data to BAR0
    // Note: This is slow byte-banging. Real driver would use DMA (dma_alloc_coherent).
    for (i = 4; i < count; i++) {
        writeb(kbuf[i], my_hansen_dev->bar0_base + off + (i - 4));
    }
    
    kfree(kbuf);
    return count;
}

// Read from device
static ssize_t hansen_read(struct file *file, char __user *buf, size_t count, loff_t *ppos) {
    // Mock read: Reads from offset 0x0
    u32 val;
    if (count < 4) return -EINVAL;
    
    val = readl(my_hansen_dev->bar0_base + 0); // Read 32-bit word at offset 0
    
    if (copy_to_user(buf, &val, 4)) return -EFAULT;
    
    return 4;
}

static const struct file_operations hansen_fops = {
    .owner = THIS_MODULE,
    .open = hansen_open,
    .release = hansen_release,
    .write = hansen_write,
    .read = hansen_read,
};

// -- PCIe Probing --

static int hansen_probe(struct pci_dev *pdev, const struct pci_device_id *id) {
    int ret;
    
    printk(KERN_INFO "hansen: Probing device %04x:%04x\n", pdev->vendor, pdev->device);
    
    // 1. Enable Device
    ret = pci_enable_device(pdev);
    if (ret) return ret;
    
    // 2. Request Regions
    ret = pci_request_regions(pdev, DRIVER_NAME);
    if (ret) goto err_disable;
    
    // 3. Alloc Struct
    my_hansen_dev = kzalloc(sizeof(struct hansen_dev), GFP_KERNEL);
    if (!my_hansen_dev) {
        ret = -ENOMEM;
        goto err_regions;
    }
    my_hansen_dev->pdev = pdev;
    
    // 4. Map BAR0
    my_hansen_dev->bar0_base = pci_iomap(pdev, 0, 0);
    if (!my_hansen_dev->bar0_base) {
        ret = -ENOMEM;
        goto err_kfree;
    }
    
    // 5. Register Char Device
    ret = alloc_chrdev_region(&my_hansen_dev->dev_major, 0, 1, DRIVER_NAME);
    if (ret < 0) goto err_iounmap;
    
    cdev_init(&my_hansen_dev->cdev, &hansen_fops);
    ret = cdev_add(&my_hansen_dev->cdev, my_hansen_dev->dev_major, 1);
    if (ret < 0) goto err_unregister;
    
    // Create Class for /dev node
    my_hansen_dev->class = class_create("hansen_class");
    if (IS_ERR(my_hansen_dev->class)) goto err_cdev_del;
    
    device_create(my_hansen_dev->class, NULL, my_hansen_dev->dev_major, NULL, "hansen0");
    
    printk(KERN_INFO "hansen: Probe successful. BAR0 mapped at %p\n", my_hansen_dev->bar0_base);
    return 0;

err_cdev_del:
    cdev_del(&my_hansen_dev->cdev);
err_unregister:
    unregister_chrdev_region(my_hansen_dev->dev_major, 1);
err_iounmap:
    pci_iounmap(pdev, my_hansen_dev->bar0_base);
err_kfree:
    kfree(my_hansen_dev);
err_regions:
    pci_release_regions(pdev);
err_disable:
    pci_disable_device(pdev);
    return ret;
}

static void hansen_remove(struct pci_dev *pdev) {
    if (my_hansen_dev) {
        device_destroy(my_hansen_dev->class, my_hansen_dev->dev_major);
        class_destroy(my_hansen_dev->class);
        cdev_del(&my_hansen_dev->cdev);
        unregister_chrdev_region(my_hansen_dev->dev_major, 1);
        pci_iounmap(pdev, my_hansen_dev->bar0_base);
        kfree(my_hansen_dev);
    }
    pci_release_regions(pdev);
    pci_disable_device(pdev);
    printk(KERN_INFO "hansen: Device removed\n");
}

// PCI ID Table
static const struct pci_device_id hansen_ids[] = {
    { PCI_DEVICE(VENDOR_ID, DEVICE_ID) },
    { 0, }
};
MODULE_DEVICE_TABLE(pci, hansen_ids);

// PCI Driver Struct
static struct pci_driver hansen_driver = {
    .name = DRIVER_NAME,
    .id_table = hansen_ids,
    .probe = hansen_probe,
    .remove = hansen_remove,
};

// Init/Exit
static int __init hansen_init(void) {
    printk(KERN_INFO "hansen: Module loaded\n");
    return pci_register_driver(&hansen_driver);
}

static void __exit hansen_exit(void) {
    pci_unregister_driver(&hansen_driver);
    printk(KERN_INFO "hansen: Module unloaded\n");
}

module_init(hansen_init);
module_exit(hansen_exit);
