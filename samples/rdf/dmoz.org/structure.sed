s/ about=/ r:about=/;
s/r:id=/r:ID=/;
s/rdf"/rdf\/"/;
s/TR\/RDF\//1999\/02\/22-rdf-syntax-ns#/;
s/<RDF /<!DOCTYPE rdf:RDF \[<!ENTITY dmoz \"http:\/\/dmoz.org\/\">\]><r:RDF /;
s/<\/RDF/<\/r:RDF/

s/r:ID="Top"/r:ID="\&dmoz;"/

s/\(r:resource=\"\)\(Top\/\)\(.*\)/\1\&dmoz;\3/;
s/\(r:ID=\"\)\(Top\/\)\(.*\)/\1\&dmoz;\3/;

/<newsGroup/!s/\(r:ID="\)\(.*:Top\/\)\(.*\)/\1\&dmoz;\3/;
/<editor/!s/\(r:ID="\)\(.*:Top\/\)\(.*\)/\1\&dmoz;\3/;
/<newsGroup/!s/\(r:resource="\)\(.*:Top\/\)\(.*\)/\1\&dmoz;\3/;
/<editor/!s/\(r:resource="\)\(.*:Top\/\)\(.*\)/\1\&dmoz;\3/;

s/\(editor r:resource="\)\(.*\)/\1\&dmoz;profiles\/\2/

