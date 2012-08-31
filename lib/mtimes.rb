def mtime(ident_pattern)
  regex = Regexp.new(ident_pattern)
  items.select { |item| regex === item.identifier }.map { |item| item[:mtime].to_i }.max.to_s
end
