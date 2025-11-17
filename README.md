<a name="readme-top"></a>

<br />

<h1 align="center">Cardabase</h1>

  <p align="center">
    Cardabase is your digital wallet for loyalty cards. Save all your shop cards in one secure place and access them instantly.
    <br />
    <div align="center">
      <img src="https://github.com/GeorgeYT9769/cardabase-app/blob/main/fastlane/metadata/android/en-US/images/featureGraphic.png?raw=true" alt="Banner">
    <!-- <a href="https://github.com/github_username/repo_name"><strong>Explore the docs »</strong></a> https://discord.com/invite/fZNDfG2xv3 -->
    <br />
    <div align="center">
      <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/GeorgeYT9769/cardabase-app?style=for-the-badge&label=Stars">
      <img alt="GitHub forks" src="https://img.shields.io/github/forks/GeorgeYT9769/cardabase-app?style=for-the-badge&label=Forks">
      <img alt="GitHub license" src="https://img.shields.io/github/license/GeorgeYT9769/cardabase-app?style=for-the-badge&label=License">
      <img alt="GitHub Downloads (all assets, all releases)" src="https://img.shields.io/github/downloads/GeorgeYT9769/cardabase-app/total?style=for-the-badge&label=Downloads">
      <br />
      <a href="https://discord.com/invite/fZNDfG2xv3">
        <img alt="Discord" src="https://img.shields.io/badge/Discord-%235865F2.svg?style=for-the-badge&logo=discord&logoColor=white">
      </a>
    </div>
  </p>
</div>

<br />

## 👌 Features

- Light/dark mode themes
- Modern look with user-friendly layout
- Light, fast and smooth experience
- Encrypted storage
- Support for modern barcode types
- Password protected cards
- Share cards easily with QR Codes
- Does not need internet connection

## 📲 Installation

