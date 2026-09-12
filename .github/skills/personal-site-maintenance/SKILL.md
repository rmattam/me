---
name: personal-site-maintenance
description: 'Maintain and redesign the GitHub Pages personal resume site in docs/. Use when updating its UI, content, navigation, portfolio sections, responsive behavior, carousel, links, analytics, chat, deployed assets, credentials, or secrets.'
---

# Personal Site Maintenance

Use this workflow for feature and design changes to the personal website.

## Current Architecture

- GitHub Pages serves `docs/index.html` and paths below `docs/`; keep all browser URLs relative to that directory.
- The site is a static Bootstrap 4 single-page resume. It does not have a package manifest or required build step.
- `docs/index.html` owns content and section order.
- `docs/scss/` and `docs/js/resume.js` are the readable style and behavior sources.
- `docs/css/modern.css` is the readable, directly deployed visual override layer loaded after the legacy theme.
- `docs/css/resume.min.css` and `docs/js/resume.min.js` are the files loaded in production. Always keep them behaviorally aligned with their readable sources.
- Local vendor files provide Bootstrap, jQuery, and jQuery Easing. Font Awesome and Google Fonts load from CDNs.

## Existing User-Facing Behavior

Preserve these contracts unless a feature request explicitly replaces one:

1. Navigation links scroll to `#about`, `#blog`, `#experience`, `#education`, `#gallery`, `#questions`, and `#credits`.
2. Bootstrap ScrollSpy marks the current navigation link active.
3. The mobile navigation collapses after a section link is selected.
4. Elements with `data-toggle="tooltip"` receive Bootstrap tooltips.
5. The Resume link downloads `cv/Resume_Rahulroymattam.pdf`.
6. About exposes email and LinkedIn, GitHub, Facebook, Twitter, and Instagram links.
7. Articles links to the existing Medium post.
8. Gallery uses a Bootstrap carousel with seven local images, indicators, captions, and previous/next controls.
9. Contact links to the GitHub issue tracker and email.
10. Google Analytics and Crisp Chat are initialized from `docs/index.html`.

## Change Workflow

1. Read `docs/index.html`, the relevant files in `docs/scss/`, and `docs/js/resume.js` before changing behavior.
2. Preserve section IDs, local asset paths, download semantics, and external destinations when the request is visual only.
3. Prefer semantic HTML, visible keyboard focus, descriptive image/link labels, and reduced-motion support.
4. Make layouts work at mobile, tablet, and desktop widths. Check that navigation, headings, dates, captions, and controls do not overlap or clip.
5. Update readable sources first. Then update the production files referenced by `docs/index.html`.
6. Do not introduce a framework or build dependency for a focused change unless the user asks for it.
7. Keep third-party analytics/chat code intact unless the user asks to remove or replace it.

## Credentials and Secrets

- Never add, commit, or expose credentials or secrets anywhere in this repository, including source files, generated assets, configuration, documentation, tests, logs, screenshots, or Git patches.
- Treat passwords, private keys, access tokens, API secrets, connection strings, session cookies, and private certificates as secrets.
- Use clearly fake placeholders or documented environment-variable names when an example needs a credential-shaped value. Do not place real values in chat, commands, fixtures, or local files.
- Before finishing any change, inspect all changed, staged, and untracked files for secret-like values. Also review the complete commit diff when preparing a commit.
- If a secret is found, stop it from being committed, remove it from the working change without exposing its value, and tell the user to revoke or rotate it. Do not assume deletion from the latest file removes it from Git history.
- Google Analytics measurement IDs and Crisp Website IDs embedded in client-side HTML are public identifiers, not authentication credentials. Never add associated API secrets or account credentials.

## Validation

1. Serve `docs/` as the web root when browser testing so relative paths match GitHub Pages.
2. Check the browser console for missing assets and JavaScript errors.
3. Exercise every navigation item, mobile menu close behavior, resume download, carousel controls, email link, and external links.
4. Capture desktop and mobile screenshots. Verify the first viewport clearly identifies Rahul, images load, focus states are visible, and content remains readable.
5. Confirm the committed CSS and JavaScript loaded by `docs/index.html` include the final changes.
6. Review `git status`, staged and unstaged diffs, and untracked files for credentials or secrets before declaring the work complete.