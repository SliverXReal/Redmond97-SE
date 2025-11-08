Redmond97 SE

Windows 95 OSR2 UI for Xfce4 4.20

v2.0 / 2025 Sliver X

![Image Screenshot](https://github.com/SliverXReal/Redmond97-SE/blob/master/screenshots/4K-Ouroboros.png)

These themes are recreations of the Windows 95 (OSR 2-era, "Detroit") GUI controls for GTK2, GTK3, GTK4, Xfwm4, Metacity and Wine.

It is a fork of the Redmond97 project. The main additions are GTK4 support, HiDPI themes, companion Wine color themes and an extended builder script.
It also has much deeper integration into Xfce4 and its plugins and full Deskbar panel support.

It does not focus on recreating a clone of the Windows 9x desktop like its parent project, (Though this can be done!), rather, using its visual language
with a modern desktop environment.

Included is variant of madmaxms' Obsidian icon theme (Based on Faenza) with slight modifications to work better with the HiDPI themes.

It was developed for Xfce4 v4.20: The need to set a panel border is a fairly recent feature of Xfce so it will not work on much older versions
than this.

Included Themes:

[New Themes]
------------
Redmond97 SE Ouroboros

Redmond97 SE Numidium

Redmond97 SE Dusk (Blue/Red/Purple)

Redmond97 SE Jet (Blue/Red/Purple)

[Microsoft Themes]
------------
Windows 95 (All)

Windows 95 Plus! (All)

Windows 98 Plus! (Baseball, Jungle, Space and Underwater)

Windows XP (Classic Theme)


All themes also have HiDPI variants for 2K and 4K displays.

An included script can be used to create new themes from templates as well.


Usage
-----
Place desired theme's folder under ~/.themes or under /usr/share/themes.

GTK2/3/4: Select a theme/fonts/etc with xfce4-appearance-settings

Wine: Import the theme's .reg file into a prefix with Wine's regedit.exe

Qt5: qt5ct and qt5-styleplugins (Or whatever package the QT5 GTK theme resides in for your distro) need installed and GTK/fonts/etc set under qt5ct.
     The following must be set somewhere such as /etc/environment:

	export QT_QPA_PLATFORMTHEME="qt5ct"

Qt6: qt6ct and qt6gtk2 need installed and GTK set under qt6ct. The QT_QPA_PLATFORMTHEME="qt5ct" variable works for it as well.


Taskbar: A replica of the Windows Explorer System Tray can be made by putting the Tray and Clock applets (in that order) together on the taskbar.
         The pulseaudio-button plugin is also themed to fit between these visually. Panel icons should be set to a fixed "16x16" size to keep them
         consistent across things.

       Included are profiles for the excellent xfce4-panel-profiles addon that replicate a Win9x or Win7 style taskbar: They should be placed in
       either /.local/share/xfce4-panel-profiles/ or /usr/local/share/xfce4-panel-profiles/layouts/ to show up in its Backup/Restore menu.
       xfce4-panel-profiles is provided in most major distro's repositories.

       If not using a profile, border size needs set to at least 1px in all panel's settings for things to look right.

Etc: 
----

    1) Panels and plugins heavily depend on setting fixed icon sizes to look right. Roughly:

       Panel Size   Panel Icons Size   Systray Icon Size
       ----------   ----------------   -----------------
       32px         16px              16px
       48px         32px              24px
       64px         48px              32px
       96px         64px              48px

    2) The CSD has a standard Windows button order defined in GTK3/4's settings.ini but Xfce4's xfsettingsd overrides this. 
       Debian 13 also has GTK button images enabled in its Xfce4 defaults and buttons sizes can't be set from the defined
       data in the theme. Under the "extras" folder is a script named "r97se-fixes.sh" that can be placed in your home
       directory/etc and set to run at logon to fix this via xfce4-session-settings > Application Autostart. Or execute the
       following somewhere else:
        gsettings set org.gnome.desktop.wm.preferences button-layout menu:minimize,maximize,close
        xfconf-query -c xsettings -p /Gtk/IconSizes -s gtk-menu=32,32:gtk-button=40,40:gtk-small-toolbar=24,24:gtk-large-toolbar=32,32:gtk-dnd=32,32:gtk-dialog=32,32
        xfconf-query -c xsettings -p /Gtk/ButtonImages -t 'bool' -s 'false';

    3) If you're running nm-applet, it won't center correctly on a Deskbar system tray. You can edit /etc/xdg/autostart/nm-applet.desktop
       to exec nm-applet --indicator instead of just nm-applet to fix this.

    4) The themes are designed around the fonts Lucida Sans and Lucida Console, though they are not required.
       7pt font works best for the clock applets.

    5) Many plugins work fine in Deskbar mode if you disable their text, like Window Buttons, Application Menu, etc.


