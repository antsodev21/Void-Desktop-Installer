#!/bin/bash

# Hace que si hay algun fallo, el Script se detenga
#set -euo pipefail

echo "#==Void-Linux-Desktop-Installer-by-Antsoftware21==#"
sudo xbps-install dialog

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
            sudo xbps-install -S pulseaudio pavucontrol

            ;;

        2)
            echo "Installing PipeWire..."
            sudo xbps-install -S pipewire wireplumber alsa-pipewire libjack-pipewire
            sudo groupadd pipewire
            sudo groupadd pulse
            sudo groupadd pulse-access
            sudo usermod -aG pipewire $USER
            sudo usermod -aG pulse $USER
            sudo usermod -aG pulse-access $USER

            ;;
    esac

    if [ $BLUETOOTH -eq 0 ]; then
        echo "Installing Bluetooth support..."
        sudo xbps-install -S bluez && sudo ln -s /etc/sv/bluetoothd/ /var/service/ && sudo usermod -aG bluetooth $USER
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
        4 "Cinnamon" \
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
            sudo xbps-install -S xorg NetworkManager elogind dbus nerd-fonts power-profiles-daemon
            sudo rm -rf /var/service/dhcpcd/
            sudo rm -rf /var/service/wpa_supplicant
            sudo ln -s /etc/sv/NetworkManager /var/service/
            sudo ln -s /etc/sv/dbus/ /var/service/
            sudo ln -s /etc/sv/power-profiles-daemon/ /var/service/
            sudo ln -s /etc/sv/polkitd/ /var/service/
            sudo ln -s /etc/sv/elogind/ /var/service/
            sudo ln -s /etc/sv/gdm/ /var/service/

            ;;

        2)
            echo "Installing KDE Plasma"
            configurar_audio_bluetooth
            sudo xbps-install -S xorg NetworkManager elogind dbus nerd-fonts power-profiles-daemon sddm kde-plasma kde-baseapps ark spectacle
            sudo rm -rf /var/service/dhcpcd/
            sudo rm -rf /var/service/wpa_supplicant
            sudo ln -s /etc/sv/NetworkManager /var/service/
            sudo ln -s /etc/sv/dbus/ /var/service/
            sudo ln -s /etc/sv/power-profiles-daemon/ /var/service/
            sudo ln -s /etc/sv/polkitd/ /var/service/
            sudo ln -s /etc/sv/elogind/ /var/service/
            pkill elogind
            sudo ln -s /etc/sv/sddm/ /var/service/

            ;;

        3)
            echo "Installing Xfce"
            configurar_audio_bluetooth
            sudo xbps-install -S xorg NetworkManager elogind dbus nerd-fonts power-profiles-daemon
            sudo rm -rf /var/service/dhcpcd/
            sudo rm -rf /var/service/wpa_supplicant
            sudo ln -s /etc/sv/NetworkManager /var/service/
            sudo ln -s /etc/sv/dbus/ /var/service/
            sudo ln -s /etc/sv/power-profiles-daemon/ /var/service/
            sudo ln -s /etc/sv/polkitd/ /var/service/
            sudo ln -s /etc/sv/elogind/ /var/service/
            sudo ln -s /etc/sv/lightdm/ /var/service/

            ;;

        4)
            echo "Installing Cinnamon"
            configurar_audio_bluetooth
            sudo xbps-install -S xorg NetworkManager elogind dbus nerd-fonts power-profiles-daemon
            sudo rm -rf /var/service/dhcpcd/
            sudo rm -rf /var/service/wpa_supplicant
            sudo ln -s /etc/sv/NetworkManager /var/service/
            sudo ln -s /etc/sv/dbus/ /var/service/
            sudo ln -s /etc/sv/power-profiles-daemon/ /var/service/
            sudo ln -s /etc/sv/polkitd/ /var/service/
            sudo ln -s /etc/sv/elogind/ /var/service/
            sudo ln -s /etc/sv/lightdm/ /var/service/

            ;;
    esac
done
