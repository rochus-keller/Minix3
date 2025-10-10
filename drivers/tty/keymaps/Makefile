# Generate binary keymaps.
# Modified for TCC compilation

LK = /usr/lib/keymaps

CC = tcc
CFLAGS = -m32 -I../../../include

.SUFFIXES: .src .map

.src.map:
	$(CC) $(CFLAGS) -DKEYSRC=\"$<\" genmap.c -o genmap
	./genmap > $@
	@rm -f genmap

all: \
	us-std.map \

install: \
	$(LK) \
	$(LK)/us-std.map \

clean:
	rm -f genmap *.map

$(LK):
	install -d $@

$(LK)/us-std.map: us-std.map
	install -c $? $@

.PHONY: all install clean

