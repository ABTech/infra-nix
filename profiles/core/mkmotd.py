#!/usr/bin/env python3

import json

palette = {
    "r": "\033[31m",
    "w": "\033[37m",
}
ink = "\u2588"  # Full block
reset = "\033[0m"

logo = """
           rrrr         www                       wwww       
 rrrrrrrrrr  rr         www                       wwwww      
 r           rrrrrrrrrwwwwwww wwwwwww    wwwwww  wwwwwwwww  
    rrrrrrr  rrrrrrrrrwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww 
                    rrrrwww wwwwwwwwwwwwwww      wwwww wwww 
          rrrrr     rrrrwwwwwwwwwwwwwwwwwwww wwwwwwwww wwww 
          rrrrrrrrrrrrrr wwww wwwwwwww  wwwwwwww wwwww wwww 
          rrrr  rrrrrrr                                     
"""

# The text rendered to the terminal:
rendered = ""
color = None
for char in logo:
    if char in palette:
        if color != char:
            rendered += palette[char]
            color = char
        rendered += ink
    else:
        rendered += char

rendered += reset

# JSON-escape so Nix can read it
with open("motd.json", "w+") as f:
    json.dump(rendered, f)

