# For HTTPS to work we need to create both a root cert and a child cert

/certificate
add name=root-cert common-name=MyRouter days-valid=3650 key-usage=key-cert-sign,crl-sign subject-alt-name=DNS:routeros.soverance.net,IP:192.168.125.1,email:support@soverance.net
sign root-cert
add name=https-cert common-name=MyRouter days-valid=3650 subject-alt-name=DNS:routeros.soverance.net,IP:192.168.125.1,email:support@soverance.net
sign ca=root-cert https-cert

# We then need to assign the cert to www-ssl service and enable it, while disabling non-https variant:

/ip service
set www-ssl certificate=https-cert disabled=no
set www disabled=yes