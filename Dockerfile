FROM gentoo/stage3-amd64-hardened
LABEL maintainer="Marek Szuba <marecki@gentoo.org>"

# Make sure /etc/portage/package.accept_keywords is a directory, not a file
#  - certain tools implicitly assume this to be the case
RUN [ "mkdir", "-p", "/etc/portage/package.accept_keywords" ]

# For consistency with other package.* we have got
RUN [ "mkdir", "-p", "/etc/portage/package.env" ]

# In case we need to override package.mask/use.mask, set package.provided etc.
RUN [ "mkdir", "-p", "/etc/portage/profile" ]

# This make.conf enables various non-default features required for
# ebuild stabilisation, and also disables default USE="bindist"
COPY files/etc/portage/make.conf /etc/portage/

# Initialise the Portage tree
# We will use subdirectories of /var/db/repos/local to inject tested ebuilds
# into the container
COPY files/etc/portage/env/*.conf /etc/portage/env/
COPY files/etc/portage/repos.conf/*.conf /etc/portage/repos.conf/
COPY files/portage-local-repo/layout.conf /var/db/repos/local/metadata/
COPY files/portage-local-repo/repo_name /var/db/repos/local/profiles/

# Make sure permissions on all copied files are sane

# FIXME: this may not work correctly when re-run on unmodified base image
# due to the way caching works in Docker.
RUN [ "emaint", "sync", "-a" ]

# If it is about anything in the base image, we are not interested
RUN [ "eselect", "news", "read", "--quiet", "all" ]
RUN [ "eselect", "news", "purge" ]

# Get the image in sync with the Portage tree + propagate use-flag changes
# introduced above
RUN [ "emerge", "-uUD", "--with-bdeps=y", "@world" ]
RUN [ "emerge", "@preserved-rebuild" ]
RUN [ "emerge", "--depclean" ]

RUN [ "emerge", "app-editors/vim", "app-portage/eix", "app-portage/gentoolkit" ]
RUN [ "mkdir", "-p", "-m", "0775", "/var/cache/eix" ]
RUN [ "chown", "portage:portage", "/var/cache/eix" ]
RUN [ "eix-update" ]

RUN [ "rm", "-rf", "/var/cache/distfiles/*" ]

CMD [ "/bin/bash" ]
