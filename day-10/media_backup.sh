#!/bin/bash

zip -r /backup/xfusioncorp_media.zip /var/www/html/media
scp /backup/xfusioncorp_media.zip natasha@ststor01:/backup/