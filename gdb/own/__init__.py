# -*- coding: utf-8 -*-

# from http://stackoverflow.com/questions/9233095/memory-dump-formatted-like-xxd-from-gdb

import gdb
from curses.ascii import isgraph

def groups_of(iterable, size, first=0):
    first = first if first != 0 else size
    chunk, iterable = iterable[:first], iterable[first:]
    while chunk:
        yield chunk
        chunk, iterable = iterable[:size], iterable[size:]

class HexDump(gdb.Command):
    def __init__(self):
        super (HexDump, self).__init__ ('hexdump', gdb.COMMAND_DATA)

    def invoke(self, arg, from_tty):
        argv = gdb.string_to_argv(arg)
        if len(argv) != 2:
            raise gdb.GdbError('hexdump takes exactly 2 arguments.')
        addr = gdb.parse_and_eval(argv[0]).cast(
            gdb.lookup_type('void').pointer())
        try:
            bytes = int(gdb.parse_and_eval(argv[1]))
        except ValueError:
            raise gdb.GdbError('Byte count numst be an integer value.')

        inferior = gdb.selected_inferior()

        align = gdb.parameter('hexdump-align')
        width = gdb.parameter('hexdump-width')
        if width == 0:
            width = 16

        mem = inferior.read_memory(addr, bytes)
        pr_addr = int(str(addr), 16)
        pr_offset = width

        if align:
            pr_offset = width - (pr_addr % width)
            pr_addr -= pr_addr % width

        for group in groups_of(mem, width, pr_offset):
            print('0x%x: ' % (pr_addr,) + '   '*(width - pr_offset))
            print(' '.join(['%02X' % (ord(g),) for g in group]) + \
                '   ' * (width - len(group) if pr_offset == width else 0) + ' ')
            print(' '*(width - pr_offset) +  ''.join(
                [g if isgraph(g) or g == ' ' else '.' for g in group]))
            pr_addr += width
            pr_offset = width

class HexDumpAlign(gdb.Parameter):
    def __init__(self):
        super (HexDumpAlign, self).__init__('hexdump-align',
                                            gdb.COMMAND_DATA,
                                            gdb.PARAM_BOOLEAN)

    set_doc = 'Determines if hexdump always starts at an "aligned" address (see hexdump-width'
    show_doc = 'Hex dump alignment is currently'

class HexDumpWidth(gdb.Parameter):
    def __init__(self):
        super (HexDumpWidth, self).__init__('hexdump-width',
                                            gdb.COMMAND_DATA,
                                            gdb.PARAM_INTEGER)

    set_doc = 'Set the number of bytes per line of hexdump'
    show_doc = 'The number of bytes per line in hexdump is'

HexDump()
HexDumpAlign()
HexDumpWidth()


