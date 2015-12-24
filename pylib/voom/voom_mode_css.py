# voom_mode_wiki.py
# VOoM (Vim Outliner of Markers): two-pane outliner and related utilities
# plugin for Python-enabled Vim version 7.x
# Website: http://www.vim.org/scripts/script.php?script_id=2657
# Author:  Vlad Irnov (vlad DOT irnov AT gmail DOT com)
# License: This program is free software. It comes without any warranty,
#          to the extent permitted by applicable law. You can redistribute it
#          and/or modify it under the terms of the Do What The Fuck You Want To
#          Public License, Version 2, as published by Sam Hocevar.
#          See http://sam.zoy.org/wtfpl/COPYING for more details.

"""
VOoM markup mode for css files.
"""

### Voom functions called
#-- voom.vim: Voom_BodyCheckTicks
#   s:voom_bodies[a:body].tick_!=b:changedtick
#    - calls Voom_BodyUpdateTree()
#    - Voom_ErrorMsg('VOom: wrong ticks for Body buffer <n>. Updated outline

# Outline puts global commands on level 1, subsequent global commands in the
# same category are on level 2 (so you can fold them).  For interfaces and
# access-lists (you can easily add more), it actually looks at 2 keywords.

def hook_makeOutline(VO, blines):
    """Return (tlines, bnodes, levels) for list of Body lines.
    blines can also be Vim buffer object.
    """
    tlines, bnodes, levels = [], [], []
    tlines_add, bnodes_add, levels_add = tlines.append, bnodes.append, levels.append
    seen = {}  # seen previousely on an input line
    sig_ = ''
    for i,L in enumerate(blines):
        if not L: continue                                     # skip empty
        elif L.startswith('<!-- '): L = L.replace('<!--','>>') # HEADLINE
        elif not L[0].isalpha(): continue                      # skip indents
        elif L[0] == '}': continue                             # skip block closers
        else: L = L.rsplit('{')[0].rstrip()                    # cleanup line
        if len(L) < 1: continue               # skip really short lines
        L = L.lower()                         # outline will be lower cased
        W = L.split()[0:4]                    # use only first 5 words
        if not W: continue

        # assign level 1 when seeing a glob cmd for the 1st time, else 2
        sig = ' '.join(W[0:2])                # sig = first 3 words
        L = ' '.join(W[0:4])
        lev = 2 if sig in seen else seen.setdefault(sig,1)
        lev = 2 if sig == sig_ else 1
        sig_ = sig
        levels_add(lev)
        tlines_add('  {0}|{1}'.format(' .'*(lev-1), L))
        bnodes_add(i+1)

    return (tlines, bnodes, levels)

def hook_newHeadline(VO, level, blnum, tlnum):
    """Return (tree_head, bodyLines).
    tree_head is new headline string in Tree buffer (text after |).
    bodyLines is list of lines to insert in Body buffer.
    # column is cursor position in new headline in Body buffer.
    """
    tree_head = 'NewHeadline'
    bodyLines = ['! NewHeadline']
    return (tree_head, bodyLines)
