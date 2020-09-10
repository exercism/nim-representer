set -e

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "slug and solution directory must be present"
    exit 1
fi
nim c --outdir:bin/ -d:slug="$1" -d:dir="$2" src/representer
