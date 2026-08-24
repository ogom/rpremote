# Releasing rpremote

This checklist prepares and publishes one immutable gem version. Run every
command from `packages/rpremote`.

## 1. Prepare the version

1. Update `Rpremote::VERSION` in `lib/rpremote/version.rb`.
2. Add the same version and release date to `CHANGELOG.md`.
3. Commit all intended files and verify that `git status --short` is empty.
4. Run the non-publishing release check:

   ```sh
   bundle exec rake release:check
   ```

The check runs the specs, RuboCop, and RBS validation; builds the gem; checks
its metadata and packaged documentation; installs it into a temporary isolated
gem directory; and executes the installed `rpremote --version` command.

## 2. Prepare publishing services

The repository must have an `origin` remote before releasing. Confirm it with:

```sh
git remote -v
```

For the first RubyGems.org release, confirm that the `rpremote` name is
available and configure either RubyGems MFA for a manual push or a pending
trusted publisher for GitHub Actions. Never commit an API key or
`~/.gem/credentials`.

## 3. Publish deliberately

`bundle exec rake release` is a publishing command: it creates and pushes the
version tag and pushes the built gem to RubyGems.org. Run it only after the
release check passes and the working tree is clean:

```sh
bundle exec rake release
```

After the tag exists on GitHub, create a GitHub Release and attach the exact
gem that passed validation. `--verify-tag` prevents GitHub CLI from silently
creating a tag at another commit:

```sh
gh release create v0.1.0 rpremote-0.1.0.gem \
  --verify-tag --generate-notes
```

Replace `0.1.0` in both places for later versions. Finally, install from
RubyGems.org in a fresh environment and run `rpremote --version`.
