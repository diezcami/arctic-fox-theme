#!/bin/bash


#---
#layout: post
#title: "My MacOS Tips & Tweak"
#date: 2020-04-19
#permalink: macos-tweaks
#---

echo "Enter Post Title:"
read title

echo "Enter permalink"
read permalink

# TODO: redirect_from?
# TODO: redirect_to?

filename="$(date +%F)-$permalink.md"

# Create entry in /_posts
echo "---" > ./_posts/$filename
echo  "layout: post" >> ./_posts/$filename
echo "title: \"$title\"" >> ./_posts/$filename 
echo  "date: $(date +%F)" >> ./_posts/$filename
echo  "permalink: $permalink" >> ./_posts/$filename
echo "---" >> ./_posts/$filename

# Create assets folder.
mkdir ./assets/resources-$permalink

echo "Created new post: _posts/$filename"
echo "Created new assets dir: _assets/resources-$permalink"