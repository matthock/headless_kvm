This is just a script to create a fully headless KVM VM, including console mode unattended install and serial console access during and after install.

It assumes qemu-kvm is installed and that you have a bridge network interface named br0, among a few other misc. assumptions.

There is also some %post scripting to set up some OpenSCAP remediations wrt SSH and Audit Logging.
