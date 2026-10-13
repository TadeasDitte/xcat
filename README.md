# xcat

`cat` for anything. `xcat` reads a file's magic bytes to work out what it is,
then prints it with the right tool. Archive members are written to stdout one
after another.

```sh
xcat notes.txt logs.gz backup.tar.zst bundle.zip
journalctl -o export | gzip | xcat        # stdin works too
```

## Supported formats

| Detected as        | Printed with                         |
|--------------------|--------------------------------------|
| gzip / bzip2 / xz / zstd | `zcat` / `bzcat` / `xzcat` / `zstdcat` |
| tar                | `tar -xOf`                           |
| tar.gz / .bz2 / .xz / .zst | `tar -z/-j/-J/--zstd -xOf`   |
| zip                | `unzip -p`, falls back to `bsdtar -xOf`, then `python3` |
| anything else      | `cat`                                |

The file extension is ignored, so a gzip file named `foo.txt` still works.

## Install

```sh
install -m 755 xcat ~/.local/bin/xcat
```

The only requirements are a POSIX shell and coreutils (`head`, `od`, `cut`).
The decompressors are needed only for the formats you actually read. If one
is missing, `xcat` names it, skips that file, and exits with status 1.

## Tests

```sh
./test/run.sh
```
