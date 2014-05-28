#!/bin/bash

/bin/cat << EOF > /etc/service/crond/run
#!/bin/sh
exec /usr/sbin/crond -n
EOF

chmod -R +x /etc/service/crond

