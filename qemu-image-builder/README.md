# Summary
Cheap&dirty mechanism for building QEMU-bootable OpenWRT images.

Running 'build-mages.sh' does the following:

1. Checks out the latest OpenWRT build SDK from GitHub
2. Copies the custom configuration from 'files' directory into the OpenWRT SDK directory
3. Builds an image for every config file in the 'build-config' directory 
5. The images are saved in the 'images' directory
6. Uploads the images to S3: http://master-thesis-lede-images.s3-eu-west-1.amazonaws.com/

N.B the default root password (as per the custom shadow file) is 'admin'


