# Test Servo on Web Archive snapshots of real web sites

This directory contains web archives, together with scripts which use them for performance testing of Servo.

## Web archives

[WARC web archives](http://iipc.github.io/warc-specifications/) are a de facto standard for archiving web content. They are the storage format for the Internet Archive [Wayback Machine](https://archive.org/web/) and supported by the [Library of Congress](http://www.loc.gov/preservation/digital/formats/fdd/fdd000236.shtml).

Web archives can be [created and viewed] in Servo, using the [pywb](https://pywb.readthedocs.io) tools, which can be installed using:
```
vitualenv -p python3 venv
source venv/bin/activate
pip install git+https://github.com/ikreymer/pywb.git
```

Using the pywb tools in http proxy mode with Servo requires the `proxychains` command (installed in Debian-based systems by `apt-get install proxychains`).


## Playing an existing archive

In this example we'll play the (WBEZ)[https://www.wbez.org/] archive.

In one window, run the `wayback` server on the WBEZ archive:
```
wayback --proxy WBEZ
```

Then, run servo with this http proxy, so when you navigtate to a recorded web site it should take you to the recorded version:
```
proxychains ${SERVO_DIRECTORY}/mach run -r --certificate-path proxy-certs/pywb-ca.pem https://www.wbez.org/
```


## Adding a new archive

In this example we'll add a web achive for an example web site (example.com)[https://www.example.com/].

First create a collection for the Example files:
```
wb-manager init Example
```

Now start recording the web archive:
```
wayback --proxy Example --live --proxy-record --autoindex
```

In another window, run Servo with this http proxy, and navigate to the web site:
```
proxychains ${SERVO_DIRECTORY}/mach run -r --certificate-path proxy-certs/pywb-ca.pem https://www.example.com/
```

Once the site has finished loading, exit Servo and the `wayback` server.

To test your archive, follow the instructions for playing an archive. In one window:
```
wayback --proxy Example
```

and in another:
```
proxychains ${SERVO_DIRECTORY}/mach run -r --certificate-path proxy-certs/pywb-ca.pem https://www.example.com/
```
