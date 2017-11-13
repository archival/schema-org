FROM jekyll/jekyll:latest

# Bundle install first to prevent reinstall on each code change, see:
# https://medium.com/@fbzga/how-to-cache-bundle-install-with-docker-7bed453a5800
COPY Gemfile* /tmp/
WORKDIR /tmp
RUN bundle install

# Add current host dir contents to image
COPY . /srv/jekyll
WORKDIR /srv/jekyll

EXPOSE 4000

CMD ["bundle","exec","jekyll","serve","--host","0.0.0.0","--port","4000"]
