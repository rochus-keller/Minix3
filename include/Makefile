# Makefile for system headers
# Modified for TCC compilation - installs modified headers

INC=/usr/include

all::
	@echo "Headers ready for installation"

clean::
	@echo "Nothing to clean in headers"

install::
	@echo "Installing Minix headers to $(INC)..."
	-rm -rf $(INC)/minix $(INC)/sys $(INC)/ibm
	mkdir -p $(INC)
	cp -r . $(INC)
	@chown -R bin $(INC) 2>/dev/null || true
	@rm -f $(INC)/Makefile
	@echo "Headers installed successfully"

# Alternative: Install to local directory for cross-compilation
install-local:
	@echo "Installing headers to ./usr/include for local build..."
	mkdir -p ./usr/include
	cp -r . ./usr/include/
	@rm -f ./usr/include/Makefile
	@echo "Local headers installed"

.PHONY: all clean install install-local

