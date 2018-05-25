FROM gentoo/stage3-amd64-hardened
LABEL maintainer="Marek Szuba <marecki@gentoo.org>"

# Make sure /etc/portage/package.keywords is a directory, not a file
#  - certain tools implicitly assume this to be the case
RUN [ "mkdir", "-p", "/etc/portage/package.keywords" ]

# This make.conf enables various non-default features required for
# ebuild stabilisation, and also disables default USE="bindist"
COPY files/etc/portage/make.conf /etc/portage/

# Initialise the Portage tree
# We will use subdirectories of /usr/local/portage to inject tested ebuilds
# into the container
COPY files/etc/portage/env/*.conf /etc/portage/env/
COPY files/etc/portage/repos.conf/*.conf /etc/portage/repos.conf/
COPY files/portage-local-repo/layout.conf /usr/local/portage/metadata/
COPY files/portage-local-repo/repo_name /usr/local/portage/profiles/
# FIXME: this may not work correctly when re-run on unmodified base image
# due to the way caching works in Docker.
RUN [ "emaint", "sync", "-a" ]

# As of end of May 2018, gentoo/stage3-amd64-hardened uses the stable
# profile 17.0/hardened so we need to manually go through all the steps
# required to upgrade to still-experimental 17.1
RUN [ "emerge", "-1", "app-portage/unsymlink-lib" ]
RUN [ "unsymlink-lib", "--analyze" ]
RUN [ "unsymlink-lib", "--migrate" ]
RUN [ "unsymlink-lib", "--finish" ]
RUN [ "eselect", "profile", "set", "--force", "default/linux/amd64/17.1/hardened" ]
RUN [ "emerge", "-1v", "/usr/lib/gcc", "/lib32", "/usr/lib32" ]
RUN [ "rm", "-f", "/lib32", "/usr/lib32" ]

# If it is about anything in the base image, we are not interested
RUN [ "eselect", "news", "read", "--quiet", "all" ]
RUN [ "eselect", "news", "purge" ]

# Get the image in sync with the Portage tree + propagate use-flag changes
# introduced above
RUN [ "emerge", "-uUD", "--with-bdeps=y", "@world" ]
RUN [ "emerge", "@preserved-rebuild" ]
RUN [ "emerge", "--depclean" ]

RUN [ "emerge", "app-editors/vim", "app-portage/eix", "app-portage/gentoolkit" ]
RUN [ "eix-update" ]

RUN [ "rm", "-rf", "/usr/portage/distfiles/*" ]

CMD [ "/bin/bash" ]
