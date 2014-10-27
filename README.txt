Here's a good way to run this:

while [ 1 ]; do ./tokens.py > /tmp/tokens-out.txt; ./tokens.py cards | tail -n 5 >> /tmp/tokens-out.txt; clear; date; echo; cat /tmp/tokens-out.txt; sleep 5; done
