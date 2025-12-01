import fnmatch
import os
import zipfile


def main():
    love_file = os.environ["LOVE_FILE"]
    os.makedirs(os.path.dirname(love_file), exist_ok=True)

    exclude_dirs = {".git", "dist", "screenshots", ".github"}
    exclude_paths = {"docs/background"}
    exclude_globs = ["*.love", "*.psd", "*.xcf"]

    def should_skip(rel_path, fname):
        rel_norm = rel_path.replace("\\", "/")

        top = rel_norm.split("/")[0] if rel_norm else fname.split("/")[0]
        if top in exclude_dirs:
            return True

        for p in exclude_paths:
            if rel_norm == p or rel_norm.startswith(p + "/"):
                return True
            combined = f"{rel_norm}/{fname}" if rel_norm else fname
            if combined == p or combined.startswith(p + "/"):
                return True

        for pattern in exclude_globs:
            if fnmatch.fnmatch(fname, pattern):
                return True

        return False

    with zipfile.ZipFile(love_file, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for root, dirs, files in os.walk("."):
            rel_root = os.path.relpath(root, ".")
            if rel_root == ".":
                rel_root = ""

            dirs[:] = [
                d for d in dirs
                if not should_skip(os.path.join(rel_root, d), d)
            ]

            for fname in files:
                if should_skip(rel_root, fname):
                    continue
                full_path = os.path.join(root, fname)
                rel_path = os.path.join(rel_root, fname) if rel_root else fname
                zf.write(full_path, rel_path.replace("\\", "/"))


if __name__ == "__main__":
    main()
