#!/bin/sh
#v2.02x

# Set CSD button order to mimic Win9x order.
gsettings set org.gnome.desktop.wm.preferences button-layout menu:minimize,maximize,close &

# Set icon sizes.
xfconf-query -c xsettings -p /Gtk/IconSizes -s gtk-menu=32,32:gtk-button=40,40:gtk-small-toolbar=24,24:gtk-large-toolbar=32,32:gtk-dnd=32,32:gtk-dialog=32,32 &

# Disable GTK button icons.
xfconf-query -c xsettings -p /Gtk/ButtonImages -t 'bool' -s 'false' &

