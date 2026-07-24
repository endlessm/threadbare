#!/bin/bash
# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
set -ex
: ${GODOT:=godot}
pushd $(dirname "$(dirname "$0")")

VERSION=$(git describe --tags)

echo "::group::Pruning project"
$GODOT --headless --import
$GODOT --headless --script tools/sqckck.gd
rm -r .godot
echo "::endgroup::"

echo "::group::Adding Backstitch launcher"
gh release download -R inkandswitch/backstitch-launcher --pattern 'backstitch-launcher-*.zip'
unzip backstitch-launcher-*.zip
rm backstitch-launcher-*.zip
rm .gitignore.template
git add backstitch-launcher-*  # ???
echo "::endgroup::"

echo "::group::Committing pruned project"
EMAIL="test@example.com" git commit --no-verify -am "Create StoryQuest kit for $VERSION"
echo "::endgroup::"

# TODO: merge this to a special branch? Push this as a tag?

echo "::group::Creating zip file"
# TODO: or should we include the `.git` folder?
git archive --format=zip --prefix=threadbare-storyquest/ --output="threadbare-storyquest-$VERSION.zip" @
