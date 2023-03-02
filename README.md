<p align="center">
  <img alt="branding" width="192" src="./data/icons/color.svg">
</p>
<h1 align="center">Tooth</h1>
<h3 align="center">Browse the Fediverse</h3>
<p align="center">
  <br />
    <a href="./CODE_OF_CONDUCT.md"><img src="https://img.shields.io/badge/Contributor%20Covenant-v2.1-1970e3.svg?style=for-the-badge&labelColor=A2C4FA" alt="Contributor Covenant v2.1" /></a>
    <a href="./LICENSE"><img src="https://img.shields.io/badge/LICENSE-GPL--3.0-1970e3.svg?style=for-the-badge&labelColor=A2C4FA" alt="License GPL-3.0" /></a>
    <a href="https://github.com/GeopJr/Tooth/actions/workflows/build.yml"><img alt="GitHub CI Status" src="https://img.shields.io/github/actions/workflow/status/GeopJr/Tooth/build.yml?branch=main&style=for-the-badge&labelColor=A2C4FA"></a>
</p>

<p align="center">
    <img alt="Screenshot of the Tooth app in light and mobile view. The current view is the main one on the 'Home' tab. The 'Notifications' tab has the number 15 in an accent-colored bubble. There are 3 posts visible by BASIL, AUBREY and HERO (only the boost tag) showcasing some of Tooth's features: 1. Image attachments, 2. custom emojis, 3. content warnings, 4. reboosts, 5. notification badges, 6.post indicators, 7. post actions." src="https://i.imgur.com/YVM9YXK.png">
</p>

# Install

## Official

<!-- ### Release

<a href="https://flathub.org/apps/dev.geopjr.Tooth" rel="noreferrer noopener" target="_blank"><img loading="lazy" draggable="false" width='240' alt='Download on Flathub' src='https://dl.flathub.org/assets/badges/flathub-badge-en.png' /></a> -->

### Nightly

[x86_64](https://nightly.link/GeopJr/Tooth/workflows/build/main/dev.geopjr.Tooth.Devel-x86_64.zip) <br /> [aarch64](https://nightly.link/GeopJr/Tooth/workflows/build/main/dev.geopjr.Tooth.Devel-aarch64.zip)

## Third Party

[![A vertical list with the title 'Packaging status'. On the left side there's repos and on the right side there's the packaged version of Tooth.](https://repology.org/badge/vertical-allrepos/tooth.svg)](https://repology.org/project/tooth/versions)

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
    <td align="center"><img loading="lazy" draggable="false" alt="Screenshot of the Tooth app in light and mobile view. The current view is the home one. The main window is inactive as there's the compose modal open. The modal's privacy setting dropdown is open. This screenshot showcases: 1. that you can write posts, 2. you can use emojis, 3. it supports character limits of the instance, 4. you can change privacy settings, 5. you can attach media, 5. you can set content warnings" src="https://i.imgur.com/SjbLmdJ.png" /></td>
    <td align="center"><img loading="lazy" draggable="false" alt="Screenshot of the Tooth app in dark and mobile view. The current view is the main one on the 'Home' tab. The 'Notifications' tab has the number 15 in an accent-colored bubble. There are 3 posts visible by BASIL, AUBREY and HERO showcasing some of Tooth's features: 1. Image attachments, 2. custom emojis, 3. content warnings, 4. reboosts, 5. notification badges, 6.post indicators, 7. post actions." src="https://i.imgur.com/nqgdnqQ.png" /></td>
  </tr>
  <tr>
    <td colspan="2" align="center"><img loading="lazy" draggable="false" alt="Screenshot of the Tooth app in light and large window size view. The current view is the main one on the 'Home' tab. 2 more posts are visible now by the users HERO and KEL. The screenshot showcases: 1. poll support, 2. user mentions in posts, 3. large window size." src="https://i.imgur.com/h82kf7I.png" /></td>
  </tr>
  <tr>
    <td align="center"><img loading="lazy" draggable="false" alt="Screenshot of the Tooth app in dark and mobile view. The current view is the search one on the 'Hashtags' tab. The search entry has '#linux' as its content. There's a full page of results returned showcasing Tooth's search functionality and ability to return how many times each hashtag was used and by how many people in the past 2 days." src="https://i.imgur.com/VxeOMOg.png" /></td>
    <td align="center"><img loading="lazy" draggable="false" alt="Screenshot of the Tooth app in light and medium window size view. The current view is the profile one on the user Xenia. This screenshot showcases: 1. verified links, 2. the ability to follow users, 3. posts, following and follower counts, 4. profile headers, 5. the sidebar." src="https://i.imgur.com/kQtxL5I.png" /></td>
  </tr>
</table>

</details>

# Sponsors

<div align="center">

[![GeopJr Sponsors](https://cdn.jsdelivr.net/gh/GeopJr/GeopJr@main/sponsors.svg)](https://github.com/sponsors/GeopJr)

</div>

# Miscellaneous

<p align="center">
  <a href='https://stopthemingmy.app'>
    <img width='240' alt='Please do not theme this app' src='https://stopthemingmy.app/badge.svg'/>
  </a><br />
  <a href="https://hosted.weblate.org/engage/tooth/">
    <img src="https://hosted.weblate.org/widgets/tooth/-/tooth/287x66-white.png" alt="Translation status" />
  </a>
</p>


> Tooth is a fork of [Tootle](https://github.com/bleakgrey/tootle) by [Bleak Grey](https://github.com/bleakgrey).

# Contributing

1. Read the [Code of Conduct](./CODE_OF_CONDUCT.md)
2. Fork it ( https://github.com/GeopJr/Tooth/fork )
3. Create your feature branch (git checkout -b my-new-feature)
4. Commit your changes (git commit -am 'Add some feature')
5. Push to the branch (git push origin my-new-feature)
6. Create a new Pull Request
