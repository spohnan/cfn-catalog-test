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
	DEV_RELEASE?=/dev
endif

KEY_NAME := $(TEMPLATE_NAME)$(DEV_RELEASE)/$(VERSION)

# If this is a tagged release then overwrite the "latest" key
all:
ifeq ($(DEV_RELEASE),)
all: setup push-dev push-release cleanup
else
all: setup push-dev cleanup
endif
.PHONY: all

setup:
	$(eval TMPDIR := $(shell mktemp -d tmp.$(TEMPLATE_NAME).XXXXXXXX))
	@find submodules templates -type f -name "*.template" -exec cp --parents '{}' $(TMPDIR) \; 
	@find $(TMPDIR) -type f | xargs sed -i 's/VERSION_STRING_TOKEN.*/$(VERSION)/g'
	@find $(TMPDIR) -type f | xargs sed -i 's/BUCKET_NAME_TOKEN.*/$(BUCKET_NAME)/g'
	@find $(TMPDIR) -type f | xargs sed -i 's/KEY_NAME_TOKEN.*/$(subst /,\/,$(KEY_NAME))/g'

push-dev:
	@echo "Pushing to S3 as $(BUCKET_NAME)/$(KEY_NAME)"
	@aws s3 sync $(TMPDIR) s3://$(BUCKET_NAME)/$(KEY_NAME) --delete --only-show-errors --acl public-read

push-release:
	@echo "Pushing to S3 as $(BUCKET_NAME)/$(TEMPLATE_NAME)/latest"
	@aws s3 sync $(TMPDIR) s3://$(BUCKET_NAME)/$(TEMPLATE_NAME)/latest --delete --only-show-errors --acl public-read

cleanup:
	$(shell rm -rf $(TMPDIR))
