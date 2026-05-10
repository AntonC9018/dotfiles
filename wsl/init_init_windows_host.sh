CURRENT_USER=$(logname)

sudo tee /etc/systemd/system/update-hosts.service > /dev/null << EOF
[Unit]
Description=Update hosts from Windows

[Service]
Type=oneshot
ExecStart=/home/$CURRENT_USER/init_windows_host.sh

[Install]
WantedBy=default.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable update-hosts.service
# sudo systemctl start update-hosts.service
