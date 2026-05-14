docs_dir := env("DOCS_DIR", "docs")
docs_port := env("DOCS_PORT", "5173")

[doc('Serve docs')]
[no-cd]
dev:
    bun run --cwd {{ docs_dir }} docs:dev --port {{ docs_port }}

[doc('Build docs')]
[no-cd]
build:
    bun run --cwd {{ docs_dir }} docs:build

[doc('Preview docs')]
[no-cd]
preview:
    bun run --cwd {{ docs_dir }} docs:preview --port {{ docs_port }}
