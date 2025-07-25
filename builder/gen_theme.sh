#!/bin/bash
#v1.57
#Dependencies: imagemagick, bc, sed, grep, tee, tar

#Check if config file was passed from command line, if not, use default file.
if [ -z $1 ]; then CONFY=theme.conf; else CONFY=$1; fi
. "$CONFY"
code=""
rgb=""
invalid_entry=0

#Limit RGB channel to 0-255
function cap_rgb {
  cap=${1%.*}
  if [ $cap -gt 255 ]; then
    cap=255
  fi
  if [ $cap -lt 1 ]; then
    cap=0
  fi
  echo $cap
}

#Convert hex to decimal for calculations.
function hex2rgb {
  code=$1
  a=0
  for i in $(echo $code | grep -o ..); do
    a=$(($a+1))
    rgb[$a]=$(echo "ibase=16;obase=A; $i" | bc)
  done
}

#Convert rgb dec to hex
function rgb2hex {
code=$(cap_rgb $1)
code="$(echo "ibase=10;obase=16; $code" | bc)"
if [ $(echo $code | wc -c ) -lt 3 ]; then
  code=0$code
fi
if [ $(echo $code | grep -c "-") -gt 0 ]; then
  echo "("$code")"echo "ibase=16;obase=A; $i" | bc
else
  echo $code
fi
}

# Overdrive RGB Channels
function overdrive {
  hex2rgb "$2"
  a=0
  for i in $(echo ${rgb[*]}); do
    a=$(($a+1))
    rgb_boost[$a]=$(echo "$(echo "$1" | gawk -F, '{ print $'$a' }' )*255" | bc)
    rgb[$a]=$(echo "${rgb[$a]%.*}+${rgb_boost[$a]%.*}" | bc)
    output=$output$(rgb2hex ${rgb[$a]})
  done
  echo $output
}

#Desaturize colors
function saturation {
  hex2rgb "$2"
  diviser="$1"
  #Calc average rgb brightness
  a=0
  for i in $(echo ${rgb[*]}); do
    a=$(($a+1))
    avgN=$(($avgN+${rgb[$a]}))
  done
  avgN=$(echo "$avgN / $a" | bc)
  if [ $sat -gt 10 ]; then
    avgN=0
  else
    avgN=$(echo "$avgN * $(echo "1 - $diviser" | bc)" | bc)
  fi

  #Populate RGB values with average value
  a=0
  for i in $(echo ${rgb[*]}); do
    a=$(($a+1))
    color=$(echo "$avgN + $(echo "${rgb[$a]} * $diviser" | bc)" | bc)
    output=$output$(rgb2hex $color)
  done
  echo $output
}

function verify {
  if [ $(echo $1 | grep -ci ",") -lt 1 ] && [ $(echo $1 | grep -ci "#") -lt 1 ]; then
    echo "INVALID"
    exit
  fi
  if [ $(echo $1 | grep -ci "#") -gt 0 ]; then
    #Filter out invalid hex codes and change 3 digit codes to 6 digit codes
  verified="$(echo $1 | grep -io [a-f0-9] | grep -io [a-f0-9] | awk '{ print; count++; if (count==6) exit }' | tr -d "\n")"
  a=0
  code=$verified
  if [ $(echo $code | wc -c ) -lt 5 ]; then
    verified=""
    for i in $(echo $code | grep -o .); do
      a=$(($a+1))
      i=$i$i
      verified=$verified$i
    done
  fi

  #Apply case filter to output. The bc command is case sensative for hex values.
  verified=$(echo $verified | grep -o [A-Fa-f0-9].*)
  verified="${verified^^}"
else
  if [ $(echo $1 | grep -ci ",") -gt 0 ]; then
    rgb[1]=$(echo $1 | gawk -F, '{ print $1 }')
    rgb[2]=$(echo $1 | gawk -F, '{ print $2 }')
    rgb[3]=$(echo $1 | gawk -F, '{ print $3 }')
    a=0
    for i in $(echo ${rgb[*]}); do
      a=$(($a+1))
      verified=$verified$(rgb2hex ${rgb[$a]})
    done
      verified="${verified^^}"
    fi
fi

  #Convert saturation level to integer
  sat=$(echo "$saturation_level * 10" | bc)
  sat=${sat%.*}

  #Determine color algorithm to use
  if [ $(echo "$enable_overdrive" | grep -ci "true") -lt 1 ] && [ $sat = 10 ]; then
            echo $verified
  else
    if [ $(echo "$enable_overdrive" | grep -ci "true") -gt 0 ] && [ $sat != 10 ]; then
      saturation "$saturation_level" $(overdrive "$window_R,$window_G,$window_B" "$verified")
    else
      if [ $sat != 10 ]; then
        saturation "$saturation_level" "$verified"
      fi
      if [ $enable_overdrive = "true" ]; then
        overdrive "$window_R,$window_G,$window_B" "$verified"
      fi
    fi
  fi
}