[<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
alt="Get it on F-Droid"
height="80">](https://f-droid.org/packages/com.georgeyt9769.cardabase/)

OR

1. Download [latest official release](https://github.com/GeorgeYT9769/cardabase-app/releases/latest).
2. Locate the "cardabase-(version you got).apk" file (usually in the Internal storage/Downloads folder).
3. Allow installing apps from unknown sources.
4. Install it by clicking on the "Install" button.

> [!NOTE]
> F-Droid releases might not be in sync with those from GitHub.

## ❗ Acknowledgments

By downloading the app you agree:

- To accept the MIT license;
- That the owner, creators, and contributors are not responsible for any hardware, software, emotional, or other damages made by bugs in the app. Download and use at your own risk;
- To allow Cardabase to use local storage (camera, internet connection - optional).

## 🔜 Coming soon

- add biometric identification for the password
- add a counter to every card, so when card is clicked, it would add a point, then this could be used to sort by the most used cards
- custom color theme, custom theme builder
- images for the cards
- anonymous bug reporting (to Discord issue tracker)
- idk, let me know via issues ;)

## 📦 Storage System

From 1.5.0, Cardabase uses this storage system:

`'ID': VALUE # EXAMPLE,`
`'cardName': <Card Name>,`   
`'cardId': <Card ID>,`  
`'redValue': <R value>,`  
`'greenValue': <G value>,`  
`'blueValue': <B value>,`  
`'cardType': <Card Type>,`  
`'hasPassword': <Password>,`
`'uniqueId': <Unique ID>,`
`'tags': <Tags>,`

- `<Card Name>` - Name of the card (String)
- `<Card ID>` - ID of the card (String)
- `<R value>` - Value of Red color, 0 - 255 (int)
- `<G value>` - Value of Green color, 0 - 255 (int)
- `<B value>` - Value of Blue color, 0 - 255 (int)
- `<Card Type>` - Type of the card, they can be [THESE](https://github.com/GeorgeYT9769/cardabase-app/blob/2e86905c4fb4f861cd3008506a681aab96ea9b38/lib/pages/createcardnew.dart#L9-L27) or [THESE](https://github.com/GeorgeYT9769/cardabase-app/blob/2e86905c4fb4f861cd3008506a681aab96ea9b38/lib/pages/createcardnew.dart#L58-L89), (same types) (String)
- `<Password>` - If the card has a password or not (bool)
- `<Unique ID>` - ID of each card, YYYYMMDDHHMMSSX, X is a bonus number only applied when importing all cards at once (String)
- `<Tags>` - List of tags to categorize the cards (List with Strings in it)

## 📥 Import a card via QR Code

From 1.3.0, you can easily import a card via QR Code.
This is how the structure of the data in the QR Code looks like:
`
'cardName': controller.text,
'cardId': controllercardid.text,
'redValue': redValue,
'greenValue': greenValue,
'blueValue': blueValue,
'cardType': cardTypeText,
'hasPassword': hasPassword,
'uniqueId': uniqueId,
'tags': selectedTags.toList(),
`
- `<Card Name>` - Name of the card (String)
- `<Card ID>` - ID of the card (String)
- `<R value>` - Value of Red color, 0 - 255 (int)
- `<G value>` - Value of Green color, 0 - 255 (int)
- `<B value>` - Value of Blue color, 0 - 255 (int)
- `<Card Type>` - Type of the card, they can be [THESE](https://github.com/GeorgeYT9769/cardabase-app/blob/2e86905c4fb4f861cd3008506a681aab96ea9b38/lib/pages/createcardnew.dart#L9-L27) or [THESE](https://github.com/GeorgeYT9769/cardabase-app/blob/2e86905c4fb4f861cd3008506a681aab96ea9b38/lib/pages/createcardnew.dart#L58-L89), (same types) (String)
- `<Password>` - If the card has a password or not (bool)

## 🤝 Thanks to

- [Edin Divović](https://www.youtube.com/@NotEdin_)
- All the bug reporters that make the app even better.

## 🙌 Support

For support, message me on Discord: "georgeyt9769".

## 🤝 Contributing
Contact me for more info :).
If your phone does not have issues with the app, you can add your device into the Tests file.

## 🔨 Self-Building
1. `git clone` the repository,
2. `cd cardabase-app` into it,
3. `flutter pub get` to download the dependencies,
4. `flutter build apk` in Terminal (you can add `--split-per-abi` if you want to get multiple versions).

> [!NOTE]
> Signing the app is ON. You need a singature key and a key.properties in the /cardabase-app/android folder or else the build will fail. You can change [THIS LINE](https://github.com/GeorgeYT9769/cardabase-app/blob/1daf9c7244a081fe847b499cc55509c10772668d/android/app/build.gradle#L86) to debug to sign it with a debug key.

Used versions:
- Flutter: 3.32.0 (or newer, used Flutter version is always added as a submodule, so you can use that one)
- Java: JDK-21
- Gradle: 8.14.2

Note: Java and Gradle versions must be compatible with each other. [See this Compatibility Matrix](https://docs.gradle.org/current/userguide/compatibility.html).

You may need to:
- Specify JAVA_HOME in gradle.properties = `android/gradle.properties`, add a line `org.gradle.java.home="C:\\path\\to\\the\\jdk"`, where you have to specify your path, (<- in case of multiple/no versions or JAVA_HOME environment variable not specified)
- Change Gradle version in gradle-wrapper.properties = `android\gradle\wrapper\gradle-wrapper.properties`, last line "distributionUrl" (change the "X.X" or "X.X.X" number). (<- in case of different Gradle installation)

## 📸 Screenshots

<div>
<img src="https://github.com/GeorgeYT9769/cardabase-app/blob/main/fastlane/metadata/android/en-US/images/phoneScreenshots/1.png?raw=true" width=204>
<img src="https://github.com/GeorgeYT9769/cardabase-app/blob/main/fastlane/metadata/android/en-US/images/phoneScreenshots/2.png?raw=true" width=204>
<img src="https://github.com/GeorgeYT9769/cardabase-app/blob/main/fastlane/metadata/android/en-US/images/phoneScreenshots/3.png?raw=true" width=204>
<img src="https://github.com/GeorgeYT9769/cardabase-app/blob/main/fastlane/metadata/android/en-US/images/phoneScreenshots/4.png?raw=true" width=204>
<img src="https://github.com/GeorgeYT9769/cardabase-app/blob/main/fastlane/metadata/android/en-US/images/phoneScreenshots/5.png?raw=true" width=204>
<img src="https://github.com/GeorgeYT9769/cardabase-app/blob/main/fastlane/metadata/android/en-US/images/phoneScreenshots/6.png?raw=true" width=204>
<img src="https://github.com/GeorgeYT9769/cardabase-app/blob/main/fastlane/metadata/android/en-US/images/phoneScreenshots/7.png?raw=true" width=204>
<img src="https://github.com/GeorgeYT9769/cardabase-app/blob/main/fastlane/metadata/android/en-US/images/phoneScreenshots/8.png?raw=true" width=204>
</div>