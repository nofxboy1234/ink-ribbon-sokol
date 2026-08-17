#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
toolchain_root="$project_root/.toolchain"
deps_root="$toolchain_root/deps"
patches_root="$project_root/toolchain/patches"
staging_root=$(mktemp -d "${TMPDIR:-/tmp}/ink-ribbon-toolchain.XXXXXX")
trap 'rm -rf -- "$staging_root"' EXIT

zig_version="0.17.0-dev.1622+2b242157b"
zig_dir_name="zig-x86_64-linux-$zig_version"
zig_url="https://ziglang.org/builds/$zig_dir_name.tar.xz"
zig_sha256="9bde4645e8d918eaa840bfcc1c8cfa9b6567cb612f7d5fe4496244e86dee702f"

zls_revision="8da87d4f3305a550e7b739bad764e34bf1e46a08"
zls_version="0.17.0-dev.44+8da87d4f"

fetch_archive() {
    local url=$1
    local sha256=$2
    local destination=$3
    local archive="$staging_root/archive"

    curl -fsSL "$url" -o "$archive"
    printf '%s  %s\n' "$sha256" "$archive" | sha256sum --check --status
    mkdir -p "$destination"
    tar -xf "$archive" --strip-components=1 -C "$destination"
}

install_zig() {
    local install_root="$HOME/.local/opt/$zig_dir_name"
    if [[ ! -x "$install_root/zig" ]]; then
        fetch_archive "$zig_url" "$zig_sha256" "$staging_root/$zig_dir_name"
        patch -d "$staging_root/$zig_dir_name" -p1 < "$patches_root/zig-stdlib.patch"
        mkdir -p "$HOME/.local/opt"
        mv "$staging_root/$zig_dir_name" "$install_root"
    fi
    mkdir -p "$HOME/.local/bin"
    ln -sfn "$install_root/zig" "$HOME/.local/bin/zig"
}

prepare_dependencies() {
    local staged_deps="$staging_root/deps"

    fetch_archive \
        "https://github.com/floooh/sokol-zig/archive/6977361859207ad33f59b33d0ac20512da6394a0.tar.gz" \
        "ad9dbfd17b97e599bf952cd790f23b8685e0df3d9dc587652a67b2c9694b2ffe" \
        "$staged_deps/sokol"
    patch -d "$staged_deps/sokol" -p1 < "$patches_root/sokol-build.patch"

    fetch_archive \
        "https://github.com/floooh/sokol-tools-bin/archive/6801e61ab7ea64dd9369ae9ff2f46d20c61fc655.tar.gz" \
        "f680d811e3e101e03230685f2196cea5bc8127700f748eeb62c454b4cd3a633b" \
        "$staged_deps/sokolshdc"

    fetch_archive \
        "https://github.com/floooh/dcimgui/archive/3a571541d522692c457482e1aaa39e9f0996f926.tar.gz" \
        "2547df48db0da7e215a4acc11dd95ba39faaeaec89a4bb2e8331ae2f4af806d4" \
        "$staged_deps/cimgui"
    patch -d "$staged_deps/cimgui" -p1 < "$patches_root/cimgui-build.patch"

    fetch_archive \
        "https://github.com/erincatto/box3d/archive/3fc20f5b453ba9e14cdf54ecafa87a2a4bcdf53c.tar.gz" \
        "3ce36c2c5c39d24a811e880910327c9a3cc31e4c6278d8d2e5da2b0a48f94df6" \
        "$staged_deps/box3d"

    fetch_archive \
        "https://github.com/jkuhlmann/cgltf/archive/85cd62382dfea638278962690cf515023f33ed00.tar.gz" \
        "793aba47e4bbe7a1a4c5822313e0b187c07cdb0a610d1ff65dcbd0619e90a65b" \
        "$staged_deps/cgltf"

    fetch_archive \
        "https://github.com/nothings/stb/archive/2c980bb59875b0d32144a71867fbdebb2f77cd20.tar.gz" \
        "9a955b1b49a4410088a2e0ee2a9c057c3c907d0c1d75454144cb980aca0ba515" \
        "$staged_deps/stb"

    fetch_archive \
        "https://github.com/zigtools/zls/archive/$zls_revision.tar.gz" \
        "621bbf0eddfcd909499338767a6d48941a9ab3d6fd3302ce72f0ccf3ebba4d43" \
        "$staged_deps/zls"
    patch -d "$staged_deps/zls" -p1 < "$patches_root/zls.patch"

    fetch_archive \
        "https://github.com/ziglibs/known-folders/archive/207c34a16e4365edc20d92c7892f962b3bed46e8.tar.gz" \
        "03fb841c2debc62c90c600f7e32d9ea21a106e79215114eec705b604d142fce8" \
        "$staged_deps/zls-deps/known_folders"
    patch -d "$staged_deps/zls-deps/known_folders" -p1 < "$patches_root/known-folders.patch"

    fetch_archive \
        "https://github.com/ziglibs/diffz/archive/d080c1eb782fff15068cabb3b82da85ce6054b74.tar.gz" \
        "a85966e6c2408f40db2fae1c56bd7eedb74259709d031fbab23fed54dd30e872" \
        "$staged_deps/zls-deps/diffz"
    patch -d "$staged_deps/zls-deps/diffz" -p1 < "$patches_root/diffz.patch"

    fetch_archive \
        "https://github.com/zigtools/lsp-kit/archive/b886a2b0d5cee85ecbcc3089b863f7517cc9ff7f.tar.gz" \
        "11e34ecf050fc888dff416d6bbe4664183b85770bd86eb6ed0d3c632c1bb193b" \
        "$staged_deps/zls-deps/lsp_kit"
    patch -d "$staged_deps/zls-deps/lsp_kit" -p1 < "$patches_root/lsp-kit.patch"

    mkdir -p "$toolchain_root/backups"
    if [[ -d "$deps_root" ]]; then
        mv "$deps_root" "$toolchain_root/backups/deps.$(date +%Y%m%d%H%M%S)"
    fi
    mv "$staged_deps" "$deps_root"
}