[HiDPI Themes]
==============
In addition to the above, for HiDPI themes (as an Xfce4 user who uses a mixture of GTK2/3/4/Qt5/Qt6 and Wine applications),
this is where it got a bit complicated for me. After a lot of testing, I ultimately am doing this:

Xfce4
-----
1) Enable HiDPI variant of theme under Appearance > Style
2) Set mouse Cursor Size to 32 or 34 under Mouse and Touchpad > Theme
3) Enable 2x Window Scaling under Appearance > Settings
4) Add the following to /etc/environment to make it global, or to something that runs when you login for your account (Like ~/.profile):

	QT_QPA_PLATFORMTHEME=qt5ct

	QT_SCALE_FACTOR=2

GTK2 Specific
-------------

By default, GTK2 assets are unscaled to prevent breaking Qt5/Qt6's GTK engines. The included script "gtk2-scale" can be put under somewhere
like /usr/local/bin and invoked as such:

	gtk2-scale <GTK2 APPLICATION>

This will load the scaled GTK2 theme for the currently selected Redmond97 SE theme, but will only work in setups that don't have an xsettings daemon running.


Theme generator script
----------------------------------------------------------
(Requires imagemagick, bc, sed, grep, tee and tar to function)

To use the script:

Run gen_theme.sh ./presets/theme_XXX.conf to build/install a theme.

-OR-

-Edit copy/edit a theme to set the desired colors and/or the text shown on Xfce4's Whisker Menu. 6 digit
and 3 digit hex codes or RGB color codes must be used.
-Run ./gen_theme.sh with the .conf file as an argument to compile and install it to ~/.themes

Alternatively, make-install-all-presets.sh will build everything under the presets directory.

Files are installed to ~/.themes/"$THEME_NAME" and ~/.themes/"$THEME_NAME"-HiDPI if enabled
in the configuraton file.

The flag --systeminstall when ran as sudo/su will install to /usr/share/themes instead for either script.

There will be warnings generated by ImagMagick when a color scheme results in grayscale PNGs for the
arrow graphics. This can be ignored: Trying to supress these has been unsuccessful so far but is planned
on being fixed at some point.

Why
---
This initially started because I wanted a dark theme with non-flat controls and colors.
Windows 95's UI glyphs are very clean and visually clear, so I developed several based on the excellent Redmond97 theme.

However, GTK4 was not supported in it, and I wanted an easy way to get the themes working for Wine as well. I also got
my first 4K monitor recently and needed to make all this scale up for it. 

As of v1.80, it has finally reached a state where it is not just a replica of the Windows 9x Explorer Shell, but a general
UI set that can be used with shell designs of all sorts in Xfce4.


Known Issues
------------
[Metacity+HiDPI]
Title fonts in headerbars are tiny . I can't seem to get it to respect any "title_scale" changes in its xml schema.

[Wine+HiDPI]
Wine applications' text will be too small at 4K, and if its DPI is manually increased in Winecfg *everything* will be scaled by
that amount, not just text.. It appears to be a conflict with using GDK_SCALE/Xfce4's Windows Scale 2x function.

[Xfce]
The PulseAudioPlugin button on Deskbars is one pixel slightly bigger than any other button: This is a technical issue with also
making it blend into the Win9x style system tray for horizontal panels.

[Button Shift Effect]
Some slight imperfections exist in GTK3/4 and GTK2 support also needs added at some point.


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



Gymnasiast | Bug Fixes for Original Redmond97 Theme



bbitmaster | 2x XPM Scaler Utility


Additional Screenshots
----------------------
![Image Screenshot](https://github.com/SliverXReal/Redmond97-SE/blob/master/screenshots/4K-Classic.png)
![Image Screenshot](https://github.com/SliverXReal/Redmond97-SE/blob/master/screenshots/4K-Millennium.png)
![Image Screenshot](https://github.com/SliverXReal/Redmond97-SE/blob/master/screenshots/4K-Numidium-Deskbar.png)
![Image Screenshot](https://github.com/SliverXReal/Redmond97-SE/blob/master/screenshots/4K-JetPurple.png)
![Image Screenshot](https://github.com/SliverXReal/Redmond97-SE/blob/master/screenshots/6-98lite_ouroboros.png)

