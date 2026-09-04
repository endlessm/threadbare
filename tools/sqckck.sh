#!/bin/bash
# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
set -ex
: "${GODOT:=godot}"
: "${GITHUB_OUTPUT:=/dev/fd/1}"
pushd "$(readlink -f "$(dirname "$0")/..")"

VERSION=$(git describe --tags)
declare -a PRUNE_FOLDERS=(
	"assets/third_party/tiny-swords-non-cc0"
	"scenes/quests/story_quests"
	"scenes/world_map"
)

echo "::group::Importing project"
$GODOT --headless --import
echo "::endgroup::"

echo "::group::Pruning project"
rm -r "${PRUNE_FOLDERS[@]}"
$GODOT --headless --script tools/sqckck.gd
rm -r .godot
echo "::endgroup::"

echo "::group::Adding Backstitch launcher"
gh release download -R inkandswitch/backstitch-launcher --pattern 'backstitch-launcher-*.zip'
unzip backstitch-launcher-*.zip
rm backstitch-launcher-*.zip
rm .gitignore.template
git add backstitch-launcher-*
echo "::endgroup::"

echo "::group::Preconfiguring Backstitch server"
cat >backstitch.cfg <<EOF
[backstitch]
available_servers = "https://alpha.backstitch.dev/"
server_url = "https://alpha.backstitch.dev/"
EOF
echo "::endgroup::"

echo "::group::Committing pruned project"
git switch --detach
git add --update
git commit --no-verify -m "Create StoryQuest kit for $VERSION"
TAG_NAME="$VERSION-storyquest-kit"
git tag --force -m "StoryQuest kit for $VERSION" "$TAG_NAME"
echo "tag_name=$TAG_NAME" >> "$GITHUB_OUTPUT"
echo "::endgroup::"

echo "::group::Creating zip file"
git archive --prefix=threadbare-storyquest/ --add-file=backstitch.cfg --format=zip --output="threadbare-storyquest-kit.zip" @
echo "::endgroup::"

echo "zip_file=threadbare-storyquest-kit.zip" >> "$GITHUB_OUTPUT"
