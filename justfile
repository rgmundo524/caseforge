default: build

validate:
    @echo "TODO: validate inputs per spec"

canonicalize:
    @echo "TODO: canonicalize deposits CSVs"

render:
    @echo "TODO: render LaTeX fragments"

pdf:
    @echo "TODO: compile PDF"

build: validate canonicalize render pdf
    @echo "Pipeline complete"

test:
    @echo "TODO: add tests"
