#!/bin/sh
# Build fixtures for every supported format and check xcat's output.
set -eu

xcat=$(cd "$(dirname "$0")/.." && pwd)/xcat
dir=$(mktemp -d "${TMPDIR:-/tmp}/xcat-test.XXXXXX")
trap 'rm -rf "$dir"' EXIT
cd "$dir"

printf 'hello\nworld\n' >hello.txt
printf 'second file\n' >two.txt
cat hello.txt two.txt >both.expected

gzip -c hello.txt >hello.gz
bzip2 -c hello.txt >hello.bz2
xz -c hello.txt >hello.xz
zstd -q -c hello.txt >hello.zst
cp hello.gz sneaky.txt
tar cf both.tar hello.txt two.txt
tar czf both.tar.gz hello.txt two.txt
tar cjf both.tar.bz2 hello.txt two.txt
tar cJf both.tar.xz hello.txt two.txt
tar --zstd -cf both.tar.zst hello.txt two.txt
python3 -m zipfile -c both.zip hello.txt two.txt

pass=0 fail=0
check() { # description expected-file command...
	desc=$1 exp=$2; shift 2
	if "$@" 2>err.out | cmp -s - "$exp"; then
		pass=$((pass + 1)); echo "ok   $desc"
	else
		fail=$((fail + 1)); echo "FAIL $desc"; sed 's/^/     /' err.out
	fi
}

check plain hello.txt "$xcat" hello.txt
check gzip hello.txt "$xcat" hello.gz
check bzip2 hello.txt "$xcat" hello.bz2
check xz hello.txt "$xcat" hello.xz
check zstd hello.txt "$xcat" hello.zst
check 'gzip with .txt name' hello.txt "$xcat" sneaky.txt
check tar both.expected "$xcat" both.tar
check tar.gz both.expected "$xcat" both.tar.gz
check tar.bz2 both.expected "$xcat" both.tar.bz2
check tar.xz both.expected "$xcat" both.tar.xz
check tar.zst both.expected "$xcat" both.tar.zst
check zip both.expected "$xcat" both.zip
check 'multiple files' both.expected "$xcat" hello.gz two.txt
check 'stdin gzip' hello.txt sh -c '"$1" <hello.gz' sh "$xcat"
check 'stdin tar.xz via -' both.expected sh -c '"$1" - <both.tar.xz' sh "$xcat"

if "$xcat" missing-file >/dev/null 2>&1; then
	fail=$((fail + 1)); echo "FAIL missing file should exit nonzero"
else
	pass=$((pass + 1)); echo "ok   missing file exits nonzero"
fi

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