generate_bindings() {
    local zig="$HOME/.local/bin/zig"
    local generated="$staging_root/generated"
    mkdir -p "$generated"

    (
        cd "$staging_root"
        "$zig" translate-c -lc \
            -I "$deps_root/box3d/include" \
            -target x86_64-linux-gnu \
            "$deps_root/box3d/include/box3d/box3d.h" > "$generated/box3d.zig"
        python3 "$project_root/toolchain/copy_box3d_docs.py" \
            --headers "$deps_root/box3d/include/box3d" \
            --bindings "$generated/box3d.zig"
        "$zig" translate-c -lc \
            -I "$deps_root/cimgui/src" \
            -target x86_64-linux-gnu \
            "$deps_root/cimgui/src/cimgui.h" > "$generated/cimgui.zig"
        "$zig" translate-c -lc \
            -I "$deps_root/cgltf" \
            -target x86_64-linux-gnu \
            "$deps_root/cgltf/cgltf.h" > "$generated/cgltf.zig"
        "$zig" translate-c -lc \
            -target x86_64-linux-gnu \
            "$project_root/src/c/model_image.h" > "$generated/model_image.zig"
    )

    sed -i "s#$project_root/.toolchain/deps/##g" "$generated/box3d.zig" "$generated/cimgui.zig" "$generated/cgltf.zig" "$generated/model_image.zig"
    mkdir -p "$project_root/src/generated"
    mv "$generated/box3d.zig" "$project_root/src/generated/box3d.zig"
    mv "$generated/cimgui.zig" "$project_root/src/generated/cimgui.zig"
    mv "$generated/cgltf.zig" "$project_root/src/generated/cgltf.zig"
    mv "$generated/model_image.zig" "$project_root/src/generated/model_image.zig"
}

install_zls() {
    local zig="$HOME/.local/bin/zig"
    local install_root="$HOME/.local/opt/zls-x86_64-linux-$zls_version"

    (
        cd "$deps_root/zls"
        "$zig" build -Doptimize=safe -Dversion-string="$zls_version"
    )
    mkdir -p "$install_root"
    cp "$deps_root/zls/zig-out/bin/zls" "$install_root/zls"
    ln -sfn "$install_root/zls" "$HOME/.local/bin/zls"
}

install_zig
prepare_dependencies
generate_bindings
sed "s#@PROJECT_ROOT@#$project_root#g" \
    "$project_root/toolchain/zls-build-config.json.in" \
    > "$toolchain_root/zls-build-config.json"
install_zls

printf 'zig: %s\n' "$("$HOME/.local/bin/zig" version)"
printf 'zls:  %s\n' "$("$HOME/.local/bin/zls" --version)"
printf 'sokol: 6977361859207ad33f59b33d0ac20512da6394a0\n'
printf 'shdc: 6801e61ab7ea64dd9369ae9ff2f46d20c61fc655\n'
printf 'cimgui: 3a571541d522692c457482e1aaa39e9f0996f926\n'
printf 'box3d: 3fc20f5b453ba9e14cdf54ecafa87a2a4bcdf53c\n'
printf 'cgltf: 85cd62382dfea638278962690cf515023f33ed00\n'
printf 'stb: 2c980bb59875b0d32144a71867fbdebb2f77cd20\n'
printf 'known-folders (ZLS pin): 207c34a16e4365edc20d92c7892f962b3bed46e8\n'
printf 'diffz (ZLS pin): d080c1eb782fff15068cabb3b82da85ce6054b74\n'
printf 'lsp-kit (ZLS pin): b886a2b0d5cee85ecbcc3089b863f7517cc9ff7f\n'
