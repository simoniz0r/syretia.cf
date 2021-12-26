#!/bin/bash

curl -sLX POST 'https://api.cloudinary.com/v1_1/syretia/image/upload' -d "$@"
