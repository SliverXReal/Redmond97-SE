Redmond97 SE

Windows 95/NT4 UI for Xfce4

v1.57 / 2025 Sliver X

![Image Screenshot](https://github.com/SliverXReal/Redmond97-SE/blob/8839943752a53c74cadd2ec97cb9fd7e805b391c/screenshots/1-ouroboros-lodpi.png)

These themes are recreations of the Windows 95 GUI controls for GTK2, GTK3, GTK4, Xfwm4, Metacity and Wine.

It is a fork of the Redmond97 project, but does not focus on recreating a clone of the Windows 95 desktop as a whole. (I just really like the UI elements)

Therefore it doesn't include things like the Firefox theme, icon set, etc from its parent project.
It does include a variant of madmaxms' Obsidian icon theme with slight modifications to work better with the HiDPI themes.

The main additions are GTK4 support, HiDPI themes, companion Wine color themes and an extended builder script.

Included Themes
---------------
[New (Dark) Themes]

Redmond97 SE Ouroboros

Redmond97 SE Numidium

Redmond97 SE Dusk (Three accent colors)

Redmond97 SE Jet (Three accent colors)

[Old (Microsoft) Themes]

Windows 95 (All)

Windows 95 Plus! (All)

Windows 98 Plus! (Baseball, Jungle, Space and Underwater)

Windows XP (Classic Theme)

All themes also have HiDPI variants for 2K and 4K displays.

An included script can be used to create new themes from templates as well.


Usage
-----
Place under ~/.themes or under a global system folder if desired.

GTK2/3/4: Select a theme/fonts/etc with your distro's theme selector/a terminal/text editor.

Wine: Import the theme's .reg file into a prefix with Wine's regedit.exe

Qt5: qt5ct and qt5-styleplugins (Or whatever package the QT5 GTK theme resides in for your distro) need installed and GTK/fonts/etc set under qt5ct.
     The following must be set somewhere such as /etc/environment:

	export QT_QPA_PLATFORMTHEME="qt5ct"

Qt6: qt6ct and qt6gtk2 need installed and GTK set under qt6ct. The QT_QPA_PLATFORMTHEME="qt5ct" variable works for it as well.

The CSD has a standard Windows button order defined in GTK3/4's settings.ini but Xfce4's xfsettingsd overrides this. 
A workaround would be to execute this somwhere at logon: 

	gsettings set org.gnome.desktop.wm.preferences button-layout menu:minimize,maximize,close


[HiDPI Themes]
==============
In addition to the above, for HiDPI themes (as an Xfce4 user who uses a mixture of GTK2/3/4/Qt5/Qt6 and Wine applications),
this is where it got a bit complicated for me. After a lot of testing, I ultimately am doing this:

Xfce4
-----
1) Enable HiDPI variant of theme under Appearance > Style
2) Set mouse Cursor Size to 32 under Mouse and Touchpad > Theme
3) Enable 2x Window Scaling under Appearance > Settings
4) Add the following to /etc/environment to make it global, or to something that runs when you login for your account (Like ~/.profile):

	QT_QPA_PLATFORMTHEME=qt5ct

	QT_SCALE_FACTOR=2

GTK2 Specific
-------------
In Xfce4, override xfsettingsd's meddling to fix GTK2 icon sizes either by:

a) Run: xfce4-settings-editor > xsettings > IconSizes

   Enter: gtk-menu=32,32:gtk-button=40,40:gtk-small-toolbar=24,24:gtk-large-toolbar=32,32:gtk-dnd=32,32:gtk-dialog=32,32

b) Run: xfconf-query -c xsettings -p /Gtk/IconSizes -s gtk-menu=32,32:gtk-button=40,40:gtk-small-toolbar=24,24:gtk-large-toolbar=32,32:gtk-dnd=32,32:gtk-dialog=32,32

By default, GTK2 assets are unscaled to prevent breaking Qt5/Qt6's GTK engines. The included script "gtk2-scale" can be put under somewhere
like /usr/local/bin and invoked as such:

	gtk2-scale <GTK2 APPLICATION>

This will load the scaled GTK2 theme for the currently selected Redmond97 SE theme, but will only work in setups that don't have an xsettings daemon running.


Theme generator script
----------------------------------------------------------
(Requires imagemagick, bc, sed, grep, tee and tar to function)

To use the script:

Run gen_theme.sh to build/install the default Ouroboros theme, or edit theme.conf to generate a new one.

-OR-

