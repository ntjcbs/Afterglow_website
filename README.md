# Afterglow website

The website for Afterglow Music Visualizer, published with GitHub Pages at [afterglowvisualizer.com](https://afterglowvisualizer.com). App Store Connect links to two of its pages:

| Page | URL | Used for |
| --- | --- | --- |
| `index.html` | https://afterglowvisualizer.com | Marketing URL |
| `support.html` | https://afterglowvisualizer.com/support.html | Support URL (required) |
| `privacy.html` | https://afterglowvisualizer.com/privacy.html | Privacy policy URL (required) |

## Files

- `index.html`, `support.html` and `style.css` are written by hand.
- `privacy.html` and everything in `images/` are generated from the app's repository by `scripts/make-site.swift`: the privacy page from its `PRIVACY.md` (the same text the app shows in Afterglow → About Afterglow), the icon from `Support/AppIcon.icon`, and the screenshots from the store media in `dist/AppStoreMedia`. Edit those sources, not the generated files.
- `CNAME` names the domain; `.nojekyll` makes GitHub Pages serve the files as they are.

After changing the privacy policy, the icon or the screenshots in the app's repository, regenerate from this repository's root:

```sh
swift scripts/make-site.swift
```

It reads the app's repository from `../Afterglow`; pass another path as an argument if it lives elsewhere. Screenshots come from `zsh Scripts/make-store-media.sh` in the app's repository; without them the existing images are kept.

## Publishing

- **GitHub Pages:** Settings → Pages → Deploy from a branch, `main`, `/ (root)`. Custom domain `afterglowvisualizer.com`, with Enforce HTTPS on.
- **DNS** (at the registrar): A records for `@` to `185.199.108.153`, `185.199.109.153`, `185.199.110.153` and `185.199.111.153`; a CNAME for `www` to `ntjcbs.github.io`.
- **Email:** support@afterglowvisualizer.com, shown on the support page, forwards to the developer's inbox through the registrar.

When the app is live, replace the "Coming soon to the Mac App Store" label in `index.html` with the App Store link and Apple's official badge.
