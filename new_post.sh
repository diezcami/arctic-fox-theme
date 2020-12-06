#!/bin/bash

echo "Enter Post Title:"
read title

echo "Enter permalink"
read permalink

# TODO: optional redirect_from
# TODO: optional redirect_to

filename="$(date +%F)-$permalink.md"

# Create entry in /_posts
echo "---" > ./_posts/$filename
echo  "layout: post" >> ./_posts/$filename
echo "title: \"$title\"" >> ./_posts/$filename 
echo  "date: $(date +%F)" >> ./_posts/$filename
echo  "permalink: $permalink" >> ./_posts/$filename
echo "---" >> ./_posts/$filename
echo "<!-- ![1.png]({{site.url}}/assets/resources-$permalink/1.png) -->" >> ./_posts/$filename # Example image structure

# Create assets folder.
mkdir ./assets/resources-$permalink

# Output
echo "Created new post: _posts/$filename"
echo "Created new assets dir: _assets/resources-$permalink"