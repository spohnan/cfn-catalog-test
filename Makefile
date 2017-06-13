#
# Build process
#   - copy templates to temp dir
#   - replace all version tokens with the output of git describe
#   - push files to S3 bucket preserving version as part of the path
#

ifeq ($(CLOUDFORMATION_BUCKET),)
	CLOUDFORMATION_BUCKET?=cloudformation-041806844807
endif

ifeq ($(TEMPLATE_NAME),)
	TEMPLATE_NAME?=cfn-catalog-test
endif

# https://git-scm.com/docs/git-describe#_examples gives an explanation of the string format
VERSION := $(shell git describe --tags --always --dirty)

# If this version is not a freshly tagged release add a dev prefix
ifeq ($(findstring -, $(VERSION)),-)
	DEVELOPMENT_FOLDER?=/dev
endif

# S3 doesn't like .'s in path names so replace them with dashes
VERSION := $(subst .,-,$(VERSION))

KEY_PREFIX := $(TEMPLATE_NAME)$(DEVELOPMENT_FOLDER)/$(VERSION)

all: setup push cleanup
.PHONY: all

setup:
	$(eval TMPDIR := $(shell mktemp -d tmp.$(TEMPLATE_NAME).XXXXXXXX))
	@find submodules templates -type f -name "*.template" -exec cp --parents '{}' $(TMPDIR) \; 
	@find $(TMPDIR) -type f | xargs sed -i 's/VERSION_STRING_TOKEN.*/$(VERSION)/g'
	@find $(TMPDIR) -type f | xargs sed -i 's/BUCKET_NAME_TOKEN.*/$(CLOUDFORMATION_BUCKET)/g'
	@find $(TMPDIR) -type f | xargs sed -i 's/KEY_PREFIX_TOKEN.*/$(subst /,\/,$(KEY_PREFIX))/g'

push:
	@aws s3 sync $(TMPDIR) s3://$(CLOUDFORMATION_BUCKET)/$(KEY_PREFIX) --delete --only-show-errors --acl public-read
	@echo "Pushing to S3 as $(CLOUDFORMATION_BUCKET)/$(KEY_PREFIX)"

cleanup:
	$(shell rm -rf $(TMPDIR))
