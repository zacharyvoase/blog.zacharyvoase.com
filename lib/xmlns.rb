XMLNS = {
  "rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
  "rdfs" => "http://www.w3.org/2000/01/rdf-schema#",
  "content" => "http://purl.org/rss/1.0/modules/content/",
  "dc" => "http://purl.org/dc/elements/1.1/",
  "foaf" => "http://xmlns.com/foaf/0.1/",
  "rss" => "http://purl.org/rss/1.0/",
  "sy" => "http://purl.org/rss/1.0/modules/syndication/",
  "xsd" => "http://www.w3.org/2001/XMLSchema",
}

def xmlns
  namespaces = {}
  XMLNS.each do |key, value|
    namespaces["xmlns:#{key}"] = value
  end
  namespaces
end
