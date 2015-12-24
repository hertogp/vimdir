"""
Normally this would go into ~/.vim/pythonx directory, but for some reason
this dir is not on my sys.path at the moment (see :py import sys; print
sys.path<CR>).  However, directory ~/.vim/pylib is present on the path, so the
snippets_helper.py (note: in snippets file do "from snippet_helpers import *")
to import all functions defined here.

"""
from datetime import date, timedelta

def ywd_isodate(year, week, dow):
    try:
        year, week, dow = int(year), int(week), int(dow)
        y0, w0, d0 = date(year, 1, 1).isocalendar()
        return (date(year, 1, 1) + timedelta(weeks=week-w0, days=dow-d0)).isoformat()
    except Exception, e:
        return "YYYY-MM-DD?"

ADDR = {'PHE.cell':  '06-20617005',
        'PHE.mail1': 'pieter@dwark.nl',
        'PHE.mail2': 'pieter.denhertog@routz.nl',
        'PHE.mail3': 'pieter.denhertog@prorail.nl',
        'PHE.mail4': 'ptr@nedportal.nl',
        'PHE.phone': '076-123234345',
        'QHE1': '123123123',
        'QRE1': '567567567567'
        }

def addr(t):
    if t:
        o = [k for k in ADDR.keys() if k.startswith(t)]
    else:
        o = ADDR.keys()
    if len(o) == 1: return ADDR[o[0]]
    return "(" + '\n'.join(o) + ")"

