"let &makeprg="pandoc -f markdown+hard_line_breaks+compact_definition_lists -t latex -V papersize:a4paper -V geometry:margin=0.5in % -o %:r.pdf"
