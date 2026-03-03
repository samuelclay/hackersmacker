Release a new version of Hacker Smacker.

## Steps

1. **Bump version**: Update the version string in all three manifest/package files:
   - `client/chrome/manifest.json`
   - `client/firefox/manifest.json`
   - `client/firefox/package.json`

2. **Build for production**: Run `make prod` to compile CoffeeScript, copy files to all extension directories, reset `config.js` to production, and package `client/chrome.zip` and `client/firefox.zip` for store submission.

3. **Write release notes**: Look at all commits since the last version bump (use `git log` to find the previous version bump commit). Write concise, user-facing release notes summarizing what changed. Output the release notes so the user can paste them into the store submission.

4. **Commit and push**: Commit all changed files (compiled JS, manifests, source) and push to remote.

5. **Deploy server**: Run:
   ```
   ssh -i /srv/secrets-newsblur/keys/newsblur.key root@hackersmacker.org "cd /srv/hackersmacker && git pull && systemctl restart hackersmacker"
   ```

6. **Remind user** to submit the new extension version to the stores:
   - **Chrome/Edge**: Upload `client/chrome.zip` to https://chrome.google.com/webstore/devconsole
   - **Firefox**: Upload `client/firefox.zip` to https://addons.mozilla.org/en-US/developers/addons
   - **Safari**: Submit via https://appstoreconnect.apple.com

   Also reload the local extension in `chrome://extensions`.

## Notes

- Always run `make prod` before committing — it compiles `.coffee` files, copies built assets to all extension directories, and packages the zips.
- `config.js` is gitignored. `make prod` resets it to the production default. `make dev` sets it to `localhost:3040`.
- The server runs Node 7.x with no CoffeeScript compiler, so always commit compiled `.js` files.
- No Docker on production — it runs node directly via systemd as `hackersmacker.service`.
