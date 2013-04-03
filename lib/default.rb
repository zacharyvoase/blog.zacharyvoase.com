require 'erb'
require 'nokogiri'

include Nanoc3::Helpers::Blogging
include Nanoc3::Helpers::Rendering
include ERB::Util

def title_of(item)
  return item[:title] if item[:title]

  content = item.compiled_content(:snapshot => :pre)
  return $1 if content =~ /<h1[^>]*>(.*)<\/h1>/i

  return item.identifier.split("/").last
end

def description_of(item)
  content = item.compiled_content(:snapshot => :body)
  html = Nokogiri::HTML(content)
  if summary = html.css('p.summary')
    return summary.text
  else
    return html.css("p").first.text
  end
end

def rel_url_for(item)
  url_for(item).gsub(%r{^#{Regexp.escape(config[:base_url])}}, "")
end

class Fixnum
  def ordinal_suffix
    if (11..13).include?(self % 100)
      "th"
    else
      case self.to_i % 10
      when 1; "st"
      when 2; "nd"
      when 3; "rd"
      else    "th"
      end
    end
  end
end
