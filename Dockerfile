FROM colstrom/ruby

RUN gem install superluminal

ENTRYPOINT ["superluminal"]