-Edit copy/edit a theme to set the desired colors and/or the text shown on Xfce4's Whisker Menu. 6 digit
and 3 digit hex codes or RGB color codes must be used.
-Run ./gen_theme.sh with the .conf file as an argument to compile and install it to ~/.themes

Alternatively, make-install-all-presets.sh will build everything under the presets directory.

Files are installed to ~/.themes/"$THEME_NAME" and ~/.themes/"$THEME_NAME"-HiDPI if enabled
in the configuraton file.

Why
---
This initially started because I wanted a dark theme with non-flat controls and colors.
Windows 95's UI glyphs are very clean and visually clear, so I developed several based on the excellent Redmond97 theme.

However, GTK4 was not supported in it, and I wanted an easy way to get the themes working for Wine as well. I also got
my first 4K monitor recently and needed to make all this scale up for it.

GTK4 support should be mostly complete and bug free as of v1.30.

GTK3 has a very nice setup in Redmond97, but due to how a lot of GTK4 programs use the CSD header bar in 2025 there isn't
really a way to make it work that way for them, at least well, so I've made both GTK3 and GTK4 use a common chunky button
scheme that behaves consistently across them and can accommodate things like Title+Subtitle headers without cutting off text.

Their coloration also behaves like active/inactive WM titles. They have a button setup like Windows, but an Xsettings
daemon will typically override this. 

GTK2 is mostly scaled 2x on the HiDPI themes via upscaled assets and geometry hacks in the .rc files. Icons will not scale up
if you are running an Xsettings mananger (Such as Xfce4's xfsettingsd) by default, so overrides must be set.

The generator script has been extended to create .reg files for usage in Wine based on the final GTK theme output. These will also work in real Windows XP, 2000, and Win95/98/Me installations for what that's worth, too.
Vista, 7, 8 and 10 (Before they removed access to the Classic theme) have not been tested.


Known Issues
------------
[Metacity+HiDPI]

Title fonts in headerbars are tiny . I can't seem to get it to respect any "title_scale" changes in its xml schema.

[GTK3/GTK4 CSD Headerbars]

Xfce4 overrides the theme's button order definitions for these. Can be worked around.

[GTK2+HiDPI]

GTK2 at 4K resolution requires a manual override if an xsettings daemon is running to fix icon scaling.


[Wine+HiDPI]

Wine applications' text will be too small at 4K, and if its DPI is manually increased in Winecfg *everything* will be scaled by
that amount, not just text.. It appears to be a conflict with using GDK_SCALE/Xfce4's Windows Scale 2x function.


Credits
-------
Sliver X | Redmond 97 SE

https://github.com/SliverXReal/Redmond97-SE.git



matthewmx86 | Redmond97 (Original GTK2/3/Xf4wm theme):

https://github.com/matthewmx86/Redmond97.git



parhelion22 | Greymond (Bits of GTK4 CSS/reference):

https://github.com/parhelion22/xfce-theme-greymond



Matthieu James & madmaxms | Faenza / Obsidian Icon Themes:

https://github.com/shlinux/faenza-icon-theme
https://github.com/madmaxms/iconpack-obsidian


Additional Screenshots
----------------------
![Image Screenshot](https://github.com/SliverXReal/Redmond97-SE/blob/9c42aa177376cfaed7a37cb119d87f9f4a8cee84/screenshots/6-Ouroboros-OuterWorlds.png)
![Image Screenshot](https://github.com/SliverXReal/Redmond97-SE/blob/9c42aa177376cfaed7a37cb119d87f9f4a8cee84/screenshots/7-DuskBlue-SystemShockRemake.png)
![Image Screenshot](https://github.com/SliverXReal/Redmond97-SE/blob/9c42aa177376cfaed7a37cb119d87f9f4a8cee84/screenshots/8-JetRed-NierReplicant.png)
![Image Screenshot](https://github.com/SliverXReal/Redmond97-SE/blob/9c42aa177376cfaed7a37cb119d87f9f4a8cee84/screenshots/9-Whistler-FF7Remake.png)
![Image Screenshot](https://github.com/SliverXReal/Redmond97-SE/blob/9c42aa177376cfaed7a37cb119d87f9f4a8cee84/screenshots/10-Travel-Scorn.png)
![Image Screenshot](https://github.com/SliverXReal/Redmond97-SE/blob/9c42aa177376cfaed7a37cb119d87f9f4a8cee84/screenshots/11-JetPurple-IcarusPS2.png)