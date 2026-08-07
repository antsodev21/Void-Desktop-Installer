#!/usr/bin/env bash
#Detector de gestor de permisos de superusuario
if command -v sudo >/dev/null 2>&1; then
    please="sudo"
elif command -v doas >/dev/null 2>&1; then
    please="doas"
else
    echo "Please Install sudo or doas"
    exit 1
fi
#instalar dialog
if ! command -v dialog >/dev/null 2>&1; then
    $please xbps-install -Sy dialog
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
#Servicios por defecto de voidlinux
base-sv() {
    $please bash -c ' 
        # Cambiado polkitd por polkit
        xbps-install -Sy xorg xdg-user-dirs power-profiles-daemon polkit NetworkManager elogind dbus gvfs-afc gvfs-mtp gvfs-smb xdg-desktop-portal nerd-fonts adwaita-fonts
        rm -rf /var/service/dhcpcd/
        rm -rf /var/service/wpa_supplicant
        ln -sf /etc/sv/NetworkManager /var/service/
        ln -sf /etc/sv/dbus /var/service/
        ln -sf /etc/sv/power-profiles-daemon /var/service/
        ln -sf /etc/sv/polkitd /var/service/
    '
    #Para deshabilitar la accion de cerrar la tapa...
    #$please sed -i 's/#HandleLidSwitch=suspend/HandleLidSwitch=ignore/g' /etc/elogind/logind.conf
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
        6 "LXQt" \
        7 "MATE" \
        8 "IceWM" \
        2>&1 >/dev/tty)
    
    # Permite que si le das a Esc o a Cancelar se cancele la instalacion
    if [ $? -ne 0 ]; then
        clear
        echo "Installation aborted"
        exit 0
    fi
    
    # En el caso que $DESKTOP sea "Escritorio" hara una cosa u otra
    case $DESKTOP in

        1)  
            echo "Installing GNOME"
            configurar_audio_bluetooth
            base-sv
            $please xbps-install -Sy gdm gnome
            $please ln -sf /etc/sv/gdm /var/service/

            ;;

        2)
            echo "Installing KDE Plasma"
            configurar_audio_bluetooth
            base-sv
            $please xbps-install -Sy sddm kde-plasma kde-baseapps ark spectacle
            $please ln -sf /etc/sv/sddm /var/service/
            ;;

        3)
            echo "Installing Xfce"
            configurar_audio_bluetooth
            base-sv
            $please xbps-install -Sy lightdm xfce4 xfce4-pulseaudio-plugin network-manager-applet
            $please  ln -sf /etc/sv/lightdm /var/service/
            # Acción al cerrar la tapa usando batería (0 = No hacer nada)
            xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lid-action-on-battery -n -t int -s 0
            
            # Acción al cerrar la tapa usando el cargador (0 = No hacer nada)
            xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lid-action-on-ac -n -t int -s 0
            
            # Evitar que elogind/logind tome el control de la tapa y sobrescriba a Xfce
            xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/logind-handle-lid-switch -n -t bool -s false
            ;;

        4)
            echo "Installing Budgie"
            configurar_audio_bluetooth
            base-sv
            $please bash << "EOF"
            xbps-install -Sy lightdm mutter budgie-desktop gnome-keyring polkit-gnome udisks2 network-manager-applet nemo tilix engrampa papirus-icon-theme arc-theme
            ln -sf /etc/sv/lightdm /var/service/
            e
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
            echo "Installing Cinnamon"
            configurar_audio_bluetooth
            base-sv
            $please xbps-install -Sy lightdm cinnamon gnome-terminal colord
            $please ln -sf /etc/sv/lightdm /var/service/
            ;;
            
        6)
            echo "Installing LXQt"
            configurar_audio_bluetooth
            base-sv
            $please xbps-install -Sy sddm discover qt6-virtualkeyboard qt6-svg qt6-multimedia lxqt
            $please ln -sf /etc/sv/sddm /var/service/
            ;;
            
        7)
            echo "Installing MATE"
            configurar_audio_bluetooth
            base-sv
            $please xbps-install -Sy lightdm mate-extras mate mate-tweak mate-polkit mate-terminal caja-wallpaper caja-sendto caja-open-terminal caja-extensions gnome-keyring gnome-screenshot
            $please ln -sf /etc/sv/lightdm /var/service/
            ;;

        8)
            echo "Installing IceWM"
            configurar_audio_bluetooth
            base-sv
            $please xbps-install -Sy lightdm icewm xarchiver p7zip ristretto arandr pcmanfm xdg-desktop-portal-gtk
            $please ln -sf /etc/sv/lightdm /var/service/
            ;;

    esac

    clear
    echo "Desktop installed. Rebooting is recommended."

    break
done
