#!/bin/bash
# /usr/local/bin/rpass

LENGTH=${1:-32}
ruby -e "puts (0...$LENGTH).map { (('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a).sample }.join"
