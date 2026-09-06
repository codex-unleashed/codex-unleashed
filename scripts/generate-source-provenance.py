#!/usr/bin/env python3
"""Record the exact upstream tree and patch result used for a build."""

import argparse
import hashlib
import json
import os
import subprocess
import tempfile
from pathlib import Path


def run_git(checkout: Path, *args: str, index: Path | None = None) -> str:
    env = os.environ.copy()
    if index is not None:
        env["GIT_INDEX_FILE"] = str(index)
    return subprocess.check_output(
        ["git", "-C", str(checkout), *args],
        env=env,
        text=True,
    ).strip()


def stage_source_tree(checkout: Path, index: Path) -> None:
    """Stage the patched source tree without build and dependency caches."""
    paths = run_git(
        checkout,
        "ls-files",
        "--others",
        "--exclude-standard",
        "-z",
        index=index,
    ).split("\0")
    excluded = (".cargo-home/", ".git/", "target/", ".zig-cache/")
    paths = [
        path
        for path in paths
        if path
        and path != "source-provenance.json"
        and not path.endswith(".index")
        and not any(path == prefix.rstrip("/") or path.startswith(prefix) for prefix in excluded)
        and "/target/" not in f"/{path}"
        and "/.zig-cache/" not in f"/{path}"
    ]
    run_git(checkout, "add", "--update", index=index)
    if paths:
        subprocess.run(
            ["git", "-C", str(checkout), "add", "--", *paths],
            env={**os.environ, "GIT_INDEX_FILE": str(index)},
            check=True,
        )


def sha256_git_diff(checkout: Path, index: Path) -> str:
    process = subprocess.Popen(
        ["git", "-C", str(checkout), "diff", "--cached", "--binary", "--no-ext-diff"],
        env={**os.environ, "GIT_INDEX_FILE": str(index)},
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    assert process.stdout is not None
    digest = hashlib.sha256()
    for chunk in iter(lambda: process.stdout.read(1024 * 1024), b""):
        digest.update(chunk)
    stderr = process.stderr.read().decode()
    if process.wait() != 0:
        raise RuntimeError(stderr)
    return digest.hexdigest()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--upstream-checkout", required=True, type=Path)
    parser.add_argument("--patch-repo", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--upstream-repository", default="openai/codex")
    parser.add_argument("--upstream-ref", default="")
    parser.add_argument("--workflow-path", default="")
    parser.add_argument("--workflow-sha", default="")
    parser.add_argument("--workflow-run-id", default="")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    checkout = args.upstream_checkout.resolve()
    patch_repo = args.patch_repo.resolve()
    output = args.output.resolve()
    original_commit = run_git(checkout, "rev-parse", "HEAD")

    patch_files = sorted(patch_repo.glob("patches/**/*.patch"))
    patches = []
    for path in patch_files:
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        patches.append({"path": path.relative_to(patch_repo).as_posix(), "sha256": digest})

    # Replay patches against the committed baseline in a separate index. Merely
    # hashing the build checkout cannot establish where its changes came from.
    with tempfile.TemporaryDirectory(prefix="codex-source-audit-") as temp:
        expected_index = Path(temp) / "expected.index"
        index = Path(temp) / "actual.index"
        run_git(checkout, "read-tree", "HEAD", index=expected_index)
        for path in patch_files:
            if path.is_symlink() or not path.resolve().is_relative_to(patch_repo / "patches"):
                raise ValueError(f"Patch escapes patches/: {path}")
            run_git(checkout, "apply", "--cached", "--", str(path), index=expected_index)
        expected_tree = run_git(checkout, "write-tree", index=expected_index)
        run_git(checkout, "read-tree", "HEAD", index=index)
        stage_source_tree(checkout, index)
        # New files explicitly added by a patch may match upstream .gitignore.
        additions = run_git(
            checkout, "diff", "--cached", "--name-only", "--diff-filter=A", "-z", "HEAD",
            index=expected_index,
        ).split("\0")
        for path in filter(None, additions):
            run_git(checkout, "add", "--force", "--", path, index=index)
        patched_tree = run_git(checkout, "write-tree", index=index)
        if patched_tree != expected_tree:
            tree_diff = run_git(
                checkout,
                "diff-tree",
                "--no-commit-id",
                "--name-status",
                "-r",
                expected_tree,
                patched_tree,
            )
            raise ValueError(
                "Source audit failed: checkout is not upstream HEAD plus patches/. "
                f"Expected tree {expected_tree}, got {patched_tree}. "
                f"Differing paths:\n{tree_diff}"
            )
        changed_paths = run_git(checkout, "diff", "--cached", "--name-only", "-z", "HEAD", index=index)
        changed_paths = [path for path in changed_paths.split("\0") if path]
        diff_sha256 = sha256_git_diff(checkout, index)

    manifest = {
        "schema_version": 2,
        "source_verified": True,
        "upstream": {
            "repository": args.upstream_repository,
            "ref": args.upstream_ref,
            "commit": original_commit,
            "baseline_tree": run_git(checkout, "rev-parse", "HEAD^{tree}"),
        },
        "patches": patches,
        "application_order": [patch["path"] for patch in patches],
        "patched_tree": patched_tree,
        "applied_diff_sha256": diff_sha256,
        "changed_paths": changed_paths,
        "workflow": {
            "path": args.workflow_path,
            "sha": args.workflow_sha,
            "run_id": args.workflow_run_id,
        },
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="ascii")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
