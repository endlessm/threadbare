#!/bin/bash
# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
set -ex
: ${GODOT:=godot}
pushd $(dirname "$(dirname "$0")")

VERSION=$(git describe --tags)
declare -a PRUNE_FOLDERS=(
	"assets/third_party/tiny-swords-non-cc0"
	"scenes/quests/lore_quests"
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

echo "::group::Committing pruned project"
git switch --detach
git commit --no-verify -am "Create StoryQuest kit for $VERSION"
echo "::endgroup::"

# TODO: merge this to a special branch? Push this as a tag?

echo "::group::Creating zip file"
git archive --format=zip --prefix=threadbare-storyquest/ --output="threadbare-storyquest-$VERSION.zip" @
echo "::endgroup::"

if [[ -n "$GITHUB_OUTPUT" ]]; then
  echo "zip_file=threadbare-storyquest-$VERSION.zip" >> "$GITHUB_OUTPUT"
fi
