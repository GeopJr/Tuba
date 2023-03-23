<p align="center">
  <img alt="A tuba in the style of GNOME icons" width="160" src="./data/icons/color.svg">
</p>
<h1 align="center">Tuba</h1>
<h3 align="center">Browse the Fediverse</h3>
<p align="center">
  <br />
    <a href="./CODE_OF_CONDUCT.md"><img src="https://img.shields.io/badge/Contributor%20Covenant-v2.1-1970e3.svg?style=for-the-badge&labelColor=A2C4FA" alt="Contributor Covenant v2.1" /></a>
    <a href="./LICENSE"><img src="https://img.shields.io/badge/LICENSE-GPL--3.0-1970e3.svg?style=for-the-badge&labelColor=A2C4FA" alt="License GPL-3.0" /></a>
    <a href="https://github.com/GeopJr/Tuba/actions/workflows/build.yml"><img alt="GitHub CI Status" src="https://img.shields.io/github/actions/workflow/status/GeopJr/Tuba/build.yml?branch=main&style=for-the-badge&labelColor=A2C4FA"></a>
    <a href='https://stopthemingmy.app'><img width='193.455' alt='Please do not theme this app' src='https://stopthemingmy.app/badge.svg'/></a>
</p>

<p align="center">
    <img alt="Screenshot of the Tuba app in light and mobile view. The current view is the main one on the 'Home' tab. The 'Notifications' tab has the number 15 in an accent-colored bubble. There are 3 posts visible by BASIL, AUBREY and HERO (only the boost tag) showcasing some of Tuba's features: 1. Image attachments, 2. custom emojis, 3. content warnings, 4. reboosts, 5. notification badges, 6.post indicators, 7. post actions." src="https://i.imgur.com/jKmFZou.png">
</p>

# Install

## Official

### Release

<a href="https://flathub.org/apps/dev.geopjr.Tuba" rel="noreferrer noopener" target="_blank"><img loading="lazy" draggable="false" width='240' alt='Download on Flathub' src='https://dl.flathub.org/assets/badges/flathub-badge-en.png' /></a>

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
libglib-2.0-dev | 2.71.2
libjson-glib-dev | 1.4.4
libxml2-dev | 2.9.10
libgee-0.8-dev | 0.8.5
libsoup2.4-dev | 2.64
libgtk-4-dev | 4.3.0
libadwaita-1.0-dev | 1.2.0
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

# Screenshots

<details>
<summary>View All</summary>

<table>
  <tr>
    <td align="center"><img loading="lazy" draggable="false" alt="Screenshot of the Tuba app in light and mobile view. The current view is the home one. The main window is inactive as there's the compose modal open. The modal's privacy setting dropdown is open. This screenshot showcases: 1. that you can write posts, 2. you can use emojis, 3. it supports character limits of the instance, 4. you can change privacy settings, 5. you can attach media, 5. you can set content warnings" src="https://i.imgur.com/3essApP.png" /></td>
    <td align="center"><img loading="lazy" draggable="false" alt="Screenshot of the Tuba app in dark and mobile view. The current view is the main one on the 'Home' tab. The 'Notifications' tab has the number 15 in an accent-colored bubble. There are 3 posts visible by BASIL, AUBREY and HERO showcasing some of Tuba's features: 1. Image attachments, 2. custom emojis, 3. content warnings, 4. reboosts, 5. notification badges, 6.post indicators, 7. post actions." src="https://i.imgur.com/Q3lnP51.png" /></td>
  </tr>
  <tr>
    <td colspan="2" align="center"><img loading="lazy" draggable="false" alt="Screenshot of the Tuba app in light and large window size view. The current view is the main one on the 'Home' tab. 2 more posts are visible now by the users HERO and KEL. The screenshot showcases: 1. poll support, 2. user mentions in posts, 3. large window size." src="https://i.imgur.com/XBtQsya.png" /></td>
  </tr>
  <tr>
    <td align="center"><img loading="lazy" draggable="false" alt="Screenshot of the Tuba app in dark and mobile view. The current view is the search one on the 'Hashtags' tab. The search entry has '#linux' as its content. There's a full page of results returned showcasing Tuba's search functionality and ability to return how many times each hashtag was used and by how many people in the past 2 days." src="https://i.imgur.com/VxeOMOg.png" /></td>
    <td align="center"><img loading="lazy" draggable="false" alt="Screenshot of the Tuba app in light and medium window size view. The current view is the profile one on the user Xenia. This screenshot showcases: 1. verified links, 2. the ability to follow users, 3. posts, following and follower counts, 4. profile headers, 5. the sidebar." src="https://i.imgur.com/jBF85mI.png" /></td>
  </tr>
</table>

</details>

# Sponsors

<div align="center">

[![GeopJr Sponsors](https://cdn.jsdelivr.net/gh/GeopJr/GeopJr@main/sponsors.svg)](https://github.com/sponsors/GeopJr)

</div>

# Acknowledgements

- Tuba is a fork of [Tootle](https://github.com/bleakgrey/tootle) by [Bleak Grey](https://github.com/bleakgrey)
- Translations are managed by [Weblate](https://hosted.weblate.org/engage/tuba/)

[![Translation status](https://hosted.weblate.org/widgets/tuba/-/tuba/287x66-white.png)](https://hosted.weblate.org/engage/tuba/)

# Contributing

1. Read the [Code of Conduct](./CODE_OF_CONDUCT.md)
2. Fork it ( https://github.com/GeopJr/Tuba/fork )
3. Create your feature branch (git checkout -b my-new-feature)
4. Commit your changes (git commit -am 'Add some feature')
5. Push to the branch (git push origin my-new-feature)
6. Create a new Pull Request
