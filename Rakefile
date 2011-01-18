require 'nanoc3/tasks'

require 'active_support/inflector'
require 'i18n'
require 'json'
require 'shellwords'

desc "Create a new article"
task :new_article do |t|
  # Get title and slug.
  title = (print "Title: "; STDIN.gets).chomp
  default_slug = title.parameterize
  slug = (print "Slug [#{default_slug}]: "; STDIN.gets).chomp
  slug = default_slug if slug.empty?

  # Create the article file.
  now = Time.now
  datestring = now.strftime("%Y/%m/%d")
  filename = "content/articles/#{datestring}/#{slug}.md"
  FileUtils.mkdir_p(File.dirname(filename))
  File.open(filename, "w+") do |f|
    f.write(<<END)
---
timestamp: #{datestring.gsub("/", "-")}
kind: article
title: #{title.to_json}
---

END
  end

  # Edit the file.
  Kernel.exec ["vim", filename].shelljoin
end
