# armlinux

This is a build framework initially created to support sunXi and RaspberryPi boards. It may be extended in the future to support more hardware platforms. The framework supports multiple build configurations, defined by files with the extension ".conf", placed in the root folder. The existing configurations were created for my personal projects and they can be used as examples to create your own configurations.

The idea of creating own framework was born from the well-known and popular Armbian. One day I found myself in big troubles while adjusting the over-complicated solution for my own needs. Also, I didn't want myself to be dependent on anyone else in case of any issue.

So, in general, you can say it is yet another "Armbian-like" framework but I consider it something more than that.

Product Configurations
---
Any custom (or "product") configurations must be located in config/product folder. 
To register a new product, you need to create a new file here. The 3 files that are already there can be used as an example. 
The "aapi.conf" file is used to create an image for the ORPALTECH AA-PI device (see https://github.com/orpaltech/aapi).
