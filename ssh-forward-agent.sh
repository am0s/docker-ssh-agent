#!/bin/bash -e
# Log the location of the SSH agent to a file

# Path to the fixed files
FIXED_SOCKET_PATH="/docker-ssh/ssh-agent_socket_path"
FIXED_SOCKET_FILE="/docker-ssh/ssh-agent_socket"

if [ -z "$SSH_AUTH_SOCK" ]; then
   echo "SSH_AUTH_SOCK is not set or is empty"
   exit 1
fi

# Decode symlinked path to real path
REAL_SSH_AUTH_SOCK=`readlink -f $SSH_AUTH_SOCK`

cleanup() {
   rm -f "$FIXED_SOCKET_FILE" "$FIXED_SOCKET_PATH"
}
trap cleanup EXIT

# Store the current socket path to a file
echo "$REAL_SSH_AUTH_SOCK" > "$FIXED_SOCKET_PATH"

# (Re)link the agent socket to a fixed path
rm -f "$FIXED_SOCKET_FILE"
ln -s "$REAL_SSH_AUTH_SOCK" "$FIXED_SOCKET_FILE"

echo "Auth socket file can be found in '$REAL_SSH_AUTH_SOCK'"
echo
echo "SSH socket is forwarded, uses the following line in another container:"
echo
echo "export SSH_AUTH_SOCK=\"$FIXED_SOCKET_FILE\""

# Wait forever
tail -f /dev/null
