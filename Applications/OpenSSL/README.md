Install OpenSSL - 

Download the latest version of OpenSSL from SourceForge
https://sourceforge.net/projects/openssl/

Unzip it somewhere safe.

Add a new path to your environment PATH variable that points to the OpenSSL "bin" directory

C:\\[path-to-OpenSSL-install-dir]\OpenSSL\bin

Finally, add a new environment variable that points to the OpenSSL configuration file

OPENSSL_CONF=[path-to-OpenSSL-install-dir]\bin\openssl.cnf