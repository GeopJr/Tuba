<p align="center">
  <img alt="A tuba in the style of GNOME icons" width="160" src="./data/icons/color.svg">
</p>
<h1 align="center">Tuba</h1>
<h3 align="center">Browse the Fediverse</h3>
<p align="center">
  <br />
    <a href="./CODE_OF_CONDUCT.md"><img src="https://img.shields.io/badge/Code%20of%20Conduct-GNOME-f5c211.svg?style=for-the-badge&labelColor=f9f06b" alt="Contributor Covenant v2.1" /></a>
    <a href="./LICENSE"><img src="https://img.shields.io/badge/LICENSE-GPL--3.0-f5c211.svg?style=for-the-badge&labelColor=f9f06b" alt="License GPL-3.0" /></a>
    <a href="https://github.com/GeopJr/Tuba/actions/workflows/build.yml"><img alt="GitHub CI Status" src="https://img.shields.io/github/actions/workflow/status/GeopJr/Tuba/build.yml?branch=main&style=for-the-badge&labelColor=f9f06b"></a>
    <a href='https://stopthemingmy.app'><img width='193.455' alt='Please do not theme this app' src='https://stopthemingmy.app/badge.svg'/></a>
</p>

<p align="center">
    <img alt="Screenshot of the Tuba app in light and mobile view. The current view is the main one on the 'Home' tab. The 'Notifications' tab has the number 15 in an accent-colored bubble. There are 3 posts visible by BASIL, AUBREY and HERO (only the boost tag) showcasing some of Tuba's features: 1. Image attachments, 2. custom emojis, 3. content warnings, 4. reboosts, 5. notification badges, 6.post indicators, 7. post actions." src="https://media.githubusercontent.com/media/GeopJr/Tuba/main/data/screenshots/screenshot-1.png">
</p>

# Install

## Official

### Release

<a href="https://flathub.org/apps/details/dev.geopjr.Tuba" rel="noreferrer noopener" target="_blank"><img loading="lazy" draggable="false" width='240' alt='Download on Flathub' src='https://flathub.org/api/badge?svg&locale=en' /></a>

### Nightly

Flatpak | Snap
:---: | :---:
[x86_64](https://nightly.link/GeopJr/Tuba/workflows/build/main/dev.geopjr.Tuba.Devel-x86_64.zip) | [x86_64](https://nightly.link/GeopJr/Tuba/workflows/build/main/snap-x86_64.zip)
[aarch64](https://nightly.link/GeopJr/Tuba/workflows/build/main/dev.geopjr.Tuba.Devel-aarch64.zip) | [aarch64](https://nightly.link/GeopJr/Tuba/workflows/build/main/snap-aarch64.zip)

## Third Party

[![A vertical list with the title 'Packaging status'. On the left side there's repos and on the right side there's the packaged version of Tuba.](https://repology.org/badge/vertical-allrepos/tuba.svg)](https://repology.org/project/tuba/versions)

## From Source

<details>
<summary>Dependencies</summary>

Package Name | Required Version
:--- |---:|
meson | 0.56
valac | 0.48
libjson-glib-dev | 1.4.4
libxml2-dev | 2.9.10
libgee-0.8-dev | 0.8.5
libsoup3.0-dev | 3.0.0
libadwaita-1.0-dev | 1.5
libsecret-1-dev | 0.20

</details>

### Makefile

```
$ make
$ make install
```

### GNOME Builder

- Clone
- Open in GNOME Builder

# Sponsors

<div align="center">

[![GeopJr Sponsors](https://cdn.jsdelivr.net/gh/GeopJr/GeopJr@main/sponsors.svg)](https://github.com/sponsors/GeopJr)

</div>

# Acknowledgements

- Tuba is a fork of [Tootle](https://github.com/bleakgrey/tootle) by [Bleak Grey](https://github.com/bleakgrey)
- Translations are managed by [Weblate](https://hosted.weblate.org/engage/tuba/)
- Design inspiration taken from [Mastodon](https://github.com/mastodon/) & [Elk](https://github.com/elk-zone/elk)

[![Translation status](https://hosted.weblate.org/widgets/tuba/-/tuba/287x66-white.png)](https://hosted.weblate.org/engage/tuba/)

# Contributing

1. Read the [Code of Conduct](./CODE_OF_CONDUCT.md)
2. Fork it ( https://github.com/GeopJr/Tuba/fork )
3. Create your feature branch (git checkout -b my-new-feature)
4. Commit your changes (git commit -am 'Add some feature')
5. Push to the branch (git push origin my-new-feature)
6. Create a new Pull Request
