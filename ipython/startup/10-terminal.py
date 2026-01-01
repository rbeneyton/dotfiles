from os import getenv

terminal_width = getenv("COLUMNS")
try:
    terminal_width = int(terminal_width)
except (ValueError, TypeError):
    terminal_width = None

if terminal_width is not None and terminal_width > 0:
    try:
        import numpy

        numpy.set_printoptions(linewidth=terminal_width)
    except:
        pass

del terminal_width
