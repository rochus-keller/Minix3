# Makefile for system headers
# Modified for TCC cross-compilation - Local install only

INC=./usr/include

all::
	@echo "Headers ready for installation"

clean::
	@echo "Cleaning local header installation..."
	rm -rf ./usr

install-local:
	@echo "Installing Minix headers to $(INC)..."
	@# Remove old installation
	rm -rf $(INC)
	@# Create fresh directory structure
	mkdir -p $(INC)/minix
	mkdir -p $(INC)/sys
	mkdir -p $(INC)/ibm
	@# Copy headers, excluding usr directory and Makefile
	@echo "Copying top-level headers..."
	@for f in *.h; do \
		test -f "$$f" && cp "$$f" $(INC)/ || true; \
	done
	@echo "Copying minix/ headers..."
	@test -d minix && cp minix/*.h $(INC)/minix/ 2>/dev/null || true
	@echo "Copying sys/ headers..."
	@test -d sys && cp sys/*.h $(INC)/sys/ 2>/dev/null || true
	@echo "Copying ibm/ headers..."
	@test -d ibm && cp ibm/*.h $(INC)/ibm/ 2>/dev/null || true
	@echo "Headers installed successfully to $(INC)"

# Alias for compatibility  
install: install-local

.PHONY: all clean install-local install

