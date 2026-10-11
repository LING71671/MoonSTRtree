check:
    moon check

test:
    moon test --target wasm
    moon test --target wasm-gc
    moon test --target js

interfaces:
    moon info
    moon fmt

diagnostics:
    moon run cmd/main

demo:
    cd playground && pnpm dev

verify-demo:
    cd playground && pnpm test
    cd playground && pnpm build

verify: interfaces check test
