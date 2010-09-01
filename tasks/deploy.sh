#!/usr/bin/env bash
jekyll --lsi && rsync -avz --delete _site/ tutoriaux-rails@ssh.alwaysdata.com:www