set -e

# Thanks rust
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "slug, solution directory and output directory must be present"
    exit 1
fi
nim c --outdir:bin/ -d:slug="$1" -d:inDir="$2" -d:outDir="$3" src/representer
