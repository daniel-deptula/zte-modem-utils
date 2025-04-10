# ZTE modem utils
Utilities for ZTE cellular network modem(s) with vendor stock firmware.

Developed and tested only on ZTE MF286D model with firmware versions Nordic_MF286D_B12 and Nordic_MF286D_B14.

I know other models and versions of firmware have a similar API but I haven't found any solution on Github that would be able to successfully login and send text messages on this one (it uses sha256 password hashing as opposed to base64, md5 or plaintext which I saw other modems accept, requires to pass a cookie, uses the additional questionable hash called "AD").
