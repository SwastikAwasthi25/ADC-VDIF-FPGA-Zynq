# Public repository contribution and publication rules

This is a public repository. Before staging source files or artifacts:

1. Publish only code, testbenches, constraints, and documents you authored or have explicit permission to release.
2. Exclude proprietary laboratory IP, unpublished research data, licensed third-party materials, passwords, tokens, private hostnames, and personal contact information.
3. Never commit generated Vivado run/cache/simulation folders, routed checkpoints, large binaries, or bitstreams unless a specific release policy and publication permission allow them.
4. Verify the board pinout, timing constraints, and versioned block-design IP dependencies rather than silently reusing machine-specific absolute paths.
5. Maintain precise verification labels: simulation PASS, synthesis complete, routed timing met on constrained paths, and physical-hardware status are different claims.
6. Review `git status` and `git diff --cached --name-status` before every push. Prefer a minimal, auditable commit.
7. Do not assume `.gitignore` prevents already tracked files or confidential files with unusual extensions from being committed.
