#!/bin/bash

/bin/mkdir -p /etc/service/crond/

/bin/cat << EOF > /etc/service/crond/run
#!/bin/sh
exec /usr/sbin/crond -n
EOF

chmod -R +x /etc/service/crond

