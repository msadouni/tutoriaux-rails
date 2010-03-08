#!/usr/bin/env bash
jekyll && rsync -avz --delete _site/ tutoriaux-rails@ssh.alwaysdata.com:www