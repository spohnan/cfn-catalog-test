#
# Build process
#   - copy templates to temp dir
#   - replace all version tokens with the output of git describe
#   - push files to S3 bucket preserving version as part of the path
#

ifeq ($(BUCKET_NAME),)
	BUCKET_NAME?=cloudformation-041806844807
endif

ifeq ($(TEMPLATE_NAME),)
	TEMPLATE_NAME?=cfn-catalog-test
endif

# https://git-scm.com/docs/git-describe#_examples gives an explanation of the string format
VERSION := $(shell git describe --tags --always --dirty)

# If this version is not a freshly tagged release add a dev prefix (v0.4-1-gd0efeb4 vs v0.4)
ifeq ($(findstring -, $(VERSION)),-)
	DEVELOPMENT_FOLDER?=/dev
endif

KEY_NAME := $(TEMPLATE_NAME)$(DEVELOPMENT_FOLDER)/$(VERSION)

all: setup push cleanup
.PHONY: all

setup:
	$(eval TMPDIR := $(shell mktemp -d tmp.$(TEMPLATE_NAME).XXXXXXXX))
	@find submodules templates -type f -name "*.template" -exec cp --parents '{}' $(TMPDIR) \; 
	@find $(TMPDIR) -type f | xargs sed -i 's/VERSION_STRING_TOKEN.*/$(VERSION)/g'
	@find $(TMPDIR) -type f | xargs sed -i 's/BUCKET_NAME_TOKEN.*/$(BUCKET_NAME)/g'
	@find $(TMPDIR) -type f | xargs sed -i 's/KEY_NAME_TOKEN.*/$(subst /,\/,$(KEY_NAME))/g'

push:
	@aws s3 sync $(TMPDIR) s3://$(BUCKET_NAME)/$(KEY_NAME) --delete --only-show-errors --acl public-read
	@echo "Pushing to S3 as $(BUCKET_NAME)/$(KEY_NAME)"

cleanup:
	$(shell rm -rf $(TMPDIR))
