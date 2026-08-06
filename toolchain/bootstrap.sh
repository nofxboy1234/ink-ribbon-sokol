#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
toolchain_root="$project_root/.toolchain"
deps_root="$toolchain_root/deps"
patches_root="$project_root/toolchain/patches"
staging_root=$(mktemp -d "${TMPDIR:-/tmp}/ink-ribbon-toolchain.XXXXXX")
trap 'rm -rf -- "$staging_root"' EXIT

zig_version="0.17.0-dev.1464+6aff551f1"
zig_dir_name="zig-x86_64-linux-$zig_version"
zig_url="https://ziglang.org/builds/$zig_dir_name.tar.xz"
zig_sha256="f0fcc0f1d028a983eb66d873adf2687b504a710789dcc52409a5535c3ddbedc2"

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
        "https://github.com/floooh/sokol-zig/archive/9bbabc13207ca6259d171f4c22e7d88a1f7030e9.tar.gz" \
        "7f230d939b9ee4963446a64804b70f2783e504a2073a8669c7892cf81711d60f" \
        "$staged_deps/sokol"
    patch -d "$staged_deps/sokol" -p1 < "$patches_root/sokol-build.patch"

    fetch_archive \
        "https://github.com/floooh/sokol-tools-bin/archive/9adef5465d8b9e7f412b0ffd48017e2741628c27.tar.gz" \
        "2128334092d2484f1c2ce1f53105099dcea8403d53dae32048fda6ceb622b642" \
        "$staged_deps/sokolshdc"

    fetch_archive \
        "https://github.com/floooh/dcimgui/archive/b78819a94fe85676c7043b3a1ca7a210bda0797b.tar.gz" \
        "75bcd423ae3e108e6438fd5ee3bc88d17f7b790858a1c7ded53be609bc9b7124" \
        "$staged_deps/cimgui"
    patch -d "$staged_deps/cimgui" -p1 < "$patches_root/cimgui-build.patch"

    fetch_archive \
        "https://github.com/erincatto/box3d/archive/c52908c9a907714e4d3a8a30be5272a1761158e1.tar.gz" \
        "14de7d9dab29ea4ef7e268769d45cbd11690466896250f0196aac998f62edb03" \
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
printf 'sokol: 9bbabc13207ca6259d171f4c22e7d88a1f7030e9\n'
printf 'shdc: 9adef5465d8b9e7f412b0ffd48017e2741628c27\n'
printf 'cgltf: 85cd62382dfea638278962690cf515023f33ed00\n'
printf 'stb: 2c980bb59875b0d32144a71867fbdebb2f77cd20\n'
