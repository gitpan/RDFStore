s/\&\([[:alnum:]]*\([^;[:alnum:]]\|$\)\)/\&amp;\1/g
s/ about=/ r:about=/;
s/r:id="/r:ID="\&dmoz;profiles\//;
s/rdf"/rdf\/"/;
s/TR\/RDF\//1999\/02\/22-rdf-syntax-ns#/;
s/<RDF /<r:RDF /;
s/<\/RDF/<\/r:RDF/
s/d:displayname/displayname/g
s/d:homepage/homepage/g
s/d:email/email/g
s/d:Text/d:Description/g
s/r:resource="Top\//r:resource="/
s/r:resource="/r:resource="\&dmoz;/

s/<homepage>\(.*\)<\/homepage>/<homepage r:resource="\1"\/>/

s/^\&lt;html.*/<\/d:Description>/
s/<img/\&lt;img/

