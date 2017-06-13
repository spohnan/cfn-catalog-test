#
#
#

VERSION := $(shell git describe --tags --always --dirty)

ifeq ($(CLOUDFORMATION_BUCKET),)
	CLOUDFORMATION_BUCKET?=cloudformation-041806844807
endif

ifeq ($(TEMPLATE_NAME),)
	TEMPLATE_NAME?=cfn-catalog-test
endif

all: setup push cleanup
.PHONY: all

setup:
	$(eval TMPDIR := $(shell mktemp -d tmp.$(TEMPLATE_NAME).XXXXXXXX))
	@find submodules templates -type f -name "*.template" -exec cp --parents '{}' $(TMPDIR) \; 
	@find $(TMPDIR) -type f | xargs sed -i 's/VERSION_STRING.*/$(VERSION)/g'

push:
	@aws s3 sync $(TMPDIR) s3://$(CLOUDFORMATION_BUCKET)/$(TEMPLATE_NAME)/$(VERSION) --delete --only-show-errors --acl public-read

cleanup:
	$(shell rm -rf $(TMPDIR))
