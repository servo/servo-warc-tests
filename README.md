# Test Servo on Web Archive snapshots of real web sites

This directory contains web archives, together with scripts which use them for performance testing of Servo.

[![Google Data Studio report](https://raw.githubusercontent.com/servo/servo-warc-tests/master/gds-screenshot.png)](https://datastudio.google.com/open/1eYJrJUUbLmvxEu_I-bM7s4fA-HlRvk-p)

## Web archives

[WARC web archives](https://iipc.github.io/warc-specifications/) are a de facto standard for archiving web content. They are the storage format for the Internet Archive [Wayback Machine](https://archive.org/web/) and supported by the [Library of Congress](http://www.loc.gov/preservation/digital/formats/fdd/fdd000236.shtml).

Web archives can be [created and viewed](https://github.com/servo/servo/wiki/Creating-and-viewing-WARC-web-archives-in-Servo) in Servo, using the [pywb](https://pywb.readthedocs.io) tools, which can be installed using:
```
virtualenv -p python3 venv
source venv/bin/activate
pip install git+https://github.com/ikreymer/pywb.git
```
### proxychains

Using the pywb tools in http proxy mode with Servo requires the `proxychains` command.

#### Debian-based systems:

```sh
apt-get install proxychains
```

run with `proxychains`

#### MacOS:

```sh
brew install proxychains-ng
```

run with `proxychains4`

## Playing an existing archive

In this example we'll play the [WBEZ](https://www.wbez.org/) archive.

In one window, run the `wayback` server on the WBEZ archive:
```
wayback --proxy WBEZ --port 8321
```

The port number (8321 here) should match the one in proxychains.conf.

Then, run servo with this http proxy, so when you navigtate to a recorded web site it should take you to the recorded version:
```
proxychains ${SERVO_DIRECTORY}/mach run -r --certificate-path proxy-certs/pywb-ca.pem https://www.wbez.org/
```


## Adding a new archive

In this example we'll add a web achive for an example web site [example.com](https://www.example.com/).

First create a collection for the Example files (If you installed the dependencies inside a virtual env, go into that env and then do the following):
```
wb-manager init Example
```

Now start recording the web archive:
```
wayback --proxy Example --live --proxy-record --autoindex --port 8321
```

In another window, clone and cd into the servo-warc-tests repository:
```sh
git clone https://github.com/servo/servo-warc-tests.git
cd servo-warc-tests
```
Run Servo with this http proxy, and navigate to the web site:
```
proxychains ${SERVO_DIRECTORY}/mach run -r --certificate-path ~/proxy-certs/pywb-ca.pem https://www.example.com/
```
Note: if you get an error saying this:
```
ERROR 2018-09-07T17:27:08Z: servo: Couldn't not find certificate file: Os { code: 2, kind: NotFound, message: "No such file or directory" }
```
Then make sure you have entered the correct path for `proxy-certs/pywb-ca.pem`. It should be in the same directory that your venv is in.

Once the site has finished loading, exit Servo, and then quit the `wayback` server.

To test your archive, follow the instructions for playing an archive. In the venv:
```
wayback --proxy Example --port 8321
```

and in the servo-warc-tests directory:
```
proxychains ${SERVO_DIRECTORY}/mach run -r --certificate-path ~/proxy-certs/pywb-ca.pem https://www.example.com/
```
