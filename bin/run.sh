set -e

# Thanks rust
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "slug, solution directory and output directory must be present"
    exit 1
fi

bin/representer --slug="$1" --input-dir="$2" --output-dir="$3" --print
