# README

#### To run a local development server:
```bash
# Will build and then run a local web server
bundle exec jekyll serve

# If the above command returns an error that jekyll couldn't be found; run:
bundle install
```

#### To see the minima template default files:
```bash
# You can override theme defaults by creating those files here
bundle info --path minima
```
Reference: https://jekyllrb.com/docs/themes/#overriding-theme-defaults

#### To build and output the static site:
```bash
# If you forget to build, the files may show canonical of localhost which would have been 
# generated due to jekyll serve command for local development.
jekyll build
```
After the build, do a commit and push of all files, including any files that have been built and generated on the _site directory.