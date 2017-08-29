#!/usr/bin/env bash
set -e # halt script on error
bundle exec jekyll build -d _site/schema-org
bundle exec htmlproofer _site
find _site/schema-org/examples -type f -print0 | xargs -0 -n1 -I % sh -c 'printf %:\ ; bundle exec rdf validate %;'
