#!/usr/bin/env bash
#instalar dialog
if ! command -v dialog >/dev/null 2>&1; then
    $please xbps-install -Sy dialog
fi
#Detector de gestor de permisos de superusuario
if command -v sudo >/dev/null 2>&1; then
    please="sudo"
elif command -v doas >/dev/null 2>&1; then
    please="doas"
else
    echo "Please Install sudo or doas"
    exit 1
fi
#==SUBMENÚ-DE-OPCIONES==#
configurar_audio_bluetooth() {
    # Pregunta por el servidor de audio
    AUDIO=$(dialog --clear \
        --backtitle "Void-Desktop-Installer-by-Antsoftware21" \
        --title "Audio" \
        --menu "Choose your audio server:" 15 50 2 \
        1 "PulseAudio" \
        2 "PipeWire" \
        2>&1 >/dev/tty)

    # Si cancela, salimos del script
    if [ $? -ne 0 ]; then
        clear
        echo "Installation aborted"
        exit 0
    fi

    # Pregunta por el Bluetooth
    dialog --clear \
        --backtitle "Void-Desktop-Installer-by-Antsoftware21" \
        --title "Bluetooth" \
        --yesno "Do you want to install Bluetooth support?\n\nThis will enable the bluetoothd service." 10 50
    BLUETOOTH=$?

    # Instala segun lo elegido
    case $AUDIO in

        1)
            echo "Installing PulseAudio..."
            $please xbps-install -Sy pulseaudio pavucontrol

            ;;

        2)
            echo "Installing PipeWire..."
            $please bash -c '
            xbps-install -Sy pipewire wireplumber alsa-pipewire libjack-pipewire pavucontrol pulseaudio-utils

            # Configura pipewire para que levante wireplumber y pipewire-pulse el mismo
            mkdir -p /etc/pipewire/pipewire.conf.d
            ln -sf /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
            ln -sf /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/

            # Integra ALSA a traves de PipeWire
            mkdir -p /etc/alsa/conf.d
            ln -sf /usr/share/alsa/alsa.conf.d/50-pipewire.conf /etc/alsa/conf.d/
            ln -sf /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d/

            # Autostart XDG: funciona en GNOME, Plasma, Xfce y Cinnamon
            mkdir -p /etc/xdg/autostart
            ln -sf /usr/share/applications/pipewire.desktop /etc/xdg/autostart/
            '
            # Grupos necesarios para acceder a los dispositivos de audio/video
            $please usermod -aG audio,video $USER
            ;;
    esac

    if [ $BLUETOOTH -eq 0 ]; then
        echo "Installing Bluetooth support..."
        $please xbps-install -Sy bluez
        # Audio Bluetooth por PipeWire
        if [ "$AUDIO" = "2" ]; then
            $please xbps-install -Sy libspa-bluetooth
        fi
        $please ln -sf /etc/sv/bluetoothd/ /var/service/
        $please usermod -aG bluetooth $USER
    else
        echo "Skipping Bluetooth"
    fi
}

#==MENÚ-DE-OPCIONES==#
while true; do
    DESKTOP=$(dialog --clear \
        --backtitle "Void-Desktop-Installer-by-Antsoftware21" \
        --title "Desktop-Installer" \
        --menu "Choose a desktop:" 15 50 4 \
        1 "GNOME" \
        2 "KDE Plasma" \
        3 "Xfce" \
        4 "Budgie" \
        5 "Cinnamon" \
        6 "Icewm" \
        7 "Lxqt" \
        8 "mate" \
        2>&1 >/dev/tty)
    
    # Permite que si le das a Esc o a Cancelar se cancele la instalacion
    if [ $? -ne 0 ]; then
        clear
        echo "Installation aborted"
        exit 0
    fi
    #Servicios por defecto de voidlinux
    base-sv(){
    $please bash -c ' 
        xbps-install -Sy xorg xdg-user-dirs power-profiles-daemon polkitd NetworkManager elogind dbus gvfs-afc gvfs-mtp gvfs-smb xdg-desktop-portal
        rm -rf /var/service/dhcpcd/
        rm -rf /var/service/wpa_supplicant
        ln -s /etc/sv/NetworkManager /var/service/
        ln -s /etc/sv/dbus/ /var/service/
        ln -s /etc/sv/power-profiles-daemon/ /var/service/
        ln -s /etc/sv/polkitd/ /var/service/
        ln -sf /etc/sv/dbus /var/service/
        '
    }
    # En el caso que $DESKTOP sea "Escritorio" hara una cosa u otra
    case $DESKTOP in

        1)  
            echo "Installing GNOME"
            configurar_audio_bluetooth
            base-sv
            $please xbps-install -Sy gdm gnome
            $please  ln -s /etc/sv/gdm/ /var/service/

            ;;

        2)
            echo "Installing KDE Plasma"
            configurar_audio_bluetooth
            base-sv
            $please xbps-install -Sy sddm kde-plasma kde-baseapps ark spectacle
            $please ln -s /etc/sv/sddm/ /var/service/
            ;;

        3)
            echo "Installing Xfce"
            configurar_audio_bluetooth
            base-sv
            $please xbps-install -Sy lightdm xfce4 xfce4-pulseaudio-plugin network-manager-applet
            $please  ln -s /etc/sv/lightdm/ /var/service/
            ;;

        4)
            echo "Installing Budgie"
            configurar_audio_bluetooth
            base-sv
            $please bash << "EOF"
            xbps-install -Sy lightdm mutter budgie-desktop gnome-keyring polkit-gnome udisks2 network-manager-applet nemo tilix engrampa papirus-icon-theme arc-theme
            ln -sf /etc/sv/lightdm/ /var/service/
            
            mkdir -p /etc/xdg/autostart
            cat > /etc/xdg/autostart/nm-applet.desktop << 'INNER_EOF'
[Desktop Entry]
Type=Application
Name=Network Manager Applet
Exec=nm-applet --indicator
Icon=nm-device-wireless
Terminal=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
INNER_EOF
EOF
            ;;
            5)
                echo "installing cinnamon"
                configurar_audio_bluetooth
                base-sv
                $please xbps-install cinnamon gnome-terminal colord
            ;;

            6)
                echo "installing icewm"
                configurar_audio_bluetooth
                base-sv
                $please xbps-install icewm xarchiver p7zip ristretto arandr pcmanfm xdg-desktop-portal-gtk
            ;;
            7)
                echo "installing lxqt"
                configurar_audio_bluetooth
                base-sv
                $please xbps-install discover qt6-virtualkeyboard qt6-svg qt6-multimedia lxqt
            ;;
            8)
                echo "installing mate"
                configurar_audio_bluetooth
                base-sv
                $please xbps-install mate-extras mate mate-tweak mate-polkit mate-terminal caja-wallpaper caja-sendto caja-open-terminal caja-extensions gnome-keyring gnome-screenshot
            ;;

    esac

    clear
    echo "Desktop installed. Rebooting is recommended."

    break
done
