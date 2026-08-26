# Releasing rpremote

This checklist prepares and publishes one immutable gem version. Run every command from `packages/rpremote`.

## 1. Prepare the version

1. Update `Rpremote::VERSION` in `lib/rpremote/version.rb`.
2. Add the same version and release date to `CHANGELOG.md`.
3. Commit all intended files and verify that `git status --short` is empty.
4. Run the non-publishing release check:

```sh
bundle exec rake release:check
```

The check runs the specs, RuboCop, and RBS validation; builds the gem; checks its metadata and packaged documentation; installs it into a temporary isolated gem directory; and executes the installed `rpremote --version` command.

## 2. Prepare publishing services

The repository must have an `origin` remote and GitHub CLI authentication before releasing. Confirm them with:

```sh
git remote -v
gh auth status
```

Choose one publishing route before the first release:

- For a manual release, sign in to RubyGems.org, confirm that the account owns `rpremote`, and enable MFA:

  ```sh
  gem signin
  gem owner rpremote
  ```

- For a GitHub Actions trusted publisher, confirm the RubyGems.org trusted-publisher entry names this repository and workflow before starting the release.

Never commit an API key or `~/.gem/credentials`.

## 3. Publish deliberately

`bundle exec rake release` is a publishing command: it creates and pushes the version tag and pushes the built gem to RubyGems.org. It is not a dry run. Run it only after the release check passes and the working tree is clean:

```sh
bundle exec rake release
```

After the tag exists on GitHub, create a GitHub Release and attach the exact gem that passed validation. `--verify-tag` prevents GitHub CLI from silently creating a tag at another commit:

```sh
gh release create v0.3.0 rpremote-0.3.0.gem --verify-tag --generate-notes
```

Replace `0.3.0` in both places for later versions. Finally, install from RubyGems.org in a fresh environment and run `rpremote --version`.
