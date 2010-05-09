require 'htmlentities'

# Convert all non-XML-1.0 named entities to numeric entities.
module XHTMLEntityFixer
  ENTITY_MAP = HTMLEntities::MAPPINGS['expanded']
  BASIC_ENTITIES = %w(quot amp apos lt gt)
  
  def self.fix(xhtml)
    xhtml.gsub(named_entity_regexp) do
      if BASIC_ENTITIES.include?($1) || !(codepoint = ENTITY_MAP[$1])
        $&
      else
        "&##{codepoint};"
      end
    end
  end
  
  def self.named_entity_regexp
    @named_entity_regexp ||= begin
      key_lengths = ENTITY_MAP.keys.map { |k| k.length }.uniq
      %r{&((?:b\.)?[a-z][a-z0-9]{#{ key_lengths.min - 1 },#{ key_lengths.max - 1 }});}i
    end
  end
end


class XHTMLEntityFixerFilter < Nanoc3::Filter
  identifier :fix_entities
  type :text
  
  def run(content, options = {})
    XHTMLEntityFixer.fix(content)
  end
end
