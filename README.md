# Schema.org and Schema Architypes for linked archival description

This repository contains examples of archival description published as linked
data, demonstrating the use of Schema.org and the in-development
[Schema Architypes extension](https://www.w3.org/community/architypes/wiki/Main_Page).

The HTML version of the site is built using [Jekyll](http://jekyllrb.com/).

## Adding examples

Examples should be added as JSON-LD Schema.org expressions as a new file in the
`_examples` directory. Each source has its own subdirectory. Each file should also
have [YAML Front Matter](https://jekyllrb.com/docs/frontmatter/) at the top, with
values for `title`, `source` (institution or project), and `description` (what the
example is intended to illustrate). Here's an example of a sample collection for
a given institution, which we'd save as `_examples/given/sample.json`:

```json
---
title: Sample collection
source: Given institution
description: An example of how to provide an example
---
{
  "@context": "http://schema.org",
  "name": "Sample collection"
}
```

When you commit changes to this repository, an automated set of tests runs on
[Travis CI](https://travis-ci.org/archival/schema-org). You can check the output
there to determine if the build was successful.

## Install dependencies

You might want to build the site locally for testing, or run some of the other
automated tests. To do so, you'll need a recent version of Ruby (2.4 or later
recommended). Once you have Ruby, run the following to get the dependencies
to build locally.

```bash
gem install bundler
bundle install
```

## Build (and serve) the site

Run the following to update the locally built copy of the site:

```bash
bundle exec jekyll build
```

To serve the site and build automatically, run the following:

```bash
bundle exec jekyll serve
```

## Testing the examples

To test building of the site, run the following:

```bash
./build.sh
```

This runs three steps: building the site, running HTML Proofer (to check) for
broken links and other validation issues, and checking to see if the JSON-LD is
valid.

There is work in progress to send the generated data to Google's
[Structured Data Testing Tool](https://search.google.com/structured-data/testing-tool/).