#Calculate shadow and highlight colors then convert decimal back to hex
function calc_colors {
a=0
#Calc boost color
boost[1]=$(echo "255*$hl_R" | bc) #Red
boost[2]=$(echo "255*$hl_G" | bc) #Green
boost[3]=$(echo "255*$hl_B" | bc) #Blue
boost1[1]=$(echo "255*$s_R" | bc) #Red
boost1[2]=$(echo "255*$s_G" | bc) #Green
boost1[3]=$(echo "255*$s_B" | bc) #Blue
for i in $(echo ${rgb[*]}); do
  a=$(($a+1))
  #Calculated shadow, highlight and disabled colors
  shadow[$a]=$(echo "${rgb[$a]}*$shadow_multiplier" | bc)
  highlight[$a]=$(echo "${rgb[$a]}*$highlight_multiplier" | bc)
  if [ $(echo $high_contrast | grep -ic "true") -gt 0 ]; then
    disabled[$a]=$(echo "${fgcolor_rgb[$a]}*$disabled_fg_multiplier" | bc)
  else
    disabled[$a]=$(echo "${rgb[$a]}*$disabled_fg_multiplier" | bc)
  fi
  #Color boost
  shadow[$a]=$(echo "$(cap_rgb ${shadow[$a]%.*})+${boost1[$a]%.*}" | bc)
  highlight[$a]=$(echo "$(cap_rgb ${highlight[$a]%.*})+${boost[$a]%.*}" | bc)

  #Cap at 255 and ignore negative values
  highlight[$a]=$(cap_rgb ${highlight[$a]%.*})
  shadow[$a]=$(cap_rgb ${shadow[$a]%.*})
  disabled[$a]=$(cap_rgb ${disabled[$a]%.*})

  #Convert DEC to HEX
  shadow_hex=$shadow_hex$(rgb2hex ${shadow[$a]%.*})
  highlight_hex=$highlight_hex$(rgb2hex ${highlight[$a]%.*})
  disabled_hex=$disabled_hex$(rgb2hex ${disabled[$a]%.*})
done

highlight="$highlight_hex"
shadow="$shadow_hex"
disabled_fgcolor="$disabled_hex"
}

