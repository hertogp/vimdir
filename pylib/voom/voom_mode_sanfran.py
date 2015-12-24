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
VOoM markup mode for Cisco confg files. See |voom_mode_cisco|.
"""

### Howto add to the outline
# - supply head_match rgx
# - supply make_vheadline
# - supply make_headline
# - virtual or not
#
# Idea is to use a rgx to match a series of repeating statements
# and turn that into a single virtual headline pointing to a comment line just
# above the first match (creating one if needed).
# The rgx matches two parts:
#   - start_ignore
#   - 
# Examples:
#
# interface fastethernet1/0/1
# ^--match-replace-----^
# ^--match-unique----------^
#
# - replace -> fa
# - vhead_line := fa1/0/..
# which allows for folding f1/0/1..48 into 1 tree headline entry
#
# access-list 1 permit ..
# ^-replace-^
# ^-unique----^
#
# - replace -> acl
# - vhead_line := acl 1...
#
# snmp-server view ...
# ^-replace-^
# ^-unique--^
#
# - nothing will be replaced
# - vhead_line := snmp-server...



# can access main module voom.py, including global outline data
import sys
if 'voom' in sys.modules:
    voom = sys.modules['voom']
    VOOMS = voom.VOOMS
import vim

print 'vim attrs'
for a in dir(vim):
    print a, getattr(vim,a)

print 'voom attrs'
for a in dir(voom):
    print a, getattr(voom,a)



import re
# re to substitute comments.  use comment_tag_sub('new text', line)
comment_tag_sub = re.compile('!.*$').sub
# re to recognize a headline
headline_match = re.compile(r'^(interface|router|access-list|dialer-list|line)').match



VHEADS = [#(r"((interface\s+fastethernet\s*).*?)\d+$","int fa","...",'!'),
          #(r"((interface\s+gigabitethernet\s*).*?)\d+$", "int gi","...","!"),
          #(r"((interface\s+vlan\s*).*?)\d+$", "int vlan","...","!"),
          #(r"((access-list\s+)\d+).*$","acl ","...","!"),
          #(r"((snmp-server)\s+).*$", "snmp-server ",'','!'),
          #(r"((line\s+con)\s+).*$", "line con ",'','!'),
          #(r"((line\s+vty)\s+).*$", "line vty ",'','!'),
          (r"((ntp\s+)).*$", "ntp ",'...','!'),
         ]
RHEADS = [(re.compile(r).match,s,t,c) for r,s,t,c in VHEADS]

def get_level2(L,his=['']):
    '''return (level,vgrp), where
       level - tree outline level for L, and
       vgrp  - virtual outline header text (if any)
    '''
    if L is None:
        del his[:]          # clear sense of history
        his[0]=''
        return (1,'')

    w = L.lower().split()
    vgrp = ''
    if len(w)<2: return 1,''
    fst = w[0] if w[0] != 'no' else w[1]
    if fst == 'interface':
        vgrp = 'int %s..'%w[-1].rstrip('0123456789')
        vgrp = vgrp.replace('fastethernet','f')
        vgrp = vgrp.replace('gigabitethernet','g')
    elif fst in 'access-list dialer-list':
        vgrp = ' '.join(w[0:2])
    else:
        if his[0] == fst: 
            return 2,''
        else: 
            his[0] = fst
            return 1,''

    if his[0] == vgrp: return 2,''
    his[0] = vgrp
    return 2,vgrp

def get_level3(L,his=['']):
    '''return (level,vgrp), where
       level - tree outline level for L, and
       vgrp  - virtual outline header text (if any)
    '''
    if L is None:
        del his[:]          # clear sense of history
        his[0]=''
        return (1,'')

    w = L.lower().split()
    vgrp = ''
    if len(w)<2: return 1,''
    fst = w[0] if w[0] != 'no' else w[1]
    if fst == 'interface':
        vgrp = 'int %s..'%w[-1].rstrip('0123456789')
        vgrp = vgrp.replace('fastethernet','f')
        vgrp = vgrp.replace('gigabitethernet','g')
    elif fst in 'access-list dialer-list':
        vgrp = ' '.join(w[0:2])
    else:
        if his[0] == fst: 
            return 2,''
        else: 
            his[0] = fst
            return 1,''

    if his[0] == vgrp: return 2,''
    his[0] = vgrp
    return 1,''
### Voom functions called
#-- voom.vim: Voom_BodyCheckTicks
#   s:voom_bodies[a:body].tick_!=b:changedtick
#    - calls Voom_BodyUpdateTree()
#    - Voom_ErrorMsg('VOom: wrong ticks for Body buffer <n>. Updated outline
#-- two

def hook_makeOutline(VO, blines):
    """Return (tlines, bnodes, levels) for list of Body lines.
    blines can also be Vim buffer object.
    """
    Z = len(blines)
    tlines, bnodes, levels = [], [], []
    tlines_add, bnodes_add, levels_add = tlines.append, bnodes.append, levels.append
    seen = {'':''} # Seen HEADS
    after = []
    b_delta = 0
    Lp=''
    if blines != VO.Body:
        print >> sys.stdout, 'blines != VO.Body'
        print >> sys.stdout, 'blines\n','\n'.join(blines)
        print >> sys.stdout, '\n\nBody\n', '\n'.join(VO.Body)
    for i,L in enumerate(blines):        
        Lp = blines[i-1] if i else ''
        b = i + 1                             # b refers to 1-based buffer line nr
        L = L.rstrip()           # clean the body line
        if not L: continue               # skip empty line
        if not L[0].isalpha(): continue  # skip indents,comments and garbage
        if len(L) == 1: continue         # skip single char lines too
        L_comment = L.find('!')
        if L_comment > 0: L = L[0:L_comment]  # strip comment
        lev,vgrp = get_level3(L) # get_level(seen,L)
        if vgrp:
            if not Lp.startswith('!'):
                after.append((i+b_delta,vgrp))
                b_delta += 1
            levels_add(1)
            tlines_add('  {0}|{1}'.format('', vgrp))
            bnodes_add(i+b_delta)

        levels_add(lev)
        tlines_add('  {0}|{1}'.format(' .'*(lev-1), L))
        bnodes_add(b+b_delta)

    for n,t in after: VO.Body[n:n]=['!!'] #blines[n:n] = ['!!']

    return (tlines, bnodes, levels)



def hook_newHeadline(VO, level, blnum, tlnum):
    """Return (tree_head, bodyLines).
    tree_head is new headline string in Tree buffer (text after |).
    bodyLines is list of lines to insert in Body buffer.
    # column is cursor position in new headline in Body buffer.
    """
    tree_head = 'NewHeadline'
    bodyLines = ['NewHeadline']
    return (tree_head, bodyLines)

def update_bnodes(VO, tlnum, delta):
    """Update VO.bnodes by adding/substracting delta to each bnode
    starting with bnode at tlnum and to the end.
    """
    bnodes = VO.bnodes
    for i in xrange(tlnum, len(bnodes)+1):
        bnodes[i-1] += delta

#def hook_changeLevBodyHead(VO, h, levDelta):
#    DO NOT CREATE THIS HOOK

# copy/paste from voom_mode_rest.py
def hook_doBodyAfterOop(VO, oop, levDelta, blnum1, tlnum1, blnum2, tlnum2, blnumCut, tlnumCut):
    # this is instead of hook_changeLevBodyHead()
    #print oop, levDelta, blnum1, tlnum1, blnum2, tlnum2, tlnumCut, blnumCut
    print 'hook_doBodyAfterOop', oop, levDelta,blnum1,blnum2
    Body = VO.Body
    Z = len(Body)
    bnodes, levels = VO.bnodes, VO.levels

    # blnum1 blnum2 is first and last lnums of Body region pasted, inserted
    # during up/down, or promoted/demoted.
    if blnum1:
        assert blnum1 == bnodes[tlnum1-1]
        if tlnum2 < len(bnodes):
            assert blnum2 == bnodes[tlnum2]-1
        else:
            assert blnum2 == Z

    # blnumCut is Body lnum after which a region was removed during 'cut',
    # 'up', 'down'. We need to check if there is blank line between nodes
    # used to be separated by the cut/moved region to prevent headline loss.
    if blnumCut:
        if tlnumCut < len(bnodes):
            assert blnumCut == bnodes[tlnumCut]-1
        else:
            assert blnumCut == Z

    # Total number of added lines minus number of deleted lines.
    b_delta = 0

    ### After 'cut' or 'up': insert blank line if there is none
    # between the nodes used to be separated by the cut/moved region.
    if (oop=='cut' or oop=='up') and (0 < blnumCut < Z) and Body[blnumCut-1].strip():
        Body[blnumCut:blnumCut] = ['']
        update_bnodes(VO, tlnumCut+1 ,1)
        b_delta+=1

    if oop=='cut':
        return

    ### Prevent loss of headline after last node in the region:
    # insert blank line after blnum2 if blnum2 is not blank, that is insert
    # blank line before bnode at tlnum2+1.
    if blnum2 < Z and Body[blnum2-1].strip():
        Body[blnum2:blnum2] = ['']
        update_bnodes(VO, tlnum2+1 ,1)
        b_delta+=1

    ### Change levels and/or styles of headlines in the affected region.
    # Always do this after Paste, even if level is unchanged -- adornments can
    # be different when pasting from other outlines.
    # Examine each headline, from bottom to top, and change adornment style.
    # To change from underline to overline style:
    #   insert overline.
    # To change from overline to underline style:
    #   delete overline if there is blank before it;
    #   otherwise change overline to blank line;
    #   remove inset from headline text.
    # Update bnodes after inserting or deleting a line.
    if levDelta or oop=='paste':
        ads_levels = VO.ads_levels
        levels_ads = dict([[v,k] for k,v in ads_levels.items()])
        # Add adornment styles for new levels. Can't do this in the main loop
        # because it goes backwards and thus will add styles in reverse order.
        for i in xrange(tlnum1, tlnum2+1):
            lev = levels[i-1]
            if not lev in levels_ads:
                ad = get_new_ad(levels_ads, ads_levels, lev)
                levels_ads[lev] = ad
                ads_levels[ad] = lev
        for i in xrange(tlnum2, tlnum1-1, -1):
            # required level (VO.levels has been updated)
            lev = levels[i-1]
            # required adornment style
            ad = levels_ads[lev]

            # deduce current adornment style
            bln = bnodes[i-1]
            L1 = Body[bln-1].rstrip()
            L2 = Body[bln].rstrip()
            if bln+1 < len(Body):
                L3 = Body[bln+1].rstrip()
            else:
                L3 = ''
            ad_ = deduce_ad_style(L1,L2,L3)

            # change adornment style
            # see deduce_ad_style() for diagram
            if ad_==ad:
                continue
            elif len(ad_)==1 and len(ad)==1:
                Body[bln] = ad*len(L2)
            elif len(ad_)==2 and len(ad)==2:
                Body[bln-1] = ad[0]*len(L1)
                Body[bln+1] = ad[0]*len(L3)
            elif len(ad_)==1 and len(ad)==2:
                # change underline if different
                if not ad_ == ad[0]:
                    Body[bln] = ad[0]*len(L2)
                # insert overline; current bnode doesn't change
                Body[bln-1:bln-1] = [ad[0]*len(L2)]
                update_bnodes(VO, i+1, 1)
                b_delta+=1
            elif len(ad_)==2 and len(ad)==1:
                # change underline if different
                if not ad_[0] == ad:
                    Body[bln+1] = ad*len(L3)
                # remove headline inset if any
                if not len(L2) == len(L2.lstrip()):
                    Body[bln] = L2.lstrip()
                # check if line before overline is blank
                if bln >1:
                    L0 = Body[bln-2].rstrip()
                else:
                    L0 = ''
                # there is blank before overline
                # delete overline; current bnode doesn't change
                if not L0:
                    Body[bln-1:bln] = []
                    update_bnodes(VO, i+1, -1)
                    b_delta-=1
                # there is no blank before overline
                # change overline to blank; only current bnode needs updating
                else:
                    Body[bln-1] = ''
                    bnodes[i-1]+=1

    ### Prevent loss of first headline: make sure it is preceded by a blank line
    blnum1 = bnodes[tlnum1-1]
    if blnum1 > 1 and Body[blnum1-2].strip():
        Body[blnum1-1:blnum1-1] = ['']
        update_bnodes(VO, tlnum1 ,1)
        b_delta+=1

    ### After 'down' : insert blank line if there is none
    # between the nodes used to be separated by the moved region.
    if oop=='down' and (0 < blnumCut < Z) and Body[blnumCut-1].strip():
        Body[blnumCut:blnumCut] = ['']
        update_bnodes(VO, tlnumCut+1 ,1)
        b_delta+=1

    assert len(Body) == Z + b_delta

