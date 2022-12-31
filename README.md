# Syphon-Transmit

Syphon Output via Adobe Mercury Transmit Engine for Adobe Mercury Transmit Hosts.

![adobe_after_effects_128](https://user-images.githubusercontent.com/65011/210151579-57b529e3-0d47-41cf-a9ad-ab9fff1e6492.png)
![adobe_character_animator_128](https://user-images.githubusercontent.com/65011/210151578-b136a690-666f-4bd4-99ea-a46d76c3bf49.png)
![adobe_premiere_pro_128](https://user-images.githubusercontent.com/65011/210151577-3c527d02-5c1b-46eb-bc6a-31f3540db513.png)


This version supports Metal Rendering

Supported, but not limited to:
* Adobe Premiere Pro 2023
* Adobe After Effects 2023
* Adobe SpeedGrade 2023
* Adobe Character Animator 2023

# Installation

1. Download the most recent release via the releases on the sidebar
2. Unzip the downloaded file
3. Install the Mercury Transmit Plugin to

`/Library/Application Support/Adobe/Common/Plug-ins/7.0/MediaCore/`

4. Launch your App
5. Ensure Mercury Transmit Plugins are enabled in Preferences.

Adobe After Effects:
<img width="1023" alt="image" src="https://user-images.githubusercontent.com/65011/210151330-bfa03e34-1de1-49f9-a572-2d03957d3672.png">

Adobe Character Animator
<img width="848" alt="image" src="https://user-images.githubusercontent.com/65011/210151320-c331b1fe-4a55-45c7-aaad-ffab397ec92c.png">

Adobe Premiere Pro:

<img width="880" alt="image" src="https://user-images.githubusercontent.com/65011/210151354-4ab40997-6a0e-4793-a57a-3b91f94396c2.png">


# Troubleshooting

I get "Plugin Damaged" when opening after installing
1. Quit whatever Adobe app.
2. Open `Terminal.app' and run the following command:

`xattr -cr /Library/Application Support/Adobe/Common/Plug-ins/7.0/MediaCore/Syphon\ Transmit.bundle`

I dont see the Syphon output in my client app.

1. Ensure Mercury Transmit is enabled, and Syphon-Transmit is visible in the preferences
2. You may need to load media, and ensure that specific settings are enable, ie, live mode is enabled in Character Animator. Consult your software's manual.

# Developers

For developers, you need to have agreed to Adobes terms and downloaded the Appropriate Mercury Transmit headers, which you can get from the Adobe Premire Pro or After Effects  C++ SDKs

https://developer.adobe.com/console/servicesandapis/pr

And install the headers in the appropriate location.