function compile_assets {
cd images
for i in $(ls -d */ | grep -o .*[A-Za-z0-9]); do
cd $i
if [ $(pwd | grep -ci "ins") -gt 0 ]; then
  convert *base.png -fuzz 15% -fill "#$bgcolor" -opaque "#ff00fa" base.png
else
  convert *base.png -fuzz 15% -fill "#$basecolor" -opaque "#ff00fa" base.png
fi
convert *border.png -fuzz 15% -fill "#$border" -opaque "#ff00fa" border.png
convert *shadow.png -fuzz 15% -fill "#$shadow" -opaque "#ff00fa" shadow.png
convert *highlight.png -fuzz 15% -fill "#$highlight" -opaque "#ff00fa" highlight.png
convert *background.png -fuzz 15% -fill "#$bgcolor" -opaque "#ff00fa" background.png
convert *check.png -fuzz 15% -fill "#$basefg" -opaque "#ff00fa" check.png
convert *_aa.png -fuzz 15% -fill "#$bgcolor" -opaque "#ff00fa" aa.png
convert *_text.png -fuzz 15% -fill "#$fgcolor" -opaque "#ff00fa" text.png
convert *_text_disabled.png -fuzz 15% -fill "#$disabled_fgcolor" -opaque "#ff00fa" text_disabled.png
convert -background none -page +0+0 background.png -page +0+0 highlight.png \
-page +0+0 shadow.png -page 0+0 border.png -page +0+0 base.png -page +0+0 check.png \
-page +0+0 aa.png -page +0+0 text.png -page +0+0 text_disabled.png -layers flatten $i.png
#remove work files
mv $i.png ../assets/
rm shadow.png border.png highlight.png background.png base.png check.png aa.png
#return to directory
cd ../
done
cd assets

#compile arrows
mv arrow.png arrow_up.png
convert -rotate "90" arrow_up.png arrow_right.png
convert -rotate "90" arrow_right.png arrow_down.png
convert -rotate "90" arrow_down.png arrow_left.png
for i in $(ls arrow*.png); do
  convert "$i" -fuzz 15% -fill "#$disabled_fgcolor" -opaque "$fgcolor" ${i%.*}"_ins.png"
done

#compile all scrollbar buttons
convert -page +0+0 scrollbar_button.png -page +0+0 arrow_up.png -layers flatten scroll_up_button.png
convert -page +0+0 scrollbar_button.png -page +0+0 arrow_right.png -layers flatten scroll_right_button.png
convert -page +0+0 scrollbar_button.png -page +0+0 arrow_down.png -layers flatten scroll_down_button.png
convert -page +0+0 scrollbar_button.png -page +0+0 arrow_left.png -layers flatten scroll_left_button.png
convert -page +0+0 scrollbar_button_active.png -page +0+0 arrow_up.png -layers flatten scroll_up_button_active.png
convert -page +0+0 scrollbar_button_active.png -page +0+0 arrow_right.png -layers flatten scroll_right_button_active.png
convert -page +0+0 scrollbar_button_active.png -page +0+0 arrow_down.png -layers flatten scroll_down_button_active.png
convert -page +0+0 scrollbar_button_active.png -page +0+0 arrow_left.png -layers flatten scroll_left_button_active.png

#compile tabs
convert -flip tab.png tab_left.png
convert -flip tab_checked.png tab_left_checked.png
convert -flip tab_gap.png tab_gap_left.png
convert -rotate "90" tab_left.png tab_left.png
convert -rotate "90" tab_left_checked.png tab_left_checked.png
convert -rotate "90" tab_gap_left.png tab_gap_left.png
cp tab_gap_left.png tab_gap_right.png
convert -flip tab_bottom.png tab_right.png
convert -flip tab_bottom_checked.png tab_right_checked.png
convert -rotate "90" tab_right.png tab_right.png
convert -rotate "90" tab_right_checked.png tab_right_checked.png
mv tab.png tab_top.png
mv tab_checked.png tab_top_checked.png
cp tab_gap.png tab_gap_top.png
mv tab_gap.png tab_gap_bottom.png

#compile switch button
convert -background none -page +0+0 switch_button.png -page +0+0 switch_off.png -layers flatten switch.png
convert -background none -page +0+0 switch_button_ins.png -page +0+0 switch_off.png -layers flatten switch_ins.png
convert -background none -page +0+0 switch_button.png -page +0+0 switch_on.png -layers flatten switch_checked.png
convert -background none -page +0+0 switch_button_ins.png -page +0+0 switch_on.png -layers flatten switch_ins_checked.png
rm switch_off.png switch_on.png switch_button.png switch_button_ins.png
cd ..

cp progressbar/*.png assets/
cp assets/progressbar_horiz.png assets/menuitem.png
cp null/null_image.png assets/null.png
#colorize extra widgets
convert assets/menuitem.png -fuzz 15% -fill "#$selectedbg" -opaque "#ff00fa" assets/menuitem.png
convert assets/progressbar_horiz.png -fuzz 15% -fill "#$selectedbg" -opaque "#ff00fa" assets/progressbar_horiz.png
convert assets/progressbar_vert.png -fuzz 15% -fill "#$selectedbg" -opaque "#ff00fa" assets/progressbar_vert.png

#compile whisker menu side image
convert -size 27x800 canvas:"#$activetitle1" assets/side_canvas.png
#convert -size 27x400 gradient:"#0803ee"-"#$border" assets/side_gradient.png
convert -size 27x400 gradient:"#$activetitle"-"#$activetitle1" assets/side_gradient.png
convert -background none -page +0+0 assets/side_canvas.png -page 0+0 assets/side_gradient.png -layers flatten assets/menu_side_gradient.png
convert -rotate -90 assets/menu_side_gradient.png assets/menu_side_gradient.png
convert -font "$menu_side_font" -fill "#$activetitletext" -pointsize $menu_side_text_size -draw "text $menu_side_text_offset '$menu_side_text'" assets/menu_side_gradient.png assets/menu_side.png
convert -rotate -90 assets/menu_side.png assets/menu_side.png

rm assets/menu_side_gradient.png

cd assets
#gtk3 assets
gtk3="../../gtk-3.0/assets/"
cp tab*.png $gtk3
cp menu_side.png $gtk3
cp menubar.png $gtk3/toolbar.png
cp scrollbar_trough.png $gtk3
cp radio*.png $gtk3
cp c_box*.png $gtk3
cp arrow*.png $gtk3
cp switch*.png $gtk3
cp comboboxbutton.png $gtk3/combobox.png
cp comboboxbutton_ins.png $gtk3/combobox_disabled.png
cp comboboxbutton_checked.png $gtk3/combobox_checked.png
cp scrollbar_button.png $gtk3
rm scrollbar_button.png
cp scroll_*_button.png $gtk3
mv headerbox.png $gtk3
cp warning.png $gtk3
mv caja_menu_side.png $gtk3
mv handle.png $gtk3
mv fm_toolbar.png $gtk3
cp close_normal.png $gtk3
cp close_normal_small.png $gtk3
cp close_pressed.png $gtk3
cp close_pressed_small.png $gtk3
cp maximize_normal.png $gtk3
cp maximize_pressed.png $gtk3
cp minimize_normal.png $gtk3
cp minimize_pressed.png $gtk3
cp restore_normal.png $gtk3
cp restore_pressed.png $gtk3
#metacity-1 assets
mv close_normal.png ../../metacity-1/
mv close_normal_small.png ../../metacity-1/
mv close_pressed.png ../../metacity-1/
mv close_pressed_small.png ../../metacity-1/
mv maximize_normal.png ../../metacity-1/
mv maximize_pressed.png ../../metacity-1/
mv minimize_normal.png ../../metacity-1/
mv minimize_pressed.png ../../metacity-1/
mv restore_normal.png ../../metacity-1/
mv restore_pressed.png ../../metacity-1/
#gtk2 assets
mv *.png ../../gtk-2.0/assets/
cd ../../

#set button icon glyph color
cd xfwm4
sed -i s/"o      c #000000 s buttons_color"/"o      c $buttons_color s buttons_color"/g *.xpm
cd ../

# Set button icon glyph color for HiDPI theme as well, if enabled.
if [ $(echo "$create_hidpi_theme" | grep -ci "1") -gt 0 ]; then

#set button icon glyph color
cd xfwm4-hidpi
sed -i s/"o      c #000000 s buttons_color"/"o      c $buttons_color s buttons_color"/g *.xpm
cd ../
else
echo "No HiDPI by config setting."
fi
}

function build_theme_config
{
echo "Generating rc and css config files..."

#Theme index
sed -i "s/Redmond97/Redmond97 SE - $Theme_name/g" index.theme
sed -i "s/IconTheme=/IconTheme=$Icon_theme/g" index.theme

#GTK-2.0
sed -i 's/fg_color:#000/fg_color:'#$fgcolor'/g' base.rc
sed -i 's/bg_color:#c0c0c0/bg_color:'#$bgcolor'/g' base.rc
sed -i 's/base_color:#fff/base_color:'#$basecolor'/g' base.rc
sed -i 's/text_color:#000/text_color:'#$basefg'/g' base.rc
sed -i 's/selected_bg_color:#0000aa/selected_bg_color:'#$selectedbg'/g' base.rc
sed -i 's/selected_fg_color:#fff/selected_fg_color:'#$selectedtext'/g' base.rc
sed -i 's/disabled_fg_color:#e0e0e0/disabled_fg_color:'#$disabled_fgcolor'/g' base.rc

#GTK-3.0
sed -i 's/@define-color fg_color #000000/@define-color fg_color '#$fgcolor'/g' gtk-base.css
sed -i 's/@define-color bg_color #c0c0c0/@define-color bg_color '#$bgcolor'/g' gtk-base.css
sed -i 's/@define-color base_color #FFFFFF/@define-color base_color '#$basecolor'/g' gtk-base.css
sed -i 's/@define-color text_color #000000/@define-color text_color '#$basefg'/g' gtk-base.css
sed -i 's/@define-color selected_bg_color #0000aa/@define-color selected_bg_color '#$selectedbg'/g' gtk-base.css
sed -i 's/@define-color selected_fg_color #FFFFFF/@define-color selected_fg_color '#$selectedtext'/g' gtk-base.css
sed -i 's/@define-color light_shadow #FFFFFF/@define-color light_shadow '#$highlight'/g' gtk-base.css
sed -i 's/@define-color disabled_fg_color #EFEFEF/@define-color disabled_fg_color '#$disabled_fgcolor'/g' gtk-base.css
sed -i 's/@define-color borders #000/@define-color borders '#$border'/g' gtk-base.css
sed -i 's/@define-color dark_shadow shade(@bg_color, 0.7)/@define-color dark_shadow '#$shadow'/g' gtk-base.css
sed -i 's/@define-color active_title_color @selected_bg_color/@define-color active_title_color #'$activetitle'/g' gtk-base.css
sed -i 's/@define-color active_title_color1 @selected_bg_color/@define-color active_title_color1 #'$activetitle1'/g' gtk-base.css
sed -i 's/@define-color active_title_text @selected_fg_color/@define-color active_title_text #'$activetitletext'/g' gtk-base.css

if [ $(echo "$enable_alternate_menu" | grep -ci "true") -lt 1 ]; then
  sed -i 's/border-left: 23px solid/border-left: '"$menu_side_width"'px solid/g' "gtk-3.0/whisker-menu.css"
fi
if [ $(echo "$enable_alternate_menu" | grep -ci "true") -gt 0 ]; then
  sed -i 's/whisker-menu.css/whisker-menu2.css/g' "gtk.css"
fi

#Add WM colors to general GTK CSS sheet.
sed -i 's/wm_active_title=#FFFFFF/wm_active_title '#$activetitle'/g' "gtk-base.css"
sed -i 's/wm_active_title_text=#000000/wm_active_title_text '#$activetitletext'/g' "gtk-base.css"
sed -i 's/wm_inactive_title=#FFFFFF/wm_inactive_title '#$inactivetitle'/g' "gtk-base.css"
sed -i 's/wm_inactive_title_text=#000000/wm_inactive_title_text '#$inactivetitletext'/g' "gtk-base.css"

#XFCE4WM
sed -i 's/active_text_color=#FFFFFF/active_text_color='#$activetitletext'/g' themerc
sed -i 's/inactive_text_color=#c0c0c0/inactive_text_color='#$inactivetitletext'/g' themerc
sed -i 's/active_color_1=#6f99be/active_color_1='#$activetitle'/g' themerc
sed -i 's/inactive_color_1=#7d7a73/inactive_color_1='#$inactivetitle'/g' themerc
sed -i 's/active_border_color=#000000/active_border_color='#$border'/g' themerc
sed -i 's/inactive_border_color=#000000/inactive_border_color='#$border'/g' themerc
if [ $(echo "$high_contrast" | grep -ci "true") -gt 0 ]; then
  echo "active_border_color=#$border" >> themerc
  echo "inactive_border_color=#$border" >> themerc
  echo "active_hilight_2=#$border" >> themerc
  echo "inactive_hilight_2=#$border" >> themerc
fi

#metacity-1
sed -i 's/_activegradient1_/#'$activetitle1'/g' metacity-theme-1.xml
sed -i 's/_activegradient2_/#'$activetitle'/g' metacity-theme-1.xml
sed -i 's/_inactivegradient1_/#'$inactivetitle'/g' metacity-theme-1.xml
sed -i 's/_inactivegradient2_/#'$inactivetitle1'/g' metacity-theme-1.xml
sed -i 's/Redmond2K/Redmond97 SE '"$Theme_name"'/g' metacity-theme-1.xml
sed -i 's/line color=\"#ffffff\"/line color=\"#'$highlight'\"/g' metacity-theme-1.xml
sed -i 's/title x=\"3\" y=\"2\" color="gtk:bg\[NORMAL\]\"/title x=\"3\" y=\"2\" color=\"#'$inactivetitletext'\"/g' metacity-theme-1.xml
sed -i 's/title x=\"3\" y=\"2\" color=\"#ffffff\"/title x=\"3\" y=\"2\" color=\"#'$activetitletext'\"/g' metacity-theme-1.xml
sed -i 's/404040/'$border'/g' metacity-theme-1.xml
sed -i 's/808080/'$shadow'/g' metacity-theme-1.xml
sed -i 's/404040/'$border'/g' metacity-theme-1.xml
sed -i 's/404040/'$border'/g' metacity-theme-1.xml
sed -i 's/color=\"gtk:bg\[NORMAL\]\"/color=\"#'$bgcolor'\"/g' metacity-theme-1.xml


#Append changes
cat gtkrc >> base.rc
rm -rf gtkrc
mv base.rc gtk-2.0/gtkrc
cat gtk.css >> gtk-base.css
rm gtk.css
mv gtk-base.css gtk-3.0/gtk.css
cp themerc xfwm4/

# If HiDPI mode enabled, copy colored themerc to that theme's folder as well.
if [ $(echo "$create_hidpi_theme" | grep -ci "1") -gt 0 ]; then
  mv themerc xfwm4-hidpi/
else
  rm themerc
fi
mv metacity-theme-1.xml metacity-1/
}

function prompt {
if [ "$invalid_entry" = "1" ]; then
  echo "Warning: invalid color code entered or config file is corrupt. Exiting..."
  exit 1
fi
echo $invalid_entry
#show settings, shunt to temporary file to build registry keys for wine
echo "Theme name: $Theme_name"
echo "Selected colors:"
hex2rgb $bgcolor
echo "Window BG color: #$bgcolor, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}" | tee ./winereg.tmp
hex2rgb $fgcolor
echo "Window FG color: #$fgcolor, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}" | tee -a ./winereg.tmp
hex2rgb $basecolor
echo "Base BG color: #$basecolor, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}" | tee -a ./winereg.tmp
hex2rgb $basefg
echo "Base text color: #$basefg, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}" | tee -a ./winereg.tmp
hex2rgb $selectedbg
echo "Selected BG color: #$selectedbg, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}" | tee -a ./winereg.tmp
hex2rgb $selectedtext
echo "Selected FG color: #$selectedtext, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}" | tee -a ./winereg.tmp
hex2rgb $activetitle
echo "Active titlebar color: #$activetitle, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}" | tee -a ./winereg.tmp
hex2rgb $activetitletext
echo "Active title text: #$activetitletext, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}" | tee -a ./winereg.tmp
hex2rgb $inactivetitle
echo "Inactive titlebar color: #$inactivetitle, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}" | tee -a ./winereg.tmp
hex2rgb $inactivetitletext
echo "Inactive title text: #$inactivetitletext, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}" | tee -a ./winereg.tmp
hex2rgb $border
echo "Border color: #$border, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}" | tee -a ./winereg.tmp
echo ""
echo "3D highlight color boost: #$(rgb2hex ${boost[1]})$(rgb2hex ${boost[2]})$(rgb2hex ${boost[3]}), RGB: ${boost[1]%.*},${boost[2]%.*},${boost[3]%.*}" | tee -a ./winereg.tmp
echo "3D shadow color boost: #$(rgb2hex ${boost1[1]})$(rgb2hex ${boost1[2]})$(rgb2hex ${boost1[3]}), RGB: ${boost1[1]%.*},${boost1[2]%.*},${boost1[3]%.*}" | tee -a ./winereg.tmp
echo ""
echo "Calculated colors:"
hex2rgb $highlight
echo "Highlight color: #$highlight, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}" | tee -a ./winereg.tmp
hex2rgb $shadow
echo "Shadow color: #$shadow, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}" | tee -a ./winereg.tmp
hex2rgb $disabled_fgcolor
echo "Disabled FG color: #$disabled_fgcolor, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}" | tee -a ./winereg.tmp
echo "Press enter to continue or ctrl+c to cancel..."
#read $entry
#build wine registry file
makewinehive
build
}

function build {
cd @
echo "Cleaning any previous orphaned files..."
#Clean incomplete or interupted builds, compile images
cleanup  2>>/dev/null
echo "Extracting base files..."
tar -xzf base.tar.gz 2>>/dev/null
echo "Compiling theme images..."
compile_assets $2 2>>/dev/null
build_theme_config

theme_name="Redmond97 SE $Theme_name"
rm -rf ~/.themes/"$theme_name"
mkdir ~/.themes/"$theme_name"

### HiDPI variant: Scaling/patches.
if [ $(echo "$create_hidpi_theme" | grep -ci "1") -gt 0 ]; then
mkdir ~/.themes/"$theme_name"-HiDPI
#####

# GTK2... #
mkdir ./gtk-2.0-hidpi/

case $hidpi_gtk2_mode in 

1)
cp -r ./gtk-2.0/* ./gtk-2.0-hidpi/
;;

2)
# Scale a bunch of PNGs to avoid blurring.
cp -r ./gtk-2.0/* ./gtk-2.0-hidpi/
cd ./gtk-2.0-hidpi/assets
for i in *.png; do convert $i -scale 200% ./$i;done
cd ../../
mv -f ./hidpi-res/gtk-2.0/*.rc ./gtk-2.0-hidpi/
sed -n "/### Base colors ###/,/### Begin ###/p" ./gtk-2.0/gtkrc > /tmp/gtkhdrtmp
cat /tmp/gtkhdrtmp ./hidpi-res/gtk-2.0/gtkrc-hidpi > ./gtk-2.0-hidpi/gtkrc
;;

3)
# Scale a bunch of PNGs to avoid blurring.
cp -r ./gtk-2.0/* ./gtk-2.0-hidpi/
mkdir ./gtk-2.0-hidpireal/
cp -r ./gtk-2.0/* ./gtk-2.0-hidpireal/
cd ./gtk-2.0-hidpireal/assets
for i in *.png; do convert $i -scale 200% ./$i;done
cd ../../
mv -f ./hidpi-res/gtk-2.0/*.rc ./gtk-2.0-hidpireal/
sed -n "/### Base colors ###/,/### Begin ###/p" ./gtk-2.0/gtkrc > /tmp/gtkhdrtmp
cat /tmp/gtkhdrtmp ./hidpi-res/gtk-2.0/gtkrc-hidpi > ./gtk-2.0-hidpireal/gtkrc
;;

*)
echo "Huh?"
;;

esac

# GTK3 #
mkdir ./gtk-3.0-hidpi/
cp -r ./gtk-3.0/* ./gtk-3.0-hidpi/
cp ./gtk-3.0/assets/arrow_down.png ./gtk-3.0-hidpi/assets/spin_down.png
cp ./gtk-3.0/assets/arrow_up.png ./gtk-3.0-hidpi/assets/spin_up.png
convert ./gtk-3.0/assets/arrow_down_ins.png -scale 200% ./gtk-3.0-hidpi/assets/arrow_down_ins.png
convert ./gtk-3.0/assets/arrow_down.png -scale 200% ./gtk-3.0-hidpi/assets/arrow_down.png
convert ./gtk-3.0-hidpi/assets/arrow_left_ins.png -scale 200% ./gtk-3.0-hidpi/assets/arrow_left_ins.png
convert ./gtk-3.0-hidpi/assets/arrow_left.png -scale 200% ./gtk-3.0-hidpi/assets/arrow_left.png
convert ./gtk-3.0-hidpi/assets/arrow_right_ins.png -scale 200% ./gtk-3.0-hidpi/assets/arrow_right_ins.png
convert ./gtk-3.0-hidpi/assets/arrow_right.png -scale 200% ./gtk-3.0-hidpi/assets/arrow_right.png
convert ./gtk-3.0-hidpi/assets/arrow_up_ins.png -scale 200% ./gtk-3.0-hidpi/assets/arrow_up_ins.png
convert ./gtk-3.0-hidpi/assets/arrow_up.png -scale 200% ./gtk-3.0-hidpi/assets/arrow_up.png
convert ./gtk-3.0-hidpi/assets/arrow_up.png -scale 200% ./gtk-3.0-hidpi/assets/arrow_up.png
convert ./gtk-3.0-hidpi/assets/c_box_checked.png -scale 200% ./gtk-3.0-hidpi/assets/c_box_checked.png
convert ./gtk-3.0-hidpi/assets/c_box_ins_checked.png -scale 200% ./gtk-3.0-hidpi/assets/c_box_ins_checked.png
convert ./gtk-3.0-hidpi/assets/c_box_ins_mixed.png -scale 200% ./gtk-3.0-hidpi/assets/c_box_ins_mixed.png
convert ./gtk-3.0-hidpi/assets/c_box_ins.png -scale 200% ./gtk-3.0-hidpi/assets/c_box_ins.png
convert ./gtk-3.0-hidpi/assets/c_box_mixed.png -scale 200% ./gtk-3.0-hidpi/assets/c_box_mixed.png
convert ./gtk-3.0-hidpi/assets/c_box.png -scale 200% ./gtk-3.0-hidpi/assets/c_box.png
convert ./gtk-3.0-hidpi/assets/combobox_checked.png -scale 200% ./gtk-3.0-hidpi/assets/combobox_checked.png
convert ./gtk-3.0-hidpi/assets/combobox_disabled.png -scale 200% ./gtk-3.0-hidpi/assets/combobox_disabled.png
convert ./gtk-3.0-hidpi/assets/combobox.png -scale 200% ./gtk-3.0-hidpi/assets/combobox.png
convert ./gtk-3.0-hidpi/assets/fm_toolbar.png -scale 200% ./gtk-3.0-hidpi/assets/fm_toolbar.png
convert ./gtk-3.0-hidpi/assets/headerbox.png -scale 200% ./gtk-3.0-hidpi/assets/headerbox.png
convert ./gtk-3.0-hidpi/assets/radio_checked.png -scale 200% ./gtk-3.0-hidpi/assets/radio_checked.png
convert ./gtk-3.0-hidpi/assets/radio_ins_checked.png -scale 200% ./gtk-3.0-hidpi/assets/radio_ins_checked.png
convert ./gtk-3.0-hidpi/assets/radio_ins_mixed.png -scale 200% ./gtk-3.0-hidpi/assets/radio_ins_mixed.png
convert ./gtk-3.0-hidpi/assets/radio_ins.png -scale 200% ./gtk-3.0-hidpi/assets/radio_ins.png
convert ./gtk-3.0-hidpi/assets/radio_mixed.png -scale 200% ./gtk-3.0-hidpi/assets/radio_mixed.png
convert ./gtk-3.0-hidpi/assets/radio.png -scale 200% ./gtk-3.0-hidpi/assets/radio.png
convert ./gtk-3.0-hidpi/assets/scrollbar_button.png -scale 200% ./gtk-3.0-hidpi/assets/scrollbar_button.png
convert ./gtk-3.0-hidpi/assets/scroll_down_button.png -scale 200% ./gtk-3.0-hidpi/assets/scroll_down_button.png
convert ./gtk-3.0-hidpi/assets/scroll_left_button.png -scale 200% ./gtk-3.0-hidpi/assets/scroll_left_button.png
convert ./gtk-3.0-hidpi/assets/scroll_right_button.png -scale 200% ./gtk-3.0-hidpi/assets/scroll_right_button.png
convert ./gtk-3.0-hidpi/assets/scroll_up_button.png -scale 200% ./gtk-3.0-hidpi/assets/scroll_up_button.png
convert ./gtk-3.0-hidpi/assets/tab_bottom_checked.png -scale 200% ./gtk-3.0-hidpi/assets/tab_bottom_checked.png
convert ./gtk-3.0-hidpi/assets/tab_bottom.png -scale 200% ./gtk-3.0-hidpi/assets/tab_bottom.png
convert ./gtk-3.0-hidpi/assets/tab_gap_bottom.png -scale 200% ./gtk-3.0-hidpi/assets/tab_gap_bottom.png
convert ./gtk-3.0-hidpi/assets/tab_gap_left.png -scale 200% ./gtk-3.0-hidpi/assets/tab_gap_left.png
convert ./gtk-3.0-hidpi/assets/tab_gap_right.png -scale 200% ./gtk-3.0-hidpi/assets/tab_gap_right.png
convert ./gtk-3.0-hidpi/assets/tab_gap_top.png -scale 200% ./gtk-3.0-hidpi/assets/tab_gap_top.png
convert ./gtk-3.0-hidpi/assets/tab_left_checked.png -scale 200% ./gtk-3.0-hidpi/assets/tab_left_checked.png
convert ./gtk-3.0-hidpi/assets/tab_left.png -scale 200% ./gtk-3.0-hidpi/assets/tab_left.png
convert ./gtk-3.0-hidpi/assets/tab_right_checked.png -scale 200% ./gtk-3.0-hidpi/assets/tab_right_checked.png
convert ./gtk-3.0-hidpi/assets/tab_right.png -scale 200% ./gtk-3.0-hidpi/assets/tab_right.png
convert ./gtk-3.0-hidpi/assets/tab_top_checked.png -scale 200% ./gtk-3.0-hidpi/assets/tab_top_checked.png
convert ./gtk-3.0-hidpi/assets/tab_top.png -scale 200% ./gtk-3.0-hidpi/assets/tab_top.png
convert ./gtk-3.0-hidpi/assets/toolbar.png -scale 200% ./gtk-3.0-hidpi/assets/toolbar.png
convert ./gtk-3.0-hidpi/assets/handle.png -scale 200% ./gtk-3.0-hidpi/assets/handle.png
mv -f ./hidpi-res/gtk-3.0/*.* ./gtk-3.0-hidpi/

# GTK4
cp -r ./gtk-4.0 ./gtk-4.0-hidpi/

# Install massaged data to HiDPI theme folders.
mv xfwm4-hidpi ~/.themes/"$theme_name"-HiDPI/xfwm4
mv gtk-2.0-hidpi ~/.themes/"$theme_name"-HiDPI/gtk-2.0
mv gtk-2.0-hidpireal ~/.themes/"$theme_name"-HiDPI/gtk-2.0-hidpi
mv gtk-3.0-hidpi ~/.themes/"$theme_name"-HiDPI/gtk-3.0
mv gtk-4.0-hidpi ~/.themes/"$theme_name"-HiDPI/gtk-4.0

# The leftovers!
cp -r metacity-1 ~/.themes/"$theme_name"-HiDPI/
cp theme.conf ~/.themes/"$theme_name"-HiDPI/
cp version ~/.themes/"$theme_name"-HiDPI/
cp LICENSE ~/.themes/"$theme_name"-HiDPI/
cp index.theme ~/.themes/"$theme_name"-HiDPI/

# Copy Wine reg key.
mkdir ~/.themes/"$theme_name"-HiDPI/wine
cp "$theme_name".reg ~/.themes/"$theme_name"-HiDPI/wine/

fi

# Normal DPI theme.
mv gtk-2.0 ~/.themes/"$theme_name"/
mv gtk-3.0 ~/.themes/"$theme_name"/
mv gtk-4.0 ~/.themes/"$theme_name"/
mv xfwm4 ~/.themes/"$theme_name"/
mv metacity-1 ~/.themes/"$theme_name"/
cp theme.conf ~/.themes/"$theme_name"/
mv version ~/.themes/"$theme_name"/
cp LICENSE ~/.themes/"$theme_name"/
mv index.theme ~/.themes/"$theme_name"/

#Copy Wine reg key.
mkdir ~/.themes/"$theme_name"/wine
mv "$theme_name".reg ~/.themes/"$theme_name"/wine/
echo "GTK2, GTK3 and XFWM4 themes configured and installed."
echo "Theme '$theme_name' installed in ~/.themes/$theme_name. You may now select and use your theme."

}


function cleanup {
#Clean incomplete or interupted builds, compile images
rm -rf gtk-2.0 gtk-3.0 images xfwm4 xfwm4-hidpi hidpi-res
rm rm base.rc gtk.css gtk-base.css gtkrc themerc version LICENSE
}


function makewinehive {
themet_name="Redmond97 SE $Theme_name"
WindowBGcolor=$(grep "Window BG color" ./winereg.tmp | cut -d ":" -f3 | cut -d " " -f2 | tr , ' ')
WindowFGcolor=$(grep "Window FG color" ./winereg.tmp | cut -d ":" -f3 | cut -d " " -f2 | tr , ' ')
BaseBGcolor=$(grep "Base BG color" ./winereg.tmp | cut -d ":" -f3 | cut -d " " -f2 | tr , ' ')
Basetextcolor=$(grep "Base text color" ./winereg.tmp | cut -d ":" -f3 | cut -d " " -f2 | tr , ' ')
SelectedBGcolor=$(grep "Selected BG color" ./winereg.tmp | cut -d ":" -f3 | cut -d " " -f2 | tr , ' ')
SelectedFGcolor=$(grep "Selected FG color" ./winereg.tmp | cut -d ":" -f3 | cut -d " " -f2 | tr , ' ')
Activetitlebarcolor=$(grep "Active titlebar color" ./winereg.tmp | cut -d ":" -f3 | cut -d " " -f2 | tr , ' ')
Activetitletext=$(grep "Active title text" ./winereg.tmp | cut -d ":" -f3 | cut -d " " -f2 | tr , ' ')
Inactivetitlebarcolor=$(grep "Inactive titlebar color" ./winereg.tmp | cut -d ":" -f3 | cut -d " " -f2 | tr , ' ')
Inactivetitletext=$(grep "nactive title text" ./winereg.tmp | cut -d ":" -f3 | cut -d " " -f2 | tr , ' ')
Bordercolor=$(grep "Border color" ./winereg.tmp | cut -d ":" -f3 | cut -d " " -f2 | tr , ' ')
highlightcolorboost=$(grep "3D highlight color boost" ./winereg.tmp | cut -d ":" -f3 | cut -d " " -f2 | tr , ' ')
shadowcolorboost=$(grep "Window BG color" ./winereg.tmp | cut -d ":" -f3 | cut -d " " -f2 | tr , ' ')
Highlightcolor=$(grep "Highlight color" ./winereg.tmp | cut -d ":" -f3 | cut -d " " -f2 | tr , ' ')
Shadowcolor=$(grep "Shadow color" ./winereg.tmp | cut -d ":" -f3 | cut -d " " -f2 | tr , ' ')
DisabledFGcolor=$(grep "Disabled FG color" ./winereg.tmp | cut -d ":" -f3 | cut -d " " -f2 | tr , ' ')
# Build reg file.
echo "Windows Registry Editor Version 5.00" > ./@/"$themet_name".reg
echo ""
echo "[HKEY_CURRENT_USER\Control Panel\Colors]" >> ./@/"$themet_name".reg
echo ""
echo "\"ActiveTitle\"=\"$Activetitlebarcolor\"" >> ./@/"$themet_name".reg
echo "\"Background\"=\"$SelectedBGcolor\"" >> ./@/"$themet_name".reg
echo "\"Hilight\"=\"$SelectedBGcolor\"" >> ./@/"$themet_name".reg
echo "\"HilightText\"=\"$SelectedFGcolor\"" >> ./@/"$themet_name".reg
echo "\"TitleText\"=\"$Activetitletext\"" >> ./@/"$themet_name".reg
echo "\"Window\"=\"$BaseBGcolor\"" >> ./@/"$themet_name".reg
echo "\"WindowText\"=\"$Basetextcolor\"" >> ./@/"$themet_name".reg
echo "\"Scrollbar\"=\"$Shadowcolor\"" >> ./@/"$themet_name".reg
echo "\"InactiveTitle\"=\"$Inactivetitlebarcolor\"" >> ./@/"$themet_name".reg
echo "\"Menu\"=\"$WindowBGcolor\"" >> ./@/"$themet_name".reg
echo "\"WindowFrame\"=\"$Bordercolor\"" >> ./@/"$themet_name".reg
echo "\"MenuText\"=\"$WindowFGcolor\"" >> ./@/"$themet_name".reg
echo "\"ActiveBorder\"=\"$WindowBGcolor\"" >> ./@/"$themet_name".reg
echo "\"InactiveBorder\"=\"$WindowBGcolor\"" >> ./@/"$themet_name".reg
echo "\"ButtonFace\"=\"$WindowBGcolor\"" >> ./@/"$themet_name".reg
echo "\"ButtonShadow\"=\"$Shadowcolor\"" >> ./@/"$themet_name".reg
echo "\"GrayText\"=\"$Inactivetitletext\"" >> ./@/"$themet_name".reg
echo "\"ButtonText\"=\"$WindowFGcolor\"" >> ./@/"$themet_name".reg
echo "\"InactiveTitleText\"=\"$Inactivetitletext\"" >> ./@/"$themet_name".reg
echo "\"ButtonHilight\"=\"$Highlightcolor\"" >> ./@/"$themet_name".reg
echo "\"ButtonDkShadow\"=\"$Shadowcolor\"" >> ./@/"$themet_name".reg
echo "\"ButtonLight\"=\"$WindowBGcolor\"" >> ./@/"$themet_name".reg
echo "\"InfoText\"=\"$WindowFGcolor\"" >> ./@/"$themet_name".reg
echo "\"InfoWindow\"=\"$BaseBGcolor\"" >> ./@/"$themet_name".reg
echo "\"GradientActiveTitle\"=\"$Activetitlebarcolor\"" >> ./@/"$themet_name".reg
echo "\"GradientInactiveTitle\"=\"$Inactivetitlebarcolor\"" >> ./@/"$themet_name".reg
#clean temp file
rm -f ./winereg.tmp
}

#Verify config file hex codes
echo "Verifying and calculating colors. Please wait..."
fgcolor=$(verify $fgcolor)
bgcolor=$(verify $bgcolor)
basecolor=$(verify $basecolor)
basefg=$(verify $basefg)
selectedbg=$(verify $selectedbg)
selectedtext=$(verify $selectedtext)
activetitletext=$(verify $activetitletext)
inactivetitletext=$(verify $inactivetitletext)
activetitle=$(verify $activetitle)
inactivetitle=$(verify $inactivetitle)
border=$(verify $border)
if [ -z "$activetitle1" ]; then
  activetitle1="$border"
else
  activetitle1=$(verify $activetitle1)
fi
if [ -z "$inactivetitle1" ]; then
  inactivetitle1="$bgcolor"
else
  inactivetitle1=$(verify $inactivetitle1)
fi

#Convert to rgb for calculations
hex2rgb $fgcolor
fgcolor_rgb[1]=${rgb[1]%.*}
fgcolor_rgb[2]=${rgb[2]%.*}
fgcolor_rgb[3]=${rgb[3]%.*}

#main functions
hex2rgb "$bgcolor"
calc_colors
prompt
cleanup  2>>/dev/null
