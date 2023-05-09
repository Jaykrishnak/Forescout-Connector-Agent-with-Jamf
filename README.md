
To install SecureConnector in the background:


1. Downloading the SecureConnector package for OS X host by opening a web browser and going to the site
In the URL, replace "fully_qualified_domain_name" with the Fully Qualified Domain Name of the Enterprise Manager.
2. Distribute this file to target endpoints.
3. Use the command-line interface or a script to perform the following
a. Unpack the archive. For example:
b. Run the ./Update.sh (http://Update.sh) script in the archive, using the following syntax: To install SecureConnector as a dissolvable executable:
To install SecureConnector as a permanent service:
Where -v determines if the SecureConnector icon is visible in the taskbar: -v 1 installs SecureConnector with a visible taskbar icon.-v 0 installs SecureConnector without a visible taskbar icon.
Invoke sudo mode only to install SecureConnector as a permanent service. Do not invoke sudo mode to install SecureConnector as a dissolvable executable.
