sudo DEBIAN_FRONTEND=noninteractive
echo "Update packages"
sudo apt-get update -y
echo "Upgrade packages"
sudo apt-get upgrade -y
echo "Install mate desktop"
sudo apt-get install -y mate-core mate-desktop-environment mate-notification-daemon
echo "Install xrdp"
sudo apt-get install -y xrdp
echo "Configure xrdp"
sudo sed -i 's/allowed_users=console/allowed_users=anybody/' /etc/X11/Xwrapper.config
sudo sed -i.bak '/fi/a #xrdp multiple users configuration \n mate-session \n' /etc/xrdp/startwm.sh
echo "Restart xrdp"
sudo systemctl restart xrdp
echo "Enable xrdp"
sudo systemctl enable xrdp
echo "Install gnome tweak tool"
sudo apt-get install gnome-tweak-tool -y
echo "Install libvlc"
sudo apt-get install -y libvlc-dev
echo "Install VLC"
sudo add-apt-repository ppa:videolan/stable-daily
sudo apt-get update
sudo apt-get install -y vlc
echo "Install GIT"
sudo apt install -y git
echo "Add ffmpeg repo"
sudo add-apt-repository  -y ppa:kirillshkrogalev/ffmpeg-next
echo "Install obs studio"
sudo apt-get install -y obs-studio
echo "Clone nginx rtmp module"
sudo git clone https://github.com/sergey-dryabzhinsky/nginx-rtmp-module.git
echo "Install nginx requrements"
sudo apt-get install -y build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev
echo "Install nginx"
wget http://nginx.org/download/nginx-1.14.2.tar.gz
wait $!
tar -xf nginx-1.14.2.tar.gz
cd nginx-1.14.2
echo "Configure nginx"
./configure --with-http_ssl_module --add-module=../nginx-rtmp-module
echo "Make nginx"
make -j 1
make install
echo "Change nginx config"
echo "worker_processes  auto;
events {
    worker_connections  1024;
}

# RTMP configuration
rtmp {
    server {
        listen 1935; # Listen on standard RTMP port
	# set connection secure link
        application show {
            live on;

	    # No RTMP playback
            deny play all;

            # Only allow publishing from localhost
            allow publish 127.0.0.1;
            deny publish all;
            # Turn on HLS
            hls on;
            hls_path /mnt/hls/;
            hls_fragment 30;
            hls_playlist_length 60;
        }
    }
}

http {
    sendfile off;
    tcp_nopush on;
    directio 512;
    default_type application/octet-stream;

    server {
        listen 8080;
        location / {
	    # set connection secure link

            # Disable cache
            add_header 'Cache-Control' 'no-cache';

            # CORS setup
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Expose-Headers' 'Content-Length';

            # allow CORS preflight requests
            if (\$request_method = 'OPTIONS') {
                add_header 'Access-Control-Allow-Origin' '*';
                add_header 'Access-Control-Max-Age' 1728000;
                add_header 'Content-Type' 'text/plain charset=UTF-8';
                add_header 'Content-Length' 0;
                return 204;
            }
            types {
                application/dash+xml mpd;
                application/vnd.apple.mpegurl m3u8;
                video/mp2t ts;
            }

            root /mnt/;
        }
    }
}" > /usr/local/nginx/conf/nginx.conf
echo "Start nginx"
/usr/local/nginx/sbin/nginx
