require 'erb'

include Nanoc3::Helpers::Blogging
include Nanoc3::Helpers::Rendering
include ERB::Util

def title_of(item)
  return item[:title] if item[:title]
  
  content = item.compiled_content(:snapshot => :pre)
  return $1 if content =~ /<h1[^>]*>(.*)<\/h1>/i
  
  return item.identifier.split("/").last
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